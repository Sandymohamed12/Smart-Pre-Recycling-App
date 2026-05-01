from pydantic import BaseModel
from datetime import datetime


class UserCreate(BaseModel):
    firebase_uid: str
    email: str
    name: str


class UserUpdate(BaseModel):
    name: str


class UserResponse(BaseModel):
    id: int
    firebase_uid: str
    email: str
    name: str
    created_at: datetime
    total_scans: int
    total_co2_saved: float

    class Config:
        from_attributes = True