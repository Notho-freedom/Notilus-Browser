# Migration DevTools - Notilus Browser

## Situation actuelle

**Problème** : `webview_windows: ^0.2.0` ne supporte **pas** les DevTools natifs (F12).

Le package `webview_windows` 0.2.0 est une version minimale qui n'expose pas les APIs WebView2 nécessaires pour ouvrir les DevTools.

## Solutions disponibles

### ✅ Solution 1 : `webview2_wrapper` (Recommandé)

**Avantages** :
- Support complet des DevTools WebView2
- API plus complète
- Maintenance active

**Migration** :
```yaml
# pubspec.yaml
dependencies:
  # Remplacer
  # webview_windows: ^0.2.0
  # Par
  webview2_wrapper: ^0.1.0
```

**Code** :
```dart
// Dans webview2_browser_engine.dart
import 'package:webview2_wrapper/webview2_wrapper.dart';

// Ouvrir les DevTools
await controller.openDevToolsWindow();
```

### 🔥 Solution 2 : Plugin Custom WebView2 (Idéal pour Notilus)

Créer un plugin Flutter custom qui wrappe directement les APIs WebView2 natives :

**Avantages** :
- Contrôle total sur les fonctionnalités
- DevTools natifs
- Gestion des events `OnNewWindowRequest`
- Debug console native
- Injection JS améliorée

**Structure** :
```
notilus_webview2/
├── lib/
│   └── notilus_webview2.dart
├── windows/
│   └── notilus_webview2_plugin.cpp
└── pubspec.yaml
```

**API WebView2 native** :
```cpp
// Ouvrir DevTools
ICoreWebView2* webView = ...;
webView->OpenDevToolsWindow();
```

### 🚀 Solution 3 : CEF (Chromium Embedded Framework)

**Avantages** :
- DevTools complets (comme Chrome)
- Extensions Chrome
- Debug réseau avancé
- Mode navigateur professionnel

**Inconvénients** :
- Plus complexe à intégrer
- Taille binaire plus importante

**Package** : `cef_flutter` ou `webview_cef`

## Implémentation actuelle

Le raccourci **F12** est maintenant configuré dans `ModernBrowserWindow` et appelle `engine.openDevTools()`.

**Comportement actuel** :
- F12 est capturé ✅
- Un message d'avertissement est affiché dans la console
- Les DevTools ne s'ouvrent pas (limitation du package)

## Prochaines étapes recommandées

1. **Court terme** : Migrer vers `webview2_wrapper` pour avoir les DevTools rapidement
2. **Moyen terme** : Créer un plugin custom `notilus_webview2` pour un contrôle total
3. **Long terme** : Évaluer CEF pour un navigateur professionnel complet

## Code de migration vers webview2_wrapper

### 1. Mettre à jour `pubspec.yaml`
```yaml
dependencies:
  webview2_wrapper: ^0.1.0
```

### 2. Modifier `webview2_browser_engine.dart`
```dart
import 'package:webview2_wrapper/webview2_wrapper.dart';

class WebView2BrowserEngine extends BrowserEngine {
  WebView2Controller? _webView;
  
  @override
  Future<void> openDevTools() async {
    if (_webView != null) {
      await _webView!.openDevToolsWindow();
    }
  }
}
```

### 3. Tester
- Appuyer sur F12
- Les DevTools WebView2 devraient s'ouvrir dans une fenêtre séparée

## Notes techniques

- WebView2 (Edge) a les DevTools intégrés
- Le problème est que `webview_windows` 0.2.0 ne les expose pas
- Les APIs natives WebView2 supportent `OpenDevToolsWindow()`
- Un plugin custom peut accéder directement à ces APIs via FFI

