"""
Module Route Discovery - Découverte intelligente des endpoints API
Utilise OpenAPI, GraphQL introspection, fuzzing et analyse de réponses
"""

import asyncio
import re
import json
from datetime import datetime
from typing import List, Dict, Optional, Any, Set
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx

from .models.route import (
    DiscoveredRoute,
    RouteParameter,
    HttpMethod,
    ParameterLocation,
    RouteDiscoveryMethod,
    OpenAPISpec,
)
from .models.server import DiscoveredServer
from .server_discovery import _discovered_servers

router = APIRouter()

# Store global des routes découvertes
_discovered_routes: Dict[str, DiscoveredRoute] = {}


# ============================================================================
# OpenAPI Parser
# ============================================================================

class OpenAPIParser:
    """Parse les spécifications OpenAPI/Swagger"""
    
    OPENAPI_ENDPOINTS = [
        '/openapi.json',
        '/swagger.json',
        '/api-docs',
        '/v2/api-docs',
        '/v3/api-docs',
        '/swagger/v1/swagger.json',
        '/api/openapi.json',
        '/.well-known/openapi.json',
    ]
    
    @classmethod
    async def discover(cls, base_url: str) -> Optional[Dict[str, Any]]:
        """Tente de découvrir et télécharger la spec OpenAPI"""
        async with httpx.AsyncClient(timeout=10.0, verify=False) as client:
            for endpoint in cls.OPENAPI_ENDPOINTS:
                try:
                    response = await client.get(f"{base_url}{endpoint}")
                    if response.status_code == 200:
                        data = response.json()
                        if 'openapi' in data or 'swagger' in data or 'paths' in data:
                            return data
                except:
                    continue
        return None
    
    @classmethod
    def parse(cls, spec: Dict[str, Any], server_id: str) -> List[DiscoveredRoute]:
        """Parse une spécification OpenAPI en routes"""
        routes = []
        
        # Déterminer la version
        is_v3 = 'openapi' in spec
        base_path = spec.get('basePath', '') if not is_v3 else ''
        
        # Parser les paths
        paths = spec.get('paths', {})
        
        for path, path_item in paths.items():
            full_path = f"{base_path}{path}"
            
            for method in ['get', 'post', 'put', 'delete', 'patch', 'head', 'options']:
                if method not in path_item:
                    continue
                
                operation = path_item[method]
                
                route = DiscoveredRoute(
                    server_id=server_id,
                    path=full_path,
                    method=HttpMethod(method.upper()),
                    discovery_method=RouteDiscoveryMethod.OPENAPI,
                    summary=operation.get('summary'),
                    description=operation.get('description'),
                    tags=operation.get('tags', []),
                    operation_id=operation.get('operationId'),
                    deprecated=operation.get('deprecated', False),
                )
                
                # Parser les paramètres
                parameters = operation.get('parameters', []) + path_item.get('parameters', [])
                
                for param in parameters:
                    route_param = RouteParameter(
                        name=param.get('name', ''),
                        location=ParameterLocation(param.get('in', 'query')),
                        type=param.get('schema', {}).get('type', 'string') if is_v3 else param.get('type', 'string'),
                        required=param.get('required', False),
                        description=param.get('description'),
                        enum_values=param.get('schema', {}).get('enum') if is_v3 else param.get('enum'),
                        default_value=param.get('schema', {}).get('default') if is_v3 else param.get('default'),
                    )
                    
                    if route_param.location == ParameterLocation.PATH:
                        route.path_params.append(route_param)
                    elif route_param.location == ParameterLocation.QUERY:
                        route.query_params.append(route_param)
                    elif route_param.location == ParameterLocation.HEADER:
                        route.header_params.append(route_param)
                
                # Parser le body (OpenAPI 3.x)
                if is_v3 and 'requestBody' in operation:
                    request_body = operation['requestBody']
                    content = request_body.get('content', {})
                    if 'application/json' in content:
                        route.body_schema = content['application/json'].get('schema', {})
                        route.content_types.append('application/json')
                
                # Parser les réponses
                responses = operation.get('responses', {})
                for status_code, response_def in responses.items():
                    try:
                        code = int(status_code)
                        route.response_codes.append(code)
                        
                        if is_v3:
                            content = response_def.get('content', {})
                            if 'application/json' in content:
                                route.response_schemas[str(code)] = content['application/json'].get('schema', {})
                        else:
                            if 'schema' in response_def:
                                route.response_schemas[str(code)] = response_def['schema']
                    except ValueError:
                        pass  # Ignorer les codes non-numériques (default, etc.)
                
                # Sécurité
                security = operation.get('security', spec.get('security', []))
                if security:
                    route.auth_required = True
                    for sec_req in security:
                        for sec_name, scopes in sec_req.items():
                            route.scopes.extend(scopes)
                
                routes.append(route)
        
        return routes


