"""
Module Analytics & Reporting - Dashboards et rapports
Centralise les données et génère des rapports professionnels
"""

from datetime import datetime, timedelta
from typing import List, Dict, Optional, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from .server_discovery import _discovered_servers
from .route_discovery import _discovered_routes
from .security_scanner import _scan_results, _vulnerabilities
from .api_testing import _results as _test_results, _collection_results
from .interception import _captured_requests
from .performance_lab import _test_results as _perf_results

from .models.security import VulnerabilitySeverity, VulnerabilityStatus
from .models.test import TestResultStatus

router = APIRouter()


# ============================================================================
# Dashboard Models
# ============================================================================

class OverviewStats(BaseModel):
    """Statistiques globales"""
    # Serveurs
    total_servers: int = 0
    healthy_servers: int = 0
    unhealthy_servers: int = 0
    
    # Routes
    total_routes: int = 0
    tested_routes: int = 0
    untested_routes: int = 0
    
    # Tests
    total_tests_run: int = 0
    passed_tests: int = 0
    failed_tests: int = 0
    test_success_rate: float = 0.0
    
    # Sécurité
    total_vulnerabilities: int = 0
    open_vulnerabilities: int = 0
    critical_count: int = 0
    high_count: int = 0
    medium_count: int = 0
    low_count: int = 0
    
    # Captures
    total_captures: int = 0
    captures_today: int = 0
    
    # Performance
    avg_response_time_ms: float = 0.0
    slowest_endpoints: List[Dict[str, Any]] = []


class ServerStats(BaseModel):
    """Statistiques d'un serveur"""
    server_id: str
    server_name: str
    status: str
    framework: str
    
    # Routes
    routes_count: int = 0
    routes_by_method: Dict[str, int] = {}
    
    # Tests
    tests_run: int = 0
    tests_passed: int = 0
    tests_failed: int = 0
    
    # Sécurité
    vulnerabilities: int = 0
    critical_vulns: int = 0
    
    # Performance
    avg_response_time_ms: float = 0.0
    total_requests: int = 0


class SecuritySummary(BaseModel):
    """Résumé de sécurité"""
    security_score: int = 100
    grade: str = "A"
    
    total_vulnerabilities: int = 0
    open_vulnerabilities: int = 0
    
    by_severity: Dict[str, int] = {}
    by_type: Dict[str, int] = {}
    by_status: Dict[str, int] = {}
    
    top_vulnerable_routes: List[Dict[str, Any]] = []
    recent_scans: List[Dict[str, Any]] = []


class TestingSummary(BaseModel):
    """Résumé des tests"""
    total_tests: int = 0
    passed: int = 0
    failed: int = 0
    error: int = 0
    skipped: int = 0
    
    success_rate: float = 0.0
    avg_duration_ms: float = 0.0
    
    recent_results: List[Dict[str, Any]] = []
    failing_tests: List[Dict[str, Any]] = []


class TrendData(BaseModel):
    """Données de tendance"""
    date: str
    value: float
    label: Optional[str] = None


# ============================================================================
# Analytics Service
# ============================================================================

