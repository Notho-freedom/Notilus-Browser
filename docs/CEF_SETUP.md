# 🚀 Setup CEF Offscreen Rendering - Notilus Browser

Guide complet pour configurer le moteur CEF offscreen avec rendu dans texture Flutter native.

## 📋 Vue d'ensemble

Le plugin `notilus_cef` permet d'afficher du contenu web rendu par Chromium Embedded Framework dans une texture Flutter native, permettant :

- ✅ Transformations 3D (Matrix4)
- ✅ Shaders personnalisés
- ✅ Blur et effets visuels
- ✅ Animations fluides sans latence
- ✅ 60 FPS GPU-accelerated
- ✅ Rendu 100% Flutter (pas d'overlay)

## 🔧 Installation

### Étape 1 : Télécharger CEF

1. Allez sur [cef-builds.spotifycdn.com](https://cef-builds.spotifycdn.com/index.html)
2. Téléchargez la version **CEF 120.x ou supérieur** pour **Windows x64**
3. Choisissez la version **Standard Distribution** (pas Debug Symbols)

**Exemple de version** : `cef_binary_120.1.8+g04c8c56+chromium-120.0.6099.109_windows64`

### Étape 2 : Extraire CEF

Extrayez l'archive dans le dossier du plugin :

```
notilus_cef/
└── windows/
    └── cef/                    ← Extraire ici
        ├── CMakeLists.txt
        ├── include/
        │   └── cef/
        ├── Release/
        │   ├── libcef.dll
        │   ├── chrome_elf.dll
        │   ├── icudtl.dat
        │   ├── snapshot_blob.bin
        │   ├── v8_context_snapshot.bin
        │   ├── locales/
        │   │   ├── en-US.pak
        │   │   └── ...
        │   └── swiftshader/
        │       ├── libEGL.dll
        │       └── libGLESv2.dll
        └── ...
```

### Étape 3 : Vérifier la structure

La structure doit être exactement :

```
notilus_cef/windows/cef/CMakeLists.txt  ← Doit exister
notilus_cef/windows/cef/include/cef/   ← Headers CEF
notilus_cef/windows/cef/Release/        ← DLLs et ressources
```

### Étape 4 : Build le projet

```bash
# Installer les dépendances
flutter pub get

# Build Windows
flutter build windows --release
```

Les DLLs CEF seront automatiquement copiées dans le dossier de build.

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Flutter Widget                  │
│      (Texture + Transform)              │
└──────────────┬──────────────────────────┘
               │ textureId
               ▼
┌─────────────────────────────────────────┐
│      notilus_cef.dart (Dart API)        │
│  - init() → textureId                   │
│  - loadUrl(), sendInput(), etc.         │
└──────────────┬──────────────────────────┘
               │ MethodChannel
               ▼
┌─────────────────────────────────────────┐
│   notilus_cef_plugin.cpp (C++ Bridge)   │
│   - Gère les appels Flutter             │
│   - Initialise CEF                      │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
┌──────────────┐  ┌──────────────┐
│ BrowserHandler│  │TextureBridge │
│ (CEF Client) │  │ (Flutter)    │
└──────┬───────┘  └──────┬───────┘
       │                 │
       │ OnPaint()       │ UpdateTexture()
       │ (BGRA buffer)   │ (RGBA texture)
       └────────┬────────┘
                ▼
        ┌───────────────┐
        │  CEF Browser  │
        │  (Chromium)   │
        └───────────────┘
```

## 💻 Utilisation

### Exemple basique

```dart
import 'package:notilus_cef/notilus_cef.dart';
import 'package:flutter/material.dart';

class MyCefView extends StatefulWidget {
  @override
  _MyCefViewState createState() => _MyCefViewState();
}

class _MyCefViewState extends State<MyCefView> {
  int? textureId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
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
Transform(
  alignment: Alignment.center,
  transform: Matrix4.identity()
    ..rotateX(-0.1)
    ..rotateY(0.05)
    ..setEntry(3, 2, 0.001), // Perspective
  child: Texture(textureId: textureId!),
)
```

### Widget CefView prêt à l'emploi

```dart
import 'package:notilus/widgets/browser/cef_view.dart';

CefView(
  initialUrl: "https://example.com",
  width: 1920,
  height: 1080,
  transform: Matrix4.identity()..rotateY(0.1),
  onUrlChanged: (url) => print("URL: $url"),
)
```

## 🎨 Effets visuels avancés

### Coverflow 3D

```dart
CoverflowCefView(
  urls: [
    "https://flutter.dev",
    "https://dart.dev",
    "https://pub.dev",
  ],
  currentIndex: 0,
)
```

### Blur et effets

```dart
import 'dart:ui';

Stack(
  children: [
    // Version floutée en arrière-plan
    ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Texture(textureId: textureId!),
    ),
    // Version nette au premier plan
    Texture(textureId: textureId!),
  ],
)
```

## 🔌 API complète

### Navigation

```dart
// Charger une URL
await NotilusCEF.loadUrl("https://example.com");

// Navigation
await NotilusCEF.goBack();
await NotilusCEF.goForward();
await NotilusCEF.reload();
await NotilusCEF.stop();

// Obtenir l'URL actuelle
final url = await NotilusCEF.getCurrentUrl();
```

### Input

```dart
// Souris
NotilusCEF.sendMouseClick(x: 100, y: 200, button: 0, down: true);
NotilusCEF.sendMouseMove(x: 150, y: 250);

// Clavier
NotilusCEF.sendKey(0x41, down: true); // 'A'
NotilusCEF.sendText("Hello World");
```

### JavaScript

```dart
// Exécuter du JavaScript
await NotilusCEF.evaluateJavaScript("console.log('Hello!')");

// Obtenir une valeur
final result = await NotilusCEF.evaluateJavaScript("document.title");
```

### Redimensionnement

```dart
await NotilusCEF.resize(2560, 1440);
```

## ⚙️ Configuration

### Chemins CEF personnalisés

Si CEF est installé ailleurs, modifiez `notilus_cef/windows/CMakeLists.txt` :

```cmake
set(CEF_ROOT "C:/path/to/cef" CACHE PATH "Chemin vers CEF")
```

### Paramètres CEF

Modifiez `notilus_cef_plugin.cpp` pour ajuster :

```cpp
CefSettings settings;
settings.windowless_rendering_enabled = true;
settings.no_sandbox = true;
settings.multi_threaded_message_loop = false;
settings.log_severity = LOGSEVERITY_WARNING;
```

## 🐛 Dépannage

### Erreur : "CEF non trouvé"

**Solution** :
1. Vérifiez que CEF est dans `notilus_cef/windows/cef/`
2. Vérifiez que `CMakeLists.txt` existe dans ce dossier
3. Vérifiez le chemin dans `CMakeLists.txt` du plugin

### Erreur : "Texture noire"

**Solutions** :
1. Vérifiez que `init()` a été appelé et a réussi
2. Vérifiez les logs CEF (dans la console)
3. Vérifiez que l'URL est valide
4. Vérifiez que les DLLs CEF sont copiées dans le dossier de build

### Erreur : "Build échoue"

**Solutions** :
1. Vérifiez Visual Studio 2022 avec C++ workload
2. Vérifiez CMake 3.14+
3. Vérifiez que CEF est compatible avec votre version de Visual Studio
4. Nettoyez le build : `flutter clean && flutter pub get`

### Performance faible

**Optimisations** :
1. Réduisez la résolution si nécessaire
2. Désactivez les effets visuels lourds
3. Vérifiez que le GPU est utilisé (pas de software rendering)

## 📊 Performance

### Résultats attendus

- **FPS** : 60 FPS stable
- **Latence** : < 16ms (1 frame)
- **Mémoire** : ~200-300 MB par instance CEF
- **CPU** : 5-15% (selon le contenu)

### Optimisations

1. **Résolution adaptative** : Réduire la résolution sur petits écrans
2. **Lazy loading** : Initialiser CEF seulement quand nécessaire
3. **Pooling** : Réutiliser les instances CEF
4. **Cache** : Utiliser le cache CEF pour les ressources

## 🔒 Sécurité

### Sandbox

Par défaut, `no_sandbox = true` pour simplifier. Pour la production :

```cpp
settings.no_sandbox = false;
// Nécessite des permissions supplémentaires
```

### Permissions

CEF peut nécessiter :
- Accès réseau
- Accès fichiers (pour le cache)
- Accès GPU (pour le rendu)

## 📚 Ressources

- [CEF Documentation](https://bitbucket.org/chromiumembedded/cef/wiki/Home)
- [CEF Builds](https://cef-builds.spotifycdn.com/index.html)
- [Flutter Desktop Plugins](https://docs.flutter.dev/development/platform-integration/desktop)
- [CEF Forum](https://magpcss.org/ceforum/)

## 🎯 Prochaines étapes

1. ✅ Setup CEF complet
2. ✅ Plugin fonctionnel
3. 🔄 Intégration dans le navigateur principal
4. 🔄 Support multi-onglets
5. 🔄 DevTools intégrés
6. 🔄 Extensions Chrome

---

**Note** : Ce setup est optimisé pour Windows. Pour macOS/Linux, des ajustements seront nécessaires.

