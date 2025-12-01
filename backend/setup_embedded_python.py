"""
Script pour télécharger et configurer Python embarqué pour Notilus Backend
Télécharge Python embeddable depuis python.org et installe les dépendances minimales
"""

import os
import sys
import urllib.request
import zipfile
import subprocess
import shutil
from pathlib import Path

# Configuration
PYTHON_VERSION = "3.10.11"
PYTHON_EMBED_URL = f"https://www.python.org/ftp/python/{PYTHON_VERSION}/python-{PYTHON_VERSION}-embed-amd64.zip"
EMBEDDED_DIR = Path(__file__).parent / "python_embedded"
PYTHON_EXE = EMBEDDED_DIR / "python.exe"
PIP_BOOTSTRAP_URL = "https://bootstrap.pypa.io/get-pip.py"

def download_file(url: str, dest: Path):
    """Télécharge un fichier depuis une URL"""
    print(f"📥 Téléchargement de {url}...")
    urllib.request.urlretrieve(url, dest)
    print(f"✅ Téléchargé: {dest}")

def extract_zip(zip_path: Path, dest_dir: Path):
    """Extrait un fichier ZIP"""
    print(f"📦 Extraction de {zip_path}...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(dest_dir)
    print(f"✅ Extrait dans: {dest_dir}")

def setup_python_embedded():
    """Configure Python embarqué"""
    print("🔧 Configuration de Python embarqué pour Notilus Backend...")
    print()
    
    # Créer le dossier si nécessaire
    EMBEDDED_DIR.mkdir(exist_ok=True)
    
    # Vérifier si Python est déjà installé
    if PYTHON_EXE.exists():
        print(f"✅ Python embarqué déjà présent: {PYTHON_EXE}")
        print("   Pour réinstaller, supprimez le dossier 'python_embedded'")
        return True
    
    # Télécharger Python embeddable
    zip_path = EMBEDDED_DIR / "python-embed.zip"
    if not zip_path.exists():
        try:
            download_file(PYTHON_EMBED_URL, zip_path)
        except Exception as e:
            print(f"❌ Erreur lors du téléchargement: {e}")
            print(f"   Téléchargez manuellement depuis: {PYTHON_EMBED_URL}")
            return False
    
    # Extraire Python
    if not PYTHON_EXE.exists():
        extract_zip(zip_path, EMBEDDED_DIR)
        zip_path.unlink()  # Supprimer le ZIP après extraction
    
    # Activer pip (nécessaire pour installer les dépendances)
    print("🔧 Activation de pip...")
    pth_file = EMBEDDED_DIR / "python310._pth"
    if pth_file.exists():
        # Modifier le fichier .pth pour permettre l'import de site-packages
        content = pth_file.read_text()
        if "import site" not in content:
            content = content.replace(
                "#import site",
                "import site"
            )
            pth_file.write_text(content)
            print("✅ Pip activé")
    
    # Télécharger et installer pip
    pip_script = EMBEDDED_DIR / "get-pip.py"
    if not (EMBEDDED_DIR / "Scripts" / "pip.exe").exists():
        try:
            download_file(PIP_BOOTSTRAP_URL, pip_script)
            print("📦 Installation de pip...")
            subprocess.run([str(PYTHON_EXE), str(pip_script)], check=True, cwd=EMBEDDED_DIR)
            pip_script.unlink()
            print("✅ Pip installé")
        except Exception as e:
            print(f"❌ Erreur lors de l'installation de pip: {e}")
            return False
    
    # Installer les dépendances minimales
    print("📦 Installation des dépendances...")
    requirements = Path(__file__).parent / "requirements.txt"
    if requirements.exists():
        try:
            # Utiliser python -m pip au lieu de pip.exe directement
            subprocess.run([str(PYTHON_EXE), "-m", "pip", "install", "-r", str(requirements)], check=True, cwd=EMBEDDED_DIR)
            print("✅ Dépendances installées")
        except Exception as e:
            print(f"⚠️  Erreur lors de l'installation des dépendances: {e}")
            print("   Vous pouvez les installer manuellement avec:")
            print(f"   {PYTHON_EXE} -m pip install -r requirements.txt")
    
    # Créer pythonw.exe pour mode furtif (copie de python.exe)
    pythonw_exe = EMBEDDED_DIR / "pythonw.exe"
    if not pythonw_exe.exists() and PYTHON_EXE.exists():
        import shutil
        shutil.copy2(PYTHON_EXE, pythonw_exe)
        print("✅ pythonw.exe créé pour mode furtif")
    
    print()
    print("✅ Python embarqué configuré avec succès!")
    print(f"📂 Emplacement: {EMBEDDED_DIR}")
    print(f"🐍 Python: {PYTHON_EXE}")
    print(f"🔇 PythonW (furtif): {pythonw_exe}")
    return True

if __name__ == "__main__":
    success = setup_python_embedded()
    sys.exit(0 if success else 1)

