@echo off
REM Script batch pour créer l'exécutable du backend Notilus

echo ========================================
echo   Build Notilus Backend Executable
echo ========================================
echo.

REM Vérifier que Python est installé
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Python n'est pas installe ou n'est pas dans le PATH
    pause
    exit /b 1
)

REM Vérifier que PyInstaller est installé
python -c "import PyInstaller" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Installation de PyInstaller...
    pip install pyinstaller
    if errorlevel 1 (
        echo [ERREUR] Impossible d'installer PyInstaller
        pause
        exit /b 1
    )
)

REM Installer les dépendances si nécessaire
if not exist "requirements.txt" (
    echo [ERREUR] Fichier requirements.txt introuvable
    pause
    exit /b 1
)

echo [INFO] Installation des dependances...
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERREUR] Impossible d'installer les dependances
    pause
    exit /b 1
)

REM Créer l'exécutable
echo [INFO] Creation de l'executable...
python build_exe.py

if errorlevel 1 (
    echo [ERREUR] Echec de la creation de l'executable
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Build termine avec succes!
echo ========================================
echo.
echo L'executable se trouve dans: dist\notilus_backend.exe
echo.
pause

