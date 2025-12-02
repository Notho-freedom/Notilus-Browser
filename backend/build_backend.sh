#!/bin/bash
# Script de build du backend Notilus avec Python 3.11
# Force l'utilisation de Python 3.11 pour une meilleure compatibilité

echo "========================================"
echo "Build du backend Notilus avec Python 3.11"
echo "========================================"
echo ""

# Vérifier que Python 3.11 est disponible
if ! command -v python3.11 &> /dev/null; then
    echo "ERREUR: Python 3.11 n'est pas disponible"
    echo "Veuillez installer Python 3.11"
    exit 1
fi

echo "[1/4] Vérification de Python 3.11..."
python3.11 --version
echo ""

# Changer vers le répertoire backend
cd "$(dirname "$0")"

echo "[2/5] Installation des dépendances avec Python 3.11..."
python3.11 -m pip install --upgrade pip
python3.11 -m pip install -r requirements.txt
python3.11 -m pip install pyinstaller
echo ""

echo "[3/5] Nettoyage des packages incompatibles..."
# Désinstaller le package 'typing' obsolète qui est incompatible avec PyInstaller
python3.11 -m pip uninstall typing -y 2>/dev/null || true
echo ""

echo "[4/5] Build de l'exécutable avec PyInstaller (Python 3.11)..."
# Copier l'icône si elle n'existe pas
if [ ! -f "icon.ico" ] && [ -f "../windows/runner/resources/app_icon.ico" ]; then
    cp "../windows/runner/resources/app_icon.ico" "icon.ico"
fi

python3.11 -m PyInstaller \
    --name=notilus-backend \
    --onefile \
    --noconsole \
    --icon=icon.ico \
    --add-data "services:services" \
    --add-data "backend_lab:backend_lab" \
    --hidden-import=uvicorn.lifespan.on \
    --hidden-import=uvicorn.lifespan.off \
    --hidden-import=uvicorn.protocols.http.auto \
    --hidden-import=uvicorn.protocols.websockets.auto \
    --hidden-import=uvicorn.loops.auto \
    --hidden-import=uvicorn.logging \
    --hidden-import=fastapi \
    --hidden-import=pydantic \
    --hidden-import=firebase_admin \
    --hidden-import=requests \
    --hidden-import=websockets \
    --hidden-import=httpx \
    --hidden-import=psutil \
    --hidden-import=jsonpath_ng \
    --hidden-import=jsonschema \
    --hidden-import=aiofiles \
    --hidden-import=edge_tts \
    --hidden-import=langdetect \
    --hidden-import=google.cloud.texttospeech \
    --collect-all=uvicorn \
    --collect-all=fastapi \
    main.py

if [ $? -ne 0 ]; then
    echo ""
    echo "ERREUR: Le build a échoué"
    exit 1
fi

echo ""
echo "[5/5] Build terminé avec succès!"
echo ""
echo "L'exécutable se trouve dans: dist/notilus-backend"
echo ""