class AnalyticsService:
    """Service d'analytics"""
    
    def get_overview(self) -> OverviewStats:
        """Génère les statistiques globales"""
        stats = OverviewStats()
        
        # Serveurs
        servers = list(_discovered_servers.values())
        stats.total_servers = len(servers)
        stats.healthy_servers = len([s for s in servers if s.health.status.value == "healthy"])
        stats.unhealthy_servers = len([s for s in servers if s.health.status.value == "unhealthy"])
        
        # Routes
        routes = list(_discovered_routes.values())
        stats.total_routes = len(routes)
        stats.tested_routes = len([r for r in routes if r.test_count > 0])
        stats.untested_routes = stats.total_routes - stats.tested_routes
        
        # Tests
        test_results = list(_test_results.values())
        stats.total_tests_run = len(test_results)
        stats.passed_tests = len([t for t in test_results if t.status == TestResultStatus.PASSED])
        stats.failed_tests = len([t for t in test_results if t.status == TestResultStatus.FAILED])
        
        if stats.total_tests_run > 0:
            stats.test_success_rate = (stats.passed_tests / stats.total_tests_run) * 100
        
        # Sécurité
        vulns = list(_vulnerabilities.values())
        open_vulns = [v for v in vulns if v.status == VulnerabilityStatus.OPEN]
        
        stats.total_vulnerabilities = len(vulns)
        stats.open_vulnerabilities = len(open_vulns)
        stats.critical_count = len([v for v in open_vulns if v.severity == VulnerabilitySeverity.CRITICAL])
        stats.high_count = len([v for v in open_vulns if v.severity == VulnerabilitySeverity.HIGH])
        stats.medium_count = len([v for v in open_vulns if v.severity == VulnerabilitySeverity.MEDIUM])
        stats.low_count = len([v for v in open_vulns if v.severity == VulnerabilitySeverity.LOW])
        
        # Captures
        captures = list(_captured_requests.values())
        stats.total_captures = len(captures)
        
        today = datetime.now().date()
        stats.captures_today = len([c for c in captures if c.timestamp.date() == today])
        
        # Performance - endpoints les plus lents
        route_times = {}
        for capture in captures:
            if capture.route_id:
                if capture.route_id not in route_times:
                    route_times[capture.route_id] = []
                route_times[capture.route_id].append(capture.duration_ms)
        
        slowest = []
        for route_id, times in route_times.items():
            avg_time = sum(times) / len(times)
            if route_id in _discovered_routes:
                route = _discovered_routes[route_id]
                slowest.append({
                    "route_id": route_id,
                    "path": route.path,
                    "method": route.method.value,
                    "avg_response_time_ms": avg_time,
                })
        
        slowest.sort(key=lambda x: -x["avg_response_time_ms"])
        stats.slowest_endpoints = slowest[:5]
        
        if captures:
            stats.avg_response_time_ms = sum(c.duration_ms for c in captures) / len(captures)
        
        return stats
    
    def get_server_stats(self, server_id: str) -> ServerStats:
        """Statistiques d'un serveur"""
        if server_id not in _discovered_servers:
            raise HTTPException(status_code=404, detail="Server not found")
        
        server = _discovered_servers[server_id]
        
        stats = ServerStats(
            server_id=server_id,
            server_name=server.name or f"Server on port {server.port}",
            status=server.status.value,
            framework=server.framework.value,
        )
        
        # Routes
        routes = [r for r in _discovered_routes.values() if r.server_id == server_id]
        stats.routes_count = len(routes)
        
        for route in routes:
            method = route.method.value
            stats.routes_by_method[method] = stats.routes_by_method.get(method, 0) + 1
        
        # Tests
        test_results = [t for t in _test_results.values() 
                       if hasattr(t, 'request') and server.base_url in t.request.url]
        stats.tests_run = len(test_results)
        stats.tests_passed = len([t for t in test_results if t.status == TestResultStatus.PASSED])
        stats.tests_failed = len([t for t in test_results if t.status == TestResultStatus.FAILED])
        
        # Sécurité
        vulns = [v for v in _vulnerabilities.values() if v.server_id == server_id]
        stats.vulnerabilities = len(vulns)
        stats.critical_vulns = len([v for v in vulns if v.severity == VulnerabilitySeverity.CRITICAL])
        
        # Performance
        captures = [c for c in _captured_requests.values() if c.server_id == server_id]
        if captures:
            stats.avg_response_time_ms = sum(c.duration_ms for c in captures) / len(captures)
            stats.total_requests = len(captures)
        
        return stats
    
    def get_security_summary(self) -> SecuritySummary:
        """Résumé de sécurité"""
        summary = SecuritySummary()
        
        vulns = list(_vulnerabilities.values())
        open_vulns = [v for v in vulns if v.status == VulnerabilityStatus.OPEN]
        
        summary.total_vulnerabilities = len(vulns)
        summary.open_vulnerabilities = len(open_vulns)
        
        # Par sévérité
        for severity in VulnerabilitySeverity:
            count = len([v for v in open_vulns if v.severity == severity])
            summary.by_severity[severity.value] = count
        
        # Par type
        type_counts = {}
        for vuln in open_vulns:
            type_name = vuln.type.value
            type_counts[type_name] = type_counts.get(type_name, 0) + 1
        summary.by_type = type_counts
        
        # Par statut
        for status in VulnerabilityStatus:
            count = len([v for v in vulns if v.status == status])
            summary.by_status[status.value] = count
        
        # Score
        score = 100
        score -= summary.by_severity.get('critical', 0) * 25
        score -= summary.by_severity.get('high', 0) * 15
        score -= summary.by_severity.get('medium', 0) * 10
        score -= summary.by_severity.get('low', 0) * 5
        summary.security_score = max(0, score)
        
        if summary.security_score >= 90:
            summary.grade = "A"
        elif summary.security_score >= 80:
            summary.grade = "B"
        elif summary.security_score >= 70:
            summary.grade = "C"
        elif summary.security_score >= 60:
            summary.grade = "D"
        else:
            summary.grade = "F"
        
        # Top routes vulnérables
        route_vulns = {}
        for vuln in open_vulns:
            if vuln.route_id:
                if vuln.route_id not in route_vulns:
                    route_vulns[vuln.route_id] = 0
                route_vulns[vuln.route_id] += 1
        
        top_routes = []
        for route_id, count in sorted(route_vulns.items(), key=lambda x: -x[1])[:5]:
            if route_id in _discovered_routes:
                route = _discovered_routes[route_id]
                top_routes.append({
                    "route_id": route_id,
                    "path": route.path,
                    "method": route.method.value,
                    "vulnerability_count": count,
                })
        summary.top_vulnerable_routes = top_routes
        
        # Scans récents
        recent_scans = sorted(_scan_results.values(), key=lambda s: s.started_at, reverse=True)[:5]
        summary.recent_scans = [
            {
                "id": s.id,
                "started_at": s.started_at.isoformat(),
                "grade": s.grade,
                "vulnerabilities_found": len(s.vulnerabilities),
            }
            for s in recent_scans
        ]
        
        return summary
    
    def get_testing_summary(self) -> TestingSummary:
        """Résumé des tests"""
        summary = TestingSummary()
        
        results = list(_test_results.values())
        
        summary.total_tests = len(results)
        summary.passed = len([r for r in results if r.status == TestResultStatus.PASSED])
        summary.failed = len([r for r in results if r.status == TestResultStatus.FAILED])
        summary.error = len([r for r in results if r.status == TestResultStatus.ERROR])
        summary.skipped = len([r for r in results if r.status == TestResultStatus.SKIPPED])
        
        if summary.total_tests > 0:
            summary.success_rate = (summary.passed / summary.total_tests) * 100
            summary.avg_duration_ms = sum(r.duration_ms for r in results) / len(results)
        
        # Résultats récents
        recent = sorted(results, key=lambda r: r.started_at, reverse=True)[:10]
        summary.recent_results = [
            {
                "id": r.id,
                "test_id": r.test_id,
                "status": r.status.value,
                "duration_ms": r.duration_ms,
                "started_at": r.started_at.isoformat(),
            }
            for r in recent
        ]
        
        # Tests en échec
        failing = [r for r in results if r.status == TestResultStatus.FAILED]
        summary.failing_tests = [
            {
                "id": r.id,
                "test_id": r.test_id,
                "error_message": r.error_message,
                "assertions_failed": r.assertions_failed,
            }
            for r in failing[:10]
        ]
        
        return summary
    
    def get_trends(self, metric: str, days: int = 7) -> List[TrendData]:
        """Récupère les tendances"""
        trends = []
        today = datetime.now().date()
        
        for i in range(days - 1, -1, -1):
            date = today - timedelta(days=i)
            date_str = date.strftime("%Y-%m-%d")
            
            if metric == "vulnerabilities":
                # Vulnérabilités découvertes ce jour
                count = len([
                    v for v in _vulnerabilities.values()
                    if v.discovered_at.date() == date
                ])
                trends.append(TrendData(date=date_str, value=count))
            
            elif metric == "tests":
                # Tests exécutés ce jour
                count = len([
                    t for t in _test_results.values()
                    if t.started_at.date() == date
                ])
                trends.append(TrendData(date=date_str, value=count))
            
            elif metric == "captures":
                # Requêtes capturées ce jour
                count = len([
                    c for c in _captured_requests.values()
                    if c.timestamp.date() == date
                ])
                trends.append(TrendData(date=date_str, value=count))
            
            elif metric == "response_time":
                # Temps de réponse moyen ce jour
                day_captures = [
                    c for c in _captured_requests.values()
                    if c.timestamp.date() == date
                ]
                if day_captures:
                    avg = sum(c.duration_ms for c in day_captures) / len(day_captures)
                else:
                    avg = 0
                trends.append(TrendData(date=date_str, value=avg))
        
        return trends


