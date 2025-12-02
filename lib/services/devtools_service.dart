/// Service DevTools natif pour Notilus
/// Capture les logs console, requêtes réseau, métriques performance via injection JS
library devtools_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/devtools_models.dart';
import 'browser_engine.dart';
import '../core/services/logger_service.dart';

/// Service DevTools qui s'interface avec le moteur de rendu web
class DevToolsService extends ChangeNotifier {
  BrowserEngine? _engine;
  Timer? _pollingTimer;
  bool _isEnabled = false;
  bool _isInjected = false;
  String? _currentUrl;

  // Données capturées
  final List<ConsoleEntry> _consoleLogs = [];
  final List<NetworkRequest> _networkRequests = [];
  final List<SourceFile> _sources = [];
  final Map<StorageType, List<StorageItem>> _storage = {};
  PerformanceMetrics? _performanceMetrics;
  DOMNode? _domTree;

  // Filtres console
  Set<ConsoleLevel> _enabledConsoleLevels = ConsoleLevel.values.toSet();
  String _consoleFilter = '';

  // Filtres réseau
  Set<RequestMethod> _enabledMethods = RequestMethod.values.toSet();
  String _networkFilter = '';
  Set<String> _enabledMimeTypes = {'all'};

  // Getters
  List<ConsoleEntry> get consoleLogs => _consoleLogs
      .where((log) =>
          _enabledConsoleLevels.contains(log.level) &&
          (_consoleFilter.isEmpty ||
              log.message.toLowerCase().contains(_consoleFilter.toLowerCase())))
      .toList();

  List<NetworkRequest> get networkRequests => _networkRequests
      .where((req) =>
          _enabledMethods.contains(req.method) &&
          (_networkFilter.isEmpty ||
              req.url.toLowerCase().contains(_networkFilter.toLowerCase())))
      .toList();

  List<SourceFile> get sources => _sources;
  Map<StorageType, List<StorageItem>> get storage => _storage;
  PerformanceMetrics? get performanceMetrics => _performanceMetrics;
  DOMNode? get domTree => _domTree;
  bool get isEnabled => _isEnabled;
  bool get isInjected => _isInjected;
  String get consoleFilter => _consoleFilter;
  String get networkFilter => _networkFilter;
  Set<ConsoleLevel> get enabledConsoleLevels => _enabledConsoleLevels;
  Set<RequestMethod> get enabledMethods => _enabledMethods;

  // Statistiques
  int get totalLogs => _consoleLogs.length;
  int get errorCount =>
      _consoleLogs.where((l) => l.level == ConsoleLevel.error).length;
  int get warningCount =>
      _consoleLogs.where((l) => l.level == ConsoleLevel.warn).length;
  int get totalRequests => _networkRequests.length;
  int get failedRequests =>
      _networkRequests.where((r) => r.status == NetworkRequestStatus.error).length;

  /// Attache le service à un moteur de rendu
  void attachEngine(BrowserEngine engine) {
    _engine = engine;
    _isInjected = false;
    notifyListeners();
  }

  /// Détache le moteur de rendu
  void detachEngine() {
    _engine = null;
    _isInjected = false;
    _stopPolling();
    notifyListeners();
  }

  /// Active le DevTools
  Future<void> enable() async {
    if (_engine == null) return;

    _isEnabled = true;
    await _injectDevToolsScript();
    _startPolling();
    notifyListeners();
  }

  /// Désactive le DevTools
  void disable() {
    _isEnabled = false;
    _stopPolling();
    notifyListeners();
  }

  /// Vide toutes les données
  void clearAll() {
    _consoleLogs.clear();
    _networkRequests.clear();
    _sources.clear();
    _storage.clear();
    _performanceMetrics = null;
    _domTree = null;
    notifyListeners();
  }

  /// Vide les logs console
  void clearConsole() {
    _consoleLogs.clear();
    notifyListeners();
  }

