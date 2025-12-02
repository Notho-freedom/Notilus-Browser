/// Service Backend Lab pour Flutter
/// Communique avec l'API Backend Lab pour les tests backend
library backend_lab_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/backend_lab/backend_lab_models.dart';

/// Service principal du Backend Lab
class BackendLabService extends ChangeNotifier {
  static const String _defaultBaseUrl = 'http://localhost:8000';
  
  String _baseUrl;
  bool _isConnected = false;
  String? _lastError;
  
  // Données en cache
  List<DiscoveredServer> _servers = [];
  List<DiscoveredRoute> _routes = [];
  List<Vulnerability> _vulnerabilities = [];
  List<CapturedRequest> _captures = [];
  List<TestResult> _testResults = [];
  List<LoadTestResult> _loadTestResults = [];
  OverviewStats? _stats;
  
  // Scan en cours
  bool _isScanning = false;
  
  // Console logs
  final List<ConsoleLogEntry> _consoleLogs = [];
  WebSocketChannel? _consoleWebSocket;
  StreamSubscription? _consoleSubscription;
  final StreamController<ConsoleLogEntry> _consoleLogController = StreamController<ConsoleLogEntry>.broadcast();
  
  BackendLabService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;
  
  // Getters
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;
  List<DiscoveredServer> get servers => _servers;
  List<DiscoveredRoute> get routes => _routes;
  List<Vulnerability> get vulnerabilities => _vulnerabilities;
  List<CapturedRequest> get captures => _captures;
  List<TestResult> get testResults => _testResults;
  List<LoadTestResult> get loadTestResults => _loadTestResults;
  OverviewStats? get stats => _stats;
  bool get isScanning => _isScanning;
  
  String get baseUrl => _baseUrl;
  
  set baseUrl(String url) {
    _baseUrl = url;
    notifyListeners();
  }
  
  // ============================================================================
  // Connection
  // ============================================================================
  
