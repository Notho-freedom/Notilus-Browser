"""
Modèles de données pour l'interception et la capture de requêtes
"""

from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
import uuid


class InterceptAction(str, Enum):
    """Action d'interception"""
    CAPTURE = "capture"        # Capturer seulement
    MODIFY = "modify"          # Modifier et continuer
    BLOCK = "block"           # Bloquer la requête
    DELAY = "delay"           # Retarder la requête
    FORWARD = "forward"       # Rediriger vers une autre URL
    MOCK = "mock"             # Retourner une réponse mockée


class ModificationOperation(str, Enum):
    """Opération de modification"""
    SET = "set"               # Définir/remplacer
    DELETE = "delete"         # Supprimer
    APPEND = "append"         # Ajouter à la fin
    PREPEND = "prepend"       # Ajouter au début
    REPLACE = "replace"       # Remplacer avec regex


class ModificationTarget(str, Enum):
    """Cible de modification"""
    URL = "url"
    METHOD = "method"
    HEADER = "header"
    QUERY_PARAM = "query_param"
    BODY = "body"
    BODY_JSON = "body_json"
    STATUS = "status"
    RESPONSE_HEADER = "response_header"
    RESPONSE_BODY = "response_body"


class Modification(BaseModel):
    """Modification à appliquer"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    
    target: ModificationTarget
    target_key: Optional[str] = None  # Pour header.X-Custom ou body.user.name
    
    operation: ModificationOperation
    value: Optional[Any] = None
    regex_pattern: Optional[str] = None  # Pour REPLACE
    regex_replacement: Optional[str] = None
    
    # Condition
    condition: Optional[str] = None  # Expression à évaluer


class InterceptMatchType(str, Enum):
    """Type de matching pour les règles"""
    CONTAINS = "contains"
    EQUALS = "equals"
    STARTS_WITH = "starts_with"
    ENDS_WITH = "ends_with"
    REGEX = "regex"
    GLOB = "glob"


class InterceptMatch(BaseModel):
    """Critère de matching pour une règle"""
    field: str  # url, method, header.X-Custom, body.key
    match_type: InterceptMatchType = InterceptMatchType.CONTAINS
    value: str
    case_sensitive: bool = False
    negate: bool = False  # Inverser le matching


class InterceptRule(BaseModel):
    """Règle d'interception"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = None
    enabled: bool = True
    priority: int = 0  # Plus haut = plus prioritaire
    
    # Matching
    matches: List[InterceptMatch] = Field(default_factory=list)
    match_all: bool = True  # True = AND, False = OR
    
    # Filtres rapides
    url_pattern: Optional[str] = None
    methods: List[str] = Field(default_factory=list)
    content_types: List[str] = Field(default_factory=list)
    status_codes: List[int] = Field(default_factory=list)  # Pour réponses
    
    # Action
    action: InterceptAction = InterceptAction.CAPTURE
    
    # Modifications (pour MODIFY)
    request_modifications: List[Modification] = Field(default_factory=list)
    response_modifications: List[Modification] = Field(default_factory=list)
    
    # Delay (pour DELAY)
    delay_ms: int = 0
    delay_random_max_ms: int = 0  # Ajouter un délai aléatoire
    
    # Forward (pour FORWARD)
    forward_to: Optional[str] = None
    preserve_host: bool = True
    
    # Mock (pour MOCK)
    mock_status: int = 200
    mock_headers: Dict[str, str] = Field(default_factory=dict)
    mock_body: Optional[str] = None
    mock_delay_ms: int = 0
    
    # Métadonnées
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    
    # Statistiques
    match_count: int = 0
    last_match: Optional[datetime] = None


class RequestDirection(str, Enum):
    """Direction de la requête (pour capture)"""
    REQUEST = "request"
    RESPONSE = "response"
    BOTH = "both"