# ============================================================================
# GraphQL Introspection
# ============================================================================

class GraphQLIntrospector:
    """Introspection des APIs GraphQL"""
    
    GRAPHQL_ENDPOINTS = [
        '/graphql',
        '/gql',
        '/api/graphql',
        '/v1/graphql',
    ]
    
    INTROSPECTION_QUERY = """
    query IntrospectionQuery {
      __schema {
        queryType { name }
        mutationType { name }
        subscriptionType { name }
        types {
          name
          kind
          description
          fields(includeDeprecated: true) {
            name
            description
            args {
              name
              description
              type {
                name
                kind
                ofType { name kind }
              }
              defaultValue
            }
            type {
              name
              kind
              ofType { name kind }
            }
            isDeprecated
            deprecationReason
          }
        }
      }
    }
    """
    
    @classmethod
    async def discover(cls, base_url: str) -> Optional[str]:
        """Découvre l'endpoint GraphQL"""
        async with httpx.AsyncClient(timeout=10.0, verify=False) as client:
            for endpoint in cls.GRAPHQL_ENDPOINTS:
                try:
                    # Test avec une query d'introspection
                    response = await client.post(
                        f"{base_url}{endpoint}",
                        json={"query": "{ __typename }"},
                        headers={"Content-Type": "application/json"}
                    )
                    if response.status_code == 200:
                        data = response.json()
                        if 'data' in data or 'errors' in data:
                            return endpoint
                except:
                    continue
        return None
    
    @classmethod
    async def introspect(cls, base_url: str, endpoint: str) -> List[DiscoveredRoute]:
        """Effectue l'introspection GraphQL"""
        routes = []
        
        async with httpx.AsyncClient(timeout=30.0, verify=False) as client:
            try:
                response = await client.post(
                    f"{base_url}{endpoint}",
                    json={"query": cls.INTROSPECTION_QUERY},
                    headers={"Content-Type": "application/json"}
                )
                
                if response.status_code != 200:
                    return routes
                
                data = response.json()
                schema = data.get('data', {}).get('__schema', {})
                
                # Parser les types Query, Mutation, Subscription
                type_map = {t['name']: t for t in schema.get('types', [])}
                
                for type_kind, gql_type in [
                    ('query', schema.get('queryType', {}).get('name')),
                    ('mutation', schema.get('mutationType', {}).get('name')),
                    ('subscription', schema.get('subscriptionType', {}).get('name')),
                ]:
                    if not gql_type or gql_type not in type_map:
                        continue
                    
                    type_def = type_map[gql_type]
                    
                    for field in type_def.get('fields', []):
                        route = DiscoveredRoute(
                            server_id="",  # Sera rempli plus tard
                            path=endpoint,
                            method=HttpMethod.POST,
                            discovery_method=RouteDiscoveryMethod.GRAPHQL_INTROSPECTION,
                            is_graphql=True,
                            graphql_type=type_kind,
                            graphql_operation=field['name'],
                            summary=field.get('description'),
                            deprecated=field.get('isDeprecated', False),
                        )
                        
                        # Parser les arguments
                        for arg in field.get('args', []):
                            param = RouteParameter(
                                name=arg['name'],
                                location=ParameterLocation.BODY,
                                type=cls._get_graphql_type(arg.get('type', {})),
                                description=arg.get('description'),
                                default_value=arg.get('defaultValue'),
                            )
                            route.path_params.append(param)
                        
                        routes.append(route)
                
            except Exception as e:
                pass
        
        return routes
    
    @staticmethod
    def _get_graphql_type(type_def: Dict) -> str:
        """Extrait le type GraphQL en string"""
        if not type_def:
            return "unknown"
        
        kind = type_def.get('kind', '')
        name = type_def.get('name', '')
        
        if kind == 'NON_NULL':
            of_type = type_def.get('ofType', {})
            return f"{GraphQLIntrospector._get_graphql_type(of_type)}!"
        elif kind == 'LIST':
            of_type = type_def.get('ofType', {})
            return f"[{GraphQLIntrospector._get_graphql_type(of_type)}]"
        else:
            return name or "unknown"


