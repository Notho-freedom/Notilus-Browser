"""
Service TTS (Text-to-Speech) pour Notilus Browser
Génération de synthèse vocale avec Microsoft Edge TTS
"""

import asyncio
from io import BytesIO
from typing import Optional, Dict, List
from functools import lru_cache
import logging

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel, Field
import edge_tts
from langdetect import detect, LangDetectException

logger = logging.getLogger(__name__)

router = APIRouter()

# Cache pour les voix (évite de les récupérer à chaque requête)
_voices_cache: Optional[List[Dict]] = None
_cache_lock = asyncio.Lock()


# ============================================================================
# Modèles Pydantic
# ============================================================================

class TTSRequest(BaseModel):
    """Requête pour la génération TTS"""
    text: str = Field(..., min_length=1, description="Texte à synthétiser")
    voice: str = Field(default="fr-FR-DeniseNeural", description="Nom de la voix à utiliser")


class TTSResponse(BaseModel):
    """Réponse pour la génération TTS"""
    status: str
    message: Optional[str] = None
    used_voice: Optional[str] = None


class VoiceCheckRequest(BaseModel):
    """Requête pour vérifier une voix"""
    voice_name: str


class VoiceCheckResponse(BaseModel):
    """Réponse pour la vérification de voix"""
    voice: str
    available: bool


class VoicesByTextRequest(BaseModel):
    """Requête pour obtenir les voix par texte"""
    text: str = Field(..., min_length=1, description="Texte pour détecter la langue")


class VoicesByLanguageResponse(BaseModel):
    """Réponse pour les voix par langue"""
    male_voices: List[Dict]
    female_voices: List[Dict]
    language_code: str


class TTSAutoRequest(BaseModel):
    """Requête pour TTS avec détection automatique de langue"""
    text: str = Field(..., min_length=1, description="Texte à synthétiser")
    preferred_gender: Optional[str] = Field(default="Female", description="Genre préféré: 'Male' ou 'Female'")
    preferred_voice: Optional[str] = Field(default=None, description="Voix préférée (optionnelle)")


class BatchTTSRequest(BaseModel):
    """Requête pour génération TTS en batch"""
    texts: List[str] = Field(..., min_items=1, max_items=10, description="Liste des textes à synthétiser")
    voice: str = Field(default="fr-FR-DeniseNeural", description="Nom de la voix à utiliser")
    auto_detect: bool = Field(default=False, description="Détecter automatiquement la langue pour chaque texte")


class PreviewVoiceRequest(BaseModel):
    """Requête pour prévisualiser une voix"""
    voice: str = Field(..., description="Nom de la voix à prévisualiser")
    sample_text: Optional[str] = Field(default=None, description="Texte d'échantillon (optionnel)")


class VoiceInfoResponse(BaseModel):
    """Réponse avec informations détaillées sur une voix"""
    voice: Dict
    available: bool
    similar_voices: List[Dict]


# ============================================================================
# Fonctions utilitaires
# ============================================================================

async def get_voices_list(force_refresh: bool = False) -> List[Dict]:
    """
    Récupère la liste des voix avec cache.
    
    Args:
        force_refresh: Force le rafraîchissement du cache
        
    Returns:
        Liste des voix disponibles
    """
    global _voices_cache
    
    async with _cache_lock:
        if _voices_cache is None or force_refresh:
            try:
                _voices_cache = await edge_tts.list_voices()
                logger.info(f"Voices cache refreshed: {len(_voices_cache)} voices loaded")
            except Exception as e:
                logger.error(f"Error fetching voices: {e}")
                if _voices_cache is None:
                    raise HTTPException(
                        status_code=500,
                        detail="Impossible de récupérer la liste des voix"
                    )
    
    return _voices_cache


