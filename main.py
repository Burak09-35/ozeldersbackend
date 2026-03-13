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
    password: str # Gerçek projede bu hash'lenmeli!
    rol: str

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

@app.get("/lessons", response_model=List[LessonResponse])
def get_lessons(db: Session = Depends(get_db)):
    return db.query(LessonTable).all()

@app.post("/lessons", response_model=LessonResponse)
def create_lesson(lesson: LessonCreate, db: Session = Depends(get_db)):
    db_lesson = LessonTable(**lesson.dict())
    db.add(db_lesson)
    db.commit()
    db.refresh(db_lesson)
    return db_lesson

@app.post("/register")
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(UserTable).filter(UserTable.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Bu email zaten kayıtlı")
    
    new_user = UserTable(
        uid=f"u_{datetime.now().timestamp()}", 
        adSoyad=user.adSoyad,
        email=user.email,
        password=user.password, # ŞİFREYİ BURADA KAYDEDİYORUZ
        rol=user.rol
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"message": "Kayit basairili"}

@app.put("/lessons/{lesson_id}")
def update_lesson(lesson_id: int, updated_data: dict, db: Session = Depends(get_db)):
    db_lesson = db.query(LessonTable).filter(LessonTable.id == lesson_id).first()
    if not db_lesson:
        raise HTTPException(status_code=404, detail="Ders bulunamadı")
    
    for key, value in updated_data.items():
        if hasattr(db_lesson, key):
            # Tarih string gelirse datetime'a çevir
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