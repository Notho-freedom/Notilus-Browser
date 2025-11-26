"""
Modèles de données pour les tests de performance
"""

from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
import uuid


class LoadTestType(str, Enum):
    """Type de test de charge"""
    LOAD = "load"              # Charge standard
    STRESS = "stress"          # Trouver le point de rupture
    SPIKE = "spike"            # Pics soudains
    ENDURANCE = "endurance"    # Test de durée
    BREAKPOINT = "breakpoint"  # Trouver la limite


class LoadTestStatus(str, Enum):
    """Status du test de charge"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class LoadTestStep(BaseModel):
    """Étape dans un scénario de charge"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    
    # Requête
    method: str = "GET"
    url: str
    headers: Dict[str, str] = Field(default_factory=dict)
    body: Optional[Any] = None
    
    # Variables à extraire
    extract: Dict[str, str] = Field(default_factory=dict)
    
    # Assertions (optionnelles)
    assertions: List[Dict[str, Any]] = Field(default_factory=list)
    
    # Timing
    think_time_ms: int = 0  # Pause après cette étape
    
    # Poids pour la randomisation
    weight: int = 1


class LoadTestScenario(BaseModel):
    """Scénario de test de charge"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = None
    
    # Steps
    steps: List[LoadTestStep] = Field(default_factory=list)
    
    # Configuration
    randomize_steps: bool = False
    loop: bool = True


class LoadTestThresholds(BaseModel):
    """Seuils de succès pour le test"""
    # Response time
    max_response_time_avg_ms: Optional[int] = None
    max_response_time_p95_ms: Optional[int] = None
    max_response_time_p99_ms: Optional[int] = None
    max_response_time_max_ms: Optional[int] = None
    
    # Error rate
    max_error_rate_percent: Optional[float] = None
    
    # Throughput
    min_requests_per_second: Optional[float] = None
    
    # Custom
    custom_thresholds: Dict[str, Any] = Field(default_factory=dict)


class LoadTestConfig(BaseModel):
    """Configuration d'un test de charge"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    description: Optional[str] = None
    
    type: LoadTestType = LoadTestType.LOAD
    
    # Cibles
    target_url: Optional[str] = None  # URL simple
    scenario: Optional[LoadTestScenario] = None  # Ou scénario complet
    
    # Configuration de charge
    virtual_users: int = 10
    ramp_up_time_sec: int = 30
    duration_sec: int = 60
    ramp_down_time_sec: int = 10
    
    # Pour STRESS test
    initial_users: int = 1
    max_users: int = 100
    step_users: int = 10
    step_duration_sec: int = 30
    
    # Pour SPIKE test
    baseline_users: int = 10
    spike_users: int = 100
    spike_duration_sec: int = 30
    spike_interval_sec: int = 60
    spike_count: int = 3
    
    # Seuils
    thresholds: LoadTestThresholds = Field(default_factory=LoadTestThresholds)
    
    # Options
    follow_redirects: bool = True
    timeout_ms: int = 30000
    verify_ssl: bool = True
    
    # Headers communs
    default_headers: Dict[str, str] = Field(default_factory=dict)
    
    # Variables
    variables: Dict[str, Any] = Field(default_factory=dict)


class TimelinePoint(BaseModel):
    """Point de métriques dans le temps"""
    timestamp: datetime
    
    # Charge
    active_users: int = 0
    
    # Requêtes
    requests: int = 0
    requests_per_second: float = 0.0
    
    # Erreurs
    errors: int = 0
    error_rate: float = 0.0
    
    # Response time
    avg_response_time_ms: float = 0.0
    min_response_time_ms: float = 0.0
    max_response_time_ms: float = 0.0
    p50_response_time_ms: float = 0.0
    p90_response_time_ms: float = 0.0
    p95_response_time_ms: float = 0.0
    p99_response_time_ms: float = 0.0
    
    # Données
    bytes_sent: int = 0
    bytes_received: int = 0


class ResponseTimeStats(BaseModel):
    """Statistiques de temps de réponse"""
    count: int = 0
    
    min_ms: float = 0.0
    max_ms: float = 0.0
    avg_ms: float = 0.0
    median_ms: float = 0.0
    std_dev_ms: float = 0.0
    
    p50_ms: float = 0.0
    p75_ms: float = 0.0
    p90_ms: float = 0.0
    p95_ms: float = 0.0
    p99_ms: float = 0.0
    p999_ms: float = 0.0


class ErrorDetail(BaseModel):
    """Détail d'une erreur pendant le test"""
    timestamp: datetime
    error_type: str  # timeout, connection, http_error, assertion
    message: str
    status_code: Optional[int] = None
    url: Optional[str] = None
    count: int = 1


class PerformanceMetrics(BaseModel):
    """Métriques de performance complètes"""
    # Timing
    total_duration_ms: float = 0.0
    
    # Requêtes
    total_requests: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    
    # Throughput
    requests_per_second: float = 0.0
    bytes_per_second: float = 0.0
    
    # Response times
    response_times: ResponseTimeStats = Field(default_factory=ResponseTimeStats)
    
    # TTFB
    ttfb_stats: ResponseTimeStats = Field(default_factory=ResponseTimeStats)
    
    # Errors
    error_rate: float = 0.0
    errors_by_type: Dict[str, int] = Field(default_factory=dict)
    errors_by_status: Dict[int, int] = Field(default_factory=dict)
    error_details: List[ErrorDetail] = Field(default_factory=list)
    
    # Data
    total_bytes_sent: int = 0
    total_bytes_received: int = 0
    avg_request_size: int = 0
    avg_response_size: int = 0
    
    # Concurrency
    max_concurrent_users: int = 0
    avg_concurrent_users: float = 0.0
    
    # Par URL (si plusieurs endpoints)
    metrics_by_url: Dict[str, Dict[str, Any]] = Field(default_factory=dict)


class ThresholdViolation(BaseModel):
    """Violation d'un seuil"""
    threshold_name: str
    expected: Any
    actual: Any
    message: str


class LoadTestResult(BaseModel):
    """Résultat d'un test de charge"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    config_id: str
    
    # Status
    status: LoadTestStatus = LoadTestStatus.PENDING
    
    # Timing
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    duration_sec: float = 0.0
    
    # Métriques
    metrics: PerformanceMetrics = Field(default_factory=PerformanceMetrics)
    
    # Timeline
    timeline: List[TimelinePoint] = Field(default_factory=list)
    timeline_interval_sec: int = 1
    
    # Seuils
    thresholds_passed: bool = True
    threshold_violations: List[ThresholdViolation] = Field(default_factory=list)
    
    # Pour STRESS test
    breakpoint_users: Optional[int] = None
    breakpoint_rps: Optional[float] = None
    
    # Erreurs système
    system_errors: List[str] = Field(default_factory=list)
    
    # Logs
    logs: List[str] = Field(default_factory=list)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class BenchmarkComparison(BaseModel):
    """Comparaison entre deux tests"""
    baseline_id: str
    compare_id: str
    
    # Différences
    rps_change_percent: float = 0.0
    avg_response_time_change_percent: float = 0.0
    p95_response_time_change_percent: float = 0.0
    error_rate_change_percent: float = 0.0
    
    # Verdict
    is_regression: bool = False
    regression_details: List[str] = Field(default_factory=list)
    improvements: List[str] = Field(default_factory=list)