  /// Vide les requêtes réseau
  void clearNetwork() {
    _networkRequests.clear();
    notifyListeners();
  }

  /// Définit le filtre de la console
  void setConsoleFilter(String filter) {
    _consoleFilter = filter;
    notifyListeners();
  }

  /// Définit le filtre réseau
  void setNetworkFilter(String filter) {
    _networkFilter = filter;
    notifyListeners();
  }

  /// Active/désactive un niveau de log
  void toggleConsoleLevel(ConsoleLevel level) {
    if (_enabledConsoleLevels.contains(level)) {
      _enabledConsoleLevels.remove(level);
    } else {
      _enabledConsoleLevels.add(level);
    }
    notifyListeners();
  }

  /// Active/désactive une méthode HTTP
  void toggleRequestMethod(RequestMethod method) {
    if (_enabledMethods.contains(method)) {
      _enabledMethods.remove(method);
    } else {
      _enabledMethods.add(method);
    }
    notifyListeners();
  }

  /// Exécute du JavaScript dans la page
  Future<String?> executeScript(String script) async {
    if (_engine == null) return null;

    try {
      // Wrapper pour capturer le résultat et les erreurs
      final wrappedScript = '''
        (function() {
          try {
            var result = eval(\`$script\`);
            return JSON.stringify({
              success: true,
              result: result !== undefined ? String(result) : 'undefined',
              type: typeof result
            });
          } catch (e) {
            return JSON.stringify({
              success: false,
              error: e.message,
              stack: e.stack
            });
          }
        })();
      ''';

      final result = await _engine!.evaluateJavaScript(wrappedScript);

      // Ajouter à la console
      _addConsoleEntry(ConsoleEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        level: ConsoleLevel.log,
        message: '> $script',
        timestamp: DateTime.now(),
        source: 'Notilus DevTools',
      ));

      if (result != null && result.toString().isNotEmpty) {
        try {
          final parsed = jsonDecode(result.toString());
          if (parsed['success'] == true) {
            final output = parsed['result'] ?? 'undefined';
            _addConsoleEntry(ConsoleEntry(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              level: ConsoleLevel.info,
              message: '← $output',
              timestamp: DateTime.now(),
              source: 'Notilus DevTools',
            ));
            return output;
          } else {
            _addConsoleEntry(ConsoleEntry(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              level: ConsoleLevel.error,
              message: '✕ ${parsed['error']}',
              timestamp: DateTime.now(),
              stackTrace: parsed['stack'],
              source: 'Notilus DevTools',
            ));
            return null;
          }
        } catch (_) {
          return result.toString();
        }
      }
      return null;
    } catch (e) {
      _addConsoleEntry(ConsoleEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        level: ConsoleLevel.error,
        message: 'Erreur d\'exécution: $e',
        timestamp: DateTime.now(),
        source: 'Notilus DevTools',
      ));
      return null;
    }
  }

  /// Récupère l'arbre DOM
  Future<void> fetchDOMTree() async {
    if (_engine == null) return;

    try {
      final result = await _engine!.evaluateJavaScript(_getDOMTreeScript());
      if (result != null && result.toString().isNotEmpty) {
        try {
          final parsed = jsonDecode(result.toString());
          _domTree = DOMNode.fromJson(parsed);
          notifyListeners();
        } catch (e) {
          LoggerService().error('Error parsing DOM tree', error: e);
        }
      }
    } catch (e) {
      LoggerService().error('Error fetching DOM tree', error: e);
    }
  }

  /// Récupère les métriques de performance
  Future<void> fetchPerformanceMetrics() async {
    if (_engine == null) return;

    try {
      final result = await _engine!.evaluateJavaScript(_getPerformanceScript());
      if (result != null && result.toString().isNotEmpty) {
        try {
          final parsed = jsonDecode(result.toString());
          _performanceMetrics = PerformanceMetrics.fromJson(parsed);
          notifyListeners();
        } catch (e) {
          LoggerService().error('Error parsing performance metrics', error: e);
        }
      }
    } catch (e) {
      LoggerService().error('Error fetching performance metrics', error: e);
    }
  }

  /// Récupère les données de storage
  Future<void> fetchStorage() async {
    if (_engine == null) return;

    try {
      final result = await _engine!.evaluateJavaScript(_getStorageScript());
      if (result != null && result.toString().isNotEmpty) {
        try {
          final parsed = jsonDecode(result.toString());

          _storage.clear();

          // LocalStorage
          final localItems = (parsed['localStorage'] as List<dynamic>?)
                  ?.map((e) => StorageItem.fromJson(
                      e as Map<String, dynamic>, StorageType.localStorage))
                  .toList() ??
              [];
          _storage[StorageType.localStorage] = localItems;

          // SessionStorage
          final sessionItems = (parsed['sessionStorage'] as List<dynamic>?)
                  ?.map((e) => StorageItem.fromJson(
                      e as Map<String, dynamic>, StorageType.sessionStorage))
                  .toList() ??
              [];
          _storage[StorageType.sessionStorage] = sessionItems;

          // Cookies
          final cookieItems = (parsed['cookies'] as List<dynamic>?)
                  ?.map((e) => StorageItem.fromJson(
                      e as Map<String, dynamic>, StorageType.cookie))
                  .toList() ??
              [];
          _storage[StorageType.cookie] = cookieItems;

          notifyListeners();
        } catch (e) {
          LoggerService().error('Error parsing storage', error: e);
        }
      }
    } catch (e) {
      LoggerService().error('Error fetching storage', error: e);
    }
  }

  /// Récupère les sources (scripts)
  Future<void> fetchSources() async {
    if (_engine == null) return;

    try {
      final result = await _engine!.evaluateJavaScript(_getSourcesScript());
      if (result != null && result.toString().isNotEmpty) {
        try {
          final parsed = jsonDecode(result.toString()) as List<dynamic>;
          _sources.clear();
          _sources.addAll(
              parsed.map((e) => SourceFile.fromJson(e as Map<String, dynamic>)));
          notifyListeners();
        } catch (e) {
          LoggerService().error('Error parsing sources', error: e);
        }
      }
    } catch (e) {
      LoggerService().error('Error fetching sources', error: e);
    }
  }

  /// Inspecte un élément spécifique du DOM
  Future<Map<String, dynamic>?> inspectElement(String selector) async {
    if (_engine == null) return null;

    try {
      final script = '''
        (function() {
          var el = document.querySelector('$selector');
          if (!el) return null;
          
          var rect = el.getBoundingClientRect();
          var styles = window.getComputedStyle(el);
          
          return JSON.stringify({
            tagName: el.tagName.toLowerCase(),
            id: el.id || null,
            className: el.className || null,
            attributes: Array.from(el.attributes).reduce((acc, attr) => {
              acc[attr.name] = attr.value;
              return acc;
            }, {}),
            rect: {
              x: rect.x,
              y: rect.y,
              width: rect.width,
              height: rect.height
            },
            styles: {
              display: styles.display,
              position: styles.position,
              color: styles.color,
              backgroundColor: styles.backgroundColor,
              fontSize: styles.fontSize,
              fontFamily: styles.fontFamily,
              padding: styles.padding,
              margin: styles.margin,
              border: styles.border
            },
            innerHTML: el.innerHTML.substring(0, 500)
          });
        })();
      ''';

      final result = await _engine!.evaluateJavaScript(script);
      if (result != null && result.toString().isNotEmpty) {
        return jsonDecode(result.toString()) as Map<String, dynamic>;
      }
    } catch (e) {
      LoggerService().error('Error inspecting element', error: e);
    }
    return null;
  }

  // --- Méthodes privées ---

  void _addConsoleEntry(ConsoleEntry entry) {
    _consoleLogs.add(entry);
    // Limiter à 1000 entrées
    if (_consoleLogs.length > 1000) {
      _consoleLogs.removeAt(0);
    }
    notifyListeners();
  }

  void _startPolling() {
    _stopPolling();
    // Polling plus fréquent pour un temps réel plus rapide (100ms au lieu de 500ms)
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _pollData();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollData() async {
    if (_engine == null || !_isEnabled) return;

    try {
      // Récupérer les logs et requêtes depuis le script injecté
      final result = await _engine!.evaluateJavaScript('''
        (function() {
          if (!window.__NOTILUS_DEVTOOLS__) return null;
          var data = window.__NOTILUS_DEVTOOLS__.flush();
          return JSON.stringify(data);
        })();
      ''');

      if (result != null && result.toString().isNotEmpty && result.toString() != 'null') {
        try {
          final parsed = jsonDecode(result.toString());

          // Traiter les logs console
          final logs = parsed['logs'] as List<dynamic>? ?? [];
          for (final log in logs) {
            _consoleLogs.add(ConsoleEntry.fromJson(log as Map<String, dynamic>));
          }

          // Traiter les requêtes réseau
          final requests = parsed['requests'] as List<dynamic>? ?? [];
          bool hasNetworkUpdates = false;
          for (final req in requests) {
            final request =
                NetworkRequest.fromJson(req as Map<String, dynamic>);
            // Mettre à jour ou ajouter
            final existingIndex =
                _networkRequests.indexWhere((r) => r.id == request.id);
            if (existingIndex >= 0) {
              // Vérifier si la requête a vraiment changé
              final existing = _networkRequests[existingIndex];
              if (existing.status != request.status ||
                  existing.statusCode != request.statusCode ||
                  existing.duration != request.duration) {
                _networkRequests[existingIndex] = request;
                hasNetworkUpdates = true;
              }
            } else {
              _networkRequests.add(request);
              hasNetworkUpdates = true;
            }
          }

          // Limiter les listes
          if (_consoleLogs.length > 1000) {
            _consoleLogs.removeRange(0, _consoleLogs.length - 1000);
          }
          if (_networkRequests.length > 500) {
            _networkRequests.removeRange(0, _networkRequests.length - 500);
          }

          // Notifier seulement s'il y a des changements
          if (logs.isNotEmpty || hasNetworkUpdates) {
            notifyListeners();
          }
        } catch (e) {
          LoggerService().error('Error parsing polled data', error: e);
        }
      }
    } catch (e) {
      // Ignorer les erreurs de polling silencieusement
    }
  }

  Future<void> _injectDevToolsScript() async {
    if (_engine == null) return;

    try {
      await _engine!.executeJavaScript(_getInjectionScript());
      _isInjected = true;
      notifyListeners();
    } catch (e) {
      LoggerService().error('Error injecting DevTools script', error: e);
    }
  }

  /// Script d'injection principal
  String _getInjectionScript() => '''
    (function() {
      if (window.__NOTILUS_DEVTOOLS__) return;
      
      window.__NOTILUS_DEVTOOLS__ = {
        logs: [],
        requests: [],
        requestMap: {},
        
        // Ajouter un log
        addLog: function(level, message, source, line, column, stack, args) {
          this.logs.push({
            id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
            level: level,
            message: message,
            timestamp: Date.now(),
            source: source || null,
            lineNumber: line || null,
            columnNumber: column || null,
            stackTrace: stack || null,
            args: args || null
          });
        },
        
        // Ajouter une requête
        addRequest: function(request) {
          this.requestMap[request.id] = request;
          this.requests.push(request);
        },
        
        // Mettre à jour une requête
        updateRequest: function(id, updates) {
          if (this.requestMap[id]) {
            Object.assign(this.requestMap[id], updates);
            // S'assurer que la requête mise à jour est aussi dans requests pour le flush
            var existingIndex = -1;
            for (var i = 0; i < this.requests.length; i++) {
              if (this.requests[i].id === id) {
                existingIndex = i;
                break;
              }
            }
            if (existingIndex >= 0) {
              Object.assign(this.requests[existingIndex], updates);
            } else {
              // Si pas dans requests, l'ajouter
              this.requests.push(this.requestMap[id]);
            }
          }
        },
        
        // Récupérer et vider les données
        flush: function() {
          // Inclure toutes les requêtes mises à jour depuis requestMap
          var allRequests = [];
          var requestIds = new Set();
          
          // Ajouter les nouvelles requêtes
          for (var i = 0; i < this.requests.length; i++) {
            var req = this.requests[i];
            requestIds.add(req.id);
            allRequests.push(req);
          }
          
          // Ajouter les requêtes mises à jour qui ne sont pas dans requests
          for (var id in this.requestMap) {
            if (!requestIds.has(id)) {
              allRequests.push(this.requestMap[id]);
            }
          }
          
          var data = {
            logs: this.logs.slice(),
            requests: allRequests
          };
          this.logs = [];
          this.requests = [];
          return data;
        }
      };
      
      // Intercepter console
      var originalConsole = {
        log: console.log,
        info: console.info,
        warn: console.warn,
        error: console.error,
        debug: console.debug,
        table: console.table
      };
      
      function formatArgs(args) {
        return Array.from(args).map(function(arg) {
          if (typeof arg === 'object') {
            try { return JSON.stringify(arg, null, 2); }
            catch (e) { return String(arg); }
          }
          return String(arg);
        }).join(' ');
      }
      
      function getStack() {
        try {
          throw new Error();
        } catch (e) {
          var lines = e.stack.split('\\n');
          return lines.slice(3).join('\\n');
        }
      }
      
      ['log', 'info', 'warn', 'error', 'debug'].forEach(function(level) {
        console[level] = function() {
          originalConsole[level].apply(console, arguments);
          window.__NOTILUS_DEVTOOLS__.addLog(
            level,
            formatArgs(arguments),
            null, null, null,
            level === 'error' ? getStack() : null,
            null
          );
        };
      });
      
      console.table = function(data) {
        originalConsole.table.apply(console, arguments);
        window.__NOTILUS_DEVTOOLS__.addLog(
          'table',
          JSON.stringify(data, null, 2),
          null, null, null, null, null
        );
      };
      
      // Intercepter les erreurs globales
      window.addEventListener('error', function(e) {
        window.__NOTILUS_DEVTOOLS__.addLog(
          'error',
          e.message,
          e.filename,
          e.lineno,
          e.colno,
          e.error ? e.error.stack : null,
          null
        );
      });
      
      window.addEventListener('unhandledrejection', function(e) {
        window.__NOTILUS_DEVTOOLS__.addLog(
          'error',
          'Unhandled Promise Rejection: ' + String(e.reason),
          null, null, null,
          e.reason && e.reason.stack ? e.reason.stack : null,
          null
        );
      });
      
      // Intercepter XMLHttpRequest
      var OriginalXHR = window.XMLHttpRequest;
      window.XMLHttpRequest = function() {
        var xhr = new OriginalXHR();
        var reqId = Date.now().toString() + Math.random().toString(36).substr(2, 9);
        var reqData = {
          id: reqId,
          method: 'GET',
          url: '',
          startTime: 0,
          requestHeaders: {}
        };
        
        var originalOpen = xhr.open;
        xhr.open = function(method, url) {
          reqData.method = method;
          reqData.url = url;
          return originalOpen.apply(xhr, arguments);
        };
        
        var originalSetHeader = xhr.setRequestHeader;
        xhr.setRequestHeader = function(name, value) {
          reqData.requestHeaders[name] = value;
          return originalSetHeader.apply(xhr, arguments);
        };
        
        var originalSend = xhr.send;
        xhr.send = function(body) {
          reqData.startTime = Date.now();
          reqData.requestBody = body ? String(body).substring(0, 1000) : null;
          reqData.status = 'pending';
          
          window.__NOTILUS_DEVTOOLS__.addRequest({
            id: reqData.id,
            method: reqData.method,
            url: reqData.url,
            startTime: reqData.startTime,
            status: 'pending',
            requestHeaders: reqData.requestHeaders,
            requestBody: reqData.requestBody
          });
          
          return originalSend.apply(xhr, arguments);
        };
        
        xhr.addEventListener('load', function() {
          window.__NOTILUS_DEVTOOLS__.updateRequest(reqData.id, {
            endTime: Date.now(),
            duration: Date.now() - reqData.startTime,
            statusCode: xhr.status,
            statusText: xhr.statusText,
            status: xhr.status >= 200 && xhr.status < 400 ? 'success' : 'error',
            responseHeaders: xhr.getAllResponseHeaders().split('\\r\\n').reduce(function(acc, line) {
              var parts = line.split(': ');
              if (parts[0]) acc[parts[0]] = parts.slice(1).join(': ');
              return acc;
            }, {}),
            responseSize: xhr.response ? xhr.response.length : 0,
            mimeType: xhr.getResponseHeader('content-type')
          });
        });
        
        xhr.addEventListener('error', function() {
          window.__NOTILUS_DEVTOOLS__.updateRequest(reqData.id, {
            endTime: Date.now(),
            duration: Date.now() - reqData.startTime,
            status: 'error',
            statusCode: 0
          });
        });
        
        return xhr;
      };
      
      // Intercepter fetch
      var originalFetch = window.fetch;
      window.fetch = function(input, init) {
        var reqId = Date.now().toString() + Math.random().toString(36).substr(2, 9);
        var url = typeof input === 'string' ? input : input.url;
        var method = (init && init.method) || 'GET';
        var startTime = Date.now();
        
        window.__NOTILUS_DEVTOOLS__.addRequest({
          id: reqId,
          method: method,
          url: url,
          startTime: startTime,
          status: 'pending',
          requestHeaders: init && init.headers ? Object.fromEntries(
            init.headers instanceof Headers ? init.headers.entries() : Object.entries(init.headers)
          ) : {},
          requestBody: init && init.body ? String(init.body).substring(0, 1000) : null
        });
        
        return originalFetch.apply(window, arguments).then(function(response) {
          var clone = response.clone();
          clone.text().then(function(text) {
            window.__NOTILUS_DEVTOOLS__.updateRequest(reqId, {
              endTime: Date.now(),
              duration: Date.now() - startTime,
              statusCode: response.status,
              statusText: response.statusText,
              status: response.ok ? 'success' : 'error',
              responseHeaders: Object.fromEntries(response.headers.entries()),
              responseSize: text.length,
              mimeType: response.headers.get('content-type')
            });
          });
          return response;
        }).catch(function(error) {
          window.__NOTILUS_DEVTOOLS__.updateRequest(reqId, {
            endTime: Date.now(),
            duration: Date.now() - startTime,
            status: 'error',
            statusCode: 0
          });
          throw error;
        });
      };
      
      console.log('%c🐙 Notilus DevTools activé', 'color: #FF2D55; font-weight: bold; font-size: 14px;');
    })();
  ''';

  /// Script pour récupérer l'arbre DOM
  String _getDOMTreeScript() => '''
    (function() {
      function serializeNode(node, depth) {
        if (depth > 10) return null;
        if (!node || node.nodeType !== 1) return null;
        
        var children = [];
        var childNodes = node.children;
        for (var i = 0; i < childNodes.length && i < 50; i++) {
          var child = serializeNode(childNodes[i], depth + 1);
          if (child) children.push(child);
        }
        
        var attrs = {};
        for (var i = 0; i < node.attributes.length; i++) {
          var attr = node.attributes[i];
          attrs[attr.name] = attr.value;
        }
        
        var textContent = null;
        if (node.childNodes.length === 1 && node.childNodes[0].nodeType === 3) {
          textContent = node.childNodes[0].textContent.trim().substring(0, 100);
        }
        
        return {
          id: Math.random().toString(36).substr(2, 9),
          tagName: node.tagName.toLowerCase(),
          nodeId: node.id || null,
          attributes: attrs,
          children: children,
          textContent: textContent
        };
      }
      
      return JSON.stringify(serializeNode(document.documentElement, 0));
    })();
  ''';

  /// Script pour récupérer les métriques de performance
  String _getPerformanceScript() => '''
    (function() {
      var perf = window.performance;
      var timing = perf.timing;
      var navigation = perf.getEntriesByType('navigation')[0] || {};
      var paint = perf.getEntriesByType('paint');
      var memory = perf.memory || {};
      
      var fp = paint.find(function(p) { return p.name === 'first-paint'; });
      var fcp = paint.find(function(p) { return p.name === 'first-contentful-paint'; });
      
      return JSON.stringify({
        pageLoadTime: timing.loadEventEnd - timing.navigationStart,
        domContentLoaded: timing.domContentLoadedEventEnd - timing.navigationStart,
        firstPaint: fp ? fp.startTime : null,
        firstContentfulPaint: fcp ? fcp.startTime : null,
        largestContentfulPaint: null,
        timeToInteractive: timing.domInteractive - timing.navigationStart,
        totalBlockingTime: null,
        cumulativeLayoutShift: null,
        jsHeapSize: memory.totalJSHeapSize || null,
        usedJsHeapSize: memory.usedJSHeapSize || null,
        domNodes: document.getElementsByTagName('*').length,
        resources: perf.getEntriesByType('resource').length,
        transferSize: perf.getEntriesByType('resource').reduce(function(sum, r) {
          return sum + (r.transferSize || 0);
        }, 0)
      });
    })();
  ''';

  /// Script pour récupérer le storage
  String _getStorageScript() => '''
    (function() {
      var result = {
        localStorage: [],
        sessionStorage: [],
        cookies: []
      };
      
      // LocalStorage
      try {
        for (var i = 0; i < localStorage.length; i++) {
          var key = localStorage.key(i);
          result.localStorage.push({
            key: key,
            value: localStorage.getItem(key).substring(0, 500)
          });
        }
      } catch (e) {}
      
      // SessionStorage
      try {
        for (var i = 0; i < sessionStorage.length; i++) {
          var key = sessionStorage.key(i);
          result.sessionStorage.push({
            key: key,
            value: sessionStorage.getItem(key).substring(0, 500)
          });
        }
      } catch (e) {}
      
      // Cookies
      try {
        var cookies = document.cookie.split(';');
        for (var i = 0; i < cookies.length; i++) {
          var parts = cookies[i].trim().split('=');
          if (parts[0]) {
            result.cookies.push({
              key: parts[0],
              value: parts.slice(1).join('=').substring(0, 500)
            });
          }
        }
      } catch (e) {}
      
      return JSON.stringify(result);
    })();
  ''';

  /// Script pour récupérer les sources
  String _getSourcesScript() => '''
    (function() {
      var sources = [];
      
      // Scripts
      var scripts = document.getElementsByTagName('script');
      for (var i = 0; i < scripts.length; i++) {
        var script = scripts[i];
        if (script.src) {
          sources.push({
            id: Math.random().toString(36).substr(2, 9),
            url: script.src,
            mimeType: 'application/javascript',
            size: null
          });
        }
      }
      
      // Stylesheets
      var links = document.getElementsByTagName('link');
      for (var i = 0; i < links.length; i++) {
        var link = links[i];
        if (link.rel === 'stylesheet' && link.href) {
          sources.push({
            id: Math.random().toString(36).substr(2, 9),
            url: link.href,
            mimeType: 'text/css',
            size: null
          });
        }
      }
      
      // Document
      sources.unshift({
        id: 'document',
        url: document.location.href,
        mimeType: 'text/html',
        size: document.documentElement.outerHTML.length
      });
      
      return JSON.stringify(sources);
    })();
  ''';

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
