from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.model.scan import Scan
from app.model.user import User
from app.schemas.scan import ScanCreate, ScanResponse

router = APIRouter(prefix="/scans", tags=["Scans"])


@router.post("/", response_model=ScanResponse)
def create_scan(scan: ScanCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == scan.user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    co2_value = scan.weight * 0.5

    new_scan = Scan(
        user_id=scan.user_id,
        material_type=scan.material_type,
        weight=scan.weight,
        co2_saved=co2_value,
    )

    db.add(new_scan)

    user.total_scans += 1
    user.total_co2_saved += co2_value

    db.commit()
    db.refresh(new_scan)

    return new_scan


@router.get("/user/{user_id}", response_model=list[ScanResponse])
def get_user_scans(user_id: int, db: Session = Depends(get_db)):
    return db.query(Scan).filter(Scan.user_id == user_id).all()