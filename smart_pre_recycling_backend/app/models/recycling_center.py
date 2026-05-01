from sqlalchemy import Column, Integer, String, Float
from app.db.base import Base


class RecyclingCenter(Base):
    __tablename__ = "recycling_centers"

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String)
    latitude = Column(Float)
    longitude = Column(Float)

    type = Column(String)  # plastic / glass / metal