# Instance singleton
_service = AnalyticsService()


# ============================================================================
# Endpoints API
# ============================================================================

@router.get("/overview", response_model=OverviewStats)
async def get_overview():
    """
    Récupère les statistiques globales du Backend Lab.
    """
    return _service.get_overview()


@router.get("/server/{server_id}", response_model=ServerStats)
async def get_server_stats(server_id: str):
    """
    Récupère les statistiques d'un serveur spécifique.
    """
    return _service.get_server_stats(server_id)


@router.get("/security", response_model=SecuritySummary)
async def get_security_summary():
    """
    Récupère le résumé de sécurité global.
    """
    return _service.get_security_summary()


@router.get("/testing", response_model=TestingSummary)
async def get_testing_summary():
    """
    Récupère le résumé des tests.
    """
    return _service.get_testing_summary()


@router.get("/trends/{metric}", response_model=List[TrendData])
async def get_trends(metric: str, days: int = 7):
    """
    Récupère les tendances d'une métrique.
    Métriques disponibles: vulnerabilities, tests, captures, response_time
    """
    valid_metrics = ["vulnerabilities", "tests", "captures", "response_time"]
    if metric not in valid_metrics:
        raise HTTPException(status_code=400, detail=f"Invalid metric. Valid: {valid_metrics}")
    
    return _service.get_trends(metric, days)


@router.get("/health")
async def health_check():
    """
    Health check de l'API Analytics.
    """
    return {
        "status": "ok",
        "service": "backend-lab-analytics",
        "timestamp": datetime.now().isoformat(),
    }
