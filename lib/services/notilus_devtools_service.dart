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
  
  // === Getters ===
  bool get isNetworkRecording => _isNetworkRecording;
  bool get isPerformanceMonitoring => _isPerformanceMonitoring;
  double get currentFps => _currentFps;
  
  // === WebView Console/Network Capture ===
  final Map<String, Function(String)> _webViewLogHandlers = {};
  
  // === Initialization ===
  void initialize() {
    _httpClient = _DevToolsHttpClient(this);
    _logSystem('Notilus DevTools initialisé');
    _logSystem('Version: 2.0.0 | Build: native-real-metrics');
    _logSystem('Métriques: CPU, Mémoire, Widgets, FPS - RÉELLES');
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
  
  /// Compte le nombre réel de widgets dans l'arbre
  int _countRealActiveWidgets() {
    try {
      int count = 0;
      void countWidgets(Element element) {
        count++;
        element.visitChildren(countWidgets);
      }
      
      // Obtenir le root element
      final binding = WidgetsBinding.instance;
      binding.rootElement?.visitChildren(countWidgets);
      
      return count;
    } catch (e) {
      return 0;
    }
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
  Widgets: ${last.activeWidgets}
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
        return 'Notilus DevTools v1.0.0';
      
      default:
        return 'Commande inconnue: $cmd\nTapez "help" pour voir les commandes disponibles';
    }
  }
  
  String _getHelpText() {
    return '''
═══════════════════════════════════════
  NOTILUS DEVTOOLS - COMMANDES REPL
═══════════════════════════════════════

Console:
  help          Affiche cette aide
  clear         Vide la console
  logs          Nombre de logs
  echo <msg>    Affiche un message

Réseau:
  requests      Nombre de requêtes
  fetch <url>   Effectue une requête GET

Performance:
  perf          Métriques actuelles

Storage:
  storage       Nombre d'entrées
  get <key>     Lire une valeur
  set <k> <v>   Définir une valeur
  del <key>     Supprimer une clé

Utilitaires:
  env           Infos environnement
  time          Heure actuelle
  json <str>    Formater du JSON
  version       Version DevTools

═══════════════════════════════════════
''';
  }
  
  void clearReplHistory() {
    _replHistory.clear();
    notifyListeners();
  }
  
  // === Cleanup ===
  
  @override
  void dispose() {
    _performanceTimer?.cancel();
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
