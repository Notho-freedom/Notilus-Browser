"""
Notilus Backend Lab - Le système de tests backend le plus avancé
"""

from .server_discovery import router as server_discovery_router
from .route_discovery import router as route_discovery_router
from .api_testing import router as api_testing_router
from .interception import router as interception_router
from .security_scanner import router as security_scanner_router
from .performance_lab import router as performance_lab_router
from .mock_server import router as mock_server_router
from .analytics import router as analytics_router

__version__ = "1.0.0"
__all__ = [
    "server_discovery_router",
    "route_discovery_router", 
    "api_testing_router",
    "interception_router",
    "security_scanner_router",
    "performance_lab_router",
    "mock_server_router",
    "analytics_router",
]
