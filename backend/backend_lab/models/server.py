"""
Modèles de données pour les serveurs découverts
"""

from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
import uuid


class ServerStatus(str, Enum):
    """Status du serveur"""
    RUNNING = "running"
    STOPPED = "stopped"
    ERROR = "error"
    UNKNOWN = "unknown"


class HealthStatus(str, Enum):
    """Status de santé du serveur"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"


class ServerFramework(str, Enum):
    """Frameworks détectables"""
    EXPRESS = "express"
    FASTAPI = "fastapi"
    DJANGO = "django"
    FLASK = "flask"
    SPRING_BOOT = "spring_boot"
    RAILS = "rails"
    LARAVEL = "laravel"
    NESTJS = "nestjs"
    GIN = "gin"
    ASPNET = "aspnet"
    KOA = "koa"
    HAPI = "hapi"
    ACTIX = "actix"
    ROCKET = "rocket"
    PHOENIX = "phoenix"
    UNKNOWN = "unknown"


class HealthCheckResult(BaseModel):
    """Résultat d'un health check"""
    status: HealthStatus = HealthStatus.UNKNOWN
    response_time_ms: float = 0.0
    last_check: datetime = Field(default_factory=datetime.now)
    uptime_percentage: float = 100.0
    error_count: int = 0
    consecutive_failures: int = 0
    ssl_valid: bool = False
    ssl_expires: Optional[datetime] = None
    error_message: Optional[str] = None
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class DiscoveredServer(BaseModel):
    """Serveur découvert"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    host: str = "localhost"
    port: int
    protocol: str = "http"
    
    # Identification
    name: Optional[str] = None
    framework: ServerFramework = ServerFramework.UNKNOWN
    framework_version: Optional[str] = None
    language: Optional[str] = None
    
    # État
    status: ServerStatus = ServerStatus.UNKNOWN
    health: HealthCheckResult = Field(default_factory=HealthCheckResult)
    
    # Métadonnées processus
    process_id: Optional[int] = None
    process_name: Optional[str] = None
    working_directory: Optional[str] = None
    command_line: Optional[str] = None
    
    # Découverte
    discovered_at: datetime = Field(default_factory=datetime.now)
    last_seen: datetime = Field(default_factory=datetime.now)
    discovery_method: str = "port_scan"
    
    # Routes (IDs des routes découvertes)
    route_ids: List[str] = Field(default_factory=list)
    routes_count: int = 0
    
    # Métriques
    request_count: int = 0
    error_rate: float = 0.0
    avg_response_time: float = 0.0
    
    # Métadonnées additionnelles
    metadata: Dict[str, Any] = Field(default_factory=dict)
    
    # Fingerprinting
    headers_signature: Dict[str, str] = Field(default_factory=dict)
    cookies_detected: List[str] = Field(default_factory=list)
    endpoints_found: List[str] = Field(default_factory=list)
    
    @property
    def base_url(self) -> str:
        """URL de base du serveur"""
        return f"{self.protocol}://{self.host}:{self.port}"
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class ScanConfig(BaseModel):
    """Configuration d'un scan de serveurs"""
    # Plages de ports
    port_ranges: List[tuple] = Field(default_factory=lambda: [
        (3000, 3010),   # Node.js common
        (5000, 5010),   # Flask, Python common
        (8000, 8010),   # Django, FastAPI common
        (8080, 8090),   # Java, general
        (4200, 4210),   # Angular
        (5173, 5180),   # Vite
    ])
    
    # Ports spécifiques à scanner
    specific_ports: List[int] = Field(default_factory=lambda: [
        80, 443, 3000, 3001, 4200, 5000, 5001, 5173, 5174,
        8000, 8001, 8080, 8081, 8888, 9000, 9090
    ])
    
    # Options
    scan_localhost: bool = True
    scan_127_0_0_1: bool = True
    scan_0_0_0_0: bool = True
    
    # Timeouts
    connection_timeout_ms: int = 500
    response_timeout_ms: int = 2000
    
    # Fingerprinting
    enable_fingerprinting: bool = True
    check_openapi: bool = True
    check_graphql: bool = True
    
    # Parallélisme
    max_concurrent_scans: int = 20
    
    # Filtres
    include_databases: bool = False
    include_internal_only: bool = True


class ScanResult(BaseModel):
    """Résultat d'un scan"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    started_at: datetime = Field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    
    # Config utilisée
    config: ScanConfig = Field(default_factory=ScanConfig)
    
    # Résultats
    servers_found: List[DiscoveredServer] = Field(default_factory=list)
    ports_scanned: int = 0
    ports_open: int = 0
    
    # Durée
    duration_ms: float = 0.0
    
    # Erreurs
    errors: List[str] = Field(default_factory=list)
    
    @property
    def is_complete(self) -> bool:
        return self.completed_at is not None
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
