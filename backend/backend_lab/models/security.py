"""
Modèles de données pour le scanner de sécurité
"""

from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
import uuid


class VulnerabilitySeverity(str, Enum):
    """Sévérité de vulnérabilité (CVSS-like)"""
    CRITICAL = "critical"  # 9.0-10.0
    HIGH = "high"          # 7.0-8.9
    MEDIUM = "medium"      # 4.0-6.9
    LOW = "low"            # 0.1-3.9
    INFO = "info"          # 0.0


class VulnerabilityType(str, Enum):
    """Type de vulnérabilité"""
    # Injection
    SQL_INJECTION = "sql_injection"
    NOSQL_INJECTION = "nosql_injection"
    COMMAND_INJECTION = "command_injection"
    LDAP_INJECTION = "ldap_injection"
    XPATH_INJECTION = "xpath_injection"
    TEMPLATE_INJECTION = "template_injection"
    
    # XSS
    REFLECTED_XSS = "reflected_xss"
    STORED_XSS = "stored_xss"
    DOM_XSS = "dom_xss"
    
    # Auth & Session
    BROKEN_AUTHENTICATION = "broken_authentication"
    BROKEN_AUTHORIZATION = "broken_authorization"
    IDOR = "idor"  # Insecure Direct Object Reference
    PRIVILEGE_ESCALATION = "privilege_escalation"
    SESSION_FIXATION = "session_fixation"
    WEAK_PASSWORD = "weak_password"
    JWT_VULNERABILITY = "jwt_vulnerability"
    
    # Data Exposure
    SENSITIVE_DATA_EXPOSURE = "sensitive_data_exposure"
    VERBOSE_ERRORS = "verbose_errors"
    DEBUG_ENDPOINT = "debug_endpoint"
    INFORMATION_DISCLOSURE = "information_disclosure"
    
    # Security Misconfiguration
    CORS_MISCONFIGURATION = "cors_misconfiguration"
    MISSING_SECURITY_HEADERS = "missing_security_headers"
    INSECURE_COOKIES = "insecure_cookies"
    SSL_ISSUES = "ssl_issues"
    
    # Rate Limiting & DoS
    NO_RATE_LIMITING = "no_rate_limiting"
    RESOURCE_EXHAUSTION = "resource_exhaustion"
    DENIAL_OF_SERVICE = "denial_of_service"
    
    # Business Logic
    MASS_ASSIGNMENT = "mass_assignment"
    PARAMETER_TAMPERING = "parameter_tampering"
    RACE_CONDITION = "race_condition"
    
    # SSRF & XXE
    SSRF = "ssrf"
    XXE = "xxe"
    
    # Other
    CSRF = "csrf"
    OPEN_REDIRECT = "open_redirect"
    FILE_UPLOAD = "file_upload"
    PATH_TRAVERSAL = "path_traversal"
    CLICKJACKING = "clickjacking"
    
    # Informational
    DEPRECATED_ENDPOINT = "deprecated_endpoint"
    OUTDATED_LIBRARY = "outdated_library"


class VulnerabilityStatus(str, Enum):
    """Statut de vulnérabilité"""
    OPEN = "open"
    CONFIRMED = "confirmed"
    FALSE_POSITIVE = "false_positive"
    FIXED = "fixed"
    ACCEPTED_RISK = "accepted_risk"
    WONT_FIX = "wont_fix"


class OWASPCategory(str, Enum):
    """Catégories OWASP Top 10 (2021)"""
    A01_BROKEN_ACCESS_CONTROL = "A01:2021-Broken Access Control"
    A02_CRYPTOGRAPHIC_FAILURES = "A02:2021-Cryptographic Failures"
    A03_INJECTION = "A03:2021-Injection"
    A04_INSECURE_DESIGN = "A04:2021-Insecure Design"
    A05_SECURITY_MISCONFIGURATION = "A05:2021-Security Misconfiguration"
    A06_VULNERABLE_COMPONENTS = "A06:2021-Vulnerable and Outdated Components"
    A07_AUTH_FAILURES = "A07:2021-Identification and Authentication Failures"
    A08_INTEGRITY_FAILURES = "A08:2021-Software and Data Integrity Failures"
    A09_LOGGING_FAILURES = "A09:2021-Security Logging and Monitoring Failures"
    A10_SSRF = "A10:2021-Server-Side Request Forgery"


