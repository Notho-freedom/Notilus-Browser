/// Service d'enregistrement d'interactions pour Notilus Studio
/// Enregistre les interactions utilisateur et génère des tests automatisés
library interaction_recorder_service;

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../browser_engine.dart';
import '../../models/studio/studio_models.dart';
import 'studio_service.dart';

/// Service d'enregistrement d'interactions
class InteractionRecorderService extends ChangeNotifier {
  final StudioService _studioService;
  BrowserEngine? _engine;

  // Session d'enregistrement
  RecordingSession? _currentSession;
  bool _isRecording = false;
  Stopwatch? _stopwatch;
  Timer? _durationTimer;

  // Configuration
  bool _recordClicks = true;
  bool _recordTyping = true;
  bool _recordScrolls = true;
  bool _recordHovers = false;
  bool _recordNavigation = true;
  bool _maskPasswords = true;

  InteractionRecorderService(this._studioService);

  // Getters
  RecordingSession? get currentSession => _currentSession;
  bool get isRecording => _isRecording;
  Duration get recordingDuration =>
      _stopwatch?.elapsed ?? Duration.zero;
  List<RecordedInteraction> get interactions =>
      _currentSession?.interactions ?? [];
  int get eventCount => _currentSession?.eventCount ?? 0;

  // Configuration getters
  bool get recordClicks => _recordClicks;
  bool get recordTyping => _recordTyping;
  bool get recordScrolls => _recordScrolls;
  bool get recordHovers => _recordHovers;
  bool get recordNavigation => _recordNavigation;
  bool get maskPasswords => _maskPasswords;

  void attachEngine(BrowserEngine engine) {
    _engine = engine;
    notifyListeners();
  }

  void detachEngine() {
    _engine = null;
    stopRecording();
    notifyListeners();
  }

  // Configuration setters
  void setRecordClicks(bool value) {
    _recordClicks = value;
    notifyListeners();
  }

  void setRecordTyping(bool value) {
    _recordTyping = value;
    notifyListeners();
  }

  void setRecordScrolls(bool value) {
    _recordScrolls = value;
    notifyListeners();
  }

  void setRecordHovers(bool value) {
    _recordHovers = value;
    notifyListeners();
  }

  void setRecordNavigation(bool value) {
    _recordNavigation = value;
    notifyListeners();
  }

  void setMaskPasswords(bool value) {
    _maskPasswords = value;
    notifyListeners();
  }

  /// Démarre l'enregistrement
  Future<void> startRecording() async {
    if (_isRecording) return;

    _isRecording = true;
    _stopwatch = Stopwatch()..start();

    _currentSession = RecordingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: _studioService.currentUrl ?? '',
      startTime: DateTime.now(),
      duration: Duration.zero,
      isRecording: true,
    );

