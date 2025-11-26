"""
Module Injection & Interception - Proxy MITM, capture et replay
Permet d'intercepter, modifier et rejouer les requêtes HTTP
"""

import asyncio
import uuid
import json
import re
import time
from datetime import datetime
from typing import List, Dict, Optional, Any
from fastapi import APIRouter, HTTPException, WebSocket
from pydantic import BaseModel
import httpx

from .models.capture import (
    CapturedRequest,
    InterceptRule,
    InterceptAction,
    InterceptMatch,
    InterceptMatchType,
    Modification,
    ModificationTarget,
    ModificationOperation,
    ProxyStatus,
    WebSocketConnection,
)

router = APIRouter()

# Stores globaux
_captured_requests: Dict[str, CapturedRequest] = {}
_intercept_rules: Dict[str, InterceptRule] = {}
_proxy_status = ProxyStatus()
_websocket_connections: Dict[str, WebSocketConnection] = {}

# WebSocket pour le streaming temps réel
_live_clients: List[WebSocket] = []


# ============================================================================
# Capture Engine
# ============================================================================

class CaptureEngine:
    """Moteur de capture des requêtes"""
    
    @staticmethod
    def capture_request(
        method: str,
        url: str,
        headers: Dict[str, str],
        body: Optional[bytes] = None,
        response_status: Optional[int] = None,
        response_headers: Optional[Dict[str, str]] = None,
        response_body: Optional[bytes] = None,
        duration_ms: float = 0.0,
    ) -> CapturedRequest:
        """Capture une requête HTTP"""
        from urllib.parse import urlparse, parse_qs
        
        parsed = urlparse(url)
        
        capture = CapturedRequest(
            id=str(uuid.uuid4()),
            timestamp=datetime.now(),
            method=method,
            url=url,
            full_url=url,
            host=parsed.netloc,
            path=parsed.path,
            query_string=parsed.query,
            query_params=dict(parse_qs(parsed.query)),
            request_headers=headers,
            request_content_type=headers.get('content-type', headers.get('Content-Type')),
            is_https=parsed.scheme == 'https',
        )
        
        # Body de la requête
        if body:
            capture.request_body = body
            capture.request_size = len(body)
            try:
                capture.request_body_text = body.decode('utf-8')
                try:
                    capture.request_body_json = json.loads(capture.request_body_text)
                except:
                    pass
            except:
                pass
        
        # Réponse
        if response_status is not None:
            capture.status_code = response_status
            capture.response_headers = response_headers or {}
            capture.response_content_type = response_headers.get('content-type') if response_headers else None
            
            if response_body:
                capture.response_body = response_body
                capture.response_size = len(response_body)
                try:
                    capture.response_body_text = response_body.decode('utf-8')
                    try:
                        capture.response_body_json = json.loads(capture.response_body_text)
                    except:
                        pass
                except:
                    pass
        
        capture.duration_ms = duration_ms
        
        # Stocker
        _captured_requests[capture.id] = capture
        
        # Notifier les clients WebSocket
        asyncio.create_task(CaptureEngine._notify_capture(capture))
        
        return capture
    
    @staticmethod
    async def _notify_capture(capture: CapturedRequest):
        """Notifie les clients WebSocket d'une nouvelle capture"""
        message = json.dumps({
            "type": "request_captured",
            "data": {
                "id": capture.id,
                "method": capture.method,
                "url": capture.url,
                "status_code": capture.status_code,
                "duration_ms": capture.duration_ms,
                "timestamp": capture.timestamp.isoformat(),
            }
        })
        
        for client in _live_clients:
            try:
                await client.send_text(message)
            except:
                pass


# ============================================================================
# Rule Engine
# ============================================================================

