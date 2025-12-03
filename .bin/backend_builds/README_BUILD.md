# Build Notilus Backend Executable

Ce guide explique comment créer un exécutable Windows du backend Notilus.

## Prérequis

- Python 3.8 ou supérieur
- pip (gestionnaire de paquets Python)
- Toutes les dépendances du backend installées

## Installation des dépendances

```bash
cd backend
pip install -r requirements.txt
pip install pyinstaller
```

## Construction de l'exécutable

### Méthode 1 : Script batch (Windows)

Double-cliquez sur `build_exe.bat` ou exécutez dans un terminal :

```bash
build_exe.bat
```

### Méthode 2 : Script Python

```bash
python build_exe.py
```

## Résultat

L'exécutable sera créé dans le dossier `dist/` :

```
backend/
  dist/
    notilus_backend.exe  ← Exécutable final
```

## Intégration dans l'application Flutter

1. **En développement** : L'exe doit être dans `backend/dist/notilus_backend.exe`
2. **En production** : L'exe doit être dans le même dossier que `notilus.exe`

### Pour le build Flutter Windows

Copiez `notilus_backend.exe` dans le dossier de build :

```bash
# Après le build Flutter
copy backend\dist\notilus_backend.exe build\windows\x64\runner\Release\
```

Ou ajoutez-le dans `pubspec.yaml` comme asset (pour qu'il soit inclus dans le build).

## Configuration

L'exécutable utilise les mêmes variables d'environnement que le backend Python normal :

- `.env` dans le dossier `backend/` (si disponible)
- Variables d'environnement système
- Valeurs par défaut (port 8000, etc.)

## Dépannage

### L'exécutable ne démarre pas

- Vérifiez que toutes les dépendances sont incluses
- Vérifiez les logs dans la console (si `--console` est utilisé)
- Testez l'exécutable manuellement : `notilus_backend.exe`

### Le backend ne répond pas

- Vérifiez que le port 8000 n'est pas utilisé
- Vérifiez le firewall Windows
- Testez avec : `curl http://localhost:8000/api/health`

### L'exécutable est trop volumineux

- Utilisez `--onefile` (déjà activé)
- Supprimez les dépendances inutiles
- Utilisez `--exclude-module` pour exclure des modules non utilisés

## Notes

- L'exécutable est autonome et ne nécessite pas Python installé
- Tous les fichiers nécessaires sont inclus dans l'exe
- Le mode `--windowed` cache la console (utilisez `--console` pour voir les logs)

