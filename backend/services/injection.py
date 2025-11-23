"""
Service d'injection pour Notilus Browser
Injection de scripts, CSS, et modifications de page
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter()


class InjectionRequest(BaseModel):
    url: str
    script: Optional[str] = None
    css: Optional[str] = None
    type: str  # "script", "css", "both"


class InjectionResult(BaseModel):
    success: bool
    message: str
    injected_at: Optional[str] = None


@router.post("/inject")
async def inject_content(request: InjectionRequest):
    """Injecter du contenu (script/CSS) dans une page"""
    # TODO: Implémenter l'injection réelle
    return {
        "status": "ok",
        "result": {
            "success": True,
            "message": "Content injected",
            "injected_at": None
        }
    }


@router.get("/injections")
async def get_injections():
    """Récupérer la liste des injections actives"""
    # TODO: Implémenter la récupération des injections
    return {
        "status": "ok",
        "injections": []
    }


@router.delete("/injections/{injection_id}")
async def remove_injection(injection_id: str):
    """Supprimer une injection"""
    # TODO: Implémenter la suppression
    return {
        "status": "ok",
        "message": "Injection removed"
    }

