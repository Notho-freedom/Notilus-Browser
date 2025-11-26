/// Service Backend Lab pour Flutter
/// Communique avec l'API Backend Lab pour les tests backend
library backend_lab_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
  OverviewStats? _stats;
  
  // Scan en cours
  bool _isScanning = false;
  
  BackendLabService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;
  
  // Getters
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;
  List<DiscoveredServer> get servers => _servers;
  List<DiscoveredRoute> get routes => _routes;
  List<Vulnerability> get vulnerabilities => _vulnerabilities;
  List<CapturedRequest> get captures => _captures;
  List<TestResult> get testResults => _testResults;
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
        return data.map((r) => DiscoveredRoute.fromJson(r)).toList();
      }
    } catch (e) {
      _lastError = e.toString();
    }
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
        return LoadTestResult.fromJson(data);
      }
    } catch (e) {
      _lastError = e.toString();
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
}
