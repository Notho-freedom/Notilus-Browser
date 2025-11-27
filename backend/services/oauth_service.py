"""
Service OAuth local pour Notilus
Gère l'authentification Google (Device Flow) et GitHub (WebView OAuth)
"""

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from pydantic import BaseModel
import httpx
import secrets
import asyncio
from typing import Optional, Dict
import os
from dotenv import load_dotenv

load_dotenv()

router = APIRouter()

# Stockage temporaire des codes device flow et tokens
_device_flows: Dict[str, Dict] = {}
_oauth_codes: Dict[str, Dict] = {}

# Configuration OAuth
GITHUB_CLIENT_ID = os.getenv("GITHUB_CLIENT_ID", "")
GITHUB_CLIENT_SECRET = os.getenv("GITHUB_CLIENT_SECRET", "")
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET", "")


class DeviceFlowResponse(BaseModel):
    device_code: str
    user_code: str
    verification_uri: str
    verification_uri_complete: str
    expires_in: int
    interval: int


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    scope: Optional[str] = None
    id_token: Optional[str] = None  # Pour Google
    refresh_token: Optional[str] = None


# ============================================================================
# Google OAuth - Device Flow
# ============================================================================

@router.get("/google/device-flow", response_model=DeviceFlowResponse)
async def google_device_flow():
    """
    Initie le Device Flow pour Google OAuth
    """
    if not GOOGLE_CLIENT_ID:
        raise HTTPException(
            status_code=500,
            detail="GOOGLE_CLIENT_ID non configuré. Configurez-le dans .env"
        )
    
    try:
        # Étape 1: Demander un device code à Google
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://oauth2.googleapis.com/device/code",
                data={
                    "client_id": GOOGLE_CLIENT_ID,
                    "scope": "openid email profile",
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            response.raise_for_status()
            data = response.json()
            
            device_code = data["device_code"]
            user_code = data["user_code"]
            
            # Stocker le device flow
            _device_flows[device_code] = {
                "user_code": user_code,
                "expires_in": data["expires_in"],
                "interval": data.get("interval", 5),
                "status": "pending",
                "access_token": None,
                "id_token": None,
            }
            
            return DeviceFlowResponse(
                device_code=device_code,
                user_code=user_code,
                verification_uri=data["verification_uri"],
                verification_uri_complete=data["verification_uri_complete"],
                expires_in=data["expires_in"],
                interval=data.get("interval", 5),
            )
    except httpx.HTTPError as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la demande device code: {str(e)}")


@router.get("/google/poll/{device_code}", response_model=TokenResponse)
async def google_poll_token(device_code: str):
    """
    Poll pour vérifier si l'utilisateur a autorisé l'app
    """
    if device_code not in _device_flows:
        raise HTTPException(status_code=404, detail="Device code invalide ou expiré")
    
    flow = _device_flows[device_code]
    
    # Vérifier si déjà complété
    if flow["status"] == "completed" and flow["access_token"]:
        return TokenResponse(
            access_token=flow["access_token"],
            token_type="Bearer",
            id_token=flow.get("id_token"),
        )
    
    # Vérifier si expiré
    if flow["status"] == "expired":
        raise HTTPException(status_code=410, detail="Device code expiré")
    
    try:
        # Poll Google pour vérifier l'autorisation
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://oauth2.googleapis.com/token",
                data={
                    "client_id": GOOGLE_CLIENT_ID,
                    "client_secret": GOOGLE_CLIENT_SECRET,
                    "device_code": device_code,
                    "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            
            if response.status_code == 200:
                data = response.json()
                flow["status"] = "completed"
                flow["access_token"] = data["access_token"]
                flow["id_token"] = data.get("id_token")
                
                return TokenResponse(
                    access_token=data["access_token"],
                    token_type=data["token_type"],
                    id_token=data.get("id_token"),
                    refresh_token=data.get("refresh_token"),
                )
            elif response.status_code == 400:
                error_data = response.json()
                error = error_data.get("error", "")
                
                if error == "authorization_pending":
                    # L'utilisateur n'a pas encore autorisé
                    return JSONResponse(
                        status_code=202,
                        content={"status": "pending", "message": "En attente d'autorisation"}
                    )
                elif error == "slow_down":
                    # Augmenter l'intervalle
                    flow["interval"] = min(flow["interval"] * 2, 60)
                    return JSONResponse(
                        status_code=202,
                        content={"status": "pending", "message": "En attente d'autorisation"}
                    )
                elif error == "expired_token":
                    flow["status"] = "expired"
                    raise HTTPException(status_code=410, detail="Device code expiré")
                else:
                    raise HTTPException(status_code=400, detail=f"Erreur OAuth: {error}")
            else:
                raise HTTPException(status_code=response.status_code, detail="Erreur lors du polling")
                
    except httpx.HTTPError as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors du polling: {str(e)}")


# ============================================================================
# GitHub OAuth - WebView Flow
# ============================================================================

@router.get("/github/authorize")
async def github_authorize(state: Optional[str] = Query(None)):
    """
    Redirige vers GitHub OAuth
    Si state n'est pas fourni, en génère un nouveau
    """
    if not GITHUB_CLIENT_ID:
        raise HTTPException(
            status_code=500,
            detail="GITHUB_CLIENT_ID non configuré. Configurez-le dans .env"
        )
    
    # Utiliser le state fourni ou en générer un nouveau
    if not state:
        state = secrets.token_urlsafe(32)
    
    # Construire l'URL d'autorisation GitHub
    redirect_uri = f"http://localhost:8000/api/oauth/github/callback"
    auth_url = (
        f"https://github.com/login/oauth/authorize"
        f"?client_id={GITHUB_CLIENT_ID}"
        f"&redirect_uri={redirect_uri}"
        f"&scope=read:user user:email"
        f"&state={state}"
    )
    
    # Stocker le state
    _oauth_codes[state] = {"status": "pending"}
    
    return RedirectResponse(url=auth_url)


@router.get("/github/callback")
async def github_callback(
    code: Optional[str] = Query(None),
    state: Optional[str] = Query(None),
    error: Optional[str] = Query(None),
):
    """
    Callback GitHub OAuth - échange le code contre un token
    """
    if error:
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Erreur d'authentification</title>
            <style>
                body {{
                    font-family: Arial, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: #1a1a1a;
                    color: white;
                }}
                .container {{
                    text-align: center;
                    padding: 20px;
                }}
                .error {{
                    color: #ff4444;
                    margin: 20px 0;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Erreur d'authentification</h1>
                <p class="error">{error}</p>
                <p>Vous pouvez fermer cette fenêtre.</p>
            </div>
        </body>
        </html>
        """
        return HTMLResponse(content=html)
    
    if not code or not state:
        raise HTTPException(status_code=400, detail="Code ou state manquant")
    
    if state not in _oauth_codes:
        raise HTTPException(status_code=400, detail="State invalide")
    
    try:
        # Échanger le code contre un access token
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://github.com/login/oauth/access_token",
                data={
                    "client_id": GITHUB_CLIENT_ID,
                    "client_secret": GITHUB_CLIENT_SECRET,
                    "code": code,
                    "state": state,
                },
                headers={
                    "Accept": "application/json",
                    "Content-Type": "application/x-www-form-urlencoded",
                },
            )
            response.raise_for_status()
            data = response.json()
            
            if "error" in data:
                raise HTTPException(status_code=400, detail=data.get("error_description", "Erreur OAuth"))
            
            # Stocker le token
            _oauth_codes[state]["status"] = "completed"
            _oauth_codes[state]["access_token"] = data["access_token"]
            
            # Afficher une page de succès
            html = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Authentification réussie</title>
                <style>
                    body {
                        font-family: Arial, sans-serif;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                        margin: 0;
                        background: #1a1a1a;
                        color: white;
                    }
                    .container {
                        text-align: center;
                        padding: 20px;
                    }
                    .success {
                        color: #44ff44;
                        margin: 20px 0;
                        font-size: 24px;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>✅ Authentification réussie</h1>
                    <p class="success">Vous pouvez fermer cette fenêtre.</p>
                    <p>Retournez à Notilus pour continuer.</p>
                </div>
            </body>
            </html>
            """
            return HTMLResponse(content=html)
            
    except httpx.HTTPError as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'échange du token: {str(e)}")


@router.get("/github/token/{state}", response_model=TokenResponse)
async def github_get_token(state: str):
    """
    Récupère le token GitHub après autorisation
    """
    if state not in _oauth_codes:
        raise HTTPException(status_code=404, detail="State invalide")
    
    oauth_data = _oauth_codes[state]
    
    if oauth_data["status"] != "completed":
        return JSONResponse(
            status_code=202,
            content={"status": "pending", "message": "En attente d'autorisation"}
        )
    
    if "access_token" not in oauth_data:
        raise HTTPException(status_code=404, detail="Token non disponible")
    
    return TokenResponse(
        access_token=oauth_data["access_token"],
        token_type="Bearer",
    )


# ============================================================================
# Utilitaires
# ============================================================================

@router.get("/config")
async def get_oauth_config():
    """
    Retourne la configuration OAuth (sans secrets)
    """
    return {
        "github_configured": bool(GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET),
        "google_configured": bool(GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET),
        "github_client_id": GITHUB_CLIENT_ID[:8] + "..." if GITHUB_CLIENT_ID else None,
        "google_client_id": GOOGLE_CLIENT_ID[:8] + "..." if GOOGLE_CLIENT_ID else None,
    }

