from pydantic import BaseModel
from datetime import datetime


class ScanCreate(BaseModel):
    user_id: int
    material_type: str
    weight: float


class ScanResponse(BaseModel):
    id: int
    user_id: int
    material_type: str
    weight: float
    co2_saved: float
    created_at: datetime

    class Config:
        from_attributes = True