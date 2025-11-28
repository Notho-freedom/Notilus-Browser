"""
Service IA pour Notilus Browser
Intelligence artificielle avec Groq et auto-switch de modèles
"""

import os
import logging
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field
import httpx

logger = logging.getLogger(__name__)

router = APIRouter()

# Liste des modèles Groq avec priorité (du plus performant au moins performant)
GROQ_MODELS = [
    "llama-3.1-70b-versatile",  # Modèle principal - très performant
    "llama-3.1-8b-instant",     # Fallback rapide
    "mixtral-8x7b-32768",      # Alternative puissante
    "gemma-7b-it",             # Fallback léger
]

# Modèle actuel utilisé
_current_model_index = 0


# ============================================================================
# Modèles Pydantic
# ============================================================================

class AIRequest(BaseModel):
    """Requête pour le service IA"""
    prompt: str = Field(..., min_length=1, description="Prompt utilisateur")
    context: Optional[Dict[str, Any]] = Field(default=None, description="Contexte additionnel")
    type: str = Field(default="general", description="Type de requête: general, code, analysis, suggestion")
    model: Optional[str] = Field(default=None, description="Modèle spécifique (optionnel, auto-sélection par défaut)")


class AIResponse(BaseModel):
    """Réponse du service IA"""
    response: str
    confidence: float
    suggestions: Optional[List[str]] = None
    model_used: str
    tokens_used: Optional[int] = None


class CodeAnalysisRequest(BaseModel):
    """Requête pour l'analyse de code"""
    code: str = Field(..., min_length=1, description="Code à analyser")
    language: Optional[str] = Field(default=None, description="Langage de programmation")


class CodeAnalysisResponse(BaseModel):
    """Réponse pour l'analyse de code"""
    issues: List[Dict[str, Any]]
    suggestions: List[str]
    complexity: int
    model_used: str


class SuggestionRequest(BaseModel):
    """Requête pour obtenir des suggestions"""
    context: Dict[str, Any] = Field(..., description="Contexte pour les suggestions")


# ============================================================================
# Fonctions utilitaires
# ============================================================================

def get_api_key(request: Request) -> Optional[str]:
    """
    Récupère la clé API depuis les headers ou les variables d'environnement.
    
    Args:
        request: Requête FastAPI
        
    Returns:
        Clé API ou None
    """
    # Vérifier dans les headers
    api_key = request.headers.get("X-Groq-API-Key")
    if api_key:
        return api_key
    
    # Vérifier dans les variables d'environnement
    api_key = os.getenv("GROQ_API_KEY")
    if api_key:
        return api_key
    
    return None


async def call_groq_api(
    api_key: str,
    prompt: str,
    model: Optional[str] = None,
    system_prompt: Optional[str] = None,
    temperature: float = 0.7,
    max_tokens: int = 2048,
) -> Dict[str, Any]:
    """
    Appelle l'API Groq avec retry et fallback automatique.
    
    Args:
        api_key: Clé API Groq
        prompt: Prompt utilisateur
        model: Modèle spécifique (optionnel)
        system_prompt: Prompt système (optionnel)
        temperature: Température pour la génération
        max_tokens: Nombre maximum de tokens
        
    Returns:
        Réponse de l'API Groq
        
    Raises:
        HTTPException: En cas d'erreur
    """
    global _current_model_index
    
    # Sélectionner le modèle
    if model:
        selected_model = model
    else:
        selected_model = GROQ_MODELS[_current_model_index]
    
    # Essayer avec le modèle actuel et les fallbacks
    last_error = None
    for attempt in range(len(GROQ_MODELS)):
        try:
            model_to_try = GROQ_MODELS[(_current_model_index + attempt) % len(GROQ_MODELS)]
            
            logger.info(f"Tentative {attempt + 1}: Utilisation du modèle {model_to_try}")
            
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})
            
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    "https://api.groq.com/openai/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": model_to_try,
                        "messages": messages,
                        "temperature": temperature,
                        "max_tokens": max_tokens,
                    },
                )
                
                if response.status_code == 200:
                    data = response.json()
                    # Mettre à jour l'index du modèle actuel si succès
                    _current_model_index = (_current_model_index + attempt) % len(GROQ_MODELS)
                    logger.info(f"Succès avec le modèle {model_to_try}")
                    return {
                        "model": model_to_try,
                        "data": data,
                    }
                elif response.status_code == 429:
                    # Rate limit - essayer le modèle suivant
                    logger.warning(f"Rate limit sur {model_to_try}, passage au modèle suivant")
                    last_error = f"Rate limit sur {model_to_try}"
                    continue
                else:
                    error_data = response.json() if response.content else {}
                    error_msg = error_data.get("error", {}).get("message", "Erreur inconnue")
                    logger.error(f"Erreur API Groq ({response.status_code}): {error_msg}")
                    last_error = error_msg
                    
                    # Si c'est une erreur de quota, essayer le modèle suivant
                    if response.status_code == 402 or "quota" in error_msg.lower():
                        logger.warning(f"Quota dépassé sur {model_to_try}, passage au modèle suivant")
                        continue
                    else:
                        # Autre erreur - ne pas retry
                        raise HTTPException(
                            status_code=response.status_code,
                            detail=f"Erreur API Groq: {error_msg}"
                        )
        
        except httpx.TimeoutException:
            logger.warning(f"Timeout sur {model_to_try}, passage au modèle suivant")
            last_error = "Timeout"
            continue
        except httpx.RequestError as e:
            logger.error(f"Erreur de requête sur {model_to_try}: {e}")
            last_error = str(e)
            continue
    
    # Tous les modèles ont échoué
    raise HTTPException(
        status_code=503,
        detail=f"Tous les modèles ont échoué. Dernière erreur: {last_error}"
    )


