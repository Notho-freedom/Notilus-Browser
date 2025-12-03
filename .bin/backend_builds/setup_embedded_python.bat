@echo off
REM Script pour configurer Python embarqué pour Notilus Backend

echo ========================================
echo   Setup Python Embedded pour Notilus
echo ========================================
echo.

REM Vérifier que Python est disponible pour exécuter le script
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Python n'est pas installe ou n'est pas dans le PATH
    echo.
    echo Veuillez installer Python 3.10+ depuis python.org
    echo ou utilisez le script setup_embedded_python.py directement
    pause
    exit /b 1
)

echo [INFO] Configuration de Python embarqué...
echo.

python setup_embedded_python.py

if errorlevel 1 (
    echo.
    echo [ERREUR] Echec de la configuration
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Configuration terminee avec succes!
echo ========================================
echo.
echo Python embarqué est maintenant disponible dans:
echo   backend\python_embedded\
echo.
pause

