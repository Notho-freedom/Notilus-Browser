"""
Module Mock Server - Serveurs mock dynamiques
Permet de créer des serveurs mock pour simuler des APIs
"""

import asyncio
import uuid
import re
import json
from datetime import datetime
from typing import List, Dict, Optional, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from .models.mock import (
    MockServer,
    MockRoute,
    MockResponse,
    MockCondition,
    MockMatch,
    MockMatchType,
    MockServerStatus,
    MockRequestLog,
)

router = APIRouter()

# Stores
_mock_servers: Dict[str, MockServer] = {}
_mock_logs: Dict[str, List[MockRequestLog]] = {}


# ============================================================================
# Mock Route Matcher
# ============================================================================

class MockRouteMatcher:
    """Matcher pour les routes mockées"""
    
    @staticmethod
    def match_path(pattern: str, path: str) -> Optional[Dict[str, str]]:
        """Match un pattern de route avec un path"""
        # Convertir le pattern en regex
        # /api/users/:id -> /api/users/(?P<id>[^/]+)
        regex_pattern = re.sub(r':(\w+)', r'(?P<\1>[^/]+)', pattern)
        regex_pattern = regex_pattern.replace('*', '.*')
        regex_pattern = f'^{regex_pattern}$'
        
        match = re.match(regex_pattern, path)
        if match:
            return match.groupdict()
        return None
    
    @staticmethod
    def check_conditions(conditions: List[MockCondition], request: Dict) -> Optional[MockCondition]:
        """Vérifie les conditions et retourne la première qui matche"""
        sorted_conditions = sorted(conditions, key=lambda c: -c.priority)
        
        for condition in sorted_conditions:
            if MockRouteMatcher._all_matches(condition.matches, request):
                return condition
        
        return None
    
    @staticmethod
    def _all_matches(matches: List[MockMatch], request: Dict) -> bool:
        """Vérifie que tous les matches sont satisfaits"""
        for match in matches:
            if not MockRouteMatcher._check_match(match, request):
                return False
        return True
    
    @staticmethod
    def _check_match(match: MockMatch, request: Dict) -> bool:
        """Vérifie un match unique"""
        # Extraire la valeur source
        value = None
        
        if match.source == "header":
            value = request.get("headers", {}).get(match.key)
        elif match.source == "query":
            value = request.get("query_params", {}).get(match.key)
        elif match.source == "body":
            if match.key:
                value = MockRouteMatcher._get_nested(request.get("body_json", {}), match.key.split('.'))
            else:
                value = request.get("body_json")
        elif match.source == "path":
            value = request.get("path_params", {}).get(match.key)
        elif match.source == "method":
            value = request.get("method")
        
        if value is None:
            return match.type == MockMatchType.NOT_EXISTS
        
        value = str(value)
        target = match.value or ""
        
        if match.type == MockMatchType.EQUALS:
            return value == target
        elif match.type == MockMatchType.CONTAINS:
            return target in value
        elif match.type == MockMatchType.STARTS_WITH:
            return value.startswith(target)
        elif match.type == MockMatchType.ENDS_WITH:
            return value.endswith(target)
        elif match.type == MockMatchType.REGEX:
            return bool(re.match(target, value))
        elif match.type == MockMatchType.EXISTS:
            return True
        elif match.type == MockMatchType.NOT_EXISTS:
            return False
        
        return False
    
    @staticmethod
    def _get_nested(data: Dict, keys: List[str]) -> Any:
        """Récupère une valeur imbriquée"""
        current = data
        for key in keys:
            if isinstance(current, dict) and key in current:
                current = current[key]
            else:
                return None
        return current


# ============================================================================
# Response Builder
# ============================================================================

