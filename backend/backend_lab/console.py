"""
Module Console - Affichage en temps réel des logs FastAPI/uvicorn
Capture et expose les logs du serveur avec coloration
"""

import logging
import re
import sys
from datetime import datetime
from typing import List, Dict, Optional, Any
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
from pydantic import BaseModel
import json
import asyncio

router = APIRouter()

# Store des logs
_logs: List[Dict[str, Any]] = []
_max_logs = 1000

# Connexions WebSocket actives
_active_connections: List[WebSocket] = []

# Queue pour les logs à envoyer
_log_queue: Optional[asyncio.Queue] = None


class LogEntry(BaseModel):
    """Entrée de log"""
    timestamp: str
    level: str
    message: str
    color: str
    raw: str


class ConsoleHandler(logging.Handler):
    """Handler personnalisé pour capturer les logs"""
    
    def emit(self, record):
        try:
            log_entry = self._format_log(record)
            _logs.append(log_entry)
            
            # Garder seulement les N derniers logs
            if len(_logs) > _max_logs:
                _logs.pop(0)
            
            # Envoyer aux clients WebSocket connectés
            self._broadcast_to_websockets(log_entry)
        except Exception:
            pass
    
    def _format_log(self, record: logging.LogRecord) -> Dict[str, Any]:
        """Formate un log avec coloration"""
        level = record.levelname
        message = self.format(record)
        raw = message
        
        # Déterminer la couleur selon le type de log
        color = self._get_color_for_log(message, level)
        
        return {
            "timestamp": datetime.now().isoformat(),
            "level": level,
            "message": message,
            "color": color,
            "raw": raw,
        }
    
    def _get_color_for_log(self, message: str, level: str) -> str:
        """Détermine la couleur selon le type de log (style FastAPI/uvicorn)"""
        message_lower = message.lower()
        
        # Erreurs
        if level == "ERROR" or "error" in message_lower or "exception" in message_lower:
            return "#EF4444"  # Rouge
        
        # Warnings
        if level == "WARNING" or "warning" in message_lower or "warn" in message_lower:
            return "#F59E0B"  # Orange
        
        # Requêtes HTTP (style FastAPI)
        if "GET" in message or "POST" in message or "PUT" in message or "DELETE" in message or "PATCH" in message:
            if "200" in message or "201" in message or "204" in message:
                return "#22C55E"  # Vert (succès)
            elif "404" in message or "500" in message or "4" in message or "5" in message:
                return "#EF4444"  # Rouge (erreur)
            elif "3" in message:
                return "#3B82F6"  # Bleu (redirection)
            else:
                return "#6366F1"  # Violet (requête)
        
        # Info
        if level == "INFO" or "info" in message_lower:
            return "#3B82F6"  # Bleu
        
        # Debug
        if level == "DEBUG" or "debug" in message_lower:
            return "#9CA3AF"  # Gris
        
        # Uvicorn startup
        if "uvicorn" in message_lower or "started" in message_lower or "application startup" in message_lower:
            return "#22C55E"  # Vert
        
        # Uvicorn shutdown
        if "shutdown" in message_lower or "stopping" in message_lower:
            return "#F59E0B"  # Orange
        
        # Par défaut
        return "#FFFFFF"  # Blanc
    
    def _broadcast_to_websockets(self, log_entry: Dict[str, Any]):
        """Envoie le log à tous les clients WebSocket connectés"""
        _broadcast_log(log_entry)


# Créer et configurer le handler
_console_handler = ConsoleHandler()
_console_handler.setFormatter(logging.Formatter('%(message)s'))

# Fonction pour initialiser les handlers (appelée après la configuration de logging)
def initialize_console_handlers():
    """Initialise les handlers de console pour capturer tous les logs"""
    # Ajouter le handler au logger uvicorn
    uvicorn_logger = logging.getLogger("uvicorn")
    if _console_handler not in uvicorn_logger.handlers:
        uvicorn_logger.addHandler(_console_handler)
    uvicorn_logger.setLevel(logging.INFO)
    uvicorn_logger.propagate = False

    # Ajouter aussi au logger FastAPI
    fastapi_logger = logging.getLogger("fastapi")
    if _console_handler not in fastapi_logger.handlers:
        fastapi_logger.addHandler(_console_handler)
    fastapi_logger.setLevel(logging.INFO)
    fastapi_logger.propagate = False

    # Ajouter au logger uvicorn.access pour les requêtes HTTP (le plus important)
    uvicorn_access_logger = logging.getLogger("uvicorn.access")
    if _console_handler not in uvicorn_access_logger.handlers:
        uvicorn_access_logger.addHandler(_console_handler)
    uvicorn_access_logger.setLevel(logging.INFO)
    uvicorn_access_logger.propagate = False

    # Ajouter au logger uvicorn.error pour les erreurs
    uvicorn_error_logger = logging.getLogger("uvicorn.error")
    if _console_handler not in uvicorn_error_logger.handlers:
        uvicorn_error_logger.addHandler(_console_handler)
    uvicorn_error_logger.setLevel(logging.INFO)
    uvicorn_error_logger.propagate = False

