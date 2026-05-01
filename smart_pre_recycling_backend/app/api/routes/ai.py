from fastapi import APIRouter, UploadFile, File
import random

router = APIRouter(prefix="/ai", tags=["AI"])

@router.post("/predict")
async def predict(file: UploadFile = File(...)):
    categories = ["plastic", "glass", "metal", "organic"]

    result = random.choice(categories)
    confidence = round(random.uniform(0.8, 0.98), 2)

    return {
        "class": result,
        "confidence": confidence,
        "recommendation": f"Dispose in {result} recycling bin."
    }