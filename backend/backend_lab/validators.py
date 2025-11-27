"""
Validateurs pour les paramètres d'API
"""

import re
from fastapi import HTTPException
from typing import Optional


def validate_server_id(server_id: str) -> str:
    """
    Valide un server_id et rejette les valeurs invalides comme {server_id}
    """
    if not server_id or not isinstance(server_id, str):
        raise HTTPException(status_code=422, detail="Invalid server_id: must be a non-empty string")
    
    # Rejeter les patterns de placeholder
    invalid_patterns = [
        r'\{.*\}',  # {server_id}, {id}, etc.
        r'%7B.*%7D',  # URL encoded { }
        r'%27.*%27',  # URL encoded quotes
        r'<.*>',  # <server_id>
        r'\[.*\]',  # [server_id]
        r'\(.*\)',  # (server_id)
    ]
    
    for pattern in invalid_patterns:
        if re.search(pattern, server_id, re.IGNORECASE):
            raise HTTPException(
                status_code=422,
                detail=f"Invalid server_id: placeholder pattern detected. Use a real server ID."
            )
    
    # Rejeter les tentatives d'injection SQL
    sql_patterns = [
        r"'.*OR.*'",
        r"'.*AND.*'",
        r".*--.*",
        r".*/\*.*\*/",
        r".*;.*",
    ]
    
    for pattern in sql_patterns:
        if re.search(pattern, server_id, re.IGNORECASE):
            raise HTTPException(
                status_code=422,
                detail="Invalid server_id: potential SQL injection attempt detected"
            )
    
    # Rejeter les tentatives XSS
    xss_patterns = [
        r'<script.*>',
        r'<img.*onerror',
        r'<svg.*onload',
    ]
    
    for pattern in xss_patterns:
        if re.search(pattern, server_id, re.IGNORECASE):
            raise HTTPException(
                status_code=422,
                detail="Invalid server_id: potential XSS attempt detected"
            )
    
    # UUID format validation (optionnel mais recommandé)
    uuid_pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    if not re.match(uuid_pattern, server_id, re.IGNORECASE):
        # Accepter aussi les IDs courts si nécessaire
        if len(server_id) < 8:
            raise HTTPException(
                status_code=422,
                detail="Invalid server_id: ID too short"
            )
    
    return server_id


def validate_route_id(route_id: str) -> str:
    """Valide un route_id"""
    return validate_server_id(route_id)  # Même validation


def validate_test_id(test_id: str) -> str:
    """Valide un test_id"""
    return validate_server_id(test_id)  # Même validation

