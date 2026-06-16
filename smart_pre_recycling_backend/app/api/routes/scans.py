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

    new_scan = Scan(
        user_id=scan.user_id,
        material_type=scan.material_type,
        recyclable=scan.recyclable,
    )

    db.add(new_scan)

    user.total_scans += 1

    db.commit()
    db.refresh(new_scan)

    return new_scan


@router.get("/user/{user_id}", response_model=list[ScanResponse])
def get_user_scans(user_id: int, db: Session = Depends(get_db)):
    return db.query(Scan).filter(Scan.user_id == user_id).all()


# DELETE SCAN
@router.delete("/{scan_id}")
def delete_scan(scan_id: int, db: Session = Depends(get_db)):
    scan = db.query(Scan).filter(Scan.id == scan_id).first()

    if not scan:
        raise HTTPException(
            status_code=404,
            detail="Scan not found",
        )

    user = db.query(User).filter(
        User.id == scan.user_id
    ).first()

    if user and user.total_scans > 0:
        user.total_scans -= 1

    db.delete(scan)
    db.commit()

    return {
        "message": "Scan deleted successfully"
    }
@router.delete("/user/{user_id}/all")
def delete_all_scans(
    user_id: int,
    db: Session = Depends(get_db),
):
    scans = db.query(Scan).filter(
        Scan.user_id == user_id
    ).all()

    for scan in scans:
        db.delete(scan)

    user = db.query(User).filter(
        User.id == user_id
    ).first()

    if user:
        user.total_scans = 0

    db.commit()

    return {
        "message": "All scans deleted"
    }
    