# Intégration du Backend dans le Build Flutter

Ce document explique comment le backend Python est intégré dans le build Flutter Windows.

## 📦 Structure du Backend

Le backend est composé de :
- `main.py` : Point d'entrée de l'API FastAPI
- `python_embedded/` : Distribution Python embarquée (~10-15 MB)
- `services/` : Modules Python pour les services (monitoring, detection, etc.)
- `backend_lab/` : Modules Python pour le Backend Lab
- `logs/` : Répertoire pour les logs (créé automatiquement)

## 🔧 Intégration Automatique

Le backend est **automatiquement copié** dans le build Flutter grâce à `windows/CMakeLists.txt`.

Lors du build (`flutter build windows`), CMake copie :
1. `main.py` → `build/windows/x64/runner/Release/main.py`
2. `python_embedded/` → `build/windows/x64/runner/Release/python_embedded/`
3. `services/` → `build/windows/x64/runner/Release/services/`
4. `backend_lab/` → `build/windows/x64/runner/Release/backend_lab/`

## 🎯 Détection Automatique

Le service `BackendProcessService` détecte automatiquement le backend :

### En développement (kDebugMode)
Cherche dans : `backend/` (répertoire source)

### En production
Cherche à côté de l'exe : `build/windows/x64/runner/Release/`

Ordre de priorité :
1. `notilus_backend.exe` (si compilé avec PyInstaller)
2. `python_embedded/pythonw.exe` (mode furtif) ⭐ **Préféré**
3. `python_embedded/python.exe` (mode standard)
4. `pythonw` système (fallback)

## ✅ Avantages

- ✅ **Automatique** : Pas besoin de copier manuellement les fichiers
- ✅ **Intégré** : Le backend est inclus dans chaque build
- ✅ **Portable** : Fonctionne sur n'importe quelle machine Windows
- ✅ **Furtif** : Utilise `pythonw.exe` en production (pas de console)

## 🚀 Build et Déploiement

### Build Flutter
```bash
flutter build windows --release
```

Le backend sera automatiquement inclus dans :
```
build/windows/x64/runner/Release/
├── notilus.exe
├── main.py
├── python_embedded/
│   ├── pythonw.exe
│   └── ...
├── services/
│   └── ...
└── backend_lab/
    └── ...
```

### Distribution

Pour distribuer l'application, copiez tout le contenu de `build/windows/x64/runner/Release/` :
- L'exe Flutter (`notilus.exe`)
- Tous les DLLs nécessaires
- Le backend Python (main.py, python_embedded/, services/, backend_lab/)

## 🔍 Vérification

Pour vérifier que le backend est bien inclus :

1. **Après le build**, vérifiez que les fichiers sont présents :
   ```bash
   dir build\windows\x64\runner\Release\python_embedded\pythonw.exe
   dir build\windows\x64\runner\Release\main.py
   ```

2. **Lancez l'application** et vérifiez les logs :
   - Le backend devrait démarrer automatiquement
   - Les logs seront dans `backend/logs/backend.log` (en dev) ou `logs/backend.log` (en prod)

## ⚠️ Notes Importantes

- Le répertoire `python_embedded/` est **ignoré par Git** (voir `backend/.gitignore`)
- Il doit être généré avec `setup_embedded_python.bat` avant le build
- Les fichiers `__pycache__` et `*.pyc` sont exclus du build pour réduire la taille

## 🐛 Dépannage

### Le backend n'est pas copié dans le build

1. Vérifiez que `backend/` existe à la racine du projet
2. Vérifiez que `python_embedded/` existe dans `backend/`
3. Vérifiez les messages CMake lors du build

### Le backend ne démarre pas en production

1. Vérifiez que `python_embedded/pythonw.exe` existe à côté de `notilus.exe`
2. Vérifiez que `main.py` existe à côté de `notilus.exe`
3. Vérifiez les logs dans `logs/backend.log`

