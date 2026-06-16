from pydantic import BaseModel
from datetime import datetime


class ScanCreate(BaseModel):
    user_id: int
    material_type: str
    recyclable: bool


class ScanResponse(BaseModel):
    id: int
    user_id: int
    material_type: str
    recyclable: bool
    created_at: datetime

    class Config:
        from_attributes = True