class RuleEngine:
    """Moteur d'évaluation des règles d'interception"""
    
    @staticmethod
    def match_rule(rule: InterceptRule, request: Dict[str, Any]) -> bool:
        """Vérifie si une règle matche une requête"""
        if not rule.enabled:
            return False
        
        # Vérification rapide
        if rule.url_pattern:
            url = request.get('url', '')
            if not re.search(rule.url_pattern, url):
                return False
        
        if rule.methods and request.get('method') not in rule.methods:
            return False
        
        # Vérification des matches détaillés
        match_results = []
        
        for match in rule.matches:
            result = RuleEngine._evaluate_match(match, request)
            if match.negate:
                result = not result
            match_results.append(result)
        
        if not match_results:
            return True
        
        if rule.match_all:
            return all(match_results)
        else:
            return any(match_results)
    
    @staticmethod
    def _evaluate_match(match: InterceptMatch, request: Dict[str, Any]) -> bool:
        """Évalue un critère de matching"""
        # Extraire la valeur
        value = RuleEngine._get_field_value(match.field, request)
        if value is None:
            return False
        
        value = str(value)
        target = match.value
        
        if not match.case_sensitive:
            value = value.lower()
            target = target.lower()
        
        if match.match_type == InterceptMatchType.EQUALS:
            return value == target
        elif match.match_type == InterceptMatchType.CONTAINS:
            return target in value
        elif match.match_type == InterceptMatchType.STARTS_WITH:
            return value.startswith(target)
        elif match.match_type == InterceptMatchType.ENDS_WITH:
            return value.endswith(target)
        elif match.match_type == InterceptMatchType.REGEX:
            return bool(re.search(target, value))
        elif match.match_type == InterceptMatchType.GLOB:
            import fnmatch
            return fnmatch.fnmatch(value, target)
        
        return False
    
    @staticmethod
    def _get_field_value(field: str, request: Dict[str, Any]) -> Optional[Any]:
        """Récupère la valeur d'un champ de la requête"""
        if field == 'url':
            return request.get('url')
        elif field == 'method':
            return request.get('method')
        elif field.startswith('header.'):
            header_name = field[7:]
            return request.get('headers', {}).get(header_name)
        elif field.startswith('query.'):
            param_name = field[6:]
            return request.get('query_params', {}).get(param_name)
        elif field.startswith('body.'):
            path = field[5:]
            return RuleEngine._get_nested(request.get('body_json', {}), path.split('.'))
        
        return None
    
    @staticmethod
    def _get_nested(data: Dict, keys: List[str]) -> Optional[Any]:
        """Récupère une valeur imbriquée"""
        current = data
        for key in keys:
            if isinstance(current, dict) and key in current:
                current = current[key]
            else:
                return None
        return current
    
    @staticmethod
    def apply_modifications(
        modifications: List[Modification],
        target_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Applique les modifications à des données"""
        result = target_data.copy()
        
        for mod in modifications:
            if mod.target == ModificationTarget.HEADER:
                if 'headers' not in result:
                    result['headers'] = {}
                
                if mod.operation == ModificationOperation.SET:
                    result['headers'][mod.target_key] = mod.value
                elif mod.operation == ModificationOperation.DELETE:
                    result['headers'].pop(mod.target_key, None)
                elif mod.operation == ModificationOperation.APPEND:
                    current = result['headers'].get(mod.target_key, '')
                    result['headers'][mod.target_key] = current + str(mod.value)
            
            elif mod.target == ModificationTarget.BODY_JSON:
                if 'body_json' not in result:
                    result['body_json'] = {}
                
                keys = mod.target_key.split('.') if mod.target_key else []
                RuleEngine._set_nested(result['body_json'], keys, mod.value, mod.operation)
            
            elif mod.target == ModificationTarget.URL:
                if mod.operation == ModificationOperation.SET:
                    result['url'] = mod.value
                elif mod.operation == ModificationOperation.REPLACE:
                    result['url'] = re.sub(mod.regex_pattern, mod.regex_replacement, result.get('url', ''))
        
        return result
    
    @staticmethod
    def _set_nested(data: Dict, keys: List[str], value: Any, operation: ModificationOperation):
        """Définit une valeur imbriquée"""
        if not keys:
            return
        
        current = data
        for key in keys[:-1]:
            if key not in current:
                current[key] = {}
            current = current[key]
        
        if operation == ModificationOperation.SET:
            current[keys[-1]] = value
        elif operation == ModificationOperation.DELETE:
            current.pop(keys[-1], None)
        elif operation == ModificationOperation.APPEND:
            if keys[-1] in current:
                if isinstance(current[keys[-1]], list):
                    current[keys[-1]].append(value)
                else:
                    current[keys[-1]] = str(current[keys[-1]]) + str(value)
            else:
                current[keys[-1]] = value


# ============================================================================
# Replay Engine
# ============================================================================

class ReplayEngine:
    """Moteur de replay des requêtes"""
    
    @staticmethod
    async def replay(
        capture_id: str,
        modifications: Optional[List[Modification]] = None
    ) -> CapturedRequest:
        """Rejoue une requête capturée"""
        if capture_id not in _captured_requests:
            raise HTTPException(status_code=404, detail="Capture not found")
        
        original = _captured_requests[capture_id]
        
        # Préparer les données
        request_data = {
            'method': original.method,
            'url': original.url,
            'headers': original.request_headers.copy(),
            'body_json': original.request_body_json,
        }
        
        # Appliquer les modifications
        if modifications:
            request_data = RuleEngine.apply_modifications(modifications, request_data)
        
        # Exécuter la requête
        start_time = time.time()
        
        async with httpx.AsyncClient(timeout=30.0, verify=False) as client:
            body = None
            if request_data.get('body_json'):
                body = json.dumps(request_data['body_json'])
            elif original.request_body:
                body = original.request_body
            
            response = await client.request(
                method=request_data['method'],
                url=request_data['url'],
                headers=request_data['headers'],
                content=body
            )
        
        duration_ms = (time.time() - start_time) * 1000
        
        # Créer la nouvelle capture
        new_capture = CaptureEngine.capture_request(
            method=request_data['method'],
            url=request_data['url'],
            headers=request_data['headers'],
            body=body.encode() if body else None,
            response_status=response.status_code,
            response_headers=dict(response.headers),
            response_body=response.content,
            duration_ms=duration_ms,
        )
        
        new_capture.parent_capture_id = capture_id
        original.replay_count += 1
        
        return new_capture
    
    @staticmethod
    async def replay_with_variations(
        capture_id: str,
        variations: List[Dict[str, Any]]
    ) -> List[CapturedRequest]:
        """Rejoue une requête avec plusieurs variations"""
        results = []
        
        for variation in variations:
            modifications = [
                Modification(**mod) for mod in variation.get('modifications', [])
            ]
            result = await ReplayEngine.replay(capture_id, modifications)
            results.append(result)
        
        return results


# ============================================================================
# Service Principal
# ============================================================================

class InterceptionService:
    """Service d'interception principal"""
    
    def __init__(self):
        self.captures = _captured_requests
        self.rules = _intercept_rules
        self.status = _proxy_status
    
    def add_rule(self, rule: InterceptRule) -> InterceptRule:
        """Ajoute une règle d'interception"""
        self.rules[rule.id] = rule
        self.status.active_rules = len([r for r in self.rules.values() if r.enabled])
        return rule
    
    def get_rules(self) -> List[InterceptRule]:
        """Récupère toutes les règles"""
        return sorted(self.rules.values(), key=lambda r: -r.priority)
    
    def delete_rule(self, rule_id: str):
        """Supprime une règle"""
        if rule_id in self.rules:
            del self.rules[rule_id]
            self.status.active_rules = len([r for r in self.rules.values() if r.enabled])
    
    def get_captures(self, limit: int = 100, method: str = None, status_code: int = None) -> List[CapturedRequest]:
        """Récupère les captures avec filtres optionnels"""
        captures = list(self.captures.values())
        
        if method:
            captures = [c for c in captures if c.method == method]
        
        if status_code:
            captures = [c for c in captures if c.status_code == status_code]
        
        captures.sort(key=lambda c: c.timestamp, reverse=True)
        return captures[:limit]
    
    def clear_captures(self):
        """Vide les captures"""
        self.captures.clear()
        self.status.requests_captured = 0


# Instance singleton
_service = InterceptionService()


# ============================================================================
# Endpoints API
# ============================================================================

class CreateRuleRequest(BaseModel):
    """Requête de création de règle"""
    name: str
    description: Optional[str] = None
    enabled: bool = True
    url_pattern: Optional[str] = None
    methods: List[str] = []
    action: InterceptAction = InterceptAction.CAPTURE
    matches: List[Dict[str, Any]] = []
    request_modifications: List[Dict[str, Any]] = []
    response_modifications: List[Dict[str, Any]] = []
    delay_ms: int = 0


class ReplayRequest(BaseModel):
    """Requête de replay"""
    modifications: List[Dict[str, Any]] = []


class ReplayVariationsRequest(BaseModel):
    """Requête de replay avec variations"""
    variations: List[Dict[str, Any]]


@router.get("/captures", response_model=List[CapturedRequest])
async def list_captures(limit: int = 100, method: str = None, status_code: int = None):
    """
    Liste les requêtes capturées avec filtres optionnels.
    """
    return _service.get_captures(limit, method, status_code)


@router.get("/captures/{capture_id}", response_model=CapturedRequest)
async def get_capture(capture_id: str):
    """
    Récupère les détails d'une capture.
    """
    if capture_id not in _captured_requests:
        raise HTTPException(status_code=404, detail="Capture not found")
    return _captured_requests[capture_id]


@router.post("/captures/{capture_id}/replay", response_model=CapturedRequest)
async def replay_capture(capture_id: str, request: Optional[ReplayRequest] = None):
    """
    Rejoue une requête capturée avec modifications optionnelles.
    """
    modifications = None
    if request and request.modifications:
        modifications = [Modification(**mod) for mod in request.modifications]
    
    return await ReplayEngine.replay(capture_id, modifications)


@router.post("/captures/{capture_id}/variations", response_model=List[CapturedRequest])
async def replay_variations(capture_id: str, request: ReplayVariationsRequest):
    """
    Rejoue une requête avec plusieurs variations (fuzzing).
    """
    return await ReplayEngine.replay_with_variations(capture_id, request.variations)


@router.delete("/captures")
async def clear_captures():
    """
    Vide toutes les captures.
    """
    _service.clear_captures()
    return {"status": "ok", "message": "Captures cleared"}


@router.post("/rules", response_model=InterceptRule)
async def create_rule(request: CreateRuleRequest):
    """
    Crée une nouvelle règle d'interception.
    """
    rule = InterceptRule(
        name=request.name,
        description=request.description,
        enabled=request.enabled,
        url_pattern=request.url_pattern,
        methods=request.methods,
        action=request.action,
        delay_ms=request.delay_ms,
    )
    
    # Parser les matches
    for match_data in request.matches:
        rule.matches.append(InterceptMatch(**match_data))
    
    # Parser les modifications
    for mod_data in request.request_modifications:
        rule.request_modifications.append(Modification(**mod_data))
    
    for mod_data in request.response_modifications:
        rule.response_modifications.append(Modification(**mod_data))
    
    return _service.add_rule(rule)


@router.get("/rules", response_model=List[InterceptRule])
async def list_rules():
    """
    Liste toutes les règles d'interception.
    """
    return _service.get_rules()


@router.put("/rules/{rule_id}", response_model=InterceptRule)
async def update_rule(rule_id: str, request: CreateRuleRequest):
    """
    Met à jour une règle existante.
    """
    if rule_id not in _intercept_rules:
        raise HTTPException(status_code=404, detail="Rule not found")
    
    rule = _intercept_rules[rule_id]
    rule.name = request.name
    rule.description = request.description
    rule.enabled = request.enabled
    rule.url_pattern = request.url_pattern
    rule.methods = request.methods
    rule.action = request.action
    rule.delay_ms = request.delay_ms
    rule.updated_at = datetime.now()
    
    return rule


@router.delete("/rules/{rule_id}")
async def delete_rule(rule_id: str):
    """
    Supprime une règle.
    """
    _service.delete_rule(rule_id)
    return {"status": "ok", "message": "Rule deleted"}


@router.get("/status", response_model=ProxyStatus)
async def get_status():
    """
    Récupère le statut du proxy d'interception.
    """
    _proxy_status.requests_captured = len(_captured_requests)
    return _proxy_status


@router.websocket("/live")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket pour le streaming temps réel des captures.
    """
    await websocket.accept()
    _live_clients.append(websocket)
    
    try:
        while True:
            # Garder la connexion ouverte
            await websocket.receive_text()
    except:
        pass
    finally:
        _live_clients.remove(websocket)
