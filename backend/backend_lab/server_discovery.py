"""
Module Server Discovery - Détection automatique des serveurs locaux
Le cœur de l'intelligence du Backend Lab
"""

import asyncio
import socket
import ssl
import re
import psutil
from datetime import datetime
from typing import List, Dict, Optional, Any, Tuple
from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
import httpx
import json

from .models.server import (
    DiscoveredServer,
    ServerStatus,
    HealthCheckResult,
    HealthStatus,
    ServerFramework,
    ScanConfig,
    ScanResult,
)

router = APIRouter()

# Store global des serveurs découverts
_discovered_servers: Dict[str, DiscoveredServer] = {}
_active_scan: Optional[ScanResult] = None


# ============================================================================
# Détection de Framework
# ============================================================================

class FrameworkDetector:
    """Détecteur de frameworks basé sur fingerprinting"""
    
    # Patterns de détection
    FRAMEWORK_SIGNATURES = {
        ServerFramework.EXPRESS: {
            'headers': {'x-powered-by': r'Express'},
            'endpoints': ['/api', '/api/v1'],
            'error_patterns': [r'Cannot (GET|POST|PUT|DELETE)'],
        },
        ServerFramework.FASTAPI: {
            'headers': {},
            'endpoints': ['/docs', '/openapi.json', '/redoc'],
            'error_patterns': [r'"detail":\s*"Not Found"'],
            'special_check': 'check_openapi'
        },
        ServerFramework.DJANGO: {
            'headers': {},
            'endpoints': ['/admin', '/admin/login'],
            'cookies': ['csrftoken'],
            'error_patterns': [r'Page not found \(404\)', r'DisallowedHost'],
        },
        ServerFramework.FLASK: {
            'headers': {'server': r'Werkzeug'},
            'endpoints': [],
            'error_patterns': [r'The requested URL was not found'],
        },
        ServerFramework.SPRING_BOOT: {
            'headers': {},
            'endpoints': ['/actuator', '/actuator/health', '/actuator/info'],
            'error_patterns': [r'"error":\s*"Not Found"', r'Whitelabel Error Page'],
        },
        ServerFramework.RAILS: {
            'headers': {'x-powered-by': r'Phusion Passenger', 'x-request-id': r'.+'},
            'cookies': ['_session_id'],
            'error_patterns': [r'Routing Error', r'No route matches'],
        },
        ServerFramework.LARAVEL: {
            'headers': {},
            'cookies': ['laravel_session', 'XSRF-TOKEN'],
            'endpoints': ['/api'],
            'error_patterns': [],
        },
        ServerFramework.NESTJS: {
            'headers': {},
            'endpoints': ['/api', '/swagger', '/api-json'],
            'error_patterns': [r'"statusCode":\s*404'],
            'special_check': 'check_openapi'
        },
        ServerFramework.GIN: {
            'headers': {},
            'error_patterns': [r'404 page not found'],
        },
        ServerFramework.ASPNET: {
            'headers': {'x-powered-by': r'ASP\.NET', 'x-aspnet-version': r'.+'},
            'endpoints': [],
            'error_patterns': [],
        },
        ServerFramework.KOA: {
            'headers': {},
            'error_patterns': [r'Not Found'],
        },
    }
    
    @classmethod
    async def detect(cls, base_url: str) -> Tuple[ServerFramework, float, Dict[str, str]]:
        """
        Détecte le framework utilisé par un serveur
        Retourne: (framework, confiance, headers_signature)
        """
        async with httpx.AsyncClient(timeout=5.0, verify=False, follow_redirects=True) as client:
            headers_signature = {}
            detected_framework = ServerFramework.UNKNOWN
            confidence = 0.0
            
            try:
                # Requête de base
                response = await client.get(base_url)
                headers = dict(response.headers)
                cookies = list(response.cookies.keys())
                body = response.text
                
                # Stocker la signature des headers
                for key in ['server', 'x-powered-by', 'x-framework', 'x-aspnet-version']:
                    if key in headers:
                        headers_signature[key] = headers[key]
                
                # Tester chaque framework
                scores: Dict[ServerFramework, float] = {}
                
                for framework, signatures in cls.FRAMEWORK_SIGNATURES.items():
                    score = 0.0
                    
                    # Check headers
                    for header_name, pattern in signatures.get('headers', {}).items():
                        if header_name in headers:
                            if re.search(pattern, headers[header_name], re.I):
                                score += 30
                    
                    # Check cookies
                    for cookie in signatures.get('cookies', []):
                        if cookie in cookies:
                            score += 20
                    
                    # Check error patterns
                    for pattern in signatures.get('error_patterns', []):
                        if re.search(pattern, body):
                            score += 15
                    
                    if score > 0:
                        scores[framework] = score
                
                # Check endpoints spécifiques
                for framework, signatures in cls.FRAMEWORK_SIGNATURES.items():
                    for endpoint in signatures.get('endpoints', []):
                        try:
                            ep_response = await client.get(f"{base_url}{endpoint}")
                            if ep_response.status_code in [200, 301, 302, 401, 403]:
                                scores[framework] = scores.get(framework, 0) + 25
                        except:
                            pass
                
                # Check OpenAPI/Swagger
                for framework in [ServerFramework.FASTAPI, ServerFramework.NESTJS]:
                    if cls.FRAMEWORK_SIGNATURES[framework].get('special_check') == 'check_openapi':
                        for endpoint in ['/openapi.json', '/swagger.json', '/api-docs']:
                            try:
                                ep_response = await client.get(f"{base_url}{endpoint}")
                                if ep_response.status_code == 200:
                                    try:
                                        data = ep_response.json()
                                        if 'openapi' in data or 'swagger' in data:
                                            scores[framework] = scores.get(framework, 0) + 40
                                    except:
                                        pass
                            except:
                                pass
                
                # Déterminer le framework avec le score le plus élevé
                if scores:
                    detected_framework = max(scores, key=scores.get)
                    max_score = scores[detected_framework]
                    confidence = min(max_score / 100, 1.0)
                
            except Exception as e:
                pass
            
            return detected_framework, confidence, headers_signature


