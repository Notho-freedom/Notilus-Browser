@echo off
REM Wrapper furtif pour le backend Notilus
REM Lance le backend Python sans afficher de console

REM Masquer la fenêtre de console
if not "%1"=="hidden" (
    start /min "" "%~f0" hidden %*
    exit
)

REM Changer vers le répertoire du script
cd /d "%~dp0"

REM Lancer le backend Python
pythonw main.py

