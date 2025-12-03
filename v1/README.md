# Notilus Browser v1 - Version Flutter (Archivée)

## 📦 Version Archivée

Cette version contient l'implémentation originale de Notilus Browser en **Flutter Desktop**.

### Stack Technique

- **Frontend**: Flutter/Dart
- **Backend**: FastAPI (Python)
- **Moteur Web**: WebView2 via plugin `webview_windows`
- **State**: Provider → Riverpod
- **Storage**: SharedPreferences + FlutterSecureStorage

### Statut

✅ **Stable** - Version de production  
📦 **Archivée** - Ne sera plus développée activement  
🔄 **Migration** - v2 en cours de développement (Tauri)

### Utilisation

```bash
# Installer les dépendances
flutter pub get

# Lancer en développement
flutter run -d windows

# Build production
flutter build windows
```

### Structure

```
v1/
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
- Le développement actif se fait dans `../v2/`

---

**Pour la nouvelle version**, consultez `../v2/README.md`