# ============================================================================
# Route Fuzzer
# ============================================================================

class RouteFuzzer:
    """Découverte de routes par fuzzing intelligent"""
    
    # Patterns de routes courants
    COMMON_ROUTES = [
        # Auth
        '/auth/login', '/auth/register', '/auth/logout', '/auth/refresh',
        '/auth/forgot-password', '/auth/reset-password', '/auth/verify',
        '/login', '/register', '/logout', '/signup',
        
        # API versionnée
        '/api', '/api/v1', '/api/v2', '/api/v3',
        
        # Resources CRUD communes
        '/users', '/users/me', '/users/:id',
        '/products', '/products/:id',
        '/orders', '/orders/:id',
        '/items', '/items/:id',
        '/posts', '/posts/:id',
        '/comments', '/comments/:id',
        '/categories', '/categories/:id',
        '/tags', '/tags/:id',
        '/files', '/files/:id',
        '/uploads', '/images',
        '/messages', '/notifications',
        '/settings', '/preferences',
        '/profiles', '/accounts',
        '/payments', '/transactions',
        '/reports', '/analytics',
        '/events', '/logs',
        
        # Admin
        '/admin', '/admin/dashboard', '/admin/users',
        '/dashboard', '/management',
        
        # Health & Status
        '/health', '/healthz', '/status', '/ping', '/ready', '/live',
        '/metrics', '/info', '/version',
        
        # Documentation
        '/docs', '/swagger', '/redoc', '/api-docs',
        
        # WebSocket
        '/ws', '/socket', '/socket.io', '/realtime',
    ]
    
    # Resources à tester avec différentes méthodes
    RESOURCE_NAMES = [
        'users', 'products', 'orders', 'items', 'posts', 'comments',
        'categories', 'tags', 'files', 'images', 'documents', 'messages',
        'notifications', 'settings', 'profiles', 'accounts', 'payments',
        'transactions', 'reports', 'analytics', 'logs', 'events',
        'customers', 'clients', 'projects', 'tasks', 'tickets',
        'invoices', 'subscriptions', 'plans', 'roles', 'permissions',
    ]
    
    @classmethod
    async def fuzz(
        cls, 
        base_url: str, 
        server_id: str,
        existing_routes: Set[str] = None,
        max_concurrent: int = 10
    ) -> List[DiscoveredRoute]:
        """Découvre des routes par fuzzing"""
        routes = []
        existing = existing_routes or set()
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def check_route(path: str, method: str = "GET") -> Optional[DiscoveredRoute]:
            async with semaphore:
                # Normaliser le path
                normalized = re.sub(r':(\w+)', r'1', path)  # Remplacer :id par 1
                
                # Skip si déjà découvert
                route_key = f"{method}:{path}"
                if route_key in existing:
                    return None
                
                try:
                    async with httpx.AsyncClient(timeout=5.0, verify=False) as client:
                        url = f"{base_url}{normalized}"
                        
                        if method == "GET":
                            response = await client.get(url)
                        elif method == "POST":
                            response = await client.post(url, json={})
                        elif method == "PUT":
                            response = await client.put(url, json={})
                        elif method == "DELETE":
                            response = await client.delete(url)
                        elif method == "PATCH":
                            response = await client.patch(url, json={})
                        else:
                            response = await client.request(method, url)
                        
                        # Route trouvée si pas 404/405
                        if response.status_code not in [404, 405, 400]:
                            route = DiscoveredRoute(
                                server_id=server_id,
                                path=path,
                                method=HttpMethod(method),
                                discovery_method=RouteDiscoveryMethod.FUZZING,
                                response_codes=[response.status_code],
                            )
                            
                            # Détecter si auth requise
                            if response.status_code in [401, 403]:
                                route.auth_required = True
                            
                            # Détecter le content type
                            content_type = response.headers.get('content-type', '')
                            if content_type:
                                route.content_types.append(content_type.split(';')[0])
                            
                            # Extraire les paramètres du path
                            path_params = re.findall(r':(\w+)', path)
                            for param_name in path_params:
                                route.path_params.append(RouteParameter(
                                    name=param_name,
                                    location=ParameterLocation.PATH,
                                    type="string",
                                    required=True,
                                ))
                            
                            existing.add(route_key)
                            return route
                            
                except Exception as e:
                    pass
                
                return None
        
        # Tester les routes communes
        tasks = []
        for path in cls.COMMON_ROUTES:
            tasks.append(check_route(path, "GET"))
        
        # Tester les resources avec toutes les méthodes
        for resource in cls.RESOURCE_NAMES:
            for prefix in ['/api', '/api/v1', '']:
                # Collection
                tasks.append(check_route(f"{prefix}/{resource}", "GET"))
                tasks.append(check_route(f"{prefix}/{resource}", "POST"))
                
                # Item
                tasks.append(check_route(f"{prefix}/{resource}/:id", "GET"))
                tasks.append(check_route(f"{prefix}/{resource}/:id", "PUT"))
                tasks.append(check_route(f"{prefix}/{resource}/:id", "DELETE"))
                tasks.append(check_route(f"{prefix}/{resource}/:id", "PATCH"))
        
        results = await asyncio.gather(*tasks)
        routes = [r for r in results if r is not None]
        
        return routes