# Initialiser immédiatement
initialize_console_handlers()

# Démarrer le worker de logs
_log_worker_task = None


async def _log_worker():
    """Worker asynchrone pour envoyer les logs aux WebSocket"""
    global _log_queue
    if _log_queue is None:
        _log_queue = asyncio.Queue()
    
    while True:
        try:
            log_entry = await _log_queue.get()
            
            # Envoyer à tous les clients connectés
            disconnected = []
            for connection in _active_connections:
                try:
                    await connection.send_json(log_entry)
                except Exception:
                    disconnected.append(connection)
            
            # Nettoyer les connexions fermées
            for conn in disconnected:
                if conn in _active_connections:
                    _active_connections.remove(conn)
            
            _log_queue.task_done()
        except Exception:
            pass


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """Endpoint WebSocket pour recevoir les logs en temps réel"""
    global _log_queue, _log_worker_task
    
    # Accepter la connexion avec les headers CORS appropriés
    await websocket.accept()
    _active_connections.append(websocket)
    
    # Démarrer le worker si nécessaire
    if _log_queue is None:
        _log_queue = asyncio.Queue()
        _log_worker_task = asyncio.create_task(_log_worker())
    
    try:
        # Envoyer les logs historiques
        for log in _logs[-100:]:  # Derniers 100 logs
            await websocket.send_json(log)
        
        # Attendre les messages (keep-alive)
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        _active_connections.remove(websocket)
    except Exception:
        if websocket in _active_connections:
            _active_connections.remove(websocket)


@router.get("/logs", response_model=List[Dict[str, Any]])
async def get_logs(limit: int = 100):
    """
    Récupère les logs récents (pour polling si WebSocket n'est pas disponible)
    """
    return _logs[-limit:]


@router.delete("/logs")
async def clear_logs():
    """Efface tous les logs"""
    _logs.clear()
    return {"message": "Logs cleared"}


@router.get("/status")
async def get_console_status():
    """Retourne le statut de la console"""
    return {
        "total_logs": len(_logs),
        "active_connections": len(_active_connections),
        "max_logs": _max_logs,
    }


# ============================================================================
# Middleware pour capturer les requêtes HTTP
# ============================================================================

class ConsoleMiddleware(BaseHTTPMiddleware):
    """Middleware pour capturer et logger toutes les requêtes HTTP"""
    
    async def dispatch(self, request: Request, call_next):
        start_time = datetime.now()
        
        # Exécuter la requête
        response = await call_next(request)
        
        # Calculer le temps de réponse
        process_time = (datetime.now() - start_time).total_seconds() * 1000
        
        # Formater le log comme uvicorn
        client_host = request.client.host if request.client else "unknown"
        method = request.method
        path = request.url.path
        status_code = response.status_code
        
        # Créer le message de log au format uvicorn
        log_message = f'{client_host} - "{method} {path} HTTP/1.1" {status_code}'
        
        # Créer l'entrée de log
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "level": "INFO",
            "message": log_message,
            "color": _get_color_for_status(status_code),
            "raw": log_message,
        }
        
        # Ajouter au store
        _logs.append(log_entry)
        if len(_logs) > _max_logs:
            _logs.pop(0)
        
        # Envoyer aux WebSocket
        _broadcast_log(log_entry)
        
        return response


def _get_color_for_status(status_code: int) -> str:
    """Détermine la couleur selon le code de statut HTTP"""
    if 200 <= status_code < 300:
        return "#22C55E"  # Vert (succès)
    elif 300 <= status_code < 400:
        return "#3B82F6"  # Bleu (redirection)
    elif 400 <= status_code < 500:
        return "#F59E0B"  # Orange (erreur client)
    elif status_code >= 500:
        return "#EF4444"  # Rouge (erreur serveur)
    return "#FFFFFF"  # Blanc par défaut


def _broadcast_log(log_entry: Dict[str, Any]):
    """Envoie le log à tous les clients WebSocket connectés"""
    if not _active_connections:
        return
    
    # Ajouter à la queue si elle existe
    if _log_queue is not None:
        try:
            _log_queue.put_nowait(log_entry)
        except Exception:
            pass

