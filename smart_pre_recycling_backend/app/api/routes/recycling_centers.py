from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.model.recycling_center import RecyclingCenter

router = APIRouter(prefix="/centers", tags=["Recycling Centers"])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# 🔹 Get all recycling centers
@router.get("/")
def get_centers(db: Session = Depends(get_db)):
    return db.query(RecyclingCenter).all()


# 🔹 Add recycling center
@router.post("/")
def add_center(name: str, latitude: float, longitude: float, type: str, db: Session = Depends(get_db)):

    center = RecyclingCenter(
        name=name,
        latitude=latitude,
        longitude=longitude,
        type=type
    )

    db.add(center)
    db.commit()
    db.refresh(center)

    return center