import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/devtools_models.dart';

/// Service principal pour les DevTools natifs de Notilus
class NotilusDevToolsService extends ChangeNotifier {
  static final NotilusDevToolsService _instance = NotilusDevToolsService._internal();
  factory NotilusDevToolsService() => _instance;
  NotilusDevToolsService._internal();

  final _uuid = const Uuid();
  
  // === Console Logs ===
  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);
  int _maxLogs = 1000;
  
  // === Network Requests ===
  final List<NetworkRequest> _requests = [];
  List<NetworkRequest> get requests => List.unmodifiable(_requests);
  int _maxRequests = 500;
  bool _isNetworkRecording = true;
  
  // === Performance Monitoring ===
  final List<PerformanceSnapshot> _performanceHistory = [];
  List<PerformanceSnapshot> get performanceHistory => List.unmodifiable(_performanceHistory);
  Timer? _performanceTimer;
  bool _isPerformanceMonitoring = false;
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  double _currentFps = 60.0;
  
  // Vraies métriques
  int _lastRenderTimeUs = 0;
  int _gcCount = 0;
  int _lastGcCount = 0;
  DateTime? _frameStartTime;
  final List<int> _frameTimes = []; // Pour calculer le render time moyen
  
  // === Storage ===
  List<StorageEntry> _storageEntries = [];
  List<StorageEntry> get storageEntries => List.unmodifiable(_storageEntries);
  
  // === REPL History ===
  final List<ReplCommand> _replHistory = [];
  List<ReplCommand> get replHistory => List.unmodifiable(_replHistory);
  
  // === HTTP Client Wrapper ===
  late final _DevToolsHttpClient _httpClient;
  http.Client get httpClient => _httpClient;
  
  // === FONCTIONNALITÉS AVANCÉES ===
  
  // Tab Analytics
  final Map<String, TabAnalytics> _tabAnalytics = {};
  Map<String, TabAnalytics> get tabAnalytics => Map.unmodifiable(_tabAnalytics);
  
  // Session Recording
  final List<RecordedSession> _sessions = [];
  List<RecordedSession> get sessions => List.unmodifiable(_sessions);
  RecordedSession? _currentSession;
  RecordedSession? get currentSession => _currentSession;
  bool get isRecording => _currentSession?.isRecording ?? false;
  
  // Smart Alerts
  final List<SmartAlert> _alerts = [];
  List<SmartAlert> get alerts => List.unmodifiable(_alerts);
  SmartMonitorConfig _monitorConfig = SmartMonitorConfig();
  SmartMonitorConfig get monitorConfig => _monitorConfig;
  Timer? _alertCheckTimer;
  int _recentErrorCount = 0;
  DateTime? _lastErrorBurstCheck;
  
  // Security Audit
  final List<SecurityIssue> _securityIssues = [];
  List<SecurityIssue> get securityIssues => List.unmodifiable(_securityIssues);
  
  // Bookmarks
  final List<DevToolsBookmark> _bookmarks = [];
  List<DevToolsBookmark> get bookmarks => List.unmodifiable(_bookmarks);
  
  // Widget Tree
  List<WidgetTreeNode> _widgetTree = [];
  List<WidgetTreeNode> get widgetTree => List.unmodifiable(_widgetTree);
  
  // Provider States
  final Map<String, ProviderState> _providerStates = {};
  Map<String, ProviderState> get providerStates => Map.unmodifiable(_providerStates);
  
  // Session start time
  DateTime _sessionStartTime = DateTime.now();
  DateTime get sessionStartTime => _sessionStartTime;
  
  // === Getters ===
  bool get isNetworkRecording => _isNetworkRecording;
  bool get isPerformanceMonitoring => _isPerformanceMonitoring;
  double get currentFps => _currentFps;
  int get alertCount => _alerts.where((a) => !a.isDismissed).length;
  int get criticalAlertCount => _alerts.where((a) => !a.isDismissed && a.severity == AlertSeverity.critical).length;
  int get securityIssueCount => _securityIssues.where((s) => !s.isResolved).length;
  
  // === WebView Console/Network Capture ===
  final Map<String, Function(String)> _webViewLogHandlers = {};
  
  // === Initialization ===
  void initialize() {
    _httpClient = _DevToolsHttpClient(this);
    _sessionStartTime = DateTime.now();
    
    _logSystem('╔══════════════════════════════════════════╗');
    _logSystem('║   NOTILUS DEVTOOLS v3.0 - ADVANCED       ║');
    _logSystem('╠══════════════════════════════════════════╣');
    _logSystem('║ ✓ Real-time Performance Metrics          ║');
    _logSystem('║ ✓ Tab Analytics & Tracking               ║');
    _logSystem('║ ✓ Session Recording & Replay             ║');
    _logSystem('║ ✓ Smart Alerts & Monitoring              ║');
    _logSystem('║ ✓ Security Audit Scanner                 ║');
    _logSystem('║ ✓ Widget Tree Inspector                  ║');
    _logSystem('║ ✓ Export Reports (JSON)                  ║');
    _logSystem('╚══════════════════════════════════════════╝');
    
    // Démarrer le smart monitoring
    startSmartMonitoring();
    
    logSuccess('DevTools initialisé avec succès', source: 'Init');
  }
  
  /// Script JavaScript à injecter pour capturer console.log et les requêtes réseau
  String getWebViewInjectionScript(String tabId) {
    return '''
(function() {
  if (window.__notilusDevToolsInjected) return;
  window.__notilusDevToolsInjected = true;
  
  // === CAPTURE CONSOLE ===
  const originalConsole = {
    log: console.log,
    warn: console.warn,
    error: console.error,
    info: console.info,
    debug: console.debug
  };
  
  function sendToNotilus(level, args) {
    try {
      const message = Array.from(args).map(arg => {
        if (typeof arg === 'object') {
          try { return JSON.stringify(arg, null, 2); }
          catch (e) { return String(arg); }
        }
        return String(arg);
      }).join(' ');
      
      window.chrome?.webview?.postMessage?.(JSON.stringify({
        type: 'console',
        tabId: '$tabId',
        level: level,
        message: message,
        timestamp: Date.now(),
        url: window.location.href
      }));
    } catch (e) {}
  }
  
  console.log = function(...args) {
    sendToNotilus('log', args);
    originalConsole.log.apply(console, args);
  };
  console.warn = function(...args) {
    sendToNotilus('warn', args);
    originalConsole.warn.apply(console, args);
  };
  console.error = function(...args) {
    sendToNotilus('error', args);
    originalConsole.error.apply(console, args);
  };
  console.info = function(...args) {
    sendToNotilus('info', args);
    originalConsole.info.apply(console, args);
  };
  console.debug = function(...args) {
    sendToNotilus('debug', args);
    originalConsole.debug.apply(console, args);
  };
  
  // === CAPTURE NETWORK (fetch) ===
  const originalFetch = window.fetch;
  window.fetch = async function(input, init) {
    const url = typeof input === 'string' ? input : input.url;
    const method = init?.method || 'GET';
    const startTime = Date.now();
    const requestId = Math.random().toString(36).substr(2, 9);
    
    // Notifier le début de la requête
    window.chrome?.webview?.postMessage?.(JSON.stringify({
      type: 'network',
      action: 'start',
      tabId: '$tabId',
      requestId: requestId,
      url: url,
      method: method,
      timestamp: startTime
    }));
    
    try {
      const response = await originalFetch.apply(this, arguments);
      const endTime = Date.now();
      const clonedResponse = response.clone();
      
      // Essayer de lire le body pour la taille
      let size = 0;
      try {
        const blob = await clonedResponse.blob();
        size = blob.size;
      } catch (e) {}
      
      window.chrome?.webview?.postMessage?.(JSON.stringify({
        type: 'network',
        action: 'complete',
        tabId: '$tabId',
        requestId: requestId,
        url: url,
        method: method,
        status: response.status,
        statusText: response.statusText,
        duration: endTime - startTime,
        size: size,
        timestamp: endTime
      }));
      
      return response;
    } catch (error) {
      window.chrome?.webview?.postMessage?.(JSON.stringify({
        type: 'network',
        action: 'error',
        tabId: '$tabId',
        requestId: requestId,
        url: url,
        method: method,
        error: error.message,
        timestamp: Date.now()
      }));
      throw error;
    }
  };
  
  // === CAPTURE NETWORK (XMLHttpRequest) ===
  const originalXHR = window.XMLHttpRequest;
  window.XMLHttpRequest = function() {
    const xhr = new originalXHR();
    const requestId = Math.random().toString(36).substr(2, 9);
    let method = 'GET';
    let url = '';
    let startTime = 0;
    
    const originalOpen = xhr.open;
    xhr.open = function(m, u, ...args) {
      method = m;
      url = u;
      return originalOpen.apply(xhr, [m, u, ...args]);
    };
    
    const originalSend = xhr.send;
    xhr.send = function(body) {
      startTime = Date.now();
      
      window.chrome?.webview?.postMessage?.(JSON.stringify({
        type: 'network',
        action: 'start',
        tabId: '$tabId',
        requestId: requestId,
        url: url,
        method: method,
        timestamp: startTime
      }));
      
      return originalSend.apply(xhr, arguments);
    };
    
    xhr.addEventListener('load', function() {
      window.chrome?.webview?.postMessage?.(JSON.stringify({
        type: 'network',
        action: 'complete',
        tabId: '$tabId',
        requestId: requestId,
        url: url,
        method: method,
        status: xhr.status,
        statusText: xhr.statusText,
        duration: Date.now() - startTime,
        size: xhr.responseText?.length || 0,
        timestamp: Date.now()
      }));
    });
    
    xhr.addEventListener('error', function() {
      window.chrome?.webview?.postMessage?.(JSON.stringify({
        type: 'network',
        action: 'error',
        tabId: '$tabId',
        requestId: requestId,
        url: url,
        method: method,
        error: 'Network error',
        timestamp: Date.now()
      }));
    });
    
    return xhr;
  };
  
  // Notifier que l'injection est terminée
  window.chrome?.webview?.postMessage?.(JSON.stringify({
    type: 'devtools-ready',
    tabId: '$tabId',
    url: window.location.href
  }));
  
  console.log('[Notilus DevTools] Injection réussie');
})();
''';
  }
  
  /// Traite un message reçu du WebView
  void handleWebViewMessage(String tabId, String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      
      switch (type) {
        case 'console':
          _handleWebViewConsole(tabId, data);
          break;
        case 'network':
          _handleWebViewNetwork(tabId, data);
          break;
        case 'devtools-ready':
          logSuccess('WebView DevTools connecté: ${data['url']}', source: 'WebView:$tabId');
          break;
      }
    } catch (e) {
      // Ignorer les messages non-DevTools
    }
  }
  
  void _handleWebViewConsole(String tabId, Map<String, dynamic> data) {
    final level = data['level'] as String? ?? 'log';
    final message = data['message'] as String? ?? '';
    final url = data['url'] as String? ?? '';
    
    LogLevel logLevel;
    switch (level) {
      case 'error':
        logLevel = LogLevel.error;
        break;
      case 'warn':
        logLevel = LogLevel.warning;
        break;
      case 'debug':
        logLevel = LogLevel.debug;
        break;
      case 'info':
        logLevel = LogLevel.info;
        break;
      default:
        logLevel = LogLevel.info;
    }
    
    log(message, level: logLevel, source: 'WebView:$tabId', data: {'url': url});
  }
  
  void _handleWebViewNetwork(String tabId, Map<String, dynamic> data) {
    final action = data['action'] as String?;
    final requestId = data['requestId'] as String? ?? '';
    final url = data['url'] as String? ?? '';
    final method = data['method'] as String? ?? 'GET';
    
    if (action == 'start') {
      final request = NetworkRequest(
        id: 'wv_${tabId}_$requestId',
        timestamp: DateTime.now(),
        method: _parseHttpMethod(method),
        url: url,
        requestHeaders: {},
        status: RequestStatus.pending,
        source: 'WebView:$tabId',
      );
      addRequest(request);
    } else if (action == 'complete') {
      updateRequest(
        'wv_${tabId}_$requestId',
        statusCode: data['status'] as int? ?? 0,
        duration: Duration(milliseconds: data['duration'] as int? ?? 0),
        responseSize: data['size'] as int? ?? 0,
        status: RequestStatus.success,
      );
    } else if (action == 'error') {
      updateRequest(
        'wv_${tabId}_$requestId',
        status: RequestStatus.error,
        error: data['error'] as String? ?? 'Unknown error',
      );
    }
  }
  
  HttpMethod _parseHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'POST': return HttpMethod.post;
      case 'PUT': return HttpMethod.put;
      case 'DELETE': return HttpMethod.delete;
      case 'PATCH': return HttpMethod.patch;
      case 'HEAD': return HttpMethod.head;
      case 'OPTIONS': return HttpMethod.options;
      default: return HttpMethod.get;
    }
  }
  
  // === Console Methods ===
  
  void log(String message, {LogLevel level = LogLevel.info, String? source, Map<String, dynamic>? data}) {
    final entry = LogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
      data: data,
    );
    _addLog(entry);
  }
  
  void logInfo(String message, {String? source, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.info, source: source, data: data);
  }
  
  void logWarning(String message, {String? source, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.warning, source: source, data: data);
  }
  
  void logError(String message, {String? source, Map<String, dynamic>? data, StackTrace? stackTrace}) {
    final entry = LogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      level: LogLevel.error,
      message: message,
      source: source,
      data: data,
      stackTrace: stackTrace,
    );
    _addLog(entry);
  }
  
  void logDebug(String message, {String? source, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.debug, source: source, data: data);
  }
  
  void logSuccess(String message, {String? source, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.success, source: source, data: data);
  }
  
  void _logSystem(String message) {
    log(message, level: LogLevel.system, source: 'DevTools');
  }
  
  void _addLog(LogEntry entry) {
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    notifyListeners();
  }
  
  void clearLogs() {
    _logs.clear();
    _logSystem('Console vidée');
    notifyListeners();
  }
  
  List<LogEntry> filterLogs({LogLevel? level, String? search}) {
    return _logs.where((log) {
      if (level != null && log.level != level) return false;
      if (search != null && search.isNotEmpty) {
        return log.message.toLowerCase().contains(search.toLowerCase());
      }
      return true;
    }).toList();
  }
  
  // === Network Methods ===
  
  void toggleNetworkRecording() {
    _isNetworkRecording = !_isNetworkRecording;
    _logSystem('Enregistrement réseau: ${_isNetworkRecording ? "activé" : "désactivé"}');
    notifyListeners();
  }
  
  String addRequest(NetworkRequest request) {
    if (!_isNetworkRecording) return request.id;
    
    _requests.add(request);
    if (_requests.length > _maxRequests) {
      _requests.removeAt(0);
    }
    notifyListeners();
    return request.id;
  }
  
  void updateRequest(String id, {
    int? statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
    int? responseSize,
    Duration? duration,
    RequestStatus? status,
    String? error,
  }) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return;
    
    _requests[index] = _requests[index].copyWith(
      statusCode: statusCode,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
      responseSize: responseSize,
      duration: duration,
      status: status,
      error: error,
    );
    
    // Audit de sécurité automatique
    if (status == RequestStatus.success) {
      auditRequest(_requests[index]);
      
      // Track pour les analytics si c'est une requête WebView
      final source = _requests[index].source;
      if (source != null && source.startsWith('WebView:')) {
        final tabId = source.replaceFirst('WebView:', '');
        trackTabRequest(tabId, _requests[index]);
      }
    }
    
    notifyListeners();
  }
  
  void clearRequests() {
    _requests.clear();
    _logSystem('Requêtes réseau vidées');
    notifyListeners();
  }
  
  List<NetworkRequest> filterRequests({HttpMethod? method, RequestStatus? status, String? search}) {
    return _requests.where((req) {
      if (method != null && req.method != method) return false;
      if (status != null && req.status != status) return false;
      if (search != null && search.isNotEmpty) {
        return req.url.toLowerCase().contains(search.toLowerCase());
      }
      return true;
    }).toList();
  }
  
  // === Performance Methods ===
  
  void startPerformanceMonitoring() {
    if (_isPerformanceMonitoring) return;
    
    _isPerformanceMonitoring = true;
    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _capturePerformanceSnapshot();
    });
    
    // FPS tracking
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    
    _logSystem('Monitoring performance démarré');
    notifyListeners();
  }
  
  void stopPerformanceMonitoring() {
    _isPerformanceMonitoring = false;
    _performanceTimer?.cancel();
    _performanceTimer = null;
    _logSystem('Monitoring performance arrêté');
    notifyListeners();
  }
  
  void _onFrame(Duration timestamp) {
    if (!_isPerformanceMonitoring) return;
    
    _frameCount++;
    final now = DateTime.now();
    
    // Calculer le temps de rendu réel du frame
    if (_frameStartTime != null) {
      final frameTimeUs = now.difference(_frameStartTime!).inMicroseconds;
      _frameTimes.add(frameTimeUs);
      // Garder seulement les 60 derniers frames
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
      _lastRenderTimeUs = frameTimeUs;
    }
    _frameStartTime = now;
    
    if (_lastFrameTime != null) {
      final elapsed = now.difference(_lastFrameTime!).inMilliseconds;
      if (elapsed >= 1000) {
        _currentFps = _frameCount * 1000 / elapsed;
        _frameCount = 0;
        _lastFrameTime = now;
      }
    } else {
      _lastFrameTime = now;
    }
    
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }
  
  void _capturePerformanceSnapshot() async {
    final memUsedMB = _getRealMemoryUsedMB();
    final memTotalMB = _getRealMemoryTotalMB();
    final memUsage = memTotalMB > 0 ? (memUsedMB / memTotalMB) * 100 : 0.0;
    
    final snapshot = PerformanceSnapshot(
      timestamp: DateTime.now(),
      cpuUsage: _getRealCpuUsage(),
      memoryUsage: memUsage,
      memoryUsedMB: memUsedMB,
      memoryTotalMB: memTotalMB,
      activeWidgets: _countRealActiveWidgets(),
      renderTime: _getRealRenderTime(),
      fps: _currentFps,
      gcCount: _trackGcCount(),
    );
    
    _performanceHistory.add(snapshot);
    
    // Garder seulement les 60 dernières secondes
    while (_performanceHistory.length > 60) {
      _performanceHistory.removeAt(0);
    }
    
    notifyListeners();
  }
  
  /// Obtient l'utilisation CPU réelle du processus (estimation basée sur le temps de frame)
  double _getRealCpuUsage() {
    // Sur Windows, on ne peut pas facilement obtenir le CPU du processus
    // On estime basé sur le temps de rendu vs temps disponible (16.67ms pour 60fps)
    if (_frameTimes.isEmpty) return 0.0;
    
    final avgFrameTimeMs = _frameTimes.fold<int>(0, (a, b) => a + b) / _frameTimes.length / 1000;
    // Si on prend tout le budget frame (16.67ms), c'est ~100% du thread UI
    final cpuEstimate = (avgFrameTimeMs / 16.67) * 100;
    return cpuEstimate.clamp(0.0, 100.0);
  }
  
  /// Obtient l'utilisation mémoire réelle via ProcessInfo
  Future<double> _getRealMemoryUsage() async {
    try {
      final info = ProcessInfo.currentRss;
      final maxRss = ProcessInfo.maxRss;
      if (maxRss > 0) {
        return (info / maxRss) * 100;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Obtient la mémoire utilisée en MB (réelle)
  int _getRealMemoryUsedMB() {
    try {
      // ProcessInfo.currentRss retourne en bytes
      return (ProcessInfo.currentRss / (1024 * 1024)).round();
    } catch (e) {
      return 0;
    }
  }
  
  /// Obtient la mémoire max/totale en MB (réelle)
  int _getRealMemoryTotalMB() {
    try {
      final maxRss = ProcessInfo.maxRss;
      if (maxRss > 0) {
        return (maxRss / (1024 * 1024)).round();
      }
      // Fallback: estimation basée sur la mémoire système
      return 4096; // 4GB par défaut
    } catch (e) {
      return 4096;
    }
  }
  
  /// Placeholder - les métriques widgets Flutter ne sont pas utilisées
  /// car Notilus est un navigateur web, pas un outil de debug Flutter
  int _countRealActiveWidgets() {
    return 0; // Non applicable pour un navigateur
  }
  
  /// Obtient le temps de rendu réel en millisecondes
  int _getRealRenderTime() {
    if (_frameTimes.isEmpty) return 0;
    // Moyenne des temps de frame en millisecondes
    final avgUs = _frameTimes.fold<int>(0, (a, b) => a + b) / _frameTimes.length;
    return (avgUs / 1000).round();
  }
  
  /// Obtient le nombre de GC (estimation via timeline)
  int _trackGcCount() {
    // On utilise le Service Protocol via dart:developer pour traquer les GC
    // Pour l'instant, on incrémente basé sur des pics de mémoire
    try {
      final currentMem = ProcessInfo.currentRss;
      // Si la mémoire a baissé significativement, c'est probablement un GC
      if (_lastGcCount > 0 && currentMem < _lastGcCount * 0.9) {
        _gcCount++;
      }
      _lastGcCount = currentMem;
    } catch (e) {
      // Ignorer
    }
    return _gcCount;
  }
  
  void clearPerformanceHistory() {
    _performanceHistory.clear();
    _logSystem('Historique performance vidé');
    notifyListeners();
  }
  
  // === Storage Methods ===
  
  Future<void> loadStorageEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      _storageEntries = keys.map((key) {
        final value = prefs.get(key);
        String valueStr;
        String type;
        
        if (value is String) {
          valueStr = value;
          type = 'String';
        } else if (value is int) {
          valueStr = value.toString();
          type = 'int';
        } else if (value is double) {
          valueStr = value.toString();
          type = 'double';
        } else if (value is bool) {
          valueStr = value.toString();
          type = 'bool';
        } else if (value is List<String>) {
          valueStr = jsonEncode(value);
          type = 'List<String>';
        } else {
          valueStr = value?.toString() ?? 'null';
          type = 'unknown';
        }
        
        return StorageEntry(
          key: key,
          value: valueStr,
          type: type,
          size: valueStr.length,
          lastModified: DateTime.now(),
        );
      }).toList();
      
      _storageEntries.sort((a, b) => a.key.compareTo(b.key));
      
      _logSystem('${_storageEntries.length} entrées de stockage chargées');
      notifyListeners();
    } catch (e) {
      logError('Erreur chargement storage: $e');
    }
  }
  
  Future<void> deleteStorageEntry(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      _storageEntries.removeWhere((e) => e.key == key);
      _logSystem('Clé "$key" supprimée');
      notifyListeners();
    } catch (e) {
      logError('Erreur suppression: $e');
    }
  }
  
  Future<void> clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _storageEntries.clear();
      _logSystem('Storage vidé');
      notifyListeners();
    } catch (e) {
      logError('Erreur clear storage: $e');
    }
  }
  
  Future<void> setStorageEntry(String key, String value, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      switch (type) {
        case 'String':
          await prefs.setString(key, value);
          break;
        case 'int':
          await prefs.setInt(key, int.parse(value));
          break;
        case 'double':
          await prefs.setDouble(key, double.parse(value));
          break;
        case 'bool':
          await prefs.setBool(key, value.toLowerCase() == 'true');
          break;
        default:
          await prefs.setString(key, value);
      }
      
      await loadStorageEntries();
      _logSystem('Clé "$key" mise à jour');
    } catch (e) {
      logError('Erreur set storage: $e');
    }
  }
  
  // === REPL Methods ===
  
  Future<String> executeCommand(String input) async {
    final command = ReplCommand(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      input: input,
    );
    
    _replHistory.add(command);
    
    try {
      final stopwatch = Stopwatch()..start();
      final result = await _executeReplCommand(input);
      stopwatch.stop();
      
      final index = _replHistory.indexWhere((c) => c.id == command.id);
      if (index != -1) {
        _replHistory[index] = ReplCommand(
          id: command.id,
          timestamp: command.timestamp,
          input: input,
          output: result,
          isError: false,
          executionTime: stopwatch.elapsed,
        );
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      final index = _replHistory.indexWhere((c) => c.id == command.id);
      if (index != -1) {
        _replHistory[index] = ReplCommand(
          id: command.id,
          timestamp: command.timestamp,
          input: input,
          output: e.toString(),
          isError: true,
        );
      }
      notifyListeners();
      return 'Erreur: $e';
    }
  }
  
  Future<String> _executeReplCommand(String input) async {
    final parts = input.trim().split(' ');
    final cmd = parts.first.toLowerCase();
    final args = parts.skip(1).toList();
    
    switch (cmd) {
      case 'help':
        return _getHelpText();
      
      case 'clear':
        clearLogs();
        return 'Console vidée';
      
      case 'logs':
        return 'Total logs: ${_logs.length}';
      
      case 'requests':
        return 'Total requêtes: ${_requests.length}';
      
      case 'perf':
        if (_performanceHistory.isEmpty) return 'Aucune donnée de performance';
        final last = _performanceHistory.last;
        return '''
Performance actuelle:
  FPS: ${last.fps.toStringAsFixed(1)}
  CPU: ${last.cpuUsage.toStringAsFixed(1)}%
  Memory: ${last.memoryUsedMB} MB / ${last.memoryTotalMB} MB
  Render: ${last.renderTime}ms
''';
      
      case 'storage':
        return 'Entrées storage: ${_storageEntries.length}';
      
      case 'get':
        if (args.isEmpty) return 'Usage: get <key>';
        final key = args.join(' ');
        final entry = _storageEntries.where((e) => e.key == key).firstOrNull;
        if (entry == null) return 'Clé "$key" non trouvée';
        return '${entry.key} (${entry.type}): ${entry.value}';
      
      case 'set':
        if (args.length < 2) return 'Usage: set <key> <value>';
        final key = args.first;
        final value = args.skip(1).join(' ');
        await setStorageEntry(key, value, 'String');
        return 'OK: $key = $value';
      
      case 'del':
        if (args.isEmpty) return 'Usage: del <key>';
        final key = args.join(' ');
        await deleteStorageEntry(key);
        return 'Clé "$key" supprimée';
      
      case 'env':
        return '''
Environnement:
  Platform: ${Platform.operatingSystem}
  Version: ${Platform.operatingSystemVersion}
  Dart: ${Platform.version}
  Locale: ${Platform.localeName}
''';
      
      case 'time':
        return DateTime.now().toIso8601String();
      
      case 'echo':
        return args.join(' ');
      
      case 'json':
        if (args.isEmpty) return 'Usage: json <string>';
        try {
          final decoded = jsonDecode(args.join(' '));
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (e) {
          return 'JSON invalide: $e';
        }
      
      case 'fetch':
        if (args.isEmpty) return 'Usage: fetch <url>';
        try {
          final response = await http.get(Uri.parse(args.first));
          return 'Status: ${response.statusCode}\nBody: ${response.body.substring(0, 500.clamp(0, response.body.length))}...';
        } catch (e) {
          return 'Erreur: $e';
        }
      
      case 'version':
        return 'Notilus DevTools v3.0.0 - Advanced Edition';
      
      // === NOUVELLES COMMANDES AVANCÉES ===
      
      case 'analytics':
        final stats = getGlobalAnalytics();
        return '''
📊 ANALYTICS GLOBALES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Onglets: ${stats['totalTabs']} (${stats['activeTabs']} actifs)
  Requêtes: ${stats['totalRequests']}
  Erreurs: ${stats['totalErrors']}
  Données: ${stats['totalDataMB']} MB
  Temps réponse moyen: ${stats['avgResponseTime']} ms
  Durée session: ${stats['sessionDuration']} min
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
      
      case 'alerts':
        final activeAlerts = _alerts.where((a) => !a.isDismissed).toList();
        if (activeAlerts.isEmpty) return '✅ Aucune alerte active';
        return '''
🔔 ALERTES ACTIVES (${activeAlerts.length})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${activeAlerts.take(10).map((a) => '  ${a.severity == AlertSeverity.critical ? "🚨" : "⚠️"} ${a.title}').join('\n')}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
      
      case 'security':
        final issues = _securityIssues.where((s) => !s.isResolved).toList();
        if (issues.isEmpty) return '🔒 Aucun problème de sécurité détecté';
        return '''
🔒 PROBLÈMES DE SÉCURITÉ (${issues.length})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${issues.take(10).map((s) => '  ${s.severity == AlertSeverity.critical ? "🔴" : "🟠"} ${s.title}').join('\n')}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
      
      case 'record':
        if (args.isEmpty) {
          if (isRecording) {
            stopRecording();
            return '⏹️ Enregistrement arrêté';
          } else {
            startRecording();
            return '📹 Enregistrement démarré';
          }
        }
        if (args.first == 'start') {
          startRecording(name: args.length > 1 ? args.skip(1).join(' ') : null);
          return '📹 Enregistrement démarré: ${_currentSession?.name}';
        }
        if (args.first == 'stop') {
          stopRecording();
          return '⏹️ Enregistrement arrêté';
        }
        return 'Usage: record [start|stop] [name]';
      
      case 'sessions':
        if (_sessions.isEmpty) return 'Aucune session enregistrée';
        return '''
📼 SESSIONS ENREGISTRÉES (${_sessions.length})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${_sessions.map((s) => '  ${s.name} - ${s.formattedDuration} (${s.events.length} events)').join('\n')}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
      
      case 'widgets':
        return '⚠️ Commande obsolète - utilisez les DevTools natifs (F12 → DevTools Natif)';
      
      case 'bookmark':
        if (args.isEmpty) return 'Usage: bookmark <titre>';
        addBookmark(title: args.join(' '), category: 'custom');
        return '🔖 Bookmark ajouté: ${args.join(' ')}';
      
      case 'export':
        final json = exportReportToJson();
        return '📄 Rapport généré (${json.length} caractères)\nUtilisez l\'UI pour sauvegarder';
      
      case 'monitor':
        if (args.isEmpty) {
          return 'Smart Monitoring: ${_alertCheckTimer != null ? "actif" : "inactif"}\nUsage: monitor [on|off]';
        }
        if (args.first == 'on') {
          startSmartMonitoring();
          return '🔔 Smart Monitoring activé';
        }
        if (args.first == 'off') {
          stopSmartMonitoring();
          return '🔕 Smart Monitoring désactivé';
        }
        return 'Usage: monitor [on|off]';
      
      default:
        return 'Commande inconnue: $cmd\nTapez "help" pour voir les commandes disponibles';
    }
  }
  
  String _getHelpText() {
    return '''
╔═══════════════════════════════════════════════╗
║    NOTILUS DEVTOOLS v3.0 - COMMANDES REPL     ║
╠═══════════════════════════════════════════════╣
║                                               ║
║  📋 CONSOLE                                   ║
║    help          Affiche cette aide           ║
║    clear         Vide la console              ║
║    logs          Nombre de logs               ║
║    echo <msg>    Affiche un message           ║
║                                               ║
║  🌐 RÉSEAU                                    ║
║    requests      Nombre de requêtes           ║
║    fetch <url>   Effectue une requête GET     ║
║                                               ║
║  📊 PERFORMANCE                               ║
║    perf          Métriques actuelles          ║
║                                               ║
║  💾 STORAGE                                   ║
║    storage       Nombre d'entrées             ║
║    get <key>     Lire une valeur              ║
║    set <k> <v>   Définir une valeur           ║
║    del <key>     Supprimer une clé            ║
║                                               ║
║  📈 ANALYTICS (NOUVEAU)                       ║
║    analytics     Stats globales               ║
║    alerts        Alertes actives              ║
║    security      Problèmes de sécurité        ║
║                                               ║
║  📹 SESSION (NOUVEAU)                         ║
║    record        Toggle enregistrement        ║
║    sessions      Liste des sessions           ║
║                                               ║
║  🛠️ UTILITAIRES                              ║
║    bookmark <t>  Ajouter un bookmark          ║
║    export        Exporter rapport JSON        ║
║    monitor       Smart Monitoring on/off      ║
║    env           Infos environnement          ║
║    time          Heure actuelle               ║
║    json <str>    Formater du JSON             ║
║    version       Version DevTools             ║
║                                               ║
╚═══════════════════════════════════════════════╝
''';
  }
  
  void clearReplHistory() {
    _replHistory.clear();
    notifyListeners();
  }
  
  // ============================================================================
  // FONCTIONNALITÉS AVANCÉES NOTILUS DEVTOOLS
  // ============================================================================
  
  // === TAB ANALYTICS ===
  
  /// Enregistre l'ouverture d'un onglet
  void trackTabOpen(String tabId, {String? title, String? url}) {
    _tabAnalytics[tabId] = TabAnalytics(
      tabId: tabId,
      tabTitle: title,
      tabUrl: url,
      openedAt: DateTime.now(),
      visitedUrls: url != null ? [url] : [],
    );
    _logSystem('Tab ouvert: $tabId');
    notifyListeners();
  }
  
  /// Met à jour les analytics d'un onglet
  void updateTabAnalytics(String tabId, {String? title, String? url}) {
    final analytics = _tabAnalytics[tabId];
    if (analytics == null) {
      trackTabOpen(tabId, title: title, url: url);
      return;
    }
    
    if (title != null) analytics.tabTitle;
    if (url != null && !analytics.visitedUrls.contains(url)) {
      analytics.visitedUrls = [...analytics.visitedUrls, url];
    }
    notifyListeners();
  }
  
  /// Enregistre la fermeture d'un onglet
  void trackTabClose(String tabId) {
    final analytics = _tabAnalytics[tabId];
    if (analytics != null) {
      analytics.closedAt = DateTime.now();
      analytics.totalActiveTime = analytics.closedAt!.difference(analytics.openedAt);
    }
    notifyListeners();
  }
  
  /// Enregistre une requête pour un onglet
  void trackTabRequest(String tabId, NetworkRequest request) {
    final analytics = _tabAnalytics[tabId];
    if (analytics == null) return;
    
    analytics.totalRequests++;
    if (request.status == RequestStatus.error) {
      analytics.failedRequests++;
    }
    if (request.responseSize != null) {
      analytics.totalDataTransferred += request.responseSize!;
    }
    if (request.duration != null) {
      final total = analytics.avgResponseTime * (analytics.totalRequests - 1) + request.duration!.inMilliseconds;
      analytics.avgResponseTime = total / analytics.totalRequests;
    }
    
    // Track domain
    final domain = request.host;
    analytics.domainRequests = Map.from(analytics.domainRequests);
    analytics.domainRequests[domain] = (analytics.domainRequests[domain] ?? 0) + 1;
    
    notifyListeners();
  }
  
  /// Obtient les statistiques agrégées de tous les onglets
  Map<String, dynamic> getGlobalAnalytics() {
    int totalRequests = 0;
    int totalErrors = 0;
    int totalData = 0;
    double avgResponseTime = 0;
    
    for (final analytics in _tabAnalytics.values) {
      totalRequests += analytics.totalRequests;
      totalErrors += analytics.failedRequests + analytics.errorCount;
      totalData += analytics.totalDataTransferred;
      avgResponseTime += analytics.avgResponseTime;
    }
    
    if (_tabAnalytics.isNotEmpty) {
      avgResponseTime /= _tabAnalytics.length;
    }
    
    return {
      'totalTabs': _tabAnalytics.length,
      'activeTabs': _tabAnalytics.values.where((a) => a.closedAt == null).length,
      'totalRequests': totalRequests,
      'totalErrors': totalErrors,
      'totalDataMB': (totalData / (1024 * 1024)).toStringAsFixed(2),
      'avgResponseTime': avgResponseTime.toStringAsFixed(0),
      'sessionDuration': DateTime.now().difference(_sessionStartTime).inMinutes,
    };
  }
  
  // === SESSION RECORDING ===
  
  /// Démarre l'enregistrement d'une session
  void startRecording({String? name}) {
    if (_currentSession?.isRecording == true) {
      stopRecording();
    }
    
    _currentSession = RecordedSession(
      id: _uuid.v4(),
      name: name ?? 'Session ${_sessions.length + 1}',
      startTime: DateTime.now(),
      events: [],
      isRecording: true,
    );
    
    _logSystem('📹 Enregistrement démarré: ${_currentSession!.name}');
    notifyListeners();
  }
  
  /// Arrête l'enregistrement
  void stopRecording() {
    if (_currentSession == null || !_currentSession!.isRecording) return;
    
    _currentSession!.endTime = DateTime.now();
    _currentSession!.isRecording = false;
    _sessions.add(_currentSession!);
    
    _logSystem('⏹️ Enregistrement arrêté: ${_currentSession!.name} (${_currentSession!.events.length} événements)');
    _currentSession = null;
    notifyListeners();
  }
  
  /// Enregistre un événement dans la session
  void recordEvent(SessionEventType type, {String? tabId, String? url, Map<String, dynamic>? data}) {
    if (_currentSession == null || !_currentSession!.isRecording) return;
    
    final event = SessionEvent(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: type,
      tabId: tabId,
      url: url,
      data: data ?? {},
    );
    
    _currentSession!.events.add(event);
    notifyListeners();
  }
  
  /// Supprime une session enregistrée
  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
  }
  
  /// Exporte une session en JSON
  String exportSession(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    return jsonEncode({
      'id': session.id,
      'name': session.name,
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'duration': session.duration.inSeconds,
      'eventsCount': session.events.length,
      'events': session.events.map((e) => {
        'id': e.id,
        'timestamp': e.timestamp.toIso8601String(),
        'type': e.type.name,
        'tabId': e.tabId,
        'url': e.url,
        'data': e.data,
      }).toList(),
    });
  }
  
  // === SMART ALERTS ===
  
  /// Démarre le monitoring intelligent
  void startSmartMonitoring() {
    _alertCheckTimer?.cancel();
    _alertCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkForAlerts();
    });
    _logSystem('🔔 Smart Monitoring activé');
  }
  
  /// Arrête le monitoring intelligent
  void stopSmartMonitoring() {
    _alertCheckTimer?.cancel();
    _alertCheckTimer = null;
    _logSystem('🔕 Smart Monitoring désactivé');
  }
  
  /// Vérifie les conditions d'alerte
  void _checkForAlerts() {
    final config = _monitorConfig;
    
    // Check FPS
    if (config.fpsDropAlert && _currentFps < config.fpsThreshold) {
      _createAlert(
        severity: _currentFps < 15 ? AlertSeverity.critical : AlertSeverity.warning,
        title: 'Chute de FPS détectée',
        message: 'FPS actuel: ${_currentFps.toStringAsFixed(1)} (seuil: ${config.fpsThreshold})',
        suggestion: 'Réduisez le nombre de widgets ou optimisez les rebuilds',
        category: 'performance',
      );
    }
    
    // Check Memory
    if (config.memorySpikAlert && _performanceHistory.isNotEmpty) {
      final memMB = _performanceHistory.last.memoryUsedMB;
      if (memMB > config.memoryThresholdMB) {
        _createAlert(
          severity: memMB > config.memoryThresholdMB * 1.5 ? AlertSeverity.critical : AlertSeverity.warning,
          title: 'Utilisation mémoire élevée',
          message: 'Mémoire: $memMB MB (seuil: ${config.memoryThresholdMB} MB)',
          suggestion: 'Vérifiez les fuites mémoire et optimisez les images',
          category: 'memory',
        );
      }
    }
    
    // Check slow requests
    if (config.slowRequestAlert) {
      final slowRequests = _requests.where((r) => 
        r.duration != null && r.duration!.inMilliseconds > config.slowRequestThresholdMs
      ).toList();
      
      if (slowRequests.isNotEmpty) {
        final latest = slowRequests.last;
        _createAlert(
          severity: AlertSeverity.warning,
          title: 'Requête lente détectée',
          message: '${latest.url} - ${latest.formattedDuration}',
          suggestion: 'Optimisez l\'API ou ajoutez du caching',
          category: 'network',
        );
      }
    }
    
    // Check error burst
    if (config.errorBurstAlert) {
      final now = DateTime.now();
      final windowStart = now.subtract(Duration(seconds: config.errorBurstWindowSeconds));
      final recentErrors = _logs.where((l) => 
        l.level == LogLevel.error && l.timestamp.isAfter(windowStart)
      ).length;
      
      if (recentErrors >= config.errorBurstThreshold) {
        _createAlert(
          severity: AlertSeverity.critical,
          title: 'Rafale d\'erreurs détectée',
          message: '$recentErrors erreurs en ${config.errorBurstWindowSeconds}s',
          suggestion: 'Vérifiez les logs pour identifier la cause',
          category: 'errors',
        );
      }
    }
  }
  
  /// Crée une alerte (évite les doublons)
  void _createAlert({
    required AlertSeverity severity,
    required String title,
    required String message,
    String? suggestion,
    required String category,
    Map<String, dynamic>? relatedData,
  }) {
    // Éviter les doublons (même titre dans les 60 dernières secondes)
    final recent = _alerts.where((a) => 
      a.title == title && 
      !a.isDismissed &&
      DateTime.now().difference(a.timestamp).inSeconds < 60
    );
    if (recent.isNotEmpty) return;
    
    final alert = SmartAlert(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      severity: severity,
      title: title,
      message: message,
      suggestion: suggestion,
      category: category,
      relatedData: relatedData,
    );
    
    _alerts.add(alert);
    
    // Log l'alerte
    if (severity == AlertSeverity.critical) {
      logError('🚨 ALERTE: $title - $message', source: 'SmartMonitor');
    } else if (severity == AlertSeverity.warning) {
      logWarning('⚠️ $title - $message', source: 'SmartMonitor');
    } else {
      logInfo('ℹ️ $title - $message', source: 'SmartMonitor');
    }
    
    notifyListeners();
  }
  
  /// Marque une alerte comme lue
  void markAlertAsRead(String alertId) {
    final alert = _alerts.firstWhere((a) => a.id == alertId);
    alert.isRead = true;
    notifyListeners();
  }
  
  /// Ferme une alerte
  void dismissAlert(String alertId) {
    final alert = _alerts.firstWhere((a) => a.id == alertId);
    alert.isDismissed = true;
    notifyListeners();
  }
  
  /// Efface toutes les alertes
  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }
  
  /// Met à jour la configuration du monitoring
  void updateMonitorConfig(SmartMonitorConfig config) {
    _monitorConfig = config;
    notifyListeners();
  }
  
  // === SECURITY AUDIT ===
  
  /// Analyse une requête pour les problèmes de sécurité
  void auditRequest(NetworkRequest request) {
    if (!_monitorConfig.securityScanEnabled) return;
    
    final url = request.url;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    
    // Check HTTPS
    if (uri.scheme == 'http' && !uri.host.contains('localhost')) {
      _addSecurityIssue(
        type: SecurityIssueType.noHttps,
        severity: AlertSeverity.warning,
        title: 'Connexion non sécurisée',
        description: 'La requête utilise HTTP au lieu de HTTPS',
        url: url,
        recommendation: 'Utilisez HTTPS pour toutes les connexions',
      );
    }
    
    // Check for exposed API keys in URL
    final apiKeyPatterns = ['api_key=', 'apikey=', 'key=', 'token=', 'secret=', 'password='];
    for (final pattern in apiKeyPatterns) {
      if (url.toLowerCase().contains(pattern)) {
        _addSecurityIssue(
          type: SecurityIssueType.exposedApiKey,
          severity: AlertSeverity.critical,
          title: 'Clé API exposée dans l\'URL',
          description: 'Une clé API ou token est visible dans l\'URL de la requête',
          url: url,
          recommendation: 'Utilisez les headers Authorization pour les tokens',
        );
        break;
      }
    }
    
    // Check for sensitive data in response
    if (request.responseBody != null) {
      final sensitivePatterns = ['password', 'credit_card', 'ssn', 'social_security'];
      final bodyLower = request.responseBody!.toLowerCase();
      for (final pattern in sensitivePatterns) {
        if (bodyLower.contains(pattern)) {
          _addSecurityIssue(
            type: SecurityIssueType.sensitiveData,
            severity: AlertSeverity.warning,
            title: 'Données sensibles potentielles',
            description: 'La réponse peut contenir des données sensibles ($pattern)',
            url: url,
            recommendation: 'Vérifiez que les données sont correctement masquées',
          );
          break;
        }
      }
    }
  }
  
  /// Ajoute un problème de sécurité
  void _addSecurityIssue({
    required SecurityIssueType type,
    required AlertSeverity severity,
    required String title,
    required String description,
    String? url,
    String? recommendation,
    Map<String, dynamic>? evidence,
  }) {
    // Éviter les doublons
    final existing = _securityIssues.where((s) => 
      s.type == type && s.url == url && !s.isResolved
    );
    if (existing.isNotEmpty) return;
    
    final issue = SecurityIssue(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      type: type,
      severity: severity,
      title: title,
      description: description,
      url: url,
      recommendation: recommendation,
      evidence: evidence,
    );
    
    _securityIssues.add(issue);
    
    if (severity == AlertSeverity.critical) {
      logError('🔒 SÉCURITÉ: $title', source: 'SecurityAudit');
    }
    
    notifyListeners();
  }
  
  /// Marque un problème de sécurité comme résolu
  void resolveSecurityIssue(String issueId) {
    final issue = _securityIssues.firstWhere((i) => i.id == issueId);
    issue.isResolved = true;
    notifyListeners();
  }
  
  // === BOOKMARKS ===
  
  /// Ajoute un bookmark
  void addBookmark({
    required String title,
    String? description,
    required String category,
    String? referenceId,
    Map<String, dynamic>? snapshot,
    Color color = const Color(0xFFFFD54F),
  }) {
    final bookmark = DevToolsBookmark(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      title: title,
      description: description,
      category: category,
      referenceId: referenceId,
      snapshot: snapshot,
      color: color,
    );
    
    _bookmarks.add(bookmark);
    _logSystem('🔖 Bookmark ajouté: $title');
    notifyListeners();
  }
  
  /// Supprime un bookmark
  void removeBookmark(String bookmarkId) {
    _bookmarks.removeWhere((b) => b.id == bookmarkId);
    notifyListeners();
  }
  
  // === WIDGET TREE INSPECTOR ===
  
  /// Obsolète - Notilus est un navigateur web, pas un outil de debug Flutter
  void captureWidgetTree() {
    _widgetTree = [];
    _logSystem('Widget tree non disponible - fonctionnalité web uniquement');
    notifyListeners();
  }
  
  // === EXPORT REPORTS ===
  
  /// Génère un rapport complet
  DevToolsReport generateReport({String? title}) {
    final summary = getGlobalAnalytics();
    summary['totalLogs'] = _logs.length;
    summary['totalErrors'] = _logs.where((l) => l.level == LogLevel.error).length;
    summary['totalWarnings'] = _logs.where((l) => l.level == LogLevel.warning).length;
    summary['totalNetworkRequests'] = _requests.length;
    summary['failedRequests'] = _requests.where((r) => r.status == RequestStatus.error).length;
    summary['securityIssues'] = _securityIssues.where((s) => !s.isResolved).length;
    summary['criticalAlerts'] = _alerts.where((a) => a.severity == AlertSeverity.critical && !a.isDismissed).length;
    
    return DevToolsReport(
      id: _uuid.v4(),
      generatedAt: DateTime.now(),
      title: title ?? 'Rapport Notilus DevTools',
      sessionDuration: DateTime.now().difference(_sessionStartTime),
      summary: summary,
      logs: List.from(_logs),
      requests: List.from(_requests),
      performanceHistory: List.from(_performanceHistory),
      alerts: List.from(_alerts),
      securityIssues: List.from(_securityIssues),
      bookmarks: List.from(_bookmarks),
      tabAnalytics: Map.from(_tabAnalytics),
    );
  }
  
  /// Exporte le rapport en JSON
  String exportReportToJson({String? title}) {
    final report = generateReport(title: title);
    return const JsonEncoder.withIndent('  ').convert({
      'report': report.toJson(),
      'logs': _logs.take(100).map((l) => {
        'timestamp': l.timestamp.toIso8601String(),
        'level': l.level.name,
        'message': l.message,
        'source': l.source,
      }).toList(),
      'requests': _requests.take(100).map((r) => {
        'timestamp': r.timestamp.toIso8601String(),
        'method': r.methodLabel,
        'url': r.url,
        'status': r.statusCode,
        'duration': r.duration?.inMilliseconds,
        'size': r.responseSize,
      }).toList(),
      'alerts': _alerts.map((a) => {
        'timestamp': a.timestamp.toIso8601String(),
        'severity': a.severity.name,
        'title': a.title,
        'message': a.message,
        'category': a.category,
      }).toList(),
      'securityIssues': _securityIssues.map((s) => {
        'timestamp': s.timestamp.toIso8601String(),
        'type': s.type.name,
        'severity': s.severity.name,
        'title': s.title,
        'url': s.url,
        'resolved': s.isResolved,
      }).toList(),
    });
  }
  
  // === Cleanup ===
  
  @override
  void dispose() {
    _performanceTimer?.cancel();
    _alertCheckTimer?.cancel();
    super.dispose();
  }
}

