# Notilus CEF Plugin

Plugin Flutter pour le rendu CEF (Chromium Embedded Framework) en mode offscreen avec support de texture native.

## 🚀 Fonctionnalités

- ✅ Rendu offscreen CEF dans une texture Flutter native
- ✅ 60 FPS, GPU-accelerated
- ✅ Transformations 3D, shaders, blur, animations Matrix4 sans latence
- ✅ Support complet des événements souris/clavier
- ✅ Exécution JavaScript bidirectionnelle
- ✅ Navigation complète (back/forward/reload)
- ✅ Gestion des popups et des erreurs

## 📦 Installation

### 1. Télécharger CEF

Téléchargez CEF depuis [cef-builds.spotifycdn.com](https://cef-builds.spotifycdn.com/index.html)

**Version recommandée**: CEF 120.x ou supérieur (Windows x64)

**Structure attendue**:
```
notilus_cef/windows/cef/
├── CMakeLists.txt
├── include/
├── Release/
│   ├── libcef.dll
│   ├── chrome_elf.dll
│   ├── icudtl.dat
│   ├── snapshot_blob.bin
│   ├── v8_context_snapshot.bin
│   ├── locales/
│   └── swiftshader/
└── ...
```

### 2. Ajouter le plugin au projet

Dans `pubspec.yaml`:
```yaml
dependencies:
  notilus_cef:
    path: ./notilus_cef
```

### 3. Configuration CMake

Le plugin cherche CEF dans `windows/cef/` par défaut. Si votre installation est ailleurs, modifiez `CEF_ROOT` dans `notilus_cef/windows/CMakeLists.txt`.

## 💻 Utilisation

### Initialisation basique

```dart
import 'package:notilus_cef/notilus_cef.dart';

class CefView extends StatefulWidget {
  @override
  _CefViewState createState() => _CefViewState();
}

class _CefViewState extends State<CefView> {
  int? textureId;

  @override
  void initState() {
    super.initState();
    _initCEF();
  }

  Future<void> _initCEF() async {
    textureId = await NotilusCEF.init(
      width: 1920,
      height: 1080,
      initialUrl: "https://flutter.dev",
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (textureId == null) {
      return CircularProgressIndicator();
    }
    
    return Texture(textureId: textureId!);
  }
}
```

### Avec transformations 3D

```dart
@override
Widget build(BuildContext context) {
  if (textureId == null) return CircularProgressIndicator();
  
  return Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()
      ..rotateX(-0.1)
      ..rotateY(0.05)
      ..setEntry(3, 2, 0.001), // Perspective
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Texture(textureId: textureId!),
    ),
  );
}
```

### Avec blur et effets

```dart
import 'dart:ui';

@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Version floutée en arrière-plan
      ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Texture(textureId: textureId!),
      ),
      // Version nette au premier plan
      Texture(textureId: textureId!),
    ],
  );
}
```

### Gestion des événements

```dart
GestureDetector(
  onTapDown: (details) {
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;
    NotilusCEF.sendMouseClick(x: x, y: y, button: 0, down: true);
    NotilusCEF.sendMouseClick(x: x, y: y, button: 0, down: false);
  },
  onPanUpdate: (details) {
    NotilusCEF.sendMouseMove(
      x: details.localPosition.dx,
      y: details.localPosition.dy,
    );
  },
  child: Texture(textureId: textureId!),
)
```

### Navigation et JavaScript

```dart
// Charger une URL
await NotilusCEF.loadUrl("https://example.com");

// Exécuter JavaScript
await NotilusCEF.evaluateJavaScript("console.log('Hello from Flutter!')");

// Navigation
await NotilusCEF.goBack();
await NotilusCEF.goForward();
await NotilusCEF.reload();

// Obtenir l'URL actuelle
final url = await NotilusCEF.getCurrentUrl();
```

## 🏗️ Architecture

```
notilus_cef/
├── lib/
│   └── notilus_cef.dart          # API Dart
├── windows/
│   ├── notilus_cef_plugin.cpp    # Bridge Flutter <-> CEF
│   ├── cef_handler.hpp/cpp       # Handler CEF (rendu offscreen)
│   ├── texture_bridge.hpp/cpp    # Bridge texture Flutter
│   ├── CMakeLists.txt            # Configuration build
│   └── cef/                       # CEF binaires (à télécharger)
```

## 🔧 Build

```bash
# Build Flutter
flutter build windows --release

# Les DLLs CEF seront copiées automatiquement dans le dossier de build
```

## ⚠️ Notes importantes

1. **Taille**: CEF ajoute ~100-200 MB à votre application
2. **Licence**: CEF utilise la licence BSD, compatible avec la plupart des projets
3. **Performance**: Le rendu est GPU-accelerated, mais nécessite un GPU compatible
4. **Threading**: CEF doit être initialisé sur le thread principal

## 🐛 Dépannage

### CEF non trouvé
- Vérifiez que CEF est extrait dans `windows/cef/`
- Vérifiez le chemin `CEF_ROOT` dans `CMakeLists.txt`

### Texture noire
- Vérifiez que CEF est initialisé (`init()` appelé)
- Vérifiez les logs CEF pour les erreurs

### Build échoue
- Vérifiez que Visual Studio 2022 avec C++ workload est installé
- Vérifiez que CMake 3.14+ est installé

## 📚 Ressources

- [CEF Documentation](https://bitbucket.org/chromiumembedded/cef/wiki/Home)
- [Flutter Desktop Plugins](https://docs.flutter.dev/development/platform-integration/desktop)
- [CEF Builds](https://cef-builds.spotifycdn.com/index.html)

