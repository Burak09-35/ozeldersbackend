from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

# Veri Modeli (Flutter'dan gelecek verinin yapısı)
class Lesson(BaseModel):
    student_name: str
    subject: str
    price: float
    is_paid: bool = False

# Şimdilik veritabanı yerine basit bir liste kullanalım
db_lessons = []

@app.get("/")
def home():
    return {"status": "Backend Çalışıyor", "user": "Burak"}

# Tüm dersleri getiren endpoint
@app.get("/lessons", response_model=List[Lesson])
def get_all_lessons():
    return db_lessons

# Yeni ders ekleyen endpoint
@app.post("/lessons")
def create_lesson(lesson: Lesson):
    db_lessons.append(lesson)
    return {"message": "Ders başarıyla kaydedildi!", "data": lesson}