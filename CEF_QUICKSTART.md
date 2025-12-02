# 🚀 CEF Offscreen - Quick Start

Guide rapide pour démarrer avec le moteur CEF offscreen de Notilus Browser.

## ⚡ Setup en 5 minutes

### 1. Télécharger CEF

```bash
# Téléchargez depuis https://cef-builds.spotifycdn.com/
# Version: CEF 120.x Windows x64 Standard Distribution
# Extrayez dans: notilus_cef/windows/cef/
```

### 2. Installer le plugin

```bash
flutter pub get
```

### 3. Build

```bash
flutter build windows --release
```

## 💻 Utilisation minimale

```dart
import 'package:notilus_cef/notilus_cef.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CefExample(),
    );
  }
}

class CefExample extends StatefulWidget {
  @override
  _CefExampleState createState() => _CefExampleState();
}

class _CefExampleState extends State<CefExample> {
  int? textureId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    textureId = await NotilusCEF.init(
      width: 1280,
      height: 720,
      initialUrl: "https://flutter.dev",
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (textureId == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      body: Texture(textureId: textureId!),
    );
  }
}
```

## 🎨 Avec transformations 3D

```dart
Transform(
  alignment: Alignment.center,
  transform: Matrix4.identity()
    ..rotateX(-0.1)
    ..rotateY(0.05),
  child: Texture(textureId: textureId!),
)
```

## 📚 Documentation complète

Voir [docs/CEF_SETUP.md](docs/CEF_SETUP.md) pour la documentation complète.

## 🐛 Problèmes courants

### CEF non trouvé
→ Vérifiez que `notilus_cef/windows/cef/CMakeLists.txt` existe

### Texture noire
→ Vérifiez que `init()` a réussi et que l'URL est valide

### Build échoue
→ Vérifiez Visual Studio 2022 avec C++ workload

---

**Prêt à créer des interfaces 3D incroyables ! 🚀**