def get_system_prompt(request_type: str) -> str:
    """Retourne le prompt système selon le type de requête."""
    prompts = {
        "general": "Tu es un assistant IA utile et concis. Réponds de manière claire et précise.",
        "code": """Tu es un expert en programmation. Analyse le code fourni et fournis:
- Les problèmes potentiels
- Les suggestions d'amélioration
- Une estimation de la complexité
Réponds en français.""",
        "analysis": "Tu es un analyste expert. Analyse les données fournies et fournis des insights pertinents.",
        "suggestion": "Tu es un assistant créatif. Fournis des suggestions pertinentes basées sur le contexte.",
    }
    return prompts.get(request_type, prompts["general"])


# ============================================================================
# Endpoints
# ============================================================================

@router.post("/chat", response_model=AIResponse)
async def chat(request: AIRequest, http_request: Request):
    """
    Chat avec l'IA via Groq.
    
    Utilise l'auto-switch de modèles en cas de limite de quota.
    """
    api_key = get_api_key(http_request)
    if not api_key:
        raise HTTPException(
            status_code=401,
            detail="Clé API Groq requise. Fournissez-la via le header 'X-Groq-API-Key' ou la variable d'environnement GROQ_API_KEY"
        )
    
    try:
        system_prompt = get_system_prompt(request.type)
        
        result = await call_groq_api(
            api_key=api_key,
            prompt=request.prompt,
            model=request.model,
            system_prompt=system_prompt,
            temperature=0.7,
            max_tokens=2048,
        )
        
        data = result["data"]
        model_used = result["model"]
        
        # Extraire la réponse
        choices = data.get("choices", [])
        if not choices:
            raise HTTPException(status_code=500, detail="Aucune réponse de l'IA")
        
        response_text = choices[0].get("message", {}).get("content", "")
        usage = data.get("usage", {})
        tokens_used = usage.get("total_tokens")
        
        return AIResponse(
            response=response_text,
            confidence=0.9,  # Groq est généralement fiable
            suggestions=None,
            model_used=model_used,
            tokens_used=tokens_used,
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors du chat IA: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la génération de la réponse: {str(e)}"
        )