# ============================================================================
# Response Analyzer
# ============================================================================

class ResponseAnalyzer:
    """Analyse les réponses pour découvrir plus de routes"""
    
    @staticmethod
    def extract_links_from_response(response_body: str, base_path: str = "") -> List[str]:
        """Extrait les liens d'une réponse JSON"""
        links = []
        
        try:
            data = json.loads(response_body)
            links.extend(ResponseAnalyzer._extract_links_recursive(data))
        except:
            pass
        
        # Patterns de liens dans le texte
        url_patterns = [
            r'"(/api[^"]+)"',
            r'"(/v\d+[^"]+)"',
            r'"(https?://[^"]+)"',
            r"'(/api[^']+)'",
        ]
        
        for pattern in url_patterns:
            matches = re.findall(pattern, response_body)
            links.extend(matches)
        
        return list(set(links))
    
    @staticmethod
    def _extract_links_recursive(data: Any, prefix: str = "") -> List[str]:
        """Extrait récursivement les liens d'un objet JSON"""
        links = []
        
        if isinstance(data, dict):
            # Chercher les clés de liens HATEOAS
            for key in ['href', 'url', 'link', 'uri', 'self', '_links']:
                if key in data:
                    value = data[key]
                    if isinstance(value, str):
                        links.append(value)
                    elif isinstance(value, dict):
                        links.extend(ResponseAnalyzer._extract_links_recursive(value))
            
            # Récurser dans les valeurs
            for value in data.values():
                links.extend(ResponseAnalyzer._extract_links_recursive(value))
        
        elif isinstance(data, list):
            for item in data:
                links.extend(ResponseAnalyzer._extract_links_recursive(item))
        
        return links


# ============================================================================
# Service Principal
# ============================================================================

