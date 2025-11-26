"""
Modèles de données pour les tests d'API
"""

from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any, Union
from pydantic import BaseModel, Field
import uuid


class AssertionOperator(str, Enum):
    """Opérateurs d'assertion"""
    EQUALS = "equals"
    NOT_EQUALS = "not_equals"
    CONTAINS = "contains"
    NOT_CONTAINS = "not_contains"
    STARTS_WITH = "starts_with"
    ENDS_WITH = "ends_with"
    MATCHES = "matches"  # Regex
    EXISTS = "exists"
    NOT_EXISTS = "not_exists"
    IS_EMPTY = "is_empty"
    IS_NOT_EMPTY = "is_not_empty"
    GREATER_THAN = "gt"
    GREATER_THAN_OR_EQUAL = "gte"
    LESS_THAN = "lt"
    LESS_THAN_OR_EQUAL = "lte"
    IS_TYPE = "is_type"
    IS_ARRAY = "is_array"
    IS_OBJECT = "is_object"
    ARRAY_LENGTH = "array_length"
    ARRAY_CONTAINS = "array_contains"
    JSON_SCHEMA = "json_schema"
    IS_NULL = "is_null"
    IS_NOT_NULL = "is_not_null"
    IS_TRUE = "is_true"
    IS_FALSE = "is_false"


class AssertionTarget(str, Enum):
    """Cible de l'assertion"""
    STATUS = "status"
    STATUS_TEXT = "status_text"
    HEADER = "header"
    BODY = "body"
    BODY_JSON = "body_json"
    RESPONSE_TIME = "response_time"
    CONTENT_TYPE = "content_type"


class TestAssertion(BaseModel):
    """Une assertion de test"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: Optional[str] = None
    
    target: AssertionTarget
    target_path: Optional[str] = None  # Pour header.X-Custom ou body.user.name
    operator: AssertionOperator
    expected: Any
    
    # Résultat
    passed: Optional[bool] = None
    actual_value: Optional[Any] = None
    error_message: Optional[str] = None


class AuthType(str, Enum):
    """Type d'authentification"""
    NONE = "none"
    BEARER = "bearer"
    BASIC = "basic"
    API_KEY = "api_key"
    OAUTH2 = "oauth2"
    DIGEST = "digest"
    AWS_SIGNATURE = "aws_sig"
    CUSTOM = "custom"


class AuthConfig(BaseModel):
    """Configuration d'authentification"""
    type: AuthType = AuthType.NONE
    
    # Bearer
    token: Optional[str] = None
    token_prefix: str = "Bearer"
    
    # Basic
    username: Optional[str] = None
    password: Optional[str] = None
    
    # API Key
    key_name: Optional[str] = None
    key_value: Optional[str] = None
    key_location: str = "header"  # header, query
    
    # OAuth2
    oauth_flow: Optional[str] = None
    client_id: Optional[str] = None
    client_secret: Optional[str] = None
    token_url: Optional[str] = None
    scope: Optional[str] = None
    
    # Custom header
    custom_headers: Dict[str, str] = Field(default_factory=dict)


class BodyType(str, Enum):
    """Type de body de requête"""
    NONE = "none"
    JSON = "json"
    FORM = "form"
    FORM_DATA = "form_data"
    RAW = "raw"
    BINARY = "binary"
    GRAPHQL = "graphql"
    XML = "xml"


class TestRequest(BaseModel):
    """Requête de test"""
    method: str = "GET"
    url: str
    
    # Paramètres
    path_params: Dict[str, str] = Field(default_factory=dict)
    query_params: Dict[str, str] = Field(default_factory=dict)
    
    # Headers
    headers: Dict[str, str] = Field(default_factory=dict)
    
    # Auth
    auth: AuthConfig = Field(default_factory=AuthConfig)
    
    # Body
    body_type: BodyType = BodyType.NONE
    body: Optional[Any] = None
    body_raw: Optional[str] = None
    
    # Options
    follow_redirects: bool = True
    timeout_ms: int = 30000
    verify_ssl: bool = True
    
    # Scripts
    pre_request_script: Optional[str] = None


class TestResponse(BaseModel):
    """Réponse de test"""
    status_code: int
    status_text: str = ""
    
    headers: Dict[str, str] = Field(default_factory=dict)
    
    body: Optional[bytes] = None
    body_text: Optional[str] = None
    body_json: Optional[Any] = None
    
    # Timing
    response_time_ms: float = 0.0
    ttfb_ms: float = 0.0  # Time to first byte
    
    # Taille
    content_length: int = 0
    
    # Métadonnées
    content_type: Optional[str] = None
    encoding: Optional[str] = None


class TestResultStatus(str, Enum):
    """Status du résultat de test"""
    PASSED = "passed"
    FAILED = "failed"
    ERROR = "error"
    SKIPPED = "skipped"