async def find_fallback_voice(original_voice: str, voices_list: List[Dict]) -> str:
    """
    Trouve une voix de fallback du même genre et de la même langue.
    
    Args:
        original_voice: Nom de la voix originale
        voices_list: Liste des voix disponibles
        
    Returns:
        Nom de la voix de fallback
    """
    try:
        # Extraire les informations de la voix originale
        original_voice_info = None
        for voice in voices_list:
            if voice.get('ShortName') == original_voice or voice.get('Name') == original_voice:
                original_voice_info = voice
                break
        
        if not original_voice_info:
            # Si on ne trouve pas la voix originale, utiliser une voix française féminine par défaut
            for voice in voices_list:
                if voice.get('Locale', '').startswith('fr') and voice.get('Gender') == 'Female':
                    logger.info(f"Fallback to default French female voice: {voice.get('ShortName')}")
                    return voice.get('ShortName')
            return "fr-FR-DeniseNeural"  # Fallback ultime
        
        # Chercher des voix du même genre et de la même langue
        target_locale = original_voice_info.get('Locale', '')
        target_gender = original_voice_info.get('Gender', '')
        target_language = target_locale.split('-')[0] if target_locale else 'fr'
        
        # Chercher des alternatives dans le même locale d'abord
        same_locale_voices = [
            voice for voice in voices_list 
            if (voice.get('Locale') == target_locale and 
                voice.get('Gender') == target_gender and 
                voice.get('ShortName') != original_voice)
        ]
        
        if same_locale_voices:
            fallback = same_locale_voices[0].get('ShortName')
            logger.info(f"Found same locale fallback: {fallback}")
            return fallback
        
        # Sinon, chercher dans la même langue
        same_language_voices = [
            voice for voice in voices_list 
            if (voice.get('Locale', '').startswith(target_language) and 
                voice.get('Gender') == target_gender and 
                voice.get('ShortName') != original_voice)
        ]
        
        if same_language_voices:
            fallback = same_language_voices[0].get('ShortName')
            logger.info(f"Found same language fallback: {fallback}")
            return fallback
        
        # Dernier recours : n'importe quelle voix du même genre
        same_gender_voices = [
            voice for voice in voices_list 
            if (voice.get('Gender') == target_gender and 
                voice.get('ShortName') != original_voice)
        ]
        
        if same_gender_voices:
            fallback = same_gender_voices[0].get('ShortName')
            logger.info(f"Found same gender fallback: {fallback}")
            return fallback
        
        return "fr-FR-DeniseNeural"  # Fallback ultime
        
    except Exception as e:
        logger.error(f"Error finding fallback voice: {e}")
        return "fr-FR-DeniseNeural"


# ============================================================================
# Endpoints
# ============================================================================

@router.post("/generate", response_class=StreamingResponse)
async def generate_tts(request: TTSRequest):
    """
    Génère un fichier audio à partir d'un texte (TTS).
    
    Retourne un flux audio MPEG avec retry automatique en cas d'échec de voix.
    """
    max_retries = 3
    
    logger.info(f"TTS Request: '{request.text[:50]}...' with voice '{request.voice}'")
    
    try:
        # Récupérer la liste des voix disponibles (avec cache)
        voices_list = await get_voices_list()
        
        current_voice = request.voice
        
        for attempt in range(max_retries):
            try:
                if attempt > 0:
                    current_voice = await find_fallback_voice(request.voice, voices_list)
                
                logger.info(f"Attempt {attempt + 1}/{max_retries}: Using voice '{current_voice}'")
                
                # Générer l'audio avec edge-tts
                communicate = edge_tts.Communicate(request.text, current_voice)
                audio_buffer = BytesIO()

                async for chunk in communicate.stream():
                    if chunk.get("type") == "audio" and "data" in chunk:
                        audio_buffer.write(chunk["data"])

                audio_buffer.seek(0)
                
                # Succès
                if attempt > 0:
                    logger.info(f"TTS succeeded with fallback voice '{current_voice}' after {attempt + 1} attempts")
                else:
                    logger.info(f"TTS succeeded with voice '{current_voice}'")
                
                return StreamingResponse(
                    content=audio_buffer,
                    media_type="audio/mpeg",
                    headers={
                        "X-Used-Voice": current_voice,
                        "X-Attempts": str(attempt + 1)
                    }
                )

            except Exception as voice_error:
                logger.warning(f"Attempt {attempt + 1} failed with voice '{current_voice}': {voice_error}")
                if attempt == max_retries - 1:
                    # Dernière tentative échouée
                    raise HTTPException(
                        status_code=500,
                        detail=f"Impossible de générer l'audio après {max_retries} tentatives. Dernière erreur: {str(voice_error)}"
                    )
                # Continuer avec la prochaine tentative

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"TTS Error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la génération TTS: {str(e)}"
        )


