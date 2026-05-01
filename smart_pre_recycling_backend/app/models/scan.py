from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from datetime import datetime
from app.db.base import Base


class Scan(Base):
    __tablename__ = "scans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    material_type = Column(String)
    weight = Column(Float)
    co2_saved = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)