# ============================================================================
# Scanner de Ports
# ============================================================================

class PortScanner:
    """Scanner de ports optimisé"""
    
    @staticmethod
    async def is_port_open(host: str, port: int, timeout: float = 0.5) -> bool:
        """Vérifie si un port est ouvert"""
        try:
            _, writer = await asyncio.wait_for(
                asyncio.open_connection(host, port),
                timeout=timeout
            )
            writer.close()
            await writer.wait_closed()
            return True
        except (asyncio.TimeoutError, ConnectionRefusedError, OSError):
            return False
    
    @staticmethod
    async def scan_ports(host: str, ports: List[int], max_concurrent: int = 50) -> List[int]:
        """Scan une liste de ports en parallèle"""
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def check_with_semaphore(port: int) -> Optional[int]:
            async with semaphore:
                if await PortScanner.is_port_open(host, port):
                    return port
                return None
        
        tasks = [check_with_semaphore(port) for port in ports]
        results = await asyncio.gather(*tasks)
        
        return [p for p in results if p is not None]
    
    @staticmethod
    async def is_http_server(host: str, port: int) -> Tuple[bool, str]:
        """
        Vérifie si le port héberge un serveur HTTP/HTTPS
        Retourne (is_http, protocol)
        """
        # Essayer HTTPS d'abord
        for protocol in ['https', 'http']:
            try:
                async with httpx.AsyncClient(timeout=2.0, verify=False) as client:
                    response = await client.get(f"{protocol}://{host}:{port}/")
                    return True, protocol
            except:
                continue
        
        return False, 'http'


# ============================================================================
# Process Analyzer
# ============================================================================

