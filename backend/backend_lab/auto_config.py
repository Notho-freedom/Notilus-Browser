"""
Module Auto Configuration - Configuration automatique basée sur le serveur cible
Quand un serveur cible est sélectionné, configure automatiquement routes, tests, etc.
"""

import asyncio
from datetime import datetime
from typing import List, Dict, Optional, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx
import json
import re

from .models.server import DiscoveredServer
from .models.route import DiscoveredRoute, RouteParameter, ParameterLocation, HttpMethod
from .server_discovery import _discovered_servers, _service as server_service
from .route_discovery import _service as route_service, OpenAPIParser, RouteFuzzer
from .api_testing import _service as test_service, FunctionalTest, TestRequest, BodyType
from .validators import validate_server_id

router = APIRouter()

# Store des configurations automatiques
_auto_configs: Dict[str, Dict[str, Any]] = {}


# ============================================================================
# Détection avancée des paramètres
# ============================================================================

class ParameterDetector:
    """Détecte automatiquement les paramètres des routes"""
    
    @staticmethod
    async def detect_route_parameters(
        server: DiscoveredServer,
        route: DiscoveredRoute
    ) -> DiscoveredRoute:
        """Détecte les paramètres d'une route en testant différentes combinaisons"""
        base_url = server.base_url
        full_path = route.path
        
        # Détecter les paramètres de path
        path_params = re.findall(r'\{(\w+)\}|:(\w+)', full_path)
        for match in path_params:
            param_name = match[0] or match[1]
            if not any(p.name == param_name for p in route.path_params):
                route.path_params.append(RouteParameter(
                    name=param_name,
                    location=ParameterLocation.PATH,
                    type="string",
                    required=True,
                ))
        
        # Tester la route pour détecter les paramètres query et body
        async with httpx.AsyncClient(timeout=5.0, verify=False) as client:
            try:
                # Test 1: Requête sans paramètres
                test_url = full_path.replace('{', '').replace('}', '').replace(':id', '1')
                response1 = await client.request(route.method.value, f"{base_url}{test_url}")
                
                # Test 2: Requête avec paramètres query communs
                test_params = {
                    'page': '1',
                    'limit': '10',
                    'offset': '0',
                    'sort': 'asc',
                    'filter': 'test',
                    'search': 'query',
                    'id': '1',
                    'status': 'active'
                }
                response2 = await client.request(
                    route.method.value,
                    f"{base_url}{test_url}",
                    params=test_params
                )
                
                # Si la réponse change, certains paramètres sont peut-être utilisés
                if response2.status_code != response1.status_code or response2.text != response1.text:
                    # Analyser la différence pour détecter les paramètres acceptés
                    for param_name in test_params.keys():
                        if not any(p.name == param_name for p in route.query_params):
                            route.query_params.append(RouteParameter(
                                name=param_name,
                                location=ParameterLocation.QUERY,
                                type="string",
                                required=False,
                            ))
                
                # Pour POST/PUT/PATCH, tester avec un body JSON
                if route.method in [HttpMethod.POST, HttpMethod.PUT, HttpMethod.PATCH]:
                    test_body = {
                        'name': 'test',
                        'email': 'test@example.com',
                        'description': 'test description',
                        'value': 123,
                        'active': True
                    }
                    response3 = await client.request(
                        route.method.value,
                        f"{base_url}{test_url}",
                        json=test_body
                    )
                    
                    # Si accepté, analyser le body pour détecter les champs
                    if response3.status_code not in [400, 422]:
                        # Essayer d'extraire le schéma du body de la réponse ou des erreurs
                        if response3.status_code == 422:  # Validation error
                            try:
                                error_data = response3.json()
                                if 'detail' in error_data:
                                    # Analyser les erreurs de validation pour détecter les champs attendus
                                    for detail in error_data['detail']:
                                        if 'loc' in detail:
                                            field_path = detail['loc']
                                            if len(field_path) > 1 and field_path[0] == 'body':
                                                field_name = field_path[-1]
                                                if not any(p.name == field_name for p in route.path_params + route.query_params):
                                                    # C'est probablement un paramètre body
                                                    route.body_schema = route.body_schema or {}
                                                    route.body_schema[field_name] = {
                                                        'type': 'string',
                                                        'description': detail.get('msg', '')
                                                    }
                            except:
                                pass
                
            except Exception as e:
                pass  # Ignorer les erreurs de test
        
        return route
    
    @staticmethod
    def extract_parameters_from_openapi(route: DiscoveredRoute, openapi_spec: Dict[str, Any]) -> DiscoveredRoute:
        """Extrait les paramètres depuis une spécification OpenAPI"""
        # Cette fonction est déjà gérée par OpenAPIParser.parse()
        # Mais on peut l'améliorer ici si nécessaire
        return route


# ============================================================================
# Configuration automatique
# ============================================================================