class RouteDiscoveryService:
    """Service principal de découverte de routes"""
    
    def __init__(self):
        self.discovered_routes: Dict[str, DiscoveredRoute] = _discovered_routes
        self.servers = _discovered_servers
    
    async def discover_routes(
        self, 
        server_id: str,
        use_openapi: bool = True,
        use_graphql: bool = True,
        use_fuzzing: bool = True,
    ) -> List[DiscoveredRoute]:
        """Découvre toutes les routes d'un serveur"""
        if server_id not in self.servers:
            raise HTTPException(status_code=404, detail="Server not found")
        
        server = self.servers[server_id]
        base_url = server.base_url
        routes = []
        discovered_paths: Set[str] = set()
        
        # 1. Essayer OpenAPI
        if use_openapi:
            spec = await OpenAPIParser.discover(base_url)
            if spec:
                openapi_routes = OpenAPIParser.parse(spec, server_id)
                for route in openapi_routes:
                    route_key = f"{route.method}:{route.path}"
                    if route_key not in discovered_paths:
                        discovered_paths.add(route_key)
                        routes.append(route)
        
        # 2. Essayer GraphQL
        if use_graphql:
            gql_endpoint = await GraphQLIntrospector.discover(base_url)
            if gql_endpoint:
                gql_routes = await GraphQLIntrospector.introspect(base_url, gql_endpoint)
                for route in gql_routes:
                    route.server_id = server_id
                    routes.append(route)
                
                # Ajouter le endpoint GraphQL lui-même
                gql_route = DiscoveredRoute(
                    server_id=server_id,
                    path=gql_endpoint,
                    method=HttpMethod.POST,
                    discovery_method=RouteDiscoveryMethod.GRAPHQL_INTROSPECTION,
                    is_graphql=True,
                    summary="GraphQL Endpoint",
                )
                routes.append(gql_route)
        
        # 3. Fuzzing
        if use_fuzzing:
            fuzz_routes = await RouteFuzzer.fuzz(
                base_url, 
                server_id,
                existing_routes=discovered_paths
            )
            routes.extend(fuzz_routes)
        
        # Stocker les routes
        for route in routes:
            self.discovered_routes[route.id] = route
        
        # Mettre à jour le serveur
        server.route_ids = [r.id for r in routes]
        server.routes_count = len(routes)
        
        return routes
    
    def get_routes_for_server(self, server_id: str) -> List[DiscoveredRoute]:
        """Récupère toutes les routes d'un serveur"""
        return [r for r in self.discovered_routes.values() if r.server_id == server_id]
    
    def get_route(self, route_id: str) -> DiscoveredRoute:
        """Récupère une route par ID"""
        if route_id not in self.discovered_routes:
            raise HTTPException(status_code=404, detail="Route not found")
        return self.discovered_routes[route_id]
    
    async def import_openapi(self, server_id: str, spec: Dict[str, Any]) -> List[DiscoveredRoute]:
        """Importe une spécification OpenAPI"""
        routes = OpenAPIParser.parse(spec, server_id)
        
        for route in routes:
            self.discovered_routes[route.id] = route
        
        if server_id in self.servers:
            self.servers[server_id].route_ids.extend([r.id for r in routes])
            self.servers[server_id].routes_count = len(self.servers[server_id].route_ids)
        
        return routes


# Instance singleton
_service = RouteDiscoveryService()


# ============================================================================
# Endpoints API
# ============================================================================

class DiscoverRequest(BaseModel):
    """Requête de découverte"""
    use_openapi: bool = True
    use_graphql: bool = True
    use_fuzzing: bool = True


class ImportOpenAPIRequest(BaseModel):
    """Requête d'import OpenAPI"""
    spec: Dict[str, Any]


@router.post("/discover/{server_id}", response_model=List[DiscoveredRoute])
async def discover_routes(server_id: str, request: Optional[DiscoverRequest] = None):
    """
    Découvre automatiquement toutes les routes d'un serveur.
    Utilise OpenAPI, GraphQL introspection et fuzzing.
    """
    options = request or DiscoverRequest()
    return await _service.discover_routes(
        server_id,
        use_openapi=options.use_openapi,
        use_graphql=options.use_graphql,
        use_fuzzing=options.use_fuzzing,
    )


@router.get("/{server_id}", response_model=List[DiscoveredRoute])
async def list_routes(server_id: str):
    """
    Liste toutes les routes découvertes pour un serveur.
    """
    return _service.get_routes_for_server(server_id)


@router.get("/{server_id}/{route_id}", response_model=DiscoveredRoute)
async def get_route(server_id: str, route_id: str):
    """
    Récupère les détails d'une route spécifique.
    """
    route = _service.get_route(route_id)
    if route.server_id != server_id:
        raise HTTPException(status_code=404, detail="Route not found for this server")
    return route


@router.post("/{server_id}/import", response_model=List[DiscoveredRoute])
async def import_openapi(server_id: str, request: ImportOpenAPIRequest):
    """
    Importe une spécification OpenAPI pour un serveur.
    """
    return await _service.import_openapi(server_id, request.spec)


@router.delete("/{route_id}")
async def delete_route(route_id: str):
    """
    Supprime une route de la liste des routes découvertes.
    """
    if route_id in _discovered_routes:
        del _discovered_routes[route_id]
    return {"status": "ok", "message": "Route deleted"}
