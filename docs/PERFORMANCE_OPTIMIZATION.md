# Performance Optimization Guide - Notilus Browser

Ce document décrit les optimisations de performance implémentées dans Notilus Browser et les meilleures pratiques à suivre.

## ✅ Optimisations implémentées

### 1. Rendu WebView2 HD
- **DevicePixelRatio forcé** : Minimum 2x pour rendu haute définition
- **GPU Acceleration** : Activée avec fond transparent
- **Font Smoothing** : Antialiasing avec `text-rendering: optimizeLegibility`
- **Image Rendering** : Optimisé avec `image-rendering: -webkit-optimize-contrast`

### 2. Services avec ChangeNotifier
- Tous les services étendent `ChangeNotifier`
- `notifyListeners()` appelé après chaque modification d'état
- Propagation correcte des changements aux widgets

### 3. Studio Services
- Services enfants propagent les changements au service parent
- WebViews gérés efficacement avec limite de 2 viewports actifs
- Capture d'écran asynchrone avec html2canvas

### 4. Settings Service
- Persistance avec `SharedPreferences`
- `notifyListeners()` après chaque modification
- Initialisation asynchrone optimisée

## 🚀 Optimisations recommandées à implémenter

### 1. Constructeurs const
Ajouter `const` aux constructeurs de widgets qui ne changent pas :

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key}); // Ajouter const
  
  @override
  Widget build(BuildContext context) {
    return const Text('Hello'); // Ajouter const
  }
}
```

### 2. RepaintBoundary
Utiliser `RepaintBoundary` pour isoler les widgets coûteux :

```dart
RepaintBoundary(
  child: ComplexAnimatedWidget(),
)
```

### 3. Selector au lieu de Consumer
Utiliser `Selector` pour écouter seulement les propriétés nécessaires :

```dart
// ❌ Moins performant - rebuild complet
Consumer<StudioService>(
  builder: (context, studio, child) => ...
)

// ✅ Plus performant - rebuild seulement si isEnabled change
Selector<StudioService, bool>(
  selector: (context, studio) => studio.isEnabled,
  builder: (context, isEnabled, child) => ...
)
```

### 4. Lazy Loading des onglets
Implémenter le chargement différé des WebViews inactifs :

```dart
// Dans TabWebViewManager
void setTabActive(String tabId, bool active) {
  final tab = _tabs[tabId];
  if (tab != null) {
    if (!active && !tab.isPinned) {
      // Suspendre le WebView après 5 minutes d'inactivité
      _scheduleSuspend(tabId);
    } else {
      // Réactiver le WebView
      _cancelSuspend(tabId);
    }
  }
}
```

### 5. Libération automatique de mémoire
Limiter le nombre de WebViews actifs :

```dart
// Dans TabWebViewManager
static const int _maxActiveWebViews = 10;

void _enforceWebViewLimit() {
  if (_activeWebViews.length > _maxActiveWebViews) {
    // Suspendre les onglets les moins récemment utilisés
    final sorted = _activeWebViews.values.toList()
      ..sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
    
    for (var i = 0; i < sorted.length - _maxActiveWebViews; i++) {
      _suspendWebView(sorted[i].id);
    }
  }
}
```

### 6. Optimisation du démarrage
Charger les services de manière asynchrone :

```dart
// Dans main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger les services critiques en parallèle
  await Future.wait([
    settingsService.initialize(),
    mosaicService.initialize(),
  ]);
  
  // Pré-chauffer un WebView en arrière-plan
  Future.delayed(Duration(seconds: 1), () {
    TabWebViewManager().prewarmWebView();
  });
  
  runApp(MyApp());
}
```

### 7. Cache des ressources
Mettre en cache les ressources fréquemment utilisées :

```dart
class CachedResourceManager {
  final Map<String, dynamic> _cache = {};
  
  Future<dynamic> getCached(String key, Future<dynamic> Function() fetch) async {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    
    final result = await fetch();
    _cache[key] = result;
    return result;
  }
}
```

### 8. Debouncing des événements
Limiter la fréquence des mises à jour coûteuses :

```dart
class DebouncedNotifier extends ChangeNotifier {
  Timer? _debounceTimer;
  
  void notifyListenersDebounced([Duration delay = const Duration(milliseconds: 300)]) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      notifyListeners();
    });
  }
}
```

### 9. Virtual Scrolling
Pour les longues listes, utiliser `ListView.builder` :

```dart
// ❌ Moins performant
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// ✅ Plus performant
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### 10. Cleanup dans dispose()
Toujours nettoyer les ressources :

```dart
@override
void dispose() {
  _timer?.cancel();
  _subscription?.cancel();
  _controller.dispose();
  super.dispose();
}
```

## 📊 Mesure des performances

### Flutter DevTools
Utiliser Flutter DevTools pour analyser les performances :

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Performance Overlay
Activer l'overlay de performance en mode debug :

```dart
MaterialApp(
  showPerformanceOverlay: true,
  ...
)
```

### Profiling
Profiler les opérations coûteuses :

```dart
Timeline.startSync('expensive_operation');
// ... code ...
Timeline.finishSync();
```

## 🎯 Métriques cibles

- **Temps de démarrage** : < 2 secondes
- **Temps de chargement d'onglet** : < 1 seconde
- **FPS** : 60 fps constant
- **Utilisation mémoire** : < 500 MB pour 10 onglets
- **Temps de réponse UI** : < 100ms

## 📝 Checklist avant release

- [ ] Tous les constructeurs possibles sont `const`
- [ ] `RepaintBoundary` utilisé pour les widgets animés coûteux
- [ ] `Selector` utilisé au lieu de `Consumer` quand possible
- [ ] Lazy loading implémenté pour les onglets
- [ ] Limite du nombre de WebViews actifs
- [ ] Cleanup correct dans tous les `dispose()`
- [ ] Pas de `setState()` après `dispose()`
- [ ] Performance testée avec Flutter DevTools
- [ ] Profiling effectué sur les opérations critiques
- [ ] Métriques cibles atteintes
