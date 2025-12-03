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

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from dotenv import load_dotenv
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

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

# ============================================================================
# Configuration de l'environnement
# ============================================================================
ENVIRONMENT = os.getenv("NOTILUS_ENV", "development")
IS_PRODUCTION = ENVIRONMENT == "production"

# ============================================================================
# Configuration du Rate Limiting
# ============================================================================
# Limites par défaut (peuvent être surchargées via variables d'environnement)
RATE_LIMIT_DEFAULT = os.getenv("NOTILUS_RATE_LIMIT_DEFAULT", "100/minute")
RATE_LIMIT_AI = os.getenv("NOTILUS_RATE_LIMIT_AI", "20/minute")  # Plus restrictif pour l'IA
RATE_LIMIT_AUTH = os.getenv("NOTILUS_RATE_LIMIT_AUTH", "10/minute")  # Très restrictif pour l'auth

# Créer le limiter
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[RATE_LIMIT_DEFAULT],
    storage_uri="memory://",  # En mémoire pour simplicité (Redis recommandé en prod)
    enabled=IS_PRODUCTION or os.getenv("NOTILUS_RATE_LIMIT_ENABLED", "false").lower() == "true",
)

# Origines CORS autorisées
# En développement: localhost sur différents ports
# En production: définir via NOTILUS_CORS_ORIGINS (séparées par des virgules)
DEFAULT_DEV_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8080",
    "http://localhost:5173",  # Vite
    "http://127.0.0.1:5173",
    "app://notilus",  # Schéma d'app Flutter Desktop
]

def get_cors_origins() -> list[str]:
    """Récupère les origines CORS autorisées selon l'environnement."""
    if IS_PRODUCTION:
        # En production, lire depuis la variable d'environnement
        origins_str = os.getenv("NOTILUS_CORS_ORIGINS", "")
        if origins_str:
            return [origin.strip() for origin in origins_str.split(",") if origin.strip()]
        # Par défaut en production, n'autoriser que l'origine de l'app
        return ["app://notilus"]
    else:
        # En développement, autoriser localhost + origines personnalisées
        custom_origins = os.getenv("NOTILUS_CORS_ORIGINS", "")
        origins = DEFAULT_DEV_ORIGINS.copy()
        if custom_origins:
            origins.extend([origin.strip() for origin in custom_origins.split(",") if origin.strip()])
        return origins

CORS_ORIGINS = get_cors_origins()

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
    docs_url="/docs" if not IS_PRODUCTION else None,  # Désactiver docs en production
    redoc_url="/redoc" if not IS_PRODUCTION else None,
)

# Configuration du Rate Limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# Configuration CORS sécurisée
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["Authorization", "Content-Type", "Accept", "Origin", "X-Requested-With"],
    expose_headers=["Content-Length", "X-Request-Id", "X-RateLimit-Limit", "X-RateLimit-Remaining"],
    max_age=600,  # Cache preflight pour 10 minutes
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
@limiter.limit("60/minute")
async def root(request: Request):
    """Endpoint racine"""
    return {
        "name": "Notilus Browser API",
        "version": "2.0.0",
        "status": "running",
        "environment": ENVIRONMENT,
        "rate_limiting": limiter.enabled,
    }


@app.get("/api/health")
@limiter.limit("120/minute")  # Plus permissif pour les health checks
async def health_check(request: Request):
    """Vérification de l'état de l'API"""
    return {
        "status": "healthy",
        "service": "notilus-api",
        "environment": ENVIRONMENT,
    }


@app.get("/api/rate-limit-status")
@limiter.limit("10/minute")
async def rate_limit_status(request: Request):
    """Vérifie le statut du rate limiting pour le client actuel"""
    return {
        "enabled": limiter.enabled,
        "default_limit": RATE_LIMIT_DEFAULT,
        "ai_limit": RATE_LIMIT_AI,
        "auth_limit": RATE_LIMIT_AUTH,
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