    // Mettre à jour la durée périodiquement
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      notifyListeners();
    });

    // Injecter le script d'enregistrement
    await _injectRecorderScript();

    notifyListeners();
  }

  /// Met en pause l'enregistrement
  void pauseRecording() {
    if (!_isRecording) return;

    _stopwatch?.stop();
    _isRecording = false;
    _durationTimer?.cancel();
    notifyListeners();
  }

  /// Reprend l'enregistrement
  void resumeRecording() {
    if (_isRecording || _currentSession == null) return;

    _stopwatch?.start();
    _isRecording = true;

    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      notifyListeners();
    });

    notifyListeners();
  }

  /// Arrête l'enregistrement
  Future<void> stopRecording() async {
    if (_currentSession == null) return;

    _isRecording = false;
    _stopwatch?.stop();
    _durationTimer?.cancel();

    // Retirer le script d'enregistrement
    await _removeRecorderScript();

    // Mettre à jour la session finale
    _currentSession = _currentSession!.copyWith(
      duration: recordingDuration,
      isRecording: false,
    );

    notifyListeners();
  }

  /// Ajoute une assertion manuelle
  void addAssertion(String selector, {String? expectedText}) {
    if (_currentSession == null || !_isRecording) return;

    _addInteraction(RecordedInteraction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: InteractionEventType.assertion,
      timestamp: recordingDuration,
      selector: selector,
      value: expectedText,
      metadata: {'assertionType': expectedText != null ? 'text' : 'visible'},
    ));
  }

  /// Ajoute une capture d'écran dans l'enregistrement
  void addScreenshot() {
    if (_currentSession == null || !_isRecording) return;

    _addInteraction(RecordedInteraction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: InteractionEventType.screenshot,
      timestamp: recordingDuration,
    ));
  }

  /// Ajoute une attente dans l'enregistrement
  void addWait(Duration duration) {
    if (_currentSession == null || !_isRecording) return;

    _addInteraction(RecordedInteraction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: InteractionEventType.wait,
      timestamp: duration,
    ));
  }

  /// Supprime une interaction
  void removeInteraction(String id) {
    if (_currentSession == null) return;

    final updatedInteractions = List<RecordedInteraction>.from(
        _currentSession!.interactions)
      ..removeWhere((i) => i.id == id);

    _currentSession = _currentSession!.copyWith(
      interactions: updatedInteractions,
    );

    notifyListeners();
  }

  /// Efface l'enregistrement actuel
  void clearRecording() {
    _currentSession = null;
    _stopwatch = null;
    _isRecording = false;
    _durationTimer?.cancel();
    notifyListeners();
  }

  /// Exporte en code Playwright
  String exportPlaywright({String testName = 'Recorded Test'}) {
    return _currentSession?.exportPlaywright(testName: testName) ?? '';
  }

  /// Exporte en code Cypress
  String exportCypress({String testName = 'Recorded Test'}) {
    return _currentSession?.exportCypress(testName: testName) ?? '';
  }

  /// Exporte en code Puppeteer
  String exportPuppeteer({String testName = 'Recorded Test'}) {
    if (_currentSession == null) return '';

    final buffer = StringBuffer();
    buffer.writeln("const puppeteer = require('puppeteer');");
    buffer.writeln();
    buffer.writeln("(async () => {");
    buffer.writeln("  const browser = await puppeteer.launch();");
    buffer.writeln("  const page = await browser.newPage();");
    buffer.writeln("  await page.goto('${_currentSession!.url}');");
    buffer.writeln();

    for (final interaction in _currentSession!.interactions) {
      buffer.writeln('  ${_toPuppeteer(interaction)}');
    }

    buffer.writeln();
    buffer.writeln("  await browser.close();");
    buffer.writeln("})();");

    return buffer.toString();
  }

  /// Exporte en code Selenium
  String exportSelenium({String testName = 'Recorded Test'}) {
    if (_currentSession == null) return '';

    final buffer = StringBuffer();
    buffer.writeln("from selenium import webdriver");
    buffer.writeln("from selenium.webdriver.common.by import By");
    buffer.writeln("from selenium.webdriver.common.keys import Keys");
    buffer.writeln("import time");
    buffer.writeln();
    buffer.writeln("driver = webdriver.Chrome()");
    buffer.writeln("driver.get('${_currentSession!.url}')");
    buffer.writeln();

    for (final interaction in _currentSession!.interactions) {
      buffer.writeln(_toSelenium(interaction));
    }

    buffer.writeln();
    buffer.writeln("driver.quit()");

    return buffer.toString();
  }

  /// Traite les messages du WebView
  void handleWebViewMessage(Map<String, dynamic> message) {
    if (message['type'] == 'recorder_event' && _isRecording) {
      final eventType = _parseEventType(message['eventType'] as String);
      if (!_shouldRecordEvent(eventType)) return;

      String? value = message['value'] as String?;

      // Masquer les mots de passe
      if (_maskPasswords &&
          eventType == InteractionEventType.type &&
          (message['inputType'] as String?) == 'password') {
        value = '********';
      }

      _addInteraction(RecordedInteraction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: eventType,
        timestamp: recordingDuration,
        selector: message['selector'] as String?,
        value: value,
        position: message['x'] != null && message['y'] != null
            ? Offset(
                (message['x'] as num).toDouble(),
                (message['y'] as num).toDouble(),
              )
            : null,
        viewportSize: message['viewportWidth'] != null
            ? Size(
                (message['viewportWidth'] as num).toDouble(),
                (message['viewportHeight'] as num).toDouble(),
              )
            : null,
        metadata: message['metadata'] as Map<String, dynamic>?,
      ));
    }
  }

  /// Injecte le script d'enregistrement
  Future<void> _injectRecorderScript() async {
    await _studioService.injectScript('''
      (function() {
        if (window.__notilusRecorder) return;
        
        window.__notilusRecorder = {
          init: function() {
            document.addEventListener('click', this.onClick.bind(this), true);
            document.addEventListener('dblclick', this.onDoubleClick.bind(this), true);
            document.addEventListener('contextmenu', this.onRightClick.bind(this), true);
            document.addEventListener('input', this.onInput.bind(this), true);
            document.addEventListener('scroll', this.onScroll.bind(this), true);
            ${_recordHovers ? "document.addEventListener('mouseover', this.onHover.bind(this), true);" : ""}
            window.addEventListener('resize', this.onResize.bind(this), true);
          },
          
          getSelector: function(el) {
            if (el.id) return '#' + el.id;
            if (el.name) return el.tagName.toLowerCase() + '[name="' + el.name + '"]';
            if (el.className) {
              const classes = el.className.split(' ').filter(c => c).slice(0, 2).join('.');
              return el.tagName.toLowerCase() + '.' + classes;
            }
            return el.tagName.toLowerCase();
          },
          
          sendEvent: function(eventType, el, extra) {
            const data = {
              type: 'recorder_event',
              eventType: eventType,
              selector: el ? this.getSelector(el) : null,
              timestamp: Date.now(),
              ...extra
            };
            window.chrome.webview.postMessage(JSON.stringify(data));
          },
          
          onClick: function(e) {
            this.sendEvent('click', e.target, {
              x: e.clientX,
              y: e.clientY
            });
          },
          
          onDoubleClick: function(e) {
            this.sendEvent('doubleClick', e.target, {
              x: e.clientX,
              y: e.clientY
            });
          },
          
          onRightClick: function(e) {
            this.sendEvent('rightClick', e.target, {
              x: e.clientX,
              y: e.clientY
            });
          },
          
          onInput: function(e) {
            const el = e.target;
            if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
              this.sendEvent('type', el, {
                value: el.value,
                inputType: el.type
              });
            }
          },
          
          onScroll: function(e) {
            this.sendEvent('scroll', null, {
              x: window.scrollX,
              y: window.scrollY
            });
          },
          
          onHover: function(e) {
            this.sendEvent('hover', e.target, {
              x: e.clientX,
              y: e.clientY
            });
          },
          
          onResize: function(e) {
            this.sendEvent('resize', null, {
              viewportWidth: window.innerWidth,
              viewportHeight: window.innerHeight
            });
          },
          
          destroy: function() {
            document.removeEventListener('click', this.onClick, true);
            document.removeEventListener('dblclick', this.onDoubleClick, true);
            document.removeEventListener('contextmenu', this.onRightClick, true);
            document.removeEventListener('input', this.onInput, true);
            document.removeEventListener('scroll', this.onScroll, true);
            document.removeEventListener('mouseover', this.onHover, true);
            window.removeEventListener('resize', this.onResize, true);
            delete window.__notilusRecorder;
          }
        };
        
        window.__notilusRecorder.init();
      })();
    ''');
  }

  /// Retire le script d'enregistrement
  Future<void> _removeRecorderScript() async {
    await _studioService.injectScript('''
      (function() {
        if (window.__notilusRecorder) {
          window.__notilusRecorder.destroy();
        }
      })();
    ''');
  }

  /// Vérifie si un type d'événement doit être enregistré
  bool _shouldRecordEvent(InteractionEventType type) {
    switch (type) {
      case InteractionEventType.click:
      case InteractionEventType.doubleClick:
      case InteractionEventType.rightClick:
        return _recordClicks;
      case InteractionEventType.type:
        return _recordTyping;
      case InteractionEventType.scroll:
        return _recordScrolls;
      case InteractionEventType.hover:
        return _recordHovers;
      case InteractionEventType.navigate:
        return _recordNavigation;
      default:
        return true;
    }
  }

  /// Parse le type d'événement depuis une chaîne
  InteractionEventType _parseEventType(String type) {
    switch (type) {
      case 'click':
        return InteractionEventType.click;
      case 'doubleClick':
        return InteractionEventType.doubleClick;
      case 'rightClick':
        return InteractionEventType.rightClick;
      case 'type':
        return InteractionEventType.type;
      case 'scroll':
        return InteractionEventType.scroll;
      case 'hover':
        return InteractionEventType.hover;
      case 'focus':
        return InteractionEventType.focus;
      case 'blur':
        return InteractionEventType.blur;
      case 'resize':
        return InteractionEventType.resize;
      case 'navigate':
        return InteractionEventType.navigate;
      default:
        return InteractionEventType.click;
    }
  }

  /// Ajoute une interaction à la session
  void _addInteraction(RecordedInteraction interaction) {
    if (_currentSession == null) return;

    final updatedInteractions = List<RecordedInteraction>.from(
        _currentSession!.interactions)
      ..add(interaction);

    _currentSession = _currentSession!.copyWith(
      interactions: updatedInteractions,
    );

    notifyListeners();
  }

  /// Convertit en code Puppeteer
  String _toPuppeteer(RecordedInteraction interaction) {
    switch (interaction.type) {
      case InteractionEventType.click:
        return "await page.click('${interaction.selector}');";
      case InteractionEventType.doubleClick:
        return "await page.click('${interaction.selector}', { clickCount: 2 });";
      case InteractionEventType.type:
        return "await page.type('${interaction.selector}', '${interaction.value ?? ''}');";
      case InteractionEventType.scroll:
        return "await page.evaluate(() => window.scrollTo(${interaction.position?.dx.round() ?? 0}, ${interaction.position?.dy.round() ?? 0}));";
      case InteractionEventType.hover:
        return "await page.hover('${interaction.selector}');";
      case InteractionEventType.navigate:
        return "await page.goto('${interaction.value ?? ''}');";
      case InteractionEventType.resize:
        return "await page.setViewport({ width: ${interaction.viewportSize?.width.round() ?? 1920}, height: ${interaction.viewportSize?.height.round() ?? 1080} });";
      case InteractionEventType.wait:
        return "await page.waitForTimeout(${interaction.timestamp.inMilliseconds});";
      case InteractionEventType.screenshot:
        return "await page.screenshot({ path: 'screenshot_${interaction.id}.png' });";
      case InteractionEventType.assertion:
        return "await page.waitForSelector('${interaction.selector}');";
      default:
        return "// ${interaction.type.displayName}";
    }
  }

  /// Convertit en code Selenium
  String _toSelenium(RecordedInteraction interaction) {
    switch (interaction.type) {
      case InteractionEventType.click:
        return "driver.find_element(By.CSS_SELECTOR, '${interaction.selector}').click()";
      case InteractionEventType.doubleClick:
        return "from selenium.webdriver.common.action_chains import ActionChains\nActionChains(driver).double_click(driver.find_element(By.CSS_SELECTOR, '${interaction.selector}')).perform()";
      case InteractionEventType.type:
        return "driver.find_element(By.CSS_SELECTOR, '${interaction.selector}').send_keys('${interaction.value ?? ''}')";
      case InteractionEventType.scroll:
        return "driver.execute_script('window.scrollTo(${interaction.position?.dx.round() ?? 0}, ${interaction.position?.dy.round() ?? 0})')";
      case InteractionEventType.navigate:
        return "driver.get('${interaction.value ?? ''}')";
      case InteractionEventType.resize:
        return "driver.set_window_size(${interaction.viewportSize?.width.round() ?? 1920}, ${interaction.viewportSize?.height.round() ?? 1080})";
      case InteractionEventType.wait:
        return "time.sleep(${interaction.timestamp.inMilliseconds / 1000})";
      case InteractionEventType.screenshot:
        return "driver.save_screenshot('screenshot_${interaction.id}.png')";
      case InteractionEventType.assertion:
        return "assert driver.find_element(By.CSS_SELECTOR, '${interaction.selector}').is_displayed()";
      default:
        return "# ${interaction.type.displayName}";
    }
  }

  @override
  void dispose() {
    stopRecording();
    super.dispose();
  }
}