class CapturedRequest(BaseModel):
    """Requête capturée"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: datetime = Field(default_factory=datetime.now)
    
    # Requête
    method: str
    url: str
    full_url: str  # Avec query params
    host: str
    path: str
    query_string: Optional[str] = None
    query_params: Dict[str, str] = Field(default_factory=dict)
    
    request_headers: Dict[str, str] = Field(default_factory=dict)
    request_body: Optional[bytes] = None
    request_body_text: Optional[str] = None
    request_body_json: Optional[Any] = None
    request_size: int = 0
    
    # Réponse
    status_code: Optional[int] = None
    status_text: Optional[str] = None
    response_headers: Dict[str, str] = Field(default_factory=dict)
    response_body: Optional[bytes] = None
    response_body_text: Optional[str] = None
    response_body_json: Optional[Any] = None
    response_size: int = 0
    
    # Content types
    request_content_type: Optional[str] = None
    response_content_type: Optional[str] = None
    
    # Timing
    duration_ms: float = 0.0
    ttfb_ms: float = 0.0
    dns_time_ms: float = 0.0
    connect_time_ms: float = 0.0
    ssl_time_ms: float = 0.0
    send_time_ms: float = 0.0
    wait_time_ms: float = 0.0
    receive_time_ms: float = 0.0
    
    # Connexion
    remote_address: Optional[str] = None
    local_address: Optional[str] = None
    protocol: str = "HTTP/1.1"
    is_https: bool = False
    
    # Associations
    server_id: Optional[str] = None
    route_id: Optional[str] = None
    
    # Modifications appliquées
    was_modified: bool = False
    modifications_applied: List[str] = Field(default_factory=list)
    original_request: Optional[Dict[str, Any]] = None  # Si modifié
    original_response: Optional[Dict[str, Any]] = None  # Si modifié
    
    # Règle qui a matché
    matched_rule_id: Optional[str] = None
    matched_rule_name: Optional[str] = None
    
    # Replay
    can_replay: bool = True
    replay_count: int = 0
    parent_capture_id: Optional[str] = None  # Si c'est un replay
    
    # Tags et notes
    tags: List[str] = Field(default_factory=list)
    notes: Optional[str] = None
    is_favorite: bool = False
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class WebSocketMessage(BaseModel):
    """Message WebSocket capturé"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    connection_id: str
    timestamp: datetime = Field(default_factory=datetime.now)
    
    direction: str  # "sent" ou "received"
    
    # Données
    opcode: int  # 1=text, 2=binary, 8=close, 9=ping, 10=pong
    data: Optional[bytes] = None
    data_text: Optional[str] = None
    data_json: Optional[Any] = None
    
    # Taille
    size: int = 0
    
    # Si modifié
    was_modified: bool = False
    original_data: Optional[bytes] = None


class WebSocketConnection(BaseModel):
    """Connexion WebSocket"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    url: str
    
    # État
    state: str = "connecting"  # connecting, open, closing, closed
    
    # Headers d'upgrade
    request_headers: Dict[str, str] = Field(default_factory=dict)
    response_headers: Dict[str, str] = Field(default_factory=dict)
    
    # Messages
    messages: List[WebSocketMessage] = Field(default_factory=list)
    message_count: int = 0
    
    # Timing
    connected_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None
    close_code: Optional[int] = None
    close_reason: Optional[str] = None
    
    # Associations
    server_id: Optional[str] = None


class ProxyStatus(BaseModel):
    """Status du proxy d'interception"""
    running: bool = False
    port: int = 8888
    ssl_enabled: bool = True
    
    # Statistiques
    requests_captured: int = 0
    requests_modified: int = 0
    requests_blocked: int = 0
    
    # Règles actives
    active_rules: int = 0
    
    # Connexions
    active_connections: int = 0
    websocket_connections: int = 0
    
    # Uptime
    started_at: Optional[datetime] = None
    uptime_seconds: float = 0.0
    
    # Certificat
    certificate_expires: Optional[datetime] = None
    certificate_fingerprint: Optional[str] = None