class MockResponseBuilder:
    """Constructeur de réponses mockées"""
    
    @staticmethod
    def build(response: MockResponse, request: Dict) -> Dict[str, Any]:
        """Construit la réponse finale"""
        body = response.body
        
        # Appliquer le template si présent
        if response.body_template:
            body = MockResponseBuilder._apply_template(response.body_template, request)
        
        # Calculer le délai
        delay = response.delay_ms
        if response.delay_random_max_ms > 0:
            import random
            delay += random.randint(0, response.delay_random_max_ms)
        
        # Simuler un échec
        if response.fail_rate > 0:
            import random
            if random.random() < response.fail_rate:
                return {
                    "status_code": 500,
                    "headers": {"Content-Type": "application/json"},
                    "body": {"error": "Internal Server Error", "message": "Simulated failure"},
                    "delay_ms": delay,
                }
        
        return {
            "status_code": response.status_code,
            "headers": response.headers,
            "body": body,
            "delay_ms": delay,
        }
    
    @staticmethod
    def _apply_template(template: str, request: Dict) -> Any:
        """Applique les substitutions de template"""
        result = template
        
        # Faker variables
        faker_pattern = r'\{\{faker\.(\w+)\}\}'
        for match in re.finditer(faker_pattern, result):
            func_name = match.group(1)
            value = MockResponseBuilder._fake_value(func_name)
            result = result.replace(match.group(0), str(value))
        
        # Request variables
        request_pattern = r'\{\{request\.(\w+(?:\.\w+)*)\}\}'
        for match in re.finditer(request_pattern, result):
            path = match.group(1)
            value = MockResponseBuilder._get_request_value(path, request)
            if value is not None:
                result = result.replace(match.group(0), str(value))
        
        # Timestamp
        result = result.replace('{{timestamp}}', str(int(datetime.now().timestamp())))
        result = result.replace('{{isoTimestamp}}', datetime.now().isoformat())
        result = result.replace('{{uuid}}', str(uuid.uuid4()))
        
        # Essayer de parser en JSON
        try:
            return json.loads(result)
        except:
            return result
    
    @staticmethod
    def _fake_value(func_name: str) -> Any:
        """Génère une valeur fake"""
        import random
        import string
        
        fakers = {
            'name': lambda: random.choice(['John Doe', 'Jane Smith', 'Bob Wilson']),
            'email': lambda: f"user_{uuid.uuid4().hex[:8]}@example.com",
            'uuid': lambda: str(uuid.uuid4()),
            'number': lambda: random.randint(1, 1000),
            'boolean': lambda: random.choice([True, False]),
            'text': lambda: 'Lorem ipsum dolor sit amet',
            'date': lambda: datetime.now().strftime('%Y-%m-%d'),
            'phone': lambda: f"+1-555-{random.randint(100,999)}-{random.randint(1000,9999)}",
        }
        
        return fakers.get(func_name, lambda: f"{{faker.{func_name}}}")()
    
    @staticmethod
    def _get_request_value(path: str, request: Dict) -> Any:
        """Récupère une valeur de la requête"""
        parts = path.split('.')
        
        if parts[0] == 'body':
            return MockRouteMatcher._get_nested(request.get('body_json', {}), parts[1:])
        elif parts[0] == 'headers':
            return request.get('headers', {}).get(parts[1] if len(parts) > 1 else '')
        elif parts[0] == 'query':
            return request.get('query_params', {}).get(parts[1] if len(parts) > 1 else '')
        elif parts[0] == 'path':
            return request.get('path_params', {}).get(parts[1] if len(parts) > 1 else '')
        
        return None


# ============================================================================
# Service Principal
# ============================================================================

class MockServerService:
    """Service de gestion des serveurs mock"""
    
    def __init__(self):
        self.servers = _mock_servers
        self.logs = _mock_logs
    
    def create_server(self, server: MockServer) -> MockServer:
        """Crée un nouveau serveur mock"""
        self.servers[server.id] = server
        self.logs[server.id] = []
        return server
    
    def get_server(self, server_id: str) -> MockServer:
        """Récupère un serveur"""
        if server_id not in self.servers:
            raise HTTPException(status_code=404, detail="Mock server not found")
        return self.servers[server_id]
    
    def delete_server(self, server_id: str):
        """Supprime un serveur"""
        if server_id in self.servers:
            del self.servers[server_id]
        if server_id in self.logs:
            del self.logs[server_id]
    
    def add_route(self, server_id: str, route: MockRoute) -> MockRoute:
        """Ajoute une route à un serveur"""
        server = self.get_server(server_id)
        server.routes.append(route)
        return route
    
    def handle_request(self, server_id: str, method: str, path: str, request: Dict) -> Dict[str, Any]:
        """Traite une requête vers un serveur mock"""
        server = self.get_server(server_id)
        
        # Trouver la route correspondante
        matched_route = None
        path_params = {}
        
        for route in server.routes:
            if not route.enabled:
                continue
            
            if route.method != "*" and route.method != method:
                continue
            
            params = MockRouteMatcher.match_path(route.path, path)
            if params is not None:
                matched_route = route
                path_params = params
                break
        
        # Ajouter les path params à la requête
        request['path_params'] = path_params
        
        # Déterminer la réponse
        if matched_route:
            matched_route.call_count += 1
            matched_route.last_called = datetime.now()
            
            # Vérifier les conditions
            condition = MockRouteMatcher.check_conditions(matched_route.conditions, request)
            
            if condition:
                response_config = condition.response
            else:
                response_config = matched_route.response
            
            response = MockResponseBuilder.build(response_config, request)
        else:
            response = MockResponseBuilder.build(server.default_response, request)
        
        # Logger la requête
        if server.log_requests:
            log = MockRequestLog(
                mock_server_id=server_id,
                mock_route_id=matched_route.id if matched_route else None,
                method=method,
                path=path,
                query_params=request.get('query_params', {}),
                headers=request.get('headers', {}),
                body=request.get('body_json'),
                response_status=response['status_code'],
                response_headers=response['headers'],
                response_body=response['body'],
                matched_route=matched_route is not None,
            )
            
            if server_id not in self.logs:
                self.logs[server_id] = []
            
            self.logs[server_id].append(log)
            
            # Limiter les logs
            if len(self.logs[server_id]) > server.max_stored_requests:
                self.logs[server_id] = self.logs[server_id][-server.max_stored_requests:]
        
        server.total_requests += 1
        
        return response