@router.post("/analyze-code", response_model=CodeAnalysisResponse)
async def analyze_code(request: CodeAnalysisRequest, http_request: Request):
    """
    Analyse du code avec l'IA.
    
    Détecte les problèmes, suggère des améliorations et estime la complexité.
    """
    api_key = get_api_key(http_request)
    if not api_key:
        raise HTTPException(
            status_code=401,
            detail="Clé API Groq requise"
        )
    
    try:
        language_hint = f"Langage: {request.language}\n\n" if request.language else ""
        prompt = f"""{language_hint}Analyse ce code et fournis:
1. Les problèmes potentiels (bugs, erreurs, mauvaises pratiques)
2. Les suggestions d'amélioration
3. Une estimation de la complexité (1-10)

Code à analyser:
```{request.code}```

Réponds au format JSON avec les clés: issues, suggestions, complexity."""

        system_prompt = get_system_prompt("code")
        
        result = await call_groq_api(
            api_key=api_key,
            prompt=prompt,
            system_prompt=system_prompt,
            temperature=0.3,  # Plus déterministe pour l'analyse
            max_tokens=2048,
        )
        
        data = result["data"]
        model_used = result["model"]
        
        choices = data.get("choices", [])
        if not choices:
            raise HTTPException(status_code=500, detail="Aucune réponse de l'IA")
        
        response_text = choices[0].get("message", {}).get("content", "")
        
        # Parser la réponse (peut être JSON ou texte)
        try:
            import json
            # Essayer d'extraire du JSON si présent
            if "{" in response_text:
                json_start = response_text.find("{")
                json_end = response_text.rfind("}") + 1
                if json_start >= 0 and json_end > json_start:
                    parsed = json.loads(response_text[json_start:json_end])
                    return CodeAnalysisResponse(
                        issues=parsed.get("issues", []),
                        suggestions=parsed.get("suggestions", []),
                        complexity=parsed.get("complexity", 5),
                        model_used=model_used,
                    )
        except:
            pass
        
        # Fallback: parser simple depuis le texte
        issues = []
        suggestions = []
        complexity = 5
        
        lines = response_text.split("\n")
        for line in lines:
            if "problème" in line.lower() or "bug" in line.lower() or "erreur" in line.lower():
                issues.append({"type": "warning", "message": line.strip()})
            elif "suggestion" in line.lower() or "amélioration" in line.lower():
                suggestions.append(line.strip())
            elif "complexité" in line.lower() or "complexity" in line.lower():
                try:
                    import re
                    numbers = re.findall(r'\d+', line)
                    if numbers:
                        complexity = int(numbers[0])
                except:
                    pass
        
        return CodeAnalysisResponse(
            issues=issues if issues else [{"type": "info", "message": "Aucun problème détecté"}],
            suggestions=suggestions if suggestions else ["Code bien structuré"],
            complexity=complexity,
            model_used=model_used,
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de l'analyse de code: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de l'analyse: {str(e)}"
        )


@router.post("/suggest")
async def get_suggestions(request: SuggestionRequest, http_request: Request):
    """
    Obtenir des suggestions basées sur le contexte.
    """
    api_key = get_api_key(http_request)
    if not api_key:
        raise HTTPException(
            status_code=401,
            detail="Clé API Groq requise"
        )
    
    try:
        context_str = "\n".join([f"{k}: {v}" for k, v in request.context.items()])
        prompt = f"Basé sur ce contexte, fournis des suggestions pertinentes:\n\n{context_str}"
        
        result = await call_groq_api(
            api_key=api_key,
            prompt=prompt,
            system_prompt=get_system_prompt("suggestion"),
            temperature=0.8,  # Plus créatif pour les suggestions
            max_tokens=1024,
        )
        
        data = result["data"]
        model_used = result["model"]
        
        choices = data.get("choices", [])
        if not choices:
            raise HTTPException(status_code=500, detail="Aucune réponse de l'IA")
        
        response_text = choices[0].get("message", {}).get("content", "")
        
        # Extraire les suggestions (format liste ou texte)
        suggestions = []
        for line in response_text.split("\n"):
            line = line.strip()
            if line and (line.startswith("-") or line.startswith("•") or line[0].isdigit()):
                suggestions.append(line.lstrip("- •1234567890. "))
            elif line and len(line) > 10:
                suggestions.append(line)
        
        return {
            "status": "ok",
            "suggestions": suggestions[:10],  # Limiter à 10 suggestions
            "model_used": model_used,
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la génération de suggestions: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la génération: {str(e)}"
        )


@router.get("/models")
async def list_models():
    """Retourne la liste des modèles disponibles."""
    return {
        "status": "ok",
        "models": GROQ_MODELS,
        "current_model": GROQ_MODELS[_current_model_index],
        "auto_switch": True,
    }


@router.get("/status")
async def status():
    """Retourne le statut du service IA."""
    return {
        "status": "OK",
        "message": "Service IA opérationnel avec Groq",
        "provider": "Groq",
        "models_available": len(GROQ_MODELS),
        "current_model": GROQ_MODELS[_current_model_index],
    }
