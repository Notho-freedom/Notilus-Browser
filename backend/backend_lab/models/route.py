"""
Modèles de données pour les routes découvertes
"""

from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
import uuid


class HttpMethod(str, Enum):
    """Méthodes HTTP"""
    GET = "GET"
    POST = "POST"
    PUT = "PUT"
    DELETE = "DELETE"
    PATCH = "PATCH"
    HEAD = "HEAD"
    OPTIONS = "OPTIONS"
    CONNECT = "CONNECT"
    TRACE = "TRACE"


class ParameterLocation(str, Enum):
    """Emplacement du paramètre"""
    PATH = "path"
    QUERY = "query"
    HEADER = "header"
    BODY = "body"
    COOKIE = "cookie"


class RouteDiscoveryMethod(str, Enum):
    """Méthode de découverte de la route"""
    OPENAPI = "openapi"
    GRAPHQL_INTROSPECTION = "graphql_introspection"
    FUZZING = "fuzzing"
    INTERCEPT = "intercept"
    MANUAL = "manual"
    HATEOAS = "hateoas"
    HTML_PARSING = "html_parsing"
    JS_PARSING = "js_parsing"


class RouteParameter(BaseModel):
    """Paramètre d'une route"""
    name: str
    location: ParameterLocation
    type: str = "string"  # string, integer, boolean, number, array, object
    required: bool = False
    default_value: Optional[Any] = None
    description: Optional[str] = None
    enum_values: Optional[List[Any]] = None
    pattern: Optional[str] = None  # Regex de validation
    example: Optional[Any] = None
    min_value: Optional[float] = None
    max_value: Optional[float] = None
    min_length: Optional[int] = None
    max_length: Optional[int] = None
    format: Optional[str] = None  # date, date-time, email, uri, etc.


class DiscoveredRoute(BaseModel):
    """Route d'API découverte"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    server_id: str
    
    # Identité
    path: str  # /api/users/{id}
    method: HttpMethod
    
    # Paramètres
    path_params: List[RouteParameter] = Field(default_factory=list)
    query_params: List[RouteParameter] = Field(default_factory=list)
    header_params: List[RouteParameter] = Field(default_factory=list)
    body_schema: Optional[Dict[str, Any]] = None  # JSON Schema
    
    # Réponse
    response_schemas: Dict[str, Dict[str, Any]] = Field(default_factory=dict)  # status_code: schema
    response_codes: List[int] = Field(default_factory=list)
    content_types: List[str] = Field(default_factory=list)
    
    # Métadonnées
    discovery_method: RouteDiscoveryMethod = RouteDiscoveryMethod.FUZZING
    discovered_at: datetime = Field(default_factory=datetime.now)
    last_tested: Optional[datetime] = None
    
    # Documentation
    summary: Optional[str] = None
    description: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    operation_id: Optional[str] = None
    deprecated: bool = False
    
    # Sécurité
    auth_required: bool = False
    auth_type: Optional[str] = None  # bearer, basic, api_key, oauth2
    scopes: List[str] = Field(default_factory=list)
    permissions: List[str] = Field(default_factory=list)
    
    # Statistiques des tests
    test_count: int = 0
    test_pass_count: int = 0
    test_fail_count: int = 0
    last_test_status: Optional[str] = None  # pass, fail, error
    
    # Statistiques d'interception
    call_count: int = 0
    avg_response_time: float = 0.0
    error_rate: float = 0.0
    last_status_codes: List[int] = Field(default_factory=list)
    
    # Vulnérabilités
    vulnerability_count: int = 0
    vulnerability_ids: List[str] = Field(default_factory=list)
    
    # GraphQL specifique
    is_graphql: bool = False
    graphql_type: Optional[str] = None  # query, mutation, subscription
    graphql_operation: Optional[str] = None
    
    @property
    def full_path(self) -> str:
        """Chemin complet avec les paramètres de query par défaut"""
        return self.path
    
    @property
    def pattern(self) -> str:
        """Pattern regex pour le matching"""
        import re
        # Convertir {param} en regex group
        pattern = re.sub(r'\{(\w+)\}', r'(?P<\1>[^/]+)', self.path)
        return f"^{pattern}$"
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class RouteGroup(BaseModel):
    """Groupe de routes (pour organisation)"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = None
    prefix: str  # /api/users
    routes: List[str] = Field(default_factory=list)  # Route IDs
    tags: List[str] = Field(default_factory=list)


class OpenAPISpec(BaseModel):
    """Spécification OpenAPI importée"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    server_id: str
    version: str  # 2.0, 3.0, 3.1
    title: str
    description: Optional[str] = None
    base_path: str = "/"
    
    # Contenu brut
    raw_spec: Dict[str, Any] = Field(default_factory=dict)
    
    # Routes extraites
    route_ids: List[str] = Field(default_factory=list)
    
    # Métadonnées
    imported_at: datetime = Field(default_factory=datetime.now)
    source_url: Optional[str] = None
