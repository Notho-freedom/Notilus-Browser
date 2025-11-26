/// Service principal Notilus Studio
/// Coordonne tous les modules de test front-end
library studio_service;

import 'dart:async';
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
  }

  // Getters
  BrowserEngine? get engine => _engine;
  String? get currentUrl => _currentUrl;
  bool get isEnabled => _isEnabled;
  StudioModule get activeModule => _activeModule;
  bool get isPanelVisible => _isPanelVisible;

  /// Attache le service à un moteur de rendu
  void attachEngine(BrowserEngine engine) {
    _engine = engine;
    responsiveTester.attachEngine(engine);
    screenshot.attachEngine(engine);
    liveEditor.attachEngine(engine);
    interactionRecorder.attachEngine(engine);
    mockupComparator.attachEngine(engine);
    notifyListeners();
  }

  /// Détache le moteur
  void detachEngine() {
    _engine = null;
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
    _currentUrl = url;
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

