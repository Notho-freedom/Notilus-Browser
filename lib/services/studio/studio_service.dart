/// Service principal Notilus Studio
/// Coordonne tous les modules de test front-end
library studio_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../browser_engine.dart';
import '../../models/studio/viewport_preset.dart';
import '../../models/studio/studio_models.dart';
import 'responsive_tester_service.dart';
import 'screenshot_service.dart';
import 'live_editor_service.dart';
import 'interaction_recorder_service.dart';
import 'mockup_comparator_service.dart';

/// Service principal de Notilus Studio
class StudioService extends ChangeNotifier {
  BrowserEngine? _engine;
  String? _currentUrl;
  bool _isEnabled = false;
  StreamSubscription<String>? _messageSubscription;

  // Services enfants
  late final ResponsiveTesterService responsiveTester;
  late final StudioScreenshotService screenshot;
  late final LiveEditorService liveEditor;
  late final InteractionRecorderService interactionRecorder;
  late final MockupComparatorService mockupComparator;

  // État actuel
  StudioModule _activeModule = StudioModule.responsive;
  bool _isPanelVisible = false;

  StudioService() {
    responsiveTester = ResponsiveTesterService(this);
    screenshot = StudioScreenshotService(this);
    liveEditor = LiveEditorService(this);
    interactionRecorder = InteractionRecorderService(this);
    mockupComparator = MockupComparatorService(this);
    
    // Écouter les changements de tous les services enfants pour propager les mises à jour
    responsiveTester.addListener(_onServiceChanged);
    screenshot.addListener(_onServiceChanged);
    liveEditor.addListener(_onServiceChanged);
    interactionRecorder.addListener(_onServiceChanged);
    mockupComparator.addListener(_onServiceChanged);
  }
  
  /// Callback appelé quand un service enfant change
  void _onServiceChanged() {
    notifyListeners();
  }

  // Getters
  BrowserEngine? get engine => _engine;
  String? get currentUrl => _currentUrl;
  bool get isEnabled => _isEnabled;
  StudioModule get activeModule => _activeModule;
  bool get isPanelVisible => _isPanelVisible;

  /// Attache le service à un moteur de rendu
  void attachEngine(BrowserEngine engine) {
    if (_engine == engine) {
      debugPrint('⚠️ StudioService: Engine already attached');
      return;
    }
    
    // Nettoyer l'ancien
    _messageSubscription?.cancel();
    
    _engine = engine;
    
    // Écouter les messages du WebView
    _messageSubscription = engine.messageStream.listen((message) {
      _handleWebViewMessage(message);
    });
    
    // Attacher aux services
    responsiveTester.attachEngine(engine);
    screenshot.attachEngine(engine);
    liveEditor.attachEngine(engine);
    interactionRecorder.attachEngine(engine);
    mockupComparator.attachEngine(engine);
    
    debugPrint('✅ StudioService: Engine attached successfully. URL: $_currentUrl');
    notifyListeners();
  }
  
  /// Gère les messages provenant du WebView
  void _handleWebViewMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      
      switch (type) {
        case 'recorder_event':
          interactionRecorder.handleWebViewMessage(data);
          break;
        case 'element_selected':
          liveEditor.handleWebViewMessage(data);
          break;
        default:
          debugPrint('Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('Message parse error: $e');
    }
  }

  /// Détache le moteur
  void detachEngine() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _engine = null;
    
    // Détacher les moteurs des services enfants (ne pas retirer les listeners)
    responsiveTester.detachEngine();
    screenshot.detachEngine();
    liveEditor.detachEngine();
    interactionRecorder.detachEngine();
    mockupComparator.detachEngine();
    notifyListeners();
  }

  /// Active/désactive Studio
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      responsiveTester.disable();
      interactionRecorder.stopRecording();
    }
    notifyListeners();
  }

  /// Affiche/masque le panneau
  void togglePanel() {
    _isPanelVisible = !_isPanelVisible;
    notifyListeners();
  }

  void showPanel() {
    _isPanelVisible = true;
    notifyListeners();
  }

  void hidePanel() {
    _isPanelVisible = false;
    notifyListeners();
  }

  /// Change le module actif
  void setActiveModule(StudioModule module) {
    _activeModule = module;
    notifyListeners();
  }

  /// Met à jour l'URL courante
  void updateUrl(String url) {
    if (_currentUrl == url) {
      return; // Pas besoin de mettre à jour si c'est la même URL
    }
    _currentUrl = url;
    debugPrint('✅ StudioService: URL updated to: $url');
    liveEditor.onUrlChanged(url);
    notifyListeners();
  }

  /// Exécute du JavaScript dans le moteur
  Future<String?> executeScript(String script) async {
    if (_engine == null) {
      debugPrint('⚠️ StudioService: No engine attached. Current URL: $_currentUrl');
      return null;
    }
    try {
      final result = await _engine!.evaluateJavaScript(script);
      debugPrint('✅ StudioService: Script executed successfully');
      return result;
    } catch (e) {
      debugPrint('❌ StudioService executeScript error: $e');
      return null;
    }
  }
  
  /// Injecte un script dans la page (sans retour)
  Future<void> injectScript(String script) async {
    if (_engine == null) return;
    try {
      await _engine!.injectJavaScript(script);
    } catch (e) {
      debugPrint('❌ StudioService injectScript error: $e');
    }
  }

  /// Injecte un script et observe les résultats
  Stream<dynamic> injectAndWatch(String script, {Duration interval = const Duration(milliseconds: 500)}) {
    final controller = StreamController<dynamic>();
    Timer? timer;

    if (_engine != null) {
      timer = Timer.periodic(interval, (_) async {
        final result = await executeScript(script);
        if (result != null && !controller.isClosed) {
          controller.add(result);
        }
      });
    }

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    
    // Retirer les listeners avant de disposer
    responsiveTester.removeListener(_onServiceChanged);
    screenshot.removeListener(_onServiceChanged);
    liveEditor.removeListener(_onServiceChanged);
    interactionRecorder.removeListener(_onServiceChanged);
    mockupComparator.removeListener(_onServiceChanged);
    
    responsiveTester.dispose();
    screenshot.dispose();
    liveEditor.dispose();
    interactionRecorder.dispose();
    mockupComparator.dispose();
    super.dispose();
  }
}

/// Modules disponibles dans Studio
enum StudioModule {
  responsive,
  screenshot,
  liveEditor,
  mockupCompare,
  interactionRecorder,
}

extension StudioModuleExtension on StudioModule {
  String get displayName {
    switch (this) {
      case StudioModule.responsive:
        return 'Responsive Tester';
      case StudioModule.screenshot:
        return 'Screenshot Studio';
      case StudioModule.liveEditor:
        return 'Live Editor';
      case StudioModule.mockupCompare:
        return 'Mockup Compare';
      case StudioModule.interactionRecorder:
        return 'Interaction Recorder';
    }
  }

  String get shortName {
    switch (this) {
      case StudioModule.responsive:
        return 'Responsive';
      case StudioModule.screenshot:
        return 'Screenshot';
      case StudioModule.liveEditor:
        return 'Editor';
      case StudioModule.mockupCompare:
        return 'Compare';
      case StudioModule.interactionRecorder:
        return 'Recorder';
    }
  }
}