class ProcessAnalyzer:
    """Analyse les processus pour identifier les serveurs"""
    
    LANGUAGE_PATTERNS = {
        'node': 'Node.js',
        'python': 'Python',
        'python3': 'Python',
        'java': 'Java',
        'ruby': 'Ruby',
        'php': 'PHP',
        'go': 'Go',
        'dotnet': '.NET',
        'beam': 'Erlang/Elixir',
        'nginx': 'Nginx',
        'apache': 'Apache',
    }
    
    @staticmethod
    def get_listening_ports() -> Dict[int, Dict[str, Any]]:
        """Récupère tous les ports en écoute avec infos processus"""
        ports_info = {}
        
        try:
            for conn in psutil.net_connections(kind='inet'):
                if conn.status == 'LISTEN' and conn.laddr:
                    port = conn.laddr.port
                    host = conn.laddr.ip
                    
                    # Ignorer les ports système et les ports > 65000
                    if port < 1024 and port not in [80, 443]:
                        continue
                    if port > 65000:
                        continue
                    
                    # Récupérer les infos du processus
                    proc_info = {}
                    if conn.pid:
                        try:
                            proc = psutil.Process(conn.pid)
                            proc_info = {
                                'pid': conn.pid,
                                'name': proc.name(),
                                'cmdline': ' '.join(proc.cmdline()[:5]),  # Limiter la longueur
                                'cwd': proc.cwd() if hasattr(proc, 'cwd') else None,
                            }
                            
                            # Détecter le langage
                            name_lower = proc.name().lower()
                            for pattern, language in ProcessAnalyzer.LANGUAGE_PATTERNS.items():
                                if pattern in name_lower:
                                    proc_info['language'] = language
                                    break
                        except (psutil.NoSuchProcess, psutil.AccessDenied):
                            pass
                    
                    ports_info[port] = {
                        'host': host,
                        'port': port,
                        **proc_info
                    }
        except Exception as e:
            pass
        
        return ports_info


# ============================================================================
# Health Checker
# ============================================================================

class HealthChecker:
    """Vérifie la santé des serveurs"""
    
    HEALTH_ENDPOINTS = [
        '/health',
        '/healthz',
        '/health/live',
        '/health/ready',
        '/actuator/health',
        '/api/health',
        '/_health',
        '/ping',
        '/status',
    ]
    
    @classmethod
    async def check(cls, base_url: str) -> HealthCheckResult:
        """Effectue un health check complet"""
        result = HealthCheckResult()
        start_time = datetime.now()
        
        async with httpx.AsyncClient(timeout=5.0, verify=False) as client:
            # Essayer les endpoints de health
            for endpoint in cls.HEALTH_ENDPOINTS:
                try:
                    response = await client.get(f"{base_url}{endpoint}")
                    if response.status_code in [200, 204]:
                        result.status = HealthStatus.HEALTHY
                        result.response_time_ms = (datetime.now() - start_time).total_seconds() * 1000
                        return result
                except:
                    continue
            
            # Fallback: vérifier la racine
            try:
                response = await client.get(base_url)
                if response.status_code < 500:
                    result.status = HealthStatus.HEALTHY
                else:
                    result.status = HealthStatus.DEGRADED
                result.response_time_ms = (datetime.now() - start_time).total_seconds() * 1000
            except Exception as e:
                result.status = HealthStatus.UNHEALTHY
                result.error_message = str(e)
        
        result.last_check = datetime.now()
        return result


# ============================================================================
# Service Principal
# ============================================================================

