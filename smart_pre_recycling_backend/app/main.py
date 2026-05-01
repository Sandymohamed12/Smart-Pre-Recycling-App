from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Firebase Admin
import firebase_admin
from firebase_admin import credentials

# Routers
from app.api.routes import health, users, scans, recycling_centers

# Database
from app.db.session import engine
from app.db.base import Base

# Import models
from app.models import user, scan, recycling_center

app = FastAPI(title="Smart Pre Recycling Backend")

# ================= CORS =================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ================= Firebase (SAFE INIT) =================
try:
    cred = credentials.Certificate(
        "smart-pre-recycling-firebase-adminsdk-fbsvc-946269cdfb.json"
    )
    firebase_admin.initialize_app(cred)
    print("Firebase initialized ✅")
except Exception as e:
    print("Firebase not initialized ⚠️:", e)

# ================= Database =================
Base.metadata.create_all(bind=engine)

# ================= Routers =================
app.include_router(health.router)
app.include_router(users.router)
app.include_router(scans.router)
app.include_router(recycling_centers.router)

# ================= Root =================
@app.get("/")
def root():
    return {"message": "Backend + DB connected 🚀"}