@router.get("/voices")
async def list_voices(force_refresh: bool = False):
    """
    Retourne toutes les voix disponibles.
    
    Args:
        force_refresh: Force le rafraîchissement du cache des voix
    """
    try:
        voices = await get_voices_list(force_refresh=force_refresh)
        return {
            "status": "ok",
            "count": len(voices),
            "voices": voices
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching voices: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Erreur lors de la récupération des voix"
        )


@router.get("/check-voice/{voice_name}")
async def check_voice(voice_name: str):
    """
    Vérifie si une voix spécifique est disponible.
    
    Args:
        voice_name: Nom de la voix à vérifier
    """
    try:
        voices = await get_voices_list()
        
        # Vérifier avec ShortName ET Name pour plus de compatibilité
        voice_available = any(
            voice.get('ShortName') == voice_name or 
            voice.get('Name') == voice_name or
            voice_name in voice.get('Name', '') 
            for voice in voices
        )
        
        if voice_available:
            return VoiceCheckResponse(voice=voice_name, available=True)
        else:
            # Debug: logger les premières voix disponibles
            logger.debug(f"Voice {voice_name} not found. First 3 available voices:")
            for i, voice in enumerate(voices[:3]):
                logger.debug(f"  {i+1}. Name: {voice.get('Name')}, ShortName: {voice.get('ShortName')}")
            
            return VoiceCheckResponse(voice=voice_name, available=False)
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error checking voice {voice_name}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la vérification de la voix {voice_name}"
        )


@router.post("/voices-by-text")
async def voices_by_text(request: VoicesByTextRequest):
    """
    Retourne les voix associées à la langue détectée du texte.
    
    Args:
        request: Requête contenant le texte à analyser
    """
    try:
        if not request.text:
            raise HTTPException(
                status_code=400,
                detail="Le texte est requis"
            )

        # Détecter la langue du texte
        try:
            language_code = detect(request.text)
            logger.info(f"Detected language: {language_code} for text: '{request.text[:30]}...'")
        except LangDetectException as e:
            logger.warning(f"Language detection failed: {e}, defaulting to 'fr'")
            language_code = 'fr'

        # Retourner les voix pour la langue détectée
        return await voices_by_language(language_code)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching voices for text: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Erreur lors de la détection de la langue et récupération des voix"
        )


@router.get("/voices-by-language/{language_code}")
async def voices_by_language(language_code: str):
    """
    Retourne les voix masculines et féminines disponibles pour une langue donnée.
    
    Args:
        language_code: Code de langue (ex: 'fr', 'en', 'es')
    """
    try:
        voices = await get_voices_list()

        # Convertir le paramètre en format minuscule
        language_prefix = language_code.lower()

        # Filtrage des voix selon le préfixe de langue et le genre
        male_voices = [
            voice for voice in voices 
            if voice['Locale'].lower().startswith(language_prefix) and voice['Gender'] == 'Male'
        ]
        female_voices = [
            voice for voice in voices 
            if voice['Locale'].lower().startswith(language_prefix) and voice['Gender'] == 'Female'
        ]

        return VoicesByLanguageResponse(
            male_voices=male_voices,
            female_voices=female_voices,
            language_code=language_code
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching voices for language {language_code}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des voix pour la langue {language_code}"
        )


@router.get("/status")
async def status():
    """Retourne le statut du service TTS."""
    try:
        # Vérifier que le service peut récupérer les voix
        voices = await get_voices_list()
        return {
            "status": "OK",
            "message": "Service TTS opérationnel",
            "voices_count": len(voices)
        }
    except Exception as e:
        logger.error(f"Status check failed: {e}")
        return {
            "status": "ERROR",
            "message": f"Service TTS en erreur: {str(e)}"
        }


# ============================================================================
# Nouvelles routes utilitaires
# ============================================================================

