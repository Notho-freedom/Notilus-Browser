"""
Notilus Browser - Backend API
API principale pour les services du navigateur Notilus
Inclut le Backend Lab - Système de tests backend ultra-avancé
"""

import sys
import os

# Ajouter le répertoire du script au PYTHONPATH pour que les imports locaux fonctionnent
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from dotenv import load_dotenv

# Services existants
from services.monitoring import router as monitoring_router
from services.detection import router as detection_router
from services.injection import router as injection_router
from services.automation import router as automation_router
from services.ai_service import router as ai_router
from services.oauth_service import router as oauth_router
from services.tts import router as tts_router

# Backend Lab - Le système de tests backend le plus avancé
from backend_lab.server_discovery import router as server_discovery_router
from backend_lab.route_discovery import router as route_discovery_router
from backend_lab.api_testing import router as api_testing_router
from backend_lab.interception import router as interception_router
from backend_lab.security_scanner import router as security_scanner_router
from backend_lab.performance_lab import router as performance_lab_router
from backend_lab.mock_server import router as mock_server_router
from backend_lab.analytics import router as analytics_router
from backend_lab.auto_config import router as auto_config_router
from backend_lab.console import router as console_router, ConsoleMiddleware
# Importer pour initialiser le handler de console
import backend_lab.console
# Réinitialiser les handlers après la configuration de logging
backend_lab.console.initialize_console_handlers()

# Charger les variables d'environnement
load_dotenv()

app = FastAPI(
    title="Notilus Browser API",
    description="""
    ## API backend pour le navigateur Notilus
    
    ### 🐙 Backend Lab - Système de tests backend ultra-avancé
    
    Le Backend Lab est un écosystème complet pour:
    - 🔍 **Server Discovery**: Détection automatique des serveurs locaux
    - 🗺️ **Route Discovery**: Découverte intelligente des endpoints API
    - 🧪 **API Testing**: Tests fonctionnels complets avec assertions
    - 💉 **Interception**: Capture, modification et replay de requêtes
    - 🛡️ **Security Scanner**: Tests de sécurité OWASP avancés
    - ⚡ **Performance Lab**: Tests de charge et stress
    - 🎭 **Mock Server**: Simulation d'APIs
    - 📊 **Analytics**: Dashboards et rapports
    
    ### 🔊 Services TTS
    - **Text-to-Speech**: Synthèse vocale avec Microsoft Edge TTS
    - Détection automatique de langue
    - Support multi-langues et multi-voix
    """,
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware pour capturer les logs de requêtes
app.add_middleware(ConsoleMiddleware)

# ============================================================================
# Services existants
# ============================================================================
app.include_router(monitoring_router, prefix="/api/monitoring", tags=["Monitoring"])
app.include_router(detection_router, prefix="/api/detection", tags=["Detection"])
app.include_router(injection_router, prefix="/api/injection", tags=["Injection"])
app.include_router(automation_router, prefix="/api/automation", tags=["Automation"])
app.include_router(ai_router, prefix="/api/ai", tags=["AI"])
app.include_router(oauth_router, prefix="/api/oauth", tags=["🔐 OAuth"])
app.include_router(tts_router, prefix="/api/tts", tags=["🔊 TTS"])

# ============================================================================
# Backend Lab - Le système de tests backend inégalable
# ============================================================================
app.include_router(
    server_discovery_router, 
    prefix="/api/backend-lab/servers", 
    tags=["🔍 Server Discovery"]
)
app.include_router(
    route_discovery_router, 
    prefix="/api/backend-lab/routes", 
    tags=["🗺️ Route Discovery"]
)
app.include_router(
    api_testing_router, 
    prefix="/api/backend-lab/tests", 
    tags=["🧪 API Testing"]
)
app.include_router(
    interception_router, 
    prefix="/api/backend-lab/intercept", 
    tags=["💉 Interception"]
)
app.include_router(
    security_scanner_router, 
    prefix="/api/backend-lab/security", 
    tags=["🛡️ Security Scanner"]
)
app.include_router(
    performance_lab_router, 
    prefix="/api/backend-lab/performance", 
    tags=["⚡ Performance Lab"]
)
app.include_router(
    mock_server_router, 
    prefix="/api/backend-lab/mocks", 
    tags=["🎭 Mock Server"]
)
app.include_router(
    analytics_router, 
    prefix="/api/backend-lab/analytics", 
    tags=["📊 Analytics"]
)
app.include_router(
    auto_config_router, 
    prefix="/api/backend-lab/auto-config", 
    tags=["⚙️ Auto Configuration"]
)
app.include_router(
    console_router, 
    prefix="/api/backend-lab/console", 
    tags=["🖥️ Console"]
)


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
    import logging.config
    import sys
    
    # Créer le répertoire de logs s'il n'existe pas
    log_dir = os.path.join(os.path.dirname(__file__), "logs")
    os.makedirs(log_dir, exist_ok=True)
    
    # Chemin du fichier de log
    log_file = os.path.join(log_dir, "backend.log")
    
    # Configuration de logging pour capturer tous les logs
    # En mode furtif (pythonw.exe), stdout/stderr ne sont pas disponibles
    # On écrit donc dans un fichier ET stdout si disponible
    log_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "default": {
                "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            },
            "access": {
                "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            },
        },
        "handlers": {
            "file": {
                "formatter": "default",
                "class": "logging.FileHandler",
                "filename": log_file,
                "mode": "a",
                "encoding": "utf-8",
            },
            "default": {
                "formatter": "default",
                "class": "logging.StreamHandler",
                "stream": "ext://sys.stdout",
            },
            "access": {
                "formatter": "access",
                "class": "logging.StreamHandler",
                "stream": "ext://sys.stdout",
            },
        },
        "loggers": {
            "uvicorn": {"handlers": ["file", "default"], "level": "INFO", "propagate": False},
            "uvicorn.error": {"handlers": ["file", "default"], "level": "INFO", "propagate": False},
            "uvicorn.access": {"handlers": ["file", "access"], "level": "INFO", "propagate": False},
            "fastapi": {"handlers": ["file", "default"], "level": "INFO", "propagate": False},
        },
        "root": {
            "handlers": ["file", "default"],
            "level": "INFO",
        },
    }
    
    # Appliquer la configuration
    logging.config.dictConfig(log_config)
    
    # Logger le démarrage
    logger = logging.getLogger(__name__)
    logger.info("=" * 60)
    logger.info("Démarrage du backend Notilus")
    logger.info(f"Python: {sys.executable}")
    logger.info(f"Port: {os.getenv('PORT', '8000')}")
    logger.info(f"Log file: {log_file}")
    logger.info("=" * 60)
    
    try:
        port = int(os.getenv("PORT", 8000))
        # Désactiver reload en mode embarqué (pas de watchfiles)
        logger.info(f"Démarrage d'uvicorn sur 127.0.0.1:{port}")
        uvicorn.run(
            "main:app",
            host="127.0.0.1",
            port=port,
            reload=False,  # Désactivé pour Python embarqué
            log_config=log_config
        )
    except Exception as e:
        logger.error(f"Erreur fatale lors du démarrage: {e}", exc_info=True)
        raise