class ServerDiscoveryService:
    """Service principal de découverte de serveurs"""
    
    def __init__(self):
        self.discovered_servers: Dict[str, DiscoveredServer] = _discovered_servers
    
    async def scan(self, config: ScanConfig = None) -> ScanResult:
        """Exécute un scan complet"""
        global _active_scan
        
        if config is None:
            config = ScanConfig()
        
        result = ScanResult(config=config)
        _active_scan = result
        
        start_time = datetime.now()
        
        # Construire la liste des ports à scanner
        ports_to_scan = set(config.specific_ports)
        for start, end in config.port_ranges:
            ports_to_scan.update(range(start, end + 1))
        
        # Construire la liste des hosts
        hosts = []
        if config.scan_localhost:
            hosts.append('localhost')
        if config.scan_127_0_0_1:
            hosts.append('127.0.0.1')
        if config.scan_0_0_0_0:
            hosts.append('0.0.0.0')
        
        result.ports_scanned = len(ports_to_scan) * len(hosts)
        
        # Récupérer les infos processus pour les ports en écoute
        process_ports = ProcessAnalyzer.get_listening_ports()
        
        # Scanner chaque host
        for host in hosts:
            # Utiliser les ports détectés par processus si disponibles
            ports_list = list(ports_to_scan)
            if host in ['localhost', '127.0.0.1', '0.0.0.0']:
                # Prioriser les ports avec des processus actifs
                process_port_list = list(process_ports.keys())
                ports_list = list(set(ports_list) | set(process_port_list))
            
            # Scanner les ports
            open_ports = await PortScanner.scan_ports(
                host, ports_list, config.max_concurrent_scans
            )
            result.ports_open += len(open_ports)
            
            # Analyser chaque port ouvert
            for port in open_ports:
                is_http, protocol = await PortScanner.is_http_server(host, port)
                
                if is_http:
                    base_url = f"{protocol}://{host}:{port}"
                    
                    # Créer le serveur
                    server = DiscoveredServer(
                        host=host,
                        port=port,
                        protocol=protocol,
                        status=ServerStatus.RUNNING,
                        discovery_method="port_scan"
                    )
                    
                    # Ajouter les infos processus
                    if port in process_ports:
                        proc_info = process_ports[port]
                        server.process_id = proc_info.get('pid')
                        server.process_name = proc_info.get('name')
                        server.working_directory = proc_info.get('cwd')
                        server.command_line = proc_info.get('cmdline')
                        server.language = proc_info.get('language')
                    
                    # Fingerprinting du framework
                    if config.enable_fingerprinting:
                        framework, confidence, headers = await FrameworkDetector.detect(base_url)
                        server.framework = framework
                        server.headers_signature = headers
                        
                        # Générer un nom
                        if server.process_name:
                            server.name = f"{server.process_name} ({framework.value if framework != ServerFramework.UNKNOWN else 'HTTP'})"
                        else:
                            server.name = f"{framework.value if framework != ServerFramework.UNKNOWN else 'HTTP'} Server"
                    
                    # Health check
                    server.health = await HealthChecker.check(base_url)
                    
                    # Stocker
                    self.discovered_servers[server.id] = server
                    result.servers_found.append(server)
        
        result.completed_at = datetime.now()
        result.duration_ms = (result.completed_at - start_time).total_seconds() * 1000
        _active_scan = None
        
        return result
    
    async def refresh_server(self, server_id: str) -> DiscoveredServer:
        """Rafraîchit les infos d'un serveur"""
        if server_id not in self.discovered_servers:
            raise HTTPException(status_code=404, detail="Server not found")
        
        server = self.discovered_servers[server_id]
        base_url = server.base_url
        
        # Re-vérifier le framework
        framework, _, headers = await FrameworkDetector.detect(base_url)
        server.framework = framework
        server.headers_signature = headers
        
        # Health check
        server.health = await HealthChecker.check(base_url)
        server.last_seen = datetime.now()
        
        if server.health.status == HealthStatus.UNHEALTHY:
            server.status = ServerStatus.ERROR
        else:
            server.status = ServerStatus.RUNNING
        
        return server
    
    def get_all_servers(self) -> List[DiscoveredServer]:
        """Retourne tous les serveurs découverts"""
        return list(self.discovered_servers.values())
    
    def get_server(self, server_id: str) -> DiscoveredServer:
        """Retourne un serveur par ID"""
        if server_id not in self.discovered_servers:
            raise HTTPException(status_code=404, detail="Server not found")
        return self.discovered_servers[server_id]
    
    def remove_server(self, server_id: str):
        """Supprime un serveur de la liste"""
        if server_id in self.discovered_servers:
            del self.discovered_servers[server_id]
    
    async def add_manual_server(
        self, 
        host: str, 
        port: int, 
        protocol: str = "http",
        name: Optional[str] = None
    ) -> DiscoveredServer:
        """Ajoute un serveur manuellement"""
        base_url = f"{protocol}://{host}:{port}"
        
        server = DiscoveredServer(
            host=host,
            port=port,
            protocol=protocol,
            name=name or f"Manual Server ({host}:{port})",
            discovery_method="manual"
        )
        
        # Vérifier et fingerprint
        framework, _, headers = await FrameworkDetector.detect(base_url)
        server.framework = framework
        server.headers_signature = headers
        server.health = await HealthChecker.check(base_url)
        
        if server.health.status != HealthStatus.UNHEALTHY:
            server.status = ServerStatus.RUNNING
        else:
            server.status = ServerStatus.ERROR
        
        self.discovered_servers[server.id] = server
        return server