@router.post("/generate-auto", response_class=StreamingResponse)
async def generate_tts_auto(request: TTSAutoRequest):
    """
    Génère un fichier audio avec détection automatique de la langue.
    
    Détecte automatiquement la langue du texte et sélectionne une voix appropriée.
    """
    try:
        # Détecter la langue
        try:
            detected_lang = detect(request.text)
            logger.info(f"Auto-detected language: {detected_lang}")
        except LangDetectException:
            detected_lang = 'fr'
            logger.warning("Language detection failed, defaulting to 'fr'")
        
        # Obtenir les voix pour la langue détectée
        voices_list = await get_voices_list()
        language_prefix = detected_lang.lower()
        
        # Filtrer les voix par langue et genre
        suitable_voices = [
            voice for voice in voices_list
            if (voice['Locale'].lower().startswith(language_prefix) and 
                voice['Gender'] == request.preferred_gender)
        ]
        
        # Utiliser la voix préférée si disponible, sinon la première voix appropriée
        selected_voice = request.preferred_voice
        if selected_voice:
            # Vérifier que la voix préférée est dans la liste appropriée
            if not any(v.get('ShortName') == selected_voice for v in suitable_voices):
                selected_voice = None
        
        if not selected_voice and suitable_voices:
            selected_voice = suitable_voices[0].get('ShortName')
        elif not suitable_voices:
            # Fallback: utiliser une voix française
            selected_voice = "fr-FR-DeniseNeural"
        
        # Générer le TTS avec la voix sélectionnée
        tts_request = TTSRequest(text=request.text, voice=selected_voice)
        return await generate_tts(tts_request)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in auto TTS generation: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la génération TTS automatique: {str(e)}"
        )


@router.post("/preview-voice", response_class=StreamingResponse)
async def preview_voice(request: PreviewVoiceRequest):
    """
    Génère un échantillon audio court pour prévisualiser une voix.
    
    Utile pour tester une voix avant de l'utiliser pour un long texte.
    """
    sample_texts = {
        'fr': "Bonjour, je suis une voix de synthèse. Comment puis-je vous aider aujourd'hui ?",
        'en': "Hello, I am a text-to-speech voice. How can I help you today?",
        'es': "Hola, soy una voz de síntesis. ¿Cómo puedo ayudarte hoy?",
        'de': "Hallo, ich bin eine Sprachsynthese-Stimme. Wie kann ich Ihnen heute helfen?",
        'it': "Ciao, sono una voce di sintesi vocale. Come posso aiutarti oggi?",
    }
    
    # Détecter la langue de la voix
    voices_list = await get_voices_list()
    voice_info = None
    for voice in voices_list:
        if voice.get('ShortName') == request.voice or voice.get('Name') == request.voice:
            voice_info = voice
            break
    
    # Choisir le texte d'échantillon
    if request.sample_text:
        text = request.sample_text
    elif voice_info:
        locale = voice_info.get('Locale', 'fr-FR')
        lang_code = locale.split('-')[0].lower()
        text = sample_texts.get(lang_code, sample_texts['fr'])
    else:
        text = sample_texts['fr']
    
    # Générer l'échantillon
    tts_request = TTSRequest(text=text, voice=request.voice)
    return await generate_tts(tts_request)


@router.post("/batch-generate")
async def batch_generate_tts(request: BatchTTSRequest):
    """
    Génère plusieurs fichiers audio en batch.
    
    Retourne une liste d'URLs ou de données audio encodées en base64.
    Note: Pour simplifier, cette route retourne les métadonnées.
    Pour obtenir les fichiers, utilisez /generate pour chaque texte.
    """
    results = []
    
    for i, text in enumerate(request.texts):
        try:
            if request.auto_detect:
                # Détection automatique pour chaque texte
                try:
                    detected_lang = detect(text)
                    voices_list = await get_voices_list()
                    language_prefix = detected_lang.lower()
                    
                    suitable_voices = [
                        v for v in voices_list
                        if v['Locale'].lower().startswith(language_prefix)
                    ]
                    voice = suitable_voices[0].get('ShortName') if suitable_voices else request.voice
                except:
                    voice = request.voice
            else:
                voice = request.voice
            
            # Note: Pour une vraie implémentation batch, il faudrait générer les fichiers
            # et les stocker temporairement ou les encoder en base64
            results.append({
                "index": i,
                "text": text[:50] + "..." if len(text) > 50 else text,
                "voice": voice,
                "status": "ready",
                "message": "Utilisez /generate pour obtenir le fichier audio"
            })
        except Exception as e:
            results.append({
                "index": i,
                "text": text[:50] + "..." if len(text) > 50 else text,
                "status": "error",
                "error": str(e)
            })
    
    return {
        "status": "ok",
        "count": len(results),
        "results": results
    }