class AutoConfigService:
    """Service de configuration automatique basé sur le serveur cible"""
    
    async def configure_server(
        self,
        server_id: str,
        discover_routes: bool = True,
        detect_parameters: bool = True,
        create_tests: bool = True
    ) -> Dict[str, Any]:
        """Configure automatiquement tout pour un serveur cible"""
        if server_id not in _discovered_servers:
            raise HTTPException(status_code=404, detail="Server not found")
        
        server = _discovered_servers[server_id]
        config = {
            'server_id': server_id,
            'configured_at': datetime.now().isoformat(),
            'routes_discovered': [],
            'tests_created': [],
            'parameters_detected': 0,
        }
        
        # 1. Rafraîchir les infos du serveur
        server = await server_service.refresh_server(server_id)
        
        # 2. Découvrir les routes
        if discover_routes:
            routes = await route_service.discover_routes(
                server_id,
                use_openapi=True,
                use_graphql=True,
                use_fuzzing=True
            )
            config['routes_discovered'] = [r.id for r in routes]
            
            # 3. Détecter les paramètres de chaque route
            if detect_parameters:
                for route in routes:
                    try:
                        route = await ParameterDetector.detect_route_parameters(server, route)
                        # Mettre à jour la route dans le store
                        route_service.discovered_routes[route.id] = route
                        config['parameters_detected'] += len(route.path_params) + len(route.query_params)
                    except Exception as e:
                        pass
            
            # 4. Créer des tests automatiques pour chaque route
            if create_tests:
                for route in routes[:20]:  # Limiter à 20 routes pour éviter la surcharge
                    try:
                        test = await self._create_auto_test(server, route)
                        if test:
                            config['tests_created'].append(test.id)
                    except Exception as e:
                        pass
        
        # Stocker la configuration
        _auto_configs[server_id] = config
        
        return config
    
    async def _create_auto_test(
        self,
        server: DiscoveredServer,
        route: DiscoveredRoute
    ) -> Optional[FunctionalTest]:
        """Crée un test automatique pour une route"""
        from .api_testing import FunctionalTest, TestRequest, TestAssertion, AssertionTarget, AssertionOperator, AuthConfig, AuthType
        
        # Construire l'URL
        test_path = route.path
        # Remplacer les paramètres de path par des valeurs de test
        test_path = re.sub(r'\{(\w+)\}', '1', test_path)
        test_path = re.sub(r':(\w+)', '1', test_path)
        url = f"{server.base_url}{test_path}"
        
        # Préparer le body si nécessaire
        body = None
        if route.method in [HttpMethod.POST, HttpMethod.PUT, HttpMethod.PATCH]:
            if route.body_schema:
                # Créer un body basé sur le schéma
                body = {}
                for field, schema in route.body_schema.items():
                    field_type = schema.get('type', 'string')
                    if field_type == 'integer':
                        body[field] = 1
                    elif field_type == 'boolean':
                        body[field] = True
                    elif field_type == 'number':
                        body[field] = 1.0
                    else:
                        body[field] = f"test_{field}"
            else:
                # Body par défaut
                body = {'name': 'test', 'value': 'test'}
        
        # Créer la requête de test
        test_request = TestRequest(
            method=route.method.value,
            url=url,
            headers={},
            body=body if body else None,
            body_type=BodyType.JSON if body else BodyType.NONE,
        )
        
        # Créer les assertions de base
        assertions = [
            TestAssertion(
                target=AssertionTarget.STATUS,
                operator=AssertionOperator.LESS_THAN,
                expected=500,  # Pas d'erreur serveur
            )
        ]
        
        # Créer le test
        test = FunctionalTest(
            name=f"Auto Test: {route.method.value} {route.path}",
            description=f"Test automatique généré pour {route.path}",
            request=test_request,
            assertions=assertions,
        )
        
        test_service.create_test(test)
        return test
    
    def get_config(self, server_id: str) -> Dict[str, Any]:
        """Récupère la configuration d'un serveur"""
        if server_id not in _auto_configs:
            raise HTTPException(status_code=404, detail="Configuration not found")
        return _auto_configs[server_id]


# Instance singleton
_service = AutoConfigService()


# ============================================================================
# Endpoints API
# ============================================================================

class ConfigureServerRequest(BaseModel):
    """Requête de configuration automatique"""
    discover_routes: bool = True
    detect_parameters: bool = True
    create_tests: bool = True


@router.post("/servers/{server_id}/configure")
async def configure_server(
    server_id: str,
    request: Optional[ConfigureServerRequest] = None
):
    """
    Configure automatiquement tout pour un serveur cible.
    Découvre les routes, détecte les paramètres, crée des tests.
    """
    server_id = validate_server_id(server_id)
    options = request or ConfigureServerRequest()
    return await _service.configure_server(
        server_id,
        discover_routes=options.discover_routes,
        detect_parameters=options.detect_parameters,
        create_tests=options.create_tests
    )


@router.get("/servers/{server_id}/config")
async def get_server_config(server_id: str):
    """
    Récupère la configuration automatique d'un serveur.
    """
    server_id = validate_server_id(server_id)
    return _service.get_config(server_id)


@router.post("/servers/{server_id}/detect-parameters")
async def detect_route_parameters(server_id: str, route_id: Optional[str] = None):
    """
    Détecte les paramètres d'une route ou de toutes les routes d'un serveur.
    """
    server_id = validate_server_id(server_id)
    if server_id not in _discovered_servers:
        raise HTTPException(status_code=404, detail="Server not found")
    
    server = _discovered_servers[server_id]
    
    if route_id:
        # Détecter pour une route spécifique
        route = route_service.get_route(route_id)
        if route.server_id != server_id:
            raise HTTPException(status_code=404, detail="Route not found for this server")
        route = await ParameterDetector.detect_route_parameters(server, route)
        route_service.discovered_routes[route.id] = route
        return route
    else:
        # Détecter pour toutes les routes
        routes = route_service.get_routes_for_server(server_id)
        updated_routes = []
        for route in routes:
            try:
                route = await ParameterDetector.detect_route_parameters(server, route)
                route_service.discovered_routes[route.id] = route
                updated_routes.append(route)
            except Exception as e:
                pass
        return updated_routes

