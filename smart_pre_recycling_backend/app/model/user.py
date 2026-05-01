from sqlalchemy import Column, Integer, String, DateTime, Float
from datetime import datetime
from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    # 🔥 هنضيف ده عشان نربط Firebase بالـ Backend
    firebase_uid = Column(String, unique=True, index=True)

    email = Column(String, unique=True, index=True)
    name = Column(String)

    created_at = Column(DateTime, default=datetime.utcnow)

    total_scans = Column(Integer, default=0)
    total_co2_saved = Column(Float, default=0.0)