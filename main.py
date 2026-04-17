from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, String, Integer, Boolean, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel
from datetime import datetime
import os

# --- 1. VERİTABANI AYARLARI (Bulut Uyumlu) ---
# Render veya Koyeb'e yüklediğimizde sistem kendi 'DATABASE_URL' adresini kullanacak.
# Senin bilgisayarındayken ise aşağıdaki Neon linkini kullanacak.
NEON_LINK = "postgresql://neondb_owner:npg_WAnoRD3GYQu4@ep-spring-fire-alwr55p7-pooler.c-3.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"
SQLALCHEMY_DATABASE_URL = os.environ.get("DATABASE_URL", NEON_LINK)

# SQLAlchemy 'postgres://' sevmez, onu düzeltiyoruz (Bulut sunucuları bazen eski tip link verir)
if SQLALCHEMY_DATABASE_URL.startswith("postgres://"):
    SQLALCHEMY_DATABASE_URL = SQLALCHEMY_DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- 2. VERİTABANI MODELLERİ ---
class UserTable(Base):
    __tablename__ = "users"
    uid = Column(String, primary_key=True, index=True)
    adSoyad = Column(String)
    email = Column(String, unique=True)
    telefon = Column(String, unique=True, index=True)
    rol = Column(String)
    password = Column(String)

class LessonTable(Base):
    __tablename__ = "lessons"
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    ogretmenId = Column(String)
    ogretmenAdi = Column(String)
    ogrenciId = Column(String)
    ogrenciAdi = Column(String)
    konu = Column(String)
    tarih = Column(DateTime)
    saat = Column(Integer)
    dakika = Column(Integer)
    odemeAlindi = Column(Boolean, default=False)
    katilimTamamlandi = Column(Boolean, default=False)

class OgretmenOgrenciLink(Base):
    __tablename__ = "ogretmen_ogrenci_link"
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    ogretmenId = Column(String, index=True)
    ogrenciId = Column(String, index=True)

# Tabloları veritabanında oluştur (sadece ilk çalışmada tabloları kurar, sonra dokunmaz)
Base.metadata.create_all(bind=engine)

# --- 3. PYDANTIC MODELLERİ ---
class LessonCreate(BaseModel):
    ogretmenId: str
    ogretmenAdi: str
    ogrenciId: str
    ogrenciAdi: str
    konu: str
    tarih: datetime
    saat: int
    dakika: int
    odemeAlindi: bool = False
    katilimTamamlandi: bool = False

class LessonResponse(LessonCreate):
    id: int
    class Config:
        from_attributes = True

class UserCreate(BaseModel):
    adSoyad: str
    email: str
    telefon: str
    password: str
    rol: str

class LoginRequest(BaseModel):
    email: str
    password: str

class OgrenciEkleRequest(BaseModel):
    ogretmenId: str
    ogrenciTelefon: str

# --- 4. FASTAPI BAŞLATMA ---
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- 5. ENDPOINTLER ---

@app.get("/")
def home():
    return {"message": "Ozel Ders API Sorunsuz Calisiyor!"}

@app.get("/lessons")
def get_lessons(user_id: str, db: Session = Depends(get_db)):
    return db.query(LessonTable).filter(
        (LessonTable.ogretmenId == user_id) | (LessonTable.ogrenciId == user_id)
    ).all()

@app.post("/lessons", response_model=LessonResponse)
def create_lesson(lesson: LessonCreate, db: Session = Depends(get_db)):
    db_lesson = LessonTable(**lesson.dict())
    db.add(db_lesson)
    db.commit()
    db.refresh(db_lesson)
    return db_lesson

@app.post("/register")
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    if db.query(UserTable).filter(UserTable.email == user.email).first():
        raise HTTPException(status_code=400, detail="Bu email zaten kayıtlı")
    if db.query(UserTable).filter(UserTable.telefon == user.telefon).first():
        raise HTTPException(status_code=400, detail="Bu telefon numarası zaten kayıtlı")
    
    new_user = UserTable(
        uid=f"u_{datetime.now().timestamp()}", 
        adSoyad=user.adSoyad,
        email=user.email,
        telefon=user.telefon,
        password=user.password, 
        rol=user.rol
    )
    db.add(new_user)
    db.commit()
    return {"message": "Kayıt başarılı", "uid": new_user.uid}

@app.post("/login")
def login_user(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(UserTable).filter(UserTable.email == req.email).first()
    if not user or user.password != req.password:
        raise HTTPException(status_code=401, detail="Hatalı giriş")
    return {"message": "Giriş başarılı", "user": {"uid": user.uid, "adSoyad": user.adSoyad, "rol": user.rol}}

@app.post("/ogrenci_ekle")
def ogrenci_ekle(req: OgrenciEkleRequest, db: Session = Depends(get_db)):
    ogrenci = db.query(UserTable).filter(UserTable.telefon == req.ogrenciTelefon).first()
    if not ogrenci or ogrenci.rol != "öğrenci":
        raise HTTPException(status_code=404, detail="Öğrenci bulunamadı")
    
    mevcut = db.query(OgretmenOgrenciLink).filter(
        OgretmenOgrenciLink.ogretmenId == req.ogretmenId, OgretmenOgrenciLink.ogrenciId == ogrenci.uid
    ).first()
    if mevcut:
        raise HTTPException(status_code=400, detail="Zaten ekli")
        
    db.add(OgretmenOgrenciLink(ogretmenId=req.ogretmenId, ogrenciId=ogrenci.uid))
    db.commit()
    return {"message": f"{ogrenci.adSoyad} eklendi"}

@app.get("/ogrencilerim")
def ogrencilerimi_getir(ogretmen_id: str, db: Session = Depends(get_db)):
    baglantilar = db.query(OgretmenOgrenciLink).filter(OgretmenOgrenciLink.ogretmenId == ogretmen_id).all()
    ids = [b.ogrenciId for b in baglantilar]
    return db.query(UserTable).filter(UserTable.uid.in_(ids)).all()

@app.put("/lessons/{lesson_id}")
def update_lesson(lesson_id: int, updated_data: dict, db: Session = Depends(get_db)):
    db_lesson = db.query(LessonTable).filter(LessonTable.id == lesson_id).first()
    if not db_lesson: raise HTTPException(status_code=404, detail="Ders yok")
    for key, value in updated_data.items():
        if hasattr(db_lesson, key):
            if key == "tarih" and isinstance(value, str): value = datetime.fromisoformat(value)
            setattr(db_lesson, key, value)
    db.commit()
    return {"message": "Güncellendi"}

@app.delete("/lessons/{lesson_id}")
def delete_lesson(lesson_id: int, db: Session = Depends(get_db)):
    db_lesson = db.query(LessonTable).filter(LessonTable.id == lesson_id).first()
    if db_lesson:
        db.delete(db_lesson)
        db.commit()
    return {"message": "Silindi"}

# --- 6. ÇALIŞTIRMA AYARI (Dinamik Port) ---
if __name__ == "__main__":
    import uvicorn
    # En önemli kısım: Bulut sunucusu kendi portunu 'PORT' değişkeniyle yollar.
    # Eğer o değişken yoksa (kendi bilgisayarındaysan), varsayılan olarak 5000 portunu kullanır.
    port = int(os.environ.get("PORT", 5000))
    uvicorn.run(app, host="0.0.0.0", port=port)