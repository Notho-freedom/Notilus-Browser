"""
Notilus Browser - Backend API
API principale pour les services du navigateur Notilus
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from dotenv import load_dotenv
import os

from services.monitoring import router as monitoring_router
from services.detection import router as detection_router
from services.injection import router as injection_router
from services.automation import router as automation_router
from services.ai_service import router as ai_router

# Charger les variables d'environnement
load_dotenv()

app = FastAPI(
    title="Notilus Browser API",
    description="API backend pour le navigateur Notilus",
    version="1.0.0"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclure les routers des services
app.include_router(monitoring_router, prefix="/api/monitoring", tags=["monitoring"])
app.include_router(detection_router, prefix="/api/detection", tags=["detection"])
app.include_router(injection_router, prefix="/api/injection", tags=["injection"])
app.include_router(automation_router, prefix="/api/automation", tags=["automation"])
app.include_router(ai_router, prefix="/api/ai", tags=["ai"])


@app.get("/")
async def root():
    """Endpoint racine"""
    return {
        "name": "Notilus Browser API",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/api/health")
async def health_check():
    """Vérification de l'état de l'API"""
    return {
        "status": "healthy",
        "service": "notilus-api"
    }


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=True
    )

