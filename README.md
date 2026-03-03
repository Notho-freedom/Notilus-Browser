# Notilus Browser - Version Flutter

Cette version contient l'implémentation Flutter Desktop de Notilus Browser.

## Architecture Backend (Sidecar Windows)

Le frontend (`notilus.exe`) démarre automatiquement un backend sidecar (`notilus-backend.exe`) sur `127.0.0.1:8000`.

- Modèle: exécutable séparé (sidecar auto-start)
- Endpoint de santé: `GET http://127.0.0.1:8000/api/health`
- Override optionnel du chemin backend: variable d'environnement `NOTILUS_BACKEND_EXE`

### Stack Technique

- **Frontend**: Flutter/Dart
- **Backend**: FastAPI (Python)
- **Moteur Web**: WebView2 via plugin `webview_windows`
- **State**: Provider → Riverpod
- **Storage**: SharedPreferences + FlutterSecureStorage

### Statut

✅ **Stable** - Version de production

### Utilisation

```bash
# Installer les dépendances
flutter pub get

# Construire le backend sidecar (Windows)
cd backend
py -3.11 -m pip install -r requirements.txt
py -3.11 -m pip install pyinstaller
py -3.11 -m PyInstaller --name=notilus-backend --onefile --noconsole --icon "..\\assets\\notilus-logo.ico" --add-data "services;services" --add-data "backend_lab;backend_lab" --collect-all=uvicorn --collect-all=fastapi main.py
cd ..

# Lancer en développement
flutter run -d windows

# Build production
flutter build windows
```

### Structure

```
/
├── lib/                    # Code Dart
│   ├── core/              # Services core
│   ├── services/          # Services métier
│   ├── widgets/           # Widgets UI
│   └── screens/           # Écrans
│
├── backend/               # Backend Python FastAPI
│   ├── main.py
│   └── requirements.txt
│
└── pubspec.yaml           # Dépendances Flutter
```

### Notes

- Cette version reste fonctionnelle
- Les bugs critiques peuvent être corrigés si nécessaire

### Smoke Test Backend

```bash
curl http://127.0.0.1:8000/api/health
```

Réponse attendue: HTTP `200`.

### Diagnostic Port 8000

```bash
netstat -ano | findstr :8000
```