class Vulnerability(BaseModel):
    """Vulnérabilité détectée"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    
    # Classification
    type: VulnerabilityType
    category: Optional[OWASPCategory] = None
    cwe_id: Optional[str] = None  # CWE-89, CWE-79, etc.
    cvss_score: Optional[float] = None  # 0.0 - 10.0
    cvss_vector: Optional[str] = None  # CVSS:3.1/AV:N/AC:L/...
    
    # Sévérité
    severity: VulnerabilitySeverity
    
    # Localisation
    server_id: str
    route_id: Optional[str] = None
    parameter: Optional[str] = None
    location: str = "unknown"  # header, body, query, path, cookie
    
    # Détails
    title: str
    description: str
    evidence: str  # Preuve de la vulnérabilité
    
    # Payload utilisé
    payload_used: Optional[str] = None
    request_sample: Optional[str] = None
    response_sample: Optional[str] = None
    
    # Remédiation
    recommendation: str
    remediation_effort: Optional[str] = None  # low, medium, high
    references: List[str] = Field(default_factory=list)
    
    # Métadonnées
    discovered_at: datetime = Field(default_factory=datetime.now)
    confidence: float = 1.0  # 0.0 - 1.0
    
    # État
    status: VulnerabilityStatus = VulnerabilityStatus.OPEN
    verified: bool = False
    verified_at: Optional[datetime] = None
    verified_by: Optional[str] = None
    
    # Notes
    notes: List[str] = Field(default_factory=list)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class ScanType(str, Enum):
    """Type de scan de sécurité"""
    QUICK = "quick"  # Tests basiques rapides
    STANDARD = "standard"  # Tests standards
    DEEP = "deep"  # Tests approfondis
    CUSTOM = "custom"  # Configuration personnalisée


class SecurityScanConfig(BaseModel):
    """Configuration d'un scan de sécurité"""
    scan_type: ScanType = ScanType.STANDARD
    
    # Cibles
    server_ids: List[str] = Field(default_factory=list)
    route_ids: List[str] = Field(default_factory=list)  # Si vide, scan tout
    
    # Types de tests
    test_injections: bool = True
    test_xss: bool = True
    test_auth: bool = True
    test_headers: bool = True
    test_cors: bool = True
    test_rate_limiting: bool = True
    test_data_exposure: bool = True
    test_business_logic: bool = False  # Nécessite config manuelle
    
    # Authentification pour les tests
    auth_configs: Dict[str, Any] = Field(default_factory=dict)
    
    # Options
    follow_redirects: bool = True
    max_depth: int = 3
    concurrent_requests: int = 5
    request_delay_ms: int = 100
    
    # Seuils
    timeout_ms: int = 30000
    max_vulnerabilities: int = 1000  # Arrêter après X vulns
    
    # Exclusions
    exclude_paths: List[str] = Field(default_factory=list)
    exclude_parameters: List[str] = Field(default_factory=list)
    
    # Payloads personnalisés
    custom_payloads: Dict[str, List[str]] = Field(default_factory=dict)


class SecurityScanResult(BaseModel):
    """Résultat d'un scan de sécurité"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    
    # Configuration
    config: SecurityScanConfig = Field(default_factory=SecurityScanConfig)
    
    # Timing
    started_at: datetime = Field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    duration_ms: float = 0.0
    
    # Statistiques
    routes_scanned: int = 0
    requests_sent: int = 0
    
    # Vulnérabilités
    vulnerabilities: List[Vulnerability] = Field(default_factory=list)
    
    # Par sévérité
    critical_count: int = 0
    high_count: int = 0
    medium_count: int = 0
    low_count: int = 0
    info_count: int = 0
    
    # Score global
    security_score: int = 100  # 0-100
    grade: str = "A"  # A, B, C, D, F
    
    # Par catégorie OWASP
    owasp_coverage: Dict[str, bool] = Field(default_factory=dict)
    
    # Erreurs
    errors: List[str] = Field(default_factory=list)
    
    @property
    def is_complete(self) -> bool:
        return self.completed_at is not None
    
    def calculate_score(self):
        """Calcule le score de sécurité"""
        # Score de base 100
        score = 100
        
        # Pénalités
        score -= self.critical_count * 25
        score -= self.high_count * 15
        score -= self.medium_count * 10
        score -= self.low_count * 5
        score -= self.info_count * 1
        
        # Minimum 0
        self.security_score = max(0, score)
        
        # Grade
        if self.security_score >= 90:
            self.grade = "A"
        elif self.security_score >= 80:
            self.grade = "B"
        elif self.security_score >= 70:
            self.grade = "C"
        elif self.security_score >= 60:
            self.grade = "D"
        else:
            self.grade = "F"
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class SecurityHeader(BaseModel):
    """Header de sécurité analysé"""
    name: str
    present: bool = False
    value: Optional[str] = None
    recommended_value: Optional[str] = None
    is_correct: bool = False
    description: str = ""
    severity_if_missing: VulnerabilitySeverity = VulnerabilitySeverity.MEDIUM


class CORSAnalysis(BaseModel):
    """Analyse CORS"""
    allow_origin: Optional[str] = None
    allow_credentials: bool = False
    allow_methods: List[str] = Field(default_factory=list)
    allow_headers: List[str] = Field(default_factory=list)
    expose_headers: List[str] = Field(default_factory=list)
    max_age: Optional[int] = None
    
    # Problèmes détectés
    has_wildcard_origin: bool = False
    has_null_origin: bool = False
    reflects_origin: bool = False
    credentials_with_wildcard: bool = False
    
    # Vulnérabilités
    vulnerabilities: List[Vulnerability] = Field(default_factory=list)