# Instance singleton
_service = MockServerService()


# ============================================================================
# Endpoints API
# ============================================================================

class CreateMockServerRequest(BaseModel):
    """Requête de création de serveur mock"""
    name: str
    description: Optional[str] = None
    port: int = 0
    cors_enabled: bool = True


class CreateMockRouteRequest(BaseModel):
    """Requête de création de route mock"""
    path: str
    method: str = "GET"
    response: Dict[str, Any]
    conditions: List[Dict[str, Any]] = []


class MockRequestSimulation(BaseModel):
    """Simulation d'une requête vers le mock"""
    method: str = "GET"
    path: str
    headers: Dict[str, str] = {}
    query_params: Dict[str, str] = {}
    body: Optional[Any] = None


@router.post("/servers", response_model=MockServer)
async def create_mock_server(request: CreateMockServerRequest):
    """
    Crée un nouveau serveur mock.
    """
    server = MockServer(
        name=request.name,
        description=request.description,
        port=request.port,
        cors_enabled=request.cors_enabled,
    )
    return _service.create_server(server)


@router.get("/servers", response_model=List[MockServer])
async def list_mock_servers():
    """
    Liste tous les serveurs mock.
    """
    return list(_mock_servers.values())


@router.get("/servers/{server_id}", response_model=MockServer)
async def get_mock_server(server_id: str):
    """
    Récupère un serveur mock.
    """
    return _service.get_server(server_id)


@router.delete("/servers/{server_id}")
async def delete_mock_server(server_id: str):
    """
    Supprime un serveur mock.
    """
    _service.delete_server(server_id)
    return {"status": "ok", "message": "Mock server deleted"}


@router.post("/servers/{server_id}/routes", response_model=MockRoute)
async def add_mock_route(server_id: str, request: CreateMockRouteRequest):
    """
    Ajoute une route à un serveur mock.
    """
    response = MockResponse(**request.response)
    
    conditions = []
    for cond_data in request.conditions:
        matches = [MockMatch(**m) for m in cond_data.get('matches', [])]
        response_data = cond_data.get('response', {})
        cond = MockCondition(
            name=cond_data.get('name'),
            priority=cond_data.get('priority', 0),
            matches=matches,
            response=MockResponse(**response_data),
        )
        conditions.append(cond)
    
    route = MockRoute(
        path=request.path,
        method=request.method,
        response=response,
        conditions=conditions,
    )
    
    return _service.add_route(server_id, route)


@router.get("/servers/{server_id}/routes", response_model=List[MockRoute])
async def list_mock_routes(server_id: str):
    """
    Liste les routes d'un serveur mock.
    """
    server = _service.get_server(server_id)
    return server.routes


@router.post("/servers/{server_id}/simulate")
async def simulate_request(server_id: str, request: MockRequestSimulation):
    """
    Simule une requête vers le serveur mock et retourne la réponse.
    """
    req_data = {
        "method": request.method,
        "path": request.path,
        "headers": request.headers,
        "query_params": request.query_params,
        "body_json": request.body,
    }
    
    response = _service.handle_request(server_id, request.method, request.path, req_data)
    
    # Appliquer le délai si nécessaire
    if response.get('delay_ms', 0) > 0:
        await asyncio.sleep(response['delay_ms'] / 1000)
    
    return response


@router.get("/servers/{server_id}/logs", response_model=List[MockRequestLog])
async def get_mock_logs(server_id: str, limit: int = 100):
    """
    Récupère les logs d'un serveur mock.
    """
    logs = _mock_logs.get(server_id, [])
    return list(reversed(logs[-limit:]))


@router.delete("/servers/{server_id}/logs")
async def clear_mock_logs(server_id: str):
    """
    Vide les logs d'un serveur mock.
    """
    _mock_logs[server_id] = []
    return {"status": "ok", "message": "Logs cleared"}
