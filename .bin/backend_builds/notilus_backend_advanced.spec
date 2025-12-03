# -*- mode: python ; coding: utf-8 -*-
"""
Fichier spec PyInstaller pour Notilus Backend
Exécutable furtif (sans console, sans fenêtre)
"""

import sys
from pathlib import Path

# Chemin du backend
backend_dir = Path(SPECPATH)

# Tous les imports cachés
hiddenimports = [
    'fastapi',
    'uvicorn',
    'uvicorn.lifespan',
    'uvicorn.lifespan.on',
    'uvicorn.protocols',
    'uvicorn.protocols.http',
    'uvicorn.protocols.http.auto',
    'uvicorn.protocols.websockets',
    'uvicorn.protocols.websockets.auto',
    'uvicorn.loops',
    'uvicorn.loops.auto',
    'uvicorn.loops.asyncio',
    'uvicorn.logging',
    'dotenv',
    'pydantic',
    'pydantic.fields',
    'pydantic.types',
    'pydantic.validators',
    'pydantic.json',
    'httpx',
    'httpx._client',
    'httpx._transports',
    'httpx._transports.default',
    'websockets',
    'websockets.client',
    'websockets.server',
    'websockets.protocol',
    'edge_tts',
    'edge_tts.communicate',
    'edge_tts.list_voices',
    'langdetect',
    'langdetect.detector',
    'google.cloud',
    'google.cloud.texttospeech',
    'firebase_admin',
    'firebase_admin.credentials',
    'firebase_admin.firestore',
    'psutil',
    'jsonpath_ng',
    'jsonpath_ng.parser',
    'jsonschema',
    'jsonschema.validators',
    'aiofiles',
    'python_multipart',
    'services',
    'services.monitoring',
    'services.detection',
    'services.injection',
    'services.automation',
    'services.ai_service',
    'services.oauth_service',
    'services.tts',
    'backend_lab',
    'backend_lab.server_discovery',
    'backend_lab.route_discovery',
    'backend_lab.api_testing',
    'backend_lab.interception',
    'backend_lab.security_scanner',
    'backend_lab.performance_lab',
    'backend_lab.mock_server',
    'backend_lab.analytics',
    'backend_lab.auto_config',
    'backend_lab.console',
    'backend_lab.models',
    'backend_lab.models.server',
    'backend_lab.models.route',
    'backend_lab.models.test',
    'backend_lab.models.security',
    'backend_lab.models.performance',
    'backend_lab.models.mock',
    'backend_lab.models.capture',
]

a = Analysis(
    ['main.py'],
    pathex=[str(backend_dir)],
    binaries=[],
    datas=[],
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'matplotlib',
        'numpy',
        'pandas',
        'scipy',
        'PIL',
        'tkinter',
        'pytest',
        'unittest',
    ],
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='notilus_backend',
    debug=False,
    bootloader_ignore_signals=False,
    strip=True,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,  # Pas de console (furtif)
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,
)