# Instance singleton
_service = ServerDiscoveryService()


# ============================================================================
# Endpoints API
# ============================================================================

class ScanRequest(BaseModel):
    """Requête de scan"""
    port_ranges: Optional[List[Tuple[int, int]]] = None
    specific_ports: Optional[List[int]] = None
    enable_fingerprinting: bool = True


class AddServerRequest(BaseModel):
    """Requête d'ajout manuel"""
    host: str
    port: int
    protocol: str = "http"
    name: Optional[str] = None


@router.post("/scan", response_model=ScanResult)
async def scan_servers(
    request: Optional[ScanRequest] = None,
    background_tasks: BackgroundTasks = None
):
    """
    Lance un scan des serveurs locaux.
    Détecte automatiquement les serveurs HTTP/HTTPS en cours d'exécution.
    """
    config = ScanConfig()
    if request:
        if request.port_ranges:
            config.port_ranges = request.port_ranges
        if request.specific_ports:
            config.specific_ports = request.specific_ports
        config.enable_fingerprinting = request.enable_fingerprinting
    
    result = await _service.scan(config)
    return result


@router.get("/servers", response_model=List[DiscoveredServer])
async def list_servers():
    """
    Liste tous les serveurs découverts.
    """
    return _service.get_all_servers()


@router.get("/servers/{server_id}", response_model=DiscoveredServer)
async def get_server(server_id: str):
    """
    Récupère les détails d'un serveur spécifique.
    """
    return _service.get_server(server_id)


@router.post("/servers/{server_id}/health", response_model=HealthCheckResult)
async def health_check(server_id: str):
    """
    Effectue un health check sur un serveur.
    """
    server = _service.get_server(server_id)
    result = await HealthChecker.check(server.base_url)
    server.health = result
    server.last_seen = datetime.now()
    return result


@router.post("/servers/{server_id}/refresh", response_model=DiscoveredServer)
async def refresh_server(server_id: str):
    """
    Rafraîchit toutes les informations d'un serveur.
    """
    return await _service.refresh_server(server_id)


@router.delete("/servers/{server_id}")
async def remove_server(server_id: str):
    """
    Supprime un serveur de la liste des serveurs découverts.
    """
    _service.remove_server(server_id)
    return {"status": "ok", "message": "Server removed"}


@router.post("/servers", response_model=DiscoveredServer)
async def add_server(request: AddServerRequest):
    """
    Ajoute un serveur manuellement.
    """
    return await _service.add_manual_server(
        request.host,
        request.port,
        request.protocol,
        request.name
    )


@router.get("/scan/status")
async def scan_status():
    """
    Retourne le statut du scan en cours.
    """
    global _active_scan
    if _active_scan:
        return {
            "scanning": True,
            "started_at": _active_scan.started_at.isoformat(),
            "ports_scanned": _active_scan.ports_scanned,
            "servers_found": len(_active_scan.servers_found)
        }
    return {"scanning": False}


@router.get("/processes")
async def list_listening_processes():
    """
    Liste tous les processus avec des ports en écoute.
    Utile pour le debug et l'analyse.
    """
    return ProcessAnalyzer.get_listening_ports()
