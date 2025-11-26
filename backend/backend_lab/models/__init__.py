"""
Modèles de données pour le Backend Lab
"""

from .server import (
    DiscoveredServer,
    ServerStatus,
    HealthCheckResult,
    HealthStatus,
    ServerFramework,
    ScanConfig,
    ScanResult,
)

from .route import (
    DiscoveredRoute,
    RouteParameter,
    HttpMethod,
    ParameterLocation,
    RouteDiscoveryMethod,
)

from .test import (
    TestRequest,
    TestResponse,
    TestResult,
    TestAssertion,
    AssertionOperator,
    TestCollection,
    TestEnvironment,
    TestVariable,
    TestScenario,
    ScenarioStep,
)

from .security import (
    Vulnerability,
    VulnerabilityType,
    VulnerabilitySeverity,
    VulnerabilityStatus,
    SecurityScanResult,
    SecurityScanConfig,
)

from .capture import (
    CapturedRequest,
    InterceptRule,
    InterceptAction,
    Modification,
    ModificationOperation,
)

from .performance import (
    LoadTestConfig,
    LoadTestResult,
    PerformanceMetrics,
    TimelinePoint,
)

from .mock import (
    MockServer,
    MockRoute,
    MockResponse,
    MockCondition,
)

__all__ = [
    # Server
    "DiscoveredServer", "ServerStatus", "HealthCheckResult", "HealthStatus",
    "ServerFramework", "ScanConfig", "ScanResult",
    # Route
    "DiscoveredRoute", "RouteParameter", "HttpMethod", "ParameterLocation",
    "RouteDiscoveryMethod",
    # Test
    "TestRequest", "TestResponse", "TestResult", "TestAssertion",
    "AssertionOperator", "TestCollection", "TestEnvironment", "TestVariable",
    "TestScenario", "ScenarioStep",
    # Security
    "Vulnerability", "VulnerabilityType", "VulnerabilitySeverity",
    "VulnerabilityStatus", "SecurityScanResult", "SecurityScanConfig",
    # Capture
    "CapturedRequest", "InterceptRule", "InterceptAction",
    "Modification", "ModificationOperation",
    # Performance
    "LoadTestConfig", "LoadTestResult", "PerformanceMetrics", "TimelinePoint",
    # Mock
    "MockServer", "MockRoute", "MockResponse", "MockCondition",
]
