from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, String, Integer, Boolean, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

# 1. VERİTABANI AYARLARI (SQLite)
SQLALCHEMY_DATABASE_URL = "sqlite:///./ozelders.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 2. VERİTABANI MODELLERİ (SQLAlchemy)
class UserTable(Base):
    __tablename__ = "users"
    uid = Column(String, primary_key=True, index=True)
    adSoyad = Column(String)
    email = Column(String, unique=True)
    telefon = Column(String, unique=True, index=True) # YENİ EKLENDİ
    rol = Column(String)  # öğretmen / öğrenci
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

# YENİ EKLENEN KÖPRÜ TABLO (Öğretmen-Öğrenci İlişkisi)
class OgretmenOgrenciLink(Base):
    __tablename__ = "ogretmen_ogrenci_link"
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    ogretmenId = Column(String, index=True)
    ogrenciId = Column(String, index=True)

Base.metadata.create_all(bind=engine)

# 3. PYDANTIC MODELLERİ (Veri Transferi İçin)
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
    telefon: str # YENİ EKLENDİ
    password: str # Gerçek projede bu hash'lenmeli!
    rol: str

class LoginRequest(BaseModel):
    email: str
    password: str

class OgrenciEkleRequest(BaseModel):
    ogretmenId: str
    ogrenciTelefon: str

# 4. FASTAPI BAŞLATMA
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# DB Bağlantısı Yardımcısı
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 5. ENDPOINTLER (API Uç Noktaları)

@app.get("/lessons")
def get_lessons(user_id: str, db: Session = Depends(get_db)):
    lessons = db.query(LessonTable).filter(
        (LessonTable.ogretmenId == user_id) | (LessonTable.ogrenciId == user_id)
    ).all()
    return lessons

@app.post("/lessons", response_model=LessonResponse)
def create_lesson(lesson: LessonCreate, db: Session = Depends(get_db)):
    db_lesson = LessonTable(**lesson.dict())
    db.add(db_lesson)
    db.commit()
    db.refresh(db_lesson)
    return db_lesson

@app.post("/register")
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    # Hem email hem de telefon benzersiz olmalı
    db_user_email = db.query(UserTable).filter(UserTable.email == user.email).first()
    if db_user_email:
        raise HTTPException(status_code=400, detail="Bu email zaten kayıtlı")
        
    db_user_tel = db.query(UserTable).filter(UserTable.telefon == user.telefon).first()
    if db_user_tel:
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
    db.refresh(new_user)
    return {"message": "Kayıt başarılı", "uid": new_user.uid}

@app.post("/login")
def login_user(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(UserTable).filter(UserTable.email == req.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    if user.password != req.password:
        raise HTTPException(status_code=401, detail="Hatalı şifre")
    
    return {
        "message": "Giriş başarılı",
        "user": {
            "uid": user.uid,
            "adSoyad": user.adSoyad,
            "rol": user.rol,
            "telefon": user.telefon
        }
    }

# --- YENİ EKLENEN ENDPOINTLER ---

@app.post("/ogrenci_ekle")
def ogrenci_ekle(req: OgrenciEkleRequest, db: Session = Depends(get_db)):
    # 1. Telefon numarasından öğrenciyi bul
    ogrenci = db.query(UserTable).filter(UserTable.telefon == req.ogrenciTelefon).first()
    
    if not ogrenci:
        raise HTTPException(status_code=404, detail="Bu numaraya ait bir kullanıcı bulunamadı.")
    
    if ogrenci.rol != "öğrenci":
        raise HTTPException(status_code=400, detail="Eklemeye çalıştığınız kişi bir öğrenci değil.")
        
    # 2. Zaten ekli mi diye kontrol et
    mevcut_baglanti = db.query(OgretmenOgrenciLink).filter(
        OgretmenOgrenciLink.ogretmenId == req.ogretmenId,
        OgretmenOgrenciLink.ogrenciId == ogrenci.uid
    ).first()
    
    if mevcut_baglanti:
        raise HTTPException(status_code=400, detail="Bu öğrenci zaten listenizde ekli.")
        
    # 3. Bağlantıyı kur ve kaydet
    yeni_baglanti = OgretmenOgrenciLink(ogretmenId=req.ogretmenId, ogrenciId=ogrenci.uid)
    db.add(yeni_baglanti)
    db.commit()
    
    return {"message": f"{ogrenci.adSoyad} başarıyla öğrencilerinize eklendi!", "ogrenciAdi": ogrenci.adSoyad}

@app.get("/ogrencilerim")
def ogrencilerimi_getir(ogretmen_id: str, db: Session = Depends(get_db)):
    # 1. Öğretmenin bağlantılı olduğu öğrenci ID'lerini bul
    baglantilar = db.query(OgretmenOgrenciLink).filter(OgretmenOgrenciLink.ogretmenId == ogretmen_id).all()
    
    if not baglantilar:
        return []
        
    ogrenci_idleri = [b.ogrenciId for b in baglantilar]
    
    # 2. O ID'lere sahip kullanıcıların bilgilerini getir
    ogrenciler = db.query(UserTable).filter(UserTable.uid.in_(ogrenci_idleri)).all()
    
    # Şifre gibi kritik bilgileri dışarı sızdırmadan sadece gerekenleri döndürüyoruz
    return [{"uid": o.uid, "adSoyad": o.adSoyad, "telefon": o.telefon} for o in ogrenciler]

# --------------------------------

@app.put("/lessons/{lesson_id}")
def update_lesson(lesson_id: int, updated_data: dict, db: Session = Depends(get_db)):
    db_lesson = db.query(LessonTable).filter(LessonTable.id == lesson_id).first()
    if not db_lesson:
        raise HTTPException(status_code=404, detail="Ders bulunamadı")
    
    for key, value in updated_data.items():
        if hasattr(db_lesson, key):
            if key == "tarih" and isinstance(value, str):
                value = datetime.fromisoformat(value)
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