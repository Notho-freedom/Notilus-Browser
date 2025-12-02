@echo off
REM Script de build du backend Notilus avec Python 3.11
REM Force l'utilisation de Python 3.11 pour une meilleure compatibilité

echo ========================================
echo Build du backend Notilus avec Python 3.11
echo ========================================
echo.

REM Vérifier que Python 3.11 est disponible
py -3.11 --version >nul 2>&1
if errorlevel 1 (
    echo ERREUR: Python 3.11 n'est pas disponible
    echo Veuillez installer Python 3.11
    pause
    exit /b 1
)

echo [1/4] Verification de Python 3.11...
py -3.11 --version
echo.

REM Changer vers le répertoire backend
cd /d "%~dp0"

echo [2/5] Installation des dependances avec Python 3.11...
py -3.11 -m pip install --upgrade pip
py -3.11 -m pip install -r requirements.txt
py -3.11 -m pip install pyinstaller
echo.

echo [3/5] Nettoyage des packages incompatibles...
REM Desinstaller le package 'typing' obsolete qui est incompatible avec PyInstaller
py -3.11 -m pip uninstall typing -y 2>nul
echo.

echo [4/5] Build de l'executable avec PyInstaller (Python 3.11)...
REM Copier l'icone si elle n'existe pas
if not exist "icon.ico" (
    if exist "..\windows\runner\resources\app_icon.ico" (
        copy "..\windows\runner\resources\app_icon.ico" "icon.ico" >nul
    )
)

py -3.11 -m PyInstaller ^
    --name=notilus-backend ^
    --onefile ^
    --noconsole ^
    --icon=icon.ico ^
    --add-data "services;services" ^
    --add-data "backend_lab;backend_lab" ^
    --hidden-import=uvicorn.lifespan.on ^
    --hidden-import=uvicorn.lifespan.off ^
    --hidden-import=uvicorn.protocols.http.auto ^
    --hidden-import=uvicorn.protocols.websockets.auto ^
    --hidden-import=uvicorn.loops.auto ^
    --hidden-import=uvicorn.logging ^
    --hidden-import=fastapi ^
    --hidden-import=pydantic ^
    --hidden-import=firebase_admin ^
    --hidden-import=requests ^
    --hidden-import=websockets ^
    --hidden-import=httpx ^
    --hidden-import=psutil ^
    --hidden-import=jsonpath_ng ^
    --hidden-import=jsonschema ^
    --hidden-import=aiofiles ^
    --hidden-import=edge_tts ^
    --hidden-import=langdetect ^
    --hidden-import=google.cloud.texttospeech ^
    --collect-all=uvicorn ^
    --collect-all=fastapi ^
    main.py

if errorlevel 1 (
    echo.
    echo ERREUR: Le build a echoue
    pause
    exit /b 1
)

echo.
echo [5/5] Build termine avec succes!
echo.
echo L'executable se trouve dans: dist\notilus-backend.exe
echo.
pause

