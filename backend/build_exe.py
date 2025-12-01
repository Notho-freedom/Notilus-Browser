"""
Script pour créer un exécutable Windows du backend Notilus
Utilise PyInstaller pour créer un fichier .exe autonome
"""

import PyInstaller.__main__
import os
import sys

# Chemin du script principal
main_script = os.path.join(os.path.dirname(__file__), 'main.py')

# Options PyInstaller simplifiées
options = [
    main_script,
    '--name=notilus_backend',
    '--onefile',  # Créer un seul fichier exe
    '--windowed',  # Pas de console ni de fenêtre (furtif)
    '--clean',  # Nettoyer les fichiers temporaires
    '--noconfirm',  # Écraser les fichiers existants sans demander
    '--hidden-import=uvicorn',
    '--hidden-import=fastapi',
    '--hidden-import=dotenv',
    '--hidden-import=backend_lab',
    '--hidden-import=services',
    '--collect-all=uvicorn',
    '--collect-all=fastapi',
]

if __name__ == '__main__':
    print("🔨 Construction de l'exécutable Notilus Backend...")
    print(f"📁 Script principal: {main_script}")
    print(f"📦 Options: {len(options)} options")
    print()
    
    try:
        PyInstaller.__main__.run(options)
        print()
        print("✅ Exécutable créé avec succès!")
        print("📂 Fichier: dist/notilus_backend.exe")
    except Exception as e:
        print(f"❌ Erreur lors de la création de l'exécutable: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