@router.get("/languages")
async def get_supported_languages():
    """
    Retourne la liste des langues supportées avec le nombre de voix disponibles.
    """
    try:
        voices = await get_voices_list()
        
        # Extraire les langues uniques
        languages = {}
        for voice in voices:
            locale = voice.get('Locale', '')
            if locale:
                lang_code = locale.split('-')[0].lower()
                if lang_code not in languages:
                    languages[lang_code] = {
                        "code": lang_code,
                        "locales": [],
                        "total_voices": 0,
                        "male_voices": 0,
                        "female_voices": 0
                    }
                
                locale_full = locale
                if locale_full not in languages[lang_code]["locales"]:
                    languages[lang_code]["locales"].append(locale_full)
                
                languages[lang_code]["total_voices"] += 1
                if voice.get('Gender') == 'Male':
                    languages[lang_code]["male_voices"] += 1
                elif voice.get('Gender') == 'Female':
                    languages[lang_code]["female_voices"] += 1
        
        return {
            "status": "ok",
            "count": len(languages),
            "languages": list(languages.values())
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching languages: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Erreur lors de la récupération des langues"
        )


@router.get("/recommended-voices")
async def get_recommended_voices(language: Optional[str] = None, limit: int = 10):
    """
    Retourne les voix recommandées/populaires.
    
    Args:
        language: Code de langue pour filtrer (optionnel)
        limit: Nombre maximum de voix à retourner
    """
    try:
        voices = await get_voices_list()
        
        # Voix recommandées (priorité aux Neural voices)
        recommended = []
        for voice in voices:
            if language:
                if not voice.get('Locale', '').lower().startswith(language.lower()):
                    continue
            
            # Prioriser les voix Neural
            if 'Neural' in voice.get('ShortName', '') or 'Neural' in voice.get('Name', ''):
                recommended.append(voice)
        
        # Trier par popularité (locale complet d'abord, puis par nom)
        recommended.sort(key=lambda v: (
            len(v.get('Locale', '')),  # Locales complets en premier
            v.get('ShortName', '')
        ))
        
        return {
            "status": "ok",
            "count": min(len(recommended), limit),
            "voices": recommended[:limit]
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching recommended voices: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Erreur lors de la récupération des voix recommandées"
        )


@router.get("/voice-info/{voice_name}")
async def get_voice_info(voice_name: str):
    """
    Retourne des informations détaillées sur une voix spécifique.
    
    Inclut les voix similaires (même langue/genre).
    """
    try:
        voices = await get_voices_list()
        
        # Trouver la voix
        voice_info = None
        for voice in voices:
            if (voice.get('ShortName') == voice_name or 
                voice.get('Name') == voice_name or
                voice_name in voice.get('Name', '')):
                voice_info = voice
                break
        
        if not voice_info:
            raise HTTPException(
                status_code=404,
                detail=f"Voix '{voice_name}' non trouvée"
            )
        
        # Trouver des voix similaires
        target_locale = voice_info.get('Locale', '')
        target_gender = voice_info.get('Gender', '')
        
        similar_voices = [
            voice for voice in voices
            if (voice.get('Locale') == target_locale and 
                voice.get('Gender') == target_gender and
                voice.get('ShortName') != voice_info.get('ShortName'))
        ]
        
        return VoiceInfoResponse(
            voice=voice_info,
            available=True,
            similar_voices=similar_voices[:5]  # Limiter à 5 voix similaires
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching voice info: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des informations sur la voix {voice_name}"
        )


@router.get("/voices-by-gender/{gender}")
async def get_voices_by_gender(gender: str, language: Optional[str] = None):
    """
    Retourne les voix filtrées par genre.
    
    Args:
        gender: 'Male' ou 'Female'
        language: Code de langue pour filtrer (optionnel)
    """
    try:
        if gender.lower() not in ['male', 'female']:
            raise HTTPException(
                status_code=400,
                detail="Le genre doit être 'Male' ou 'Female'"
            )
        
        voices = await get_voices_list()
        
        filtered_voices = [
            voice for voice in voices
            if voice.get('Gender', '').lower() == gender.lower()
        ]
        
        if language:
            filtered_voices = [
                voice for voice in filtered_voices
                if voice.get('Locale', '').lower().startswith(language.lower())
            ]
        
        return {
            "status": "ok",
            "gender": gender,
            "language": language,
            "count": len(filtered_voices),
            "voices": filtered_voices
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching voices by gender: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des voix par genre"
        )