  /// Vérifie la connexion à l'API
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/analytics/health'),
      ).timeout(const Duration(seconds: 5));
      
      _isConnected = response.statusCode == 200;
      _lastError = _isConnected ? null : 'Server returned ${response.statusCode}';
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
    }
    
    notifyListeners();
    return _isConnected;
  }
  
  // ============================================================================
  // Server Discovery
  // ============================================================================
  
  /// Lance un scan des serveurs locaux
  Future<List<DiscoveredServer>> scanServers({
    List<int>? specificPorts,
    bool enableFingerprinting = true,
  }) async {
    _isScanning = true;
    notifyListeners();
    
    try {
      final body = <String, dynamic>{
        'enable_fingerprinting': enableFingerprinting,
      };
      if (specificPorts != null) {
        body['specific_ports'] = specificPorts;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backend-lab/servers/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serversJson = data['servers_found'] as List? ?? [];
        _servers = serversJson
            .map((s) => DiscoveredServer.fromJson(s))
            .toList();
        _lastError = null;
      } else {
        _lastError = 'Scan failed: ${response.statusCode}';
      }
    } catch (e) {
      _lastError = e.toString();
    }
    
    _isScanning = false;
    notifyListeners();
    return _servers;
  }
  
  /// Récupère la liste des serveurs
  Future<List<DiscoveredServer>> getServers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/servers/servers'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _servers = data.map((s) => DiscoveredServer.fromJson(s)).toList();
        _lastError = null;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    
    notifyListeners();
    return _servers;
  }
  
  /// Effectue un health check sur un serveur
  Future<HealthCheckResult?> healthCheck(String serverId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backend-lab/servers/servers/$serverId/health'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HealthCheckResult.fromJson(data);
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }
  
  /// Découvre ou ajoute un serveur manuellement (pour les serveurs de l'historique)
  /// Retourne le serveur découvert ou null si échec
  Future<DiscoveredServer?> discoverOrAddServer({
    required String host,
    required int port,
    String protocol = 'http',
    String? name,
  }) async {
    final serverId = '$host:$port';
    
    // Vérifier si le serveur existe déjà
    final existingServer = _servers.firstWhere(
      (s) => s.host == host && s.port == port,
      orElse: () => DiscoveredServer(id: '', port: 0),
    );
    
    if (existingServer.id.isNotEmpty) {
      return existingServer;
    }
    
    // Détecter si c'est un serveur local ou distant
    final isLocal = host == 'localhost' || 
                   host == '127.0.0.1' || 
                   host.startsWith('192.168.') || 
                   host.startsWith('10.') || 
                   host.startsWith('172.');
    
    try {
      if (isLocal) {
        // Pour les serveurs locaux, essayer un scan ciblé
        try {
          final scanResult = await scanServers(
            specificPorts: [port],
            enableFingerprinting: true,
          ).timeout(const Duration(seconds: 10));
          
          // Vérifier si le serveur a été découvert
          final discovered = scanResult.firstWhere(
            (s) => s.host == host && s.port == port,
            orElse: () => DiscoveredServer(id: '', port: 0),
          );
          
          if (discovered.id.isNotEmpty) {
            return discovered;
          }
        } catch (e) {
          // Si le scan échoue, continuer avec la création manuelle
          debugPrint('Scan failed for $host:$port: $e');
        }
      }
      
      // Créer un serveur manuellement (pour serveurs distants ou si scan échoue)
      final manualServer = DiscoveredServer(
        id: serverId,
        host: host,
        port: port,
        protocol: protocol,
        name: name ?? '$host:$port',
        status: ServerStatus.unknown,
      );
      
      // Ajouter le serveur à la liste
      _servers.add(manualServer);
      notifyListeners();
      
      // Pour les serveurs locaux, essayer un health check
      if (isLocal) {
        try {
          final health = await healthCheck(serverId).timeout(const Duration(seconds: 5));
          if (health != null) {
            final updatedServer = DiscoveredServer(
              id: serverId,
              host: host,
              port: port,
              protocol: protocol,
              name: name ?? '$host:$port',
              status: health.status == HealthStatus.healthy 
                  ? ServerStatus.running 
                  : ServerStatus.unknown,
              health: health,
            );
            
            _servers.removeWhere((s) => s.id == serverId);
            _servers.add(updatedServer);
            notifyListeners();
            return updatedServer;
          }
        } catch (e) {
          // Si le health check échoue, garder le serveur manuel
          debugPrint('Health check failed for $host:$port: $e');
        }
      }
      
      return manualServer;
    } catch (e) {
      _lastError = e.toString();
      // Créer quand même un serveur basique pour permettre la découverte de routes
      final manualServer = DiscoveredServer(
        id: serverId,
        host: host,
        port: port,
        protocol: protocol,
        name: name ?? '$host:$port',
        status: ServerStatus.unknown,
      );
      
      // Vérifier qu'il n'existe pas déjà avant d'ajouter
      if (!_servers.any((s) => s.id == serverId)) {
        _servers.add(manualServer);
        notifyListeners();
      }
      return manualServer;
    }
  }
  
  // ============================================================================
  // Route Discovery
  // ============================================================================
  
  /// Découvre les routes d'un serveur
  Future<List<DiscoveredRoute>> discoverRoutes(
    String serverId, {
    bool useOpenapi = true,
    bool useGraphql = true,
    bool useFuzzing = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backend-lab/routes/discover/$serverId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'use_openapi': useOpenapi,
          'use_graphql': useGraphql,
          'use_fuzzing': useFuzzing,
        }),
      ).timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final newRoutes = data.map((r) => DiscoveredRoute.fromJson(r)).toList();
        
        // Ajouter ou mettre à jour les routes
        for (final route in newRoutes) {
          _routes.removeWhere((r) => r.id == route.id);
          _routes.add(route);
        }
        
        _lastError = null;
        notifyListeners();
        return newRoutes;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    
    notifyListeners();
    return [];
  }
  
  /// Récupère les routes d'un serveur
  Future<List<DiscoveredRoute>> getRoutes(String serverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/routes/$serverId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final routes = data.map((r) => DiscoveredRoute.fromJson(r)).toList();
        
        // Mettre à jour le cache (remplacer les routes de ce serveur)
        _routes.removeWhere((r) => r.serverId == serverId);
        _routes.addAll(routes);
        
        _lastError = null;
        notifyListeners();
        return routes;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
    return [];
  }
  
  // ============================================================================
  // API Testing
  // ============================================================================
  
  /// Exécute un test rapide
  Future<TestResult?> runQuickTest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
    String bodyType = 'none',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backend-lab/tests/run'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'method': method,
          'url': url,
          'headers': headers ?? {},
          'body': body,
          'body_type': bodyType,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = TestResult.fromJson(data);
        _testResults.insert(0, result);
        notifyListeners();
        return result;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }
  
  /// Récupère les résultats de tests
  Future<List<TestResult>> getTestResults({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/tests/results?limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _testResults = data.map((r) => TestResult.fromJson(r)).toList();
        notifyListeners();
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return _testResults;
  }
  
  // ============================================================================
  // Interception
  // ============================================================================
  
  /// Récupère les requêtes capturées
  Future<List<CapturedRequest>> getCaptures({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/intercept/captures?limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _captures = data.map((c) => CapturedRequest.fromJson(c)).toList();
        notifyListeners();
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return _captures;
  }
  
  /// Rejoue une requête capturée
  Future<CapturedRequest?> replayCapture(String captureId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backend-lab/intercept/captures/$captureId/replay'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final capture = CapturedRequest.fromJson(data);
        _captures.insert(0, capture);
        notifyListeners();
        return capture;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }
  
  /// Vide les captures
  Future<bool> clearCaptures() async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/backend-lab/intercept/captures'),
      );
      
      if (response.statusCode == 200) {
        _captures.clear();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return false;
  }
  
  // ============================================================================
  // Security Scanner
  // ============================================================================
  
  /// Lance un scan de sécurité
  Future<SecurityScanResult?> runSecurityScan({
    List<String>? serverIds,
    List<String>? routeIds,
    bool testInjections = true,
    bool testXss = true,
    bool testHeaders = true,
    bool testCors = true,
    bool testRateLimiting = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backend-lab/security/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'server_ids': serverIds ?? [],
          'route_ids': routeIds ?? [],
          'test_injections': testInjections,
          'test_xss': testXss,
          'test_headers': testHeaders,
          'test_cors': testCors,
          'test_rate_limiting': testRateLimiting,
        }),
      ).timeout(const Duration(minutes: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = SecurityScanResult.fromJson(data);
        
        // Mettre à jour les vulnérabilités
        for (final vuln in result.vulnerabilities) {
          _vulnerabilities.removeWhere((v) => v.id == vuln.id);
          _vulnerabilities.add(vuln);
        }
        
        notifyListeners();
        return result;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }
  
  /// Récupère les vulnérabilités
  Future<List<Vulnerability>> getVulnerabilities() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/security/vulnerabilities'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _vulnerabilities = data.map((v) => Vulnerability.fromJson(v)).toList();
        notifyListeners();
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return _vulnerabilities;
  }
  
  // ============================================================================
  // Performance Lab
  // ============================================================================
  
  /// Lance un test de charge
  Future<LoadTestResult?> runLoadTest({
    required String name,
    required String targetUrl,
    int virtualUsers = 10,
    int durationSec = 60,
    int rampUpSec = 10,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backend-lab/performance/load'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'target_url': targetUrl,
          'virtual_users': virtualUsers,
          'duration_sec': durationSec,
          'ramp_up_time_sec': rampUpSec,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = LoadTestResult.fromJson(data);
        
        // Ajouter le résultat à la liste
        _loadTestResults.insert(0, result); // Ajouter au début
        if (_loadTestResults.length > 50) {
          _loadTestResults.removeLast(); // Garder seulement les 50 derniers
        }
        
        notifyListeners();
        return result;
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
    return null;
  }
  
  /// Récupère un résultat de test de performance
  Future<LoadTestResult?> getLoadTestResult(String runId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/performance/runs/$runId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoadTestResult.fromJson(data);
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }
  
  // ============================================================================
  // Analytics
  // ============================================================================
  
  /// Récupère les statistiques globales
  Future<OverviewStats?> getOverviewStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/analytics/overview'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _stats = OverviewStats.fromJson(data);
        notifyListeners();
        return _stats;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }
  
  /// Récupère le résumé de sécurité
  Future<Map<String, dynamic>?> getSecuritySummary() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/analytics/security'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }
  
  // ============================================================================
  // Auto Configuration
  // ============================================================================
  
  /// Configure automatiquement un serveur (découvre routes, détecte paramètres, crée tests)
  Future<Map<String, dynamic>?> configureServer(
    String serverId, {
    bool discoverRoutes = true,
    bool detectParameters = true,
    bool createTests = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/backend-lab/auto-config/servers/$serverId/configure'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'discover_routes': discoverRoutes,
          'detect_parameters': detectParameters,
          'create_tests': createTests,
        }),
      ).timeout(const Duration(minutes: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Rafraîchir les données après configuration
        await Future.wait([
          getServers(),
          getRoutes(serverId),
        ]);
        notifyListeners();
        return data;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }
  
  /// Détecte les paramètres d'une route ou de toutes les routes d'un serveur
  Future<List<DiscoveredRoute>?> detectRouteParameters(
    String serverId, {
    String? routeId,
  }) async {
    try {
      final url = routeId != null
          ? '$_baseUrl/api/backend-lab/auto-config/servers/$serverId/detect-parameters?route_id=$routeId'
          : '$_baseUrl/api/backend-lab/auto-config/servers/$serverId/detect-parameters';
      
      final response = await http.post(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = (data is List ? data : [data])
            .map((r) => DiscoveredRoute.fromJson(r))
            .toList();
        
        // Mettre à jour les routes
        for (final route in routes) {
          _routes.removeWhere((r) => r.id == route.id);
          _routes.add(route);
        }
        
        notifyListeners();
        return routes;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }
  
  // ============================================================================
  // Helpers
  // ============================================================================
  
  /// Rafraîchit toutes les données
  Future<void> refreshAll() async {
    await Future.wait([
      getServers(),
      getCaptures(),
      getVulnerabilities(),
      getTestResults(),
      getOverviewStats(),
    ]);
  }
  
  /// Nettoie les données
  void clearData() {
    _servers.clear();
    _routes.clear();
    _vulnerabilities.clear();
    _captures.clear();
    _testResults.clear();
    _stats = null;
    notifyListeners();
  }
  
  // ============================================================================
  // Console
  // ============================================================================
  
  /// Connecte au WebSocket de la console
  Future<void> connectConsole() async {
    // Si déjà connecté, ne pas reconnecter
    if (_consoleWebSocket != null) {
      return;
    }
    
    try {
      // Nettoyer l'URL pour éviter les caractères indésirables
      String cleanBaseUrl = _baseUrl.trim();
      if (cleanBaseUrl.endsWith('/')) {
        cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length - 1);
      }
      if (cleanBaseUrl.endsWith('#')) {
        cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length - 1);
      }
      
      final wsUrl = cleanBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      final wsUri = Uri.parse('$wsUrl/api/backend-lab/console/ws');
      
      _consoleWebSocket = WebSocketChannel.connect(wsUri);
      
      _consoleSubscription = _consoleWebSocket!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data as String);
            final logEntry = ConsoleLogEntry.fromJson(jsonData);
            _consoleLogs.add(logEntry);
            
            // Garder seulement les 1000 derniers logs
            if (_consoleLogs.length > 1000) {
              _consoleLogs.removeAt(0);
            }
            
            _consoleLogController.add(logEntry);
            notifyListeners();
          } catch (e) {
            // Ignorer les erreurs de parsing
          }
        },
        onError: (error) {
          _lastError = 'Console WebSocket error: $error';
          notifyListeners();
        },
        onDone: () {
          // Reconnexion automatique après 2 secondes
          Future.delayed(const Duration(seconds: 2), () {
            if (_isConnected) {
              connectConsole();
            }
          });
        },
      );
    } catch (e) {
      _lastError = 'Failed to connect console: $e';
      notifyListeners();
    }
  }
  
  /// Déconnecte de la console
  void disconnectConsole() {
    _consoleSubscription?.cancel();
    _consoleWebSocket?.sink.close();
    _consoleSubscription = null;
    _consoleWebSocket = null;
  }
  
  /// Récupère les logs de la console
  Future<List<ConsoleLogEntry>> getConsoleLogs({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/backend-lab/console/logs?limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _consoleLogs.clear();
        _consoleLogs.addAll(data.map((e) => ConsoleLogEntry.fromJson(e)).toList());
        notifyListeners();
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return _consoleLogs;
  }
  
  /// Efface les logs de la console
  Future<bool> clearConsoleLogs() async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/backend-lab/console/logs'),
      );
      
      if (response.statusCode == 200) {
        _consoleLogs.clear();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return false;
  }
  
  // Getters
  List<ConsoleLogEntry> get consoleLogs => _consoleLogs;
  Stream<ConsoleLogEntry> get consoleLogStream => _consoleLogController.stream;
}
