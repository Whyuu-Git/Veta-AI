# Entry point aplikasi FastAPI.
# Jalankan dengan: uvicorn app.main:app --reload --port 8000
# Dokumentasi & testing interaktif otomatis: http://localhost:8000/docs

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers.auth import router as auth_router
from app.routers.profile import router as profile_router
from app.routers.researches import router as researches_router
from app.routers.mentor import router as mentor_router
from app.routers.intelligence import router as intelligence_router
from app.routers.notes import router as research_notes_router
from app.routers.pdf import router as pdf_router

app = FastAPI(title="AI Research Companion API")

# CORS: izinkan app Flutter (yang jalan di alamat/port berbeda) akses API ini.
# Untuk development diizinkan semua asal ("*") dulu, dipersempit sebelum rilis.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(researches_router)
app.include_router(mentor_router)
app.include_router(intelligence_router)
app.include_router(research_notes_router)
app.include_router(pdf_router)


@app.get("/")
async def root():
    # Endpoint sederhana buat cek server hidup
    return {"status": "ok", "message": "AI Research Companion API jalan"}