class TestResult(BaseModel):
    """Résultat d'un test"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    test_id: str
    
    # Status
    status: TestResultStatus
    
    # Requête/Réponse
    request: TestRequest
    response: Optional[TestResponse] = None
    
    # Assertions
    assertions: List[TestAssertion] = Field(default_factory=list)
    assertions_passed: int = 0
    assertions_failed: int = 0
    
    # Timing
    started_at: datetime = Field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    duration_ms: float = 0.0
    
    # Erreur
    error_message: Optional[str] = None
    error_stack: Optional[str] = None
    
    # Variables extraites
    extracted_variables: Dict[str, Any] = Field(default_factory=dict)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class VariableExtraction(BaseModel):
    """Extraction de variable depuis une réponse"""
    name: str
    source: str  # body, header, status
    path: Optional[str] = None  # JSONPath ou header name
    regex: Optional[str] = None
    default_value: Optional[Any] = None


class FunctionalTest(BaseModel):
    """Test fonctionnel d'un endpoint"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = None
    
    # Route cible
    route_id: Optional[str] = None
    
    # Requête
    request: TestRequest
    
    # Assertions
    assertions: List[TestAssertion] = Field(default_factory=list)
    
    # Extraction de variables
    extract_variables: List[VariableExtraction] = Field(default_factory=list)
    
    # Script post-réponse
    post_response_script: Optional[str] = None
    
    # Dépendances
    depends_on: List[str] = Field(default_factory=list)  # IDs d'autres tests
    
    # Tags
    tags: List[str] = Field(default_factory=list)
    
    # Configuration
    retry_count: int = 0
    retry_delay_ms: int = 1000
    skip_if_fail_dependency: bool = True
    
    # Métadonnées
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)


class TestVariable(BaseModel):
    """Variable d'environnement de test"""
    key: str
    value: str
    type: str = "string"  # string, secret, dynamic
    is_secret: bool = False
    description: Optional[str] = None


class TestEnvironment(BaseModel):
    """Environnement de test"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str  # Development, Staging, Production
    description: Optional[str] = None
    
    variables: Dict[str, TestVariable] = Field(default_factory=dict)
    
    # URL de base
    base_url: Optional[str] = None
    
    # Config globale
    default_headers: Dict[str, str] = Field(default_factory=dict)
    default_auth: Optional[AuthConfig] = None
    
    # Métadonnées
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    is_active: bool = False


class TestCollection(BaseModel):
    """Collection de tests"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = None
    
    # Variables locales à la collection
    variables: Dict[str, TestVariable] = Field(default_factory=dict)
    
    # Tests
    tests: List[FunctionalTest] = Field(default_factory=list)
    test_order: List[str] = Field(default_factory=list)  # Ordre d'exécution
    
    # Hooks
    setup_script: Optional[str] = None
    teardown_script: Optional[str] = None
    pre_request_script: Optional[str] = None
    post_response_script: Optional[str] = None
    
    # Configuration
    stop_on_failure: bool = False
    parallel_execution: bool = False
    
    # Tags
    tags: List[str] = Field(default_factory=list)
    
    # Métadonnées
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)


class ScenarioStepType(str, Enum):
    """Type d'étape de scénario"""
    REQUEST = "request"
    CONDITION = "condition"
    LOOP = "loop"
    DELAY = "delay"
    SCRIPT = "script"
    SET_VARIABLE = "set_variable"
    LOG = "log"


class ScenarioStep(BaseModel):
    """Étape d'un scénario de test"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    type: ScenarioStepType
    
    # Pour REQUEST
    request: Optional[TestRequest] = None
    assertions: List[TestAssertion] = Field(default_factory=list)
    extract: List[VariableExtraction] = Field(default_factory=list)
    
    # Pour CONDITION
    condition: Optional[str] = None  # Expression à évaluer
    if_true: Optional[str] = None  # ID du step suivant si vrai
    if_false: Optional[str] = None  # ID du step suivant si faux
    
    # Pour LOOP
    loop_count: Optional[int] = None
    loop_variable: Optional[str] = None
    loop_over: Optional[str] = None  # Variable contenant une liste
    loop_steps: List[str] = Field(default_factory=list)  # IDs des steps dans la boucle
    
    # Pour DELAY
    delay_ms: Optional[int] = None
    
    # Pour SCRIPT
    script: Optional[str] = None
    
    # Pour SET_VARIABLE
    variable_name: Optional[str] = None
    variable_value: Optional[str] = None
    
    # Pour LOG
    log_message: Optional[str] = None
    
    # Step suivant (si pas de condition)
    next_step: Optional[str] = None


class TestScenario(BaseModel):
    """Scénario de test (workflow)"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = None
    
    # Steps
    steps: List[ScenarioStep] = Field(default_factory=list)
    start_step: Optional[str] = None  # ID du premier step
    
    # Variables initiales
    initial_variables: Dict[str, Any] = Field(default_factory=dict)
    
    # Configuration
    timeout_ms: int = 300000  # 5 minutes
    
    # Métadonnées
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    tags: List[str] = Field(default_factory=list)


class CollectionRunResult(BaseModel):
    """Résultat d'exécution d'une collection"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    collection_id: str
    environment_id: Optional[str] = None
    
    # Résultats
    test_results: List[TestResult] = Field(default_factory=list)
    
    # Statistiques
    total_tests: int = 0
    passed_tests: int = 0
    failed_tests: int = 0
    skipped_tests: int = 0
    error_tests: int = 0
    
    # Timing
    started_at: datetime = Field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    duration_ms: float = 0.0
    
    # Statut global
    status: TestResultStatus = TestResultStatus.PASSED
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