@router.get("/voices-by-locale/{locale}")
async def get_voices_by_locale(locale: str):
    """
    Retourne les voix pour un locale spécifique (ex: 'fr-FR', 'en-US').
    
    Args:
        locale: Locale complet (ex: 'fr-FR', 'en-US', 'es-ES')
    """
    try:
        voices = await get_voices_list()
        
        locale_lower = locale.lower()
        filtered_voices = [
            voice for voice in voices
            if voice.get('Locale', '').lower() == locale_lower
        ]
        
        if not filtered_voices:
            raise HTTPException(
                status_code=404,
                detail=f"Aucune voix trouvée pour le locale '{locale}'"
            )
        
        # Séparer par genre
        male_voices = [v for v in filtered_voices if v.get('Gender') == 'Male']
        female_voices = [v for v in filtered_voices if v.get('Gender') == 'Female']
        
        return {
            "status": "ok",
            "locale": locale,
            "total": len(filtered_voices),
            "male_count": len(male_voices),
            "female_count": len(female_voices),
            "male_voices": male_voices,
            "female_voices": female_voices
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching voices by locale: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des voix pour le locale {locale}"
        )


class CompareVoicesRequest(BaseModel):
    """Requête pour comparer des voix"""
    voices: List[str] = Field(..., min_items=1, max_items=5, description="Liste des voix à comparer")
    sample_text: Optional[str] = Field(default=None, description="Texte d'échantillon (optionnel)")


@router.post("/compare-voices")
async def compare_voices(request: CompareVoicesRequest):
    """
    Compare plusieurs voix avec le même texte.
    
    Retourne les informations de comparaison avec des URLs pour prévisualiser chaque voix.
    """
    if not request.sample_text:
        request.sample_text = "Bonjour, ceci est un test de comparaison de voix."
    
    comparison_results = []
    
    for voice_name in request.voices:
        try:
            # Vérifier que la voix existe
            voices_list = await get_voices_list()
            voice_exists = any(
                v.get('ShortName') == voice_name or 
                v.get('Name') == voice_name
                for v in voices_list
            )
            
            if voice_exists:
                comparison_results.append({
                    "voice": voice_name,
                    "available": True,
                    "preview_url": f"/api/tts/preview-voice",
                    "message": "Utilisez POST /api/tts/preview-voice avec cette voix pour générer l'échantillon"
                })
            else:
                comparison_results.append({
                    "voice": voice_name,
                    "available": False,
                    "error": "Voix non trouvée"
                })
        except Exception as e:
            comparison_results.append({
                "voice": voice_name,
                "available": False,
                "error": str(e)
            })
    
    return {
        "status": "ok",
        "sample_text": request.sample_text,
        "count": len(comparison_results),
        "comparisons": comparison_results
    }


@router.get("/search-voices")
async def search_voices(
    query: Optional[str] = None,
    language: Optional[str] = None,
    gender: Optional[str] = None,
    locale: Optional[str] = None,
    limit: int = 20
):
    """
    Recherche de voix avec filtres multiples.
    
    Args:
        query: Recherche textuelle dans les noms de voix
        language: Filtrer par code de langue
        gender: Filtrer par genre ('Male' ou 'Female')
        locale: Filtrer par locale complet
        limit: Nombre maximum de résultats
    """
    try:
        voices = await get_voices_list()
        filtered = voices
        
        # Filtre par query
        if query:
            query_lower = query.lower()
            filtered = [
                v for v in filtered
                if (query_lower in v.get('ShortName', '').lower() or
                    query_lower in v.get('Name', '').lower() or
                    query_lower in v.get('Locale', '').lower())
            ]
        
        # Filtre par langue
        if language:
            filtered = [
                v for v in filtered
                if v.get('Locale', '').lower().startswith(language.lower())
            ]
        
        # Filtre par genre
        if gender:
            if gender.lower() not in ['male', 'female']:
                raise HTTPException(
                    status_code=400,
                    detail="Le genre doit être 'Male' ou 'Female'"
                )
            filtered = [
                v for v in filtered
                if v.get('Gender', '').lower() == gender.lower()
            ]
        
        # Filtre par locale
        if locale:
            filtered = [
                v for v in filtered
                if v.get('Locale', '').lower() == locale.lower()
            ]
        
        return {
            "status": "ok",
            "query": query,
            "filters": {
                "language": language,
                "gender": gender,
                "locale": locale
            },
            "count": len(filtered),
            "limit": limit,
            "voices": filtered[:limit]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error searching voices: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Erreur lors de la recherche de voix"
        )