/// Client HTTP qui intercepte les requêtes pour le monitoring
class _DevToolsHttpClient extends http.BaseClient {
  final NotilusDevToolsService _devTools;
  final http.Client _inner = http.Client();
  final _uuid = const Uuid();
  
  _DevToolsHttpClient(this._devTools);
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestId = _uuid.v4();
    final startTime = DateTime.now();
    
    // Enregistrer la requête
    final networkRequest = NetworkRequest(
      id: requestId,
      timestamp: startTime,
      method: _parseMethod(request.method),
      url: request.url.toString(),
      requestHeaders: Map.from(request.headers),
      requestBody: request is http.Request ? request.body : null,
      status: RequestStatus.pending,
    );
    
    _devTools.addRequest(networkRequest);
    
    try {
      final response = await _inner.send(request);
      final endTime = DateTime.now();
      
      // Lire le body
      final bytes = await response.stream.toBytes();
      final body = utf8.decode(bytes, allowMalformed: true);
      
      _devTools.updateRequest(
        requestId,
        statusCode: response.statusCode,
        responseHeaders: response.headers,
        responseBody: body,
        responseSize: bytes.length,
        duration: endTime.difference(startTime),
        status: RequestStatus.success,
      );
      
      // Recréer le stream pour le retourner
      return http.StreamedResponse(
        Stream.fromIterable([bytes]),
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        contentLength: bytes.length,
        request: request,
      );
    } catch (e) {
      _devTools.updateRequest(
        requestId,
        status: RequestStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }
  
  HttpMethod _parseMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.get;
      case 'POST':
        return HttpMethod.post;
      case 'PUT':
        return HttpMethod.put;
      case 'DELETE':
        return HttpMethod.delete;
      case 'PATCH':
        return HttpMethod.patch;
      case 'HEAD':
        return HttpMethod.head;
      case 'OPTIONS':
        return HttpMethod.options;
      default:
        return HttpMethod.get;
    }
  }
}
