"""
Modèles de données pour les serveurs mock
"""

from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
import uuid


class MockServerStatus(str, Enum):
    """Status du serveur mock"""
    STOPPED = "stopped"
    STARTING = "starting"
    RUNNING = "running"
    STOPPING = "stopping"
    ERROR = "error"


class MockMatchType(str, Enum):
    """Type de matching pour les conditions"""
    EQUALS = "equals"
    CONTAINS = "contains"
    STARTS_WITH = "starts_with"
    ENDS_WITH = "ends_with"
    REGEX = "regex"
    EXISTS = "exists"
    NOT_EXISTS = "not_exists"
    JSON_PATH = "json_path"


class MockMatch(BaseModel):
    """Critère de matching pour une réponse conditionnelle"""
    type: MockMatchType = MockMatchType.EQUALS
    source: str  # header, query, body, path, method
    key: Optional[str] = None  # Nom du header, paramètre, ou JSONPath
    value: Optional[str] = None  # Valeur attendue
    negate: bool = False


class MockCondition(BaseModel):
    """Condition pour une réponse différente"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: Optional[str] = None
    priority: int = 0  # Plus haut = plus prioritaire
    
    # Matching (AND entre tous)
    matches: List[MockMatch] = Field(default_factory=list)
    
    # Réponse si match
    response: "MockResponse"


class MockResponse(BaseModel):
    """Réponse mockée"""
    status_code: int = 200
    status_text: Optional[str] = None
    
    headers: Dict[str, str] = Field(default_factory=lambda: {
        "Content-Type": "application/json"
    })
    
    # Body
    body: Optional[Any] = None
    body_template: Optional[str] = None  # Template avec variables
    body_file: Optional[str] = None  # Chemin vers un fichier
    
    # Délai
    delay_ms: int = 0
    delay_random_max_ms: int = 0
    
    # Comportement
    fail_rate: float = 0.0  # Pourcentage d'échec (retourne 500)
    
    # Callback (pour réponses dynamiques)
    callback_script: Optional[str] = None  # JavaScript


class MockRoute(BaseModel):
    """Route mockée"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    
    # Matching
    path: str  # /api/users/:id ou /api/users/*
    method: str = "GET"  # Peut être "*" pour tous
    
    # Réponse par défaut
    response: MockResponse = Field(default_factory=MockResponse)
    
    # Réponses conditionnelles
    conditions: List[MockCondition] = Field(default_factory=list)
    
    # Options
    enabled: bool = True
    
    # Statistiques
    call_count: int = 0
    last_called: Optional[datetime] = None
    
    # Documentation
    description: Optional[str] = None
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class MockServer(BaseModel):
    """Serveur mock"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = None
    
    # Configuration réseau
    port: int = 0  # 0 = port auto
    host: str = "127.0.0.1"
    
    # SSL
    ssl_enabled: bool = False
    ssl_cert: Optional[str] = None
    ssl_key: Optional[str] = None
    
    # Routes
    routes: List[MockRoute] = Field(default_factory=list)
    
    # Comportement global
    default_delay_ms: int = 0
    default_response: MockResponse = Field(default_factory=lambda: MockResponse(
        status_code=404,
        body={"error": "Not Found", "message": "No matching route"}
    ))
    
    # CORS
    cors_enabled: bool = True
    cors_origins: List[str] = Field(default_factory=lambda: ["*"])
    cors_methods: List[str] = Field(default_factory=lambda: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
    cors_headers: List[str] = Field(default_factory=lambda: ["*"])
    
    # Logging
    log_requests: bool = True
    store_requests: bool = True
    max_stored_requests: int = 1000
    
    # État
    status: MockServerStatus = MockServerStatus.STOPPED
    actual_port: Optional[int] = None
    
    # Métadonnées
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    
    # Statistiques
    total_requests: int = 0
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class MockRequestLog(BaseModel):
    """Log d'une requête reçue par le mock"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    mock_server_id: str
    mock_route_id: Optional[str] = None
    
    timestamp: datetime = Field(default_factory=datetime.now)
    
    # Requête
    method: str
    path: str
    query_params: Dict[str, str] = Field(default_factory=dict)
    headers: Dict[str, str] = Field(default_factory=dict)
    body: Optional[Any] = None
    
    # Réponse envoyée
    response_status: int
    response_headers: Dict[str, str] = Field(default_factory=dict)
    response_body: Optional[Any] = None
    
    # Matching
    matched_route: bool = False
    matched_condition: Optional[str] = None
    
    # Timing
    processing_time_ms: float = 0.0
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class RecordedScenario(BaseModel):
    """Scénario enregistré à partir de vraies requêtes"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = None
    
    # Serveur source
    source_server_id: Optional[str] = None
    
    # Requêtes enregistrées
    requests: List[Dict[str, Any]] = Field(default_factory=list)
    
    # Métadonnées
    recorded_at: datetime = Field(default_factory=datetime.now)
    duration_sec: float = 0.0
    request_count: int = 0
    
    # Pour génération de mock
    routes_generated: List[str] = Field(default_factory=list)


# Mise à jour de la forward reference
MockCondition.model_rebuild()
