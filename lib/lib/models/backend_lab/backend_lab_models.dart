/// Modèles de données pour le Backend Lab
/// Système de tests backend ultra-avancé pour Notilus
library backend_lab_models;

import 'package:flutter/material.dart';

// ============================================================================
// Enums
// ============================================================================

/// Status d'un serveur
enum ServerStatus { running, stopped, error, unknown }

/// Status de santé
enum HealthStatus { healthy, degraded, unhealthy, unknown }

/// Frameworks détectables
enum ServerFramework {
  express,
  fastapi,
  django,
  flask,
  springBoot,
  rails,
  laravel,
  nestjs,
  gin,
  aspnet,
  unknown,
}

/// Méthodes HTTP
enum HttpMethod { GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS }

/// Sévérité des vulnérabilités
enum VulnerabilitySeverity { critical, high, medium, low, info }

/// Status de vulnérabilité
enum VulnerabilityStatus { open, confirmed, falsePositive, fixed, acceptedRisk }

/// Type de vulnérabilité
enum VulnerabilityType {
  sqlInjection,
  nosqlInjection,
  xss,
  commandInjection,
  corsIssue,
  missingHeaders,
  noRateLimiting,
  authBypass,
  ssrf,
  other,
}

/// Status de résultat de test
enum TestResultStatus { passed, failed, error, skipped }

/// Type de test de charge
enum LoadTestType { load, stress, spike, endurance }

/// Status de test de charge
enum LoadTestStatus { pending, running, completed, failed, cancelled }

// ============================================================================
// Server Discovery Models
// ============================================================================

/// Résultat d'un health check
class HealthCheckResult {
  final HealthStatus status;
  final double responseTimeMs;
  final DateTime lastCheck;
  final double uptimePercentage;
  final int errorCount;
  final String? errorMessage;

  HealthCheckResult({
    this.status = HealthStatus.unknown,
    this.responseTimeMs = 0,
    DateTime? lastCheck,
    this.uptimePercentage = 100,
    this.errorCount = 0,
    this.errorMessage,
  }) : lastCheck = lastCheck ?? DateTime.now();

  factory HealthCheckResult.fromJson(Map<String, dynamic> json) {
    return HealthCheckResult(
      status: HealthStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => HealthStatus.unknown,
      ),
      responseTimeMs: (json['response_time_ms'] ?? 0).toDouble(),
      lastCheck: json['last_check'] != null
          ? DateTime.parse(json['last_check'])
          : DateTime.now(),
      uptimePercentage: (json['uptime_percentage'] ?? 100).toDouble(),
      errorCount: json['error_count'] ?? 0,
      errorMessage: json['error_message'],
    );
  }

  Color get statusColor {
    switch (status) {
      case HealthStatus.healthy:
        return const Color(0xFF4CAF50);
      case HealthStatus.degraded:
        return const Color(0xFFFF9800);
      case HealthStatus.unhealthy:
        return const Color(0xFFF44336);
      case HealthStatus.unknown:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Serveur découvert
class DiscoveredServer {
  final String id;
  final String host;
  final int port;
  final String protocol;
  final String? name;
  final ServerFramework framework;
  final String? language;
  final ServerStatus status;
  final HealthCheckResult health;
  final int? processId;
  final String? processName;
  final DateTime discoveredAt;
  final DateTime lastSeen;
  final int routesCount;
  final int requestCount;
  final double avgResponseTime;

  DiscoveredServer({
    required this.id,
    this.host = 'localhost',
    required this.port,
    this.protocol = 'http',
    this.name,
    this.framework = ServerFramework.unknown,
    this.language,
    this.status = ServerStatus.unknown,
    HealthCheckResult? health,
    this.processId,
    this.processName,
    DateTime? discoveredAt,
    DateTime? lastSeen,
    this.routesCount = 0,
    this.requestCount = 0,
    this.avgResponseTime = 0,
  })  : health = health ?? HealthCheckResult(),
        discoveredAt = discoveredAt ?? DateTime.now(),
        lastSeen = lastSeen ?? DateTime.now();

  String get baseUrl => '$protocol://$host:$port';

  String get displayName => name ?? '$framework Server';

  Color get statusColor {
    switch (status) {
      case ServerStatus.running:
        return const Color(0xFF4CAF50);
      case ServerStatus.stopped:
        return const Color(0xFF9E9E9E);
      case ServerStatus.error:
        return const Color(0xFFF44336);
      case ServerStatus.unknown:
        return const Color(0xFFFF9800);
    }
  }

  IconData get frameworkIcon {
    switch (framework) {
      case ServerFramework.express:
      case ServerFramework.nestjs:
        return Icons.javascript;
      case ServerFramework.fastapi:
      case ServerFramework.django:
      case ServerFramework.flask:
        return Icons.code;
      case ServerFramework.springBoot:
        return Icons.eco;
      case ServerFramework.rails:
        return Icons.train;
      default:
        return Icons.dns;
    }
  }

  factory DiscoveredServer.fromJson(Map<String, dynamic> json) {
    return DiscoveredServer(
      id: json['id'],
      host: json['host'] ?? 'localhost',
      port: json['port'],
      protocol: json['protocol'] ?? 'http',
      name: json['name'],
      framework: ServerFramework.values.firstWhere(
        (e) => e.name == json['framework'],
        orElse: () => ServerFramework.unknown,
      ),
      language: json['language'],
      status: ServerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ServerStatus.unknown,
      ),
      health: json['health'] != null
          ? HealthCheckResult.fromJson(json['health'])
          : null,
      processId: json['process_id'],
      processName: json['process_name'],
      discoveredAt: json['discovered_at'] != null
          ? DateTime.parse(json['discovered_at'])
          : null,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      routesCount: json['routes_count'] ?? 0,
      requestCount: json['request_count'] ?? 0,
      avgResponseTime: (json['avg_response_time'] ?? 0).toDouble(),
    );
  }
}

// ============================================================================
// Route Discovery Models
// ============================================================================

/// Paramètre de route
class RouteParameter {
  final String name;
  final String location; // path, query, header, body
  final String type;
  final bool required;
  final String? description;
  final dynamic defaultValue;

  RouteParameter({
    required this.name,
    required this.location,
    this.type = 'string',
    this.required = false,
    this.description,
    this.defaultValue,
  });

  factory RouteParameter.fromJson(Map<String, dynamic> json) {
    return RouteParameter(
      name: json['name'],
      location: json['location'],
      type: json['type'] ?? 'string',
      required: json['required'] ?? false,
      description: json['description'],
      defaultValue: json['default_value'],
    );
  }
}

/// Route découverte
class DiscoveredRoute {
  final String id;
  final String serverId;
  final String path;
  final HttpMethod method;
  final List<RouteParameter> pathParams;
  final List<RouteParameter> queryParams;
  final String? summary;
  final String? description;
  final List<String> tags;
  final bool authRequired;
  final String? authType;
  final bool deprecated;
  final int testCount;
  final int callCount;
  final double avgResponseTime;
  final int vulnerabilityCount;

  DiscoveredRoute({
    required this.id,
    required this.serverId,
    required this.path,
    required this.method,
    this.pathParams = const [],
    this.queryParams = const [],
    this.summary,
    this.description,
    this.tags = const [],
    this.authRequired = false,
    this.authType,
    this.deprecated = false,
    this.testCount = 0,
    this.callCount = 0,
    this.avgResponseTime = 0,
    this.vulnerabilityCount = 0,
  });

  Color get methodColor {
    switch (method) {
      case HttpMethod.GET:
        return const Color(0xFF4CAF50);
      case HttpMethod.POST:
        return const Color(0xFF2196F3);
      case HttpMethod.PUT:
        return const Color(0xFFFF9800);
      case HttpMethod.DELETE:
        return const Color(0xFFF44336);
      case HttpMethod.PATCH:
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  factory DiscoveredRoute.fromJson(Map<String, dynamic> json) {
    return DiscoveredRoute(
      id: json['id'],
      serverId: json['server_id'],
      path: json['path'],
      method: HttpMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => HttpMethod.GET,
      ),
      pathParams: (json['path_params'] as List? ?? [])
          .map((p) => RouteParameter.fromJson(p))
          .toList(),
      queryParams: (json['query_params'] as List? ?? [])
          .map((p) => RouteParameter.fromJson(p))
          .toList(),
      summary: json['summary'],
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      authRequired: json['auth_required'] ?? false,
      authType: json['auth_type'],
      deprecated: json['deprecated'] ?? false,
      testCount: json['test_count'] ?? 0,
      callCount: json['call_count'] ?? 0,
      avgResponseTime: (json['avg_response_time'] ?? 0).toDouble(),
      vulnerabilityCount: json['vulnerability_count'] ?? 0,
    );
  }
}

// ============================================================================
// Security Models
// ============================================================================

/// Vulnérabilité détectée
class Vulnerability {
  final String id;
  final VulnerabilityType type;
  final VulnerabilitySeverity severity;
  final VulnerabilityStatus status;
  final String serverId;
  final String? routeId;
  final String? parameter;
  final String title;
  final String description;
  final String evidence;
  final String? payloadUsed;
  final String recommendation;
  final List<String> references;
  final DateTime discoveredAt;
  final double confidence;

  Vulnerability({
    required this.id,
    required this.type,
    required this.severity,
    this.status = VulnerabilityStatus.open,
    required this.serverId,
    this.routeId,
    this.parameter,
    required this.title,
    required this.description,
    required this.evidence,
    this.payloadUsed,
    required this.recommendation,
    this.references = const [],
    DateTime? discoveredAt,
    this.confidence = 1.0,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  Color get severityColor {
    switch (severity) {
      case VulnerabilitySeverity.critical:
        return const Color(0xFF9C27B0);
      case VulnerabilitySeverity.high:
        return const Color(0xFFF44336);
      case VulnerabilitySeverity.medium:
        return const Color(0xFFFF9800);
      case VulnerabilitySeverity.low:
        return const Color(0xFF2196F3);
      case VulnerabilitySeverity.info:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case VulnerabilityType.sqlInjection:
        return Icons.storage;
      case VulnerabilityType.xss:
        return Icons.code;
      case VulnerabilityType.commandInjection:
        return Icons.terminal;
      case VulnerabilityType.corsIssue:
        return Icons.public;
      case VulnerabilityType.missingHeaders:
        return Icons.security;
      case VulnerabilityType.noRateLimiting:
        return Icons.speed;
      default:
        return Icons.bug_report;
    }
  }

  factory Vulnerability.fromJson(Map<String, dynamic> json) {
    return Vulnerability(
      id: json['id'],
      type: VulnerabilityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VulnerabilityType.other,
      ),
      severity: VulnerabilitySeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => VulnerabilitySeverity.medium,
      ),
      status: VulnerabilityStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VulnerabilityStatus.open,
      ),
      serverId: json['server_id'],
      routeId: json['route_id'],
      parameter: json['parameter'],
      title: json['title'],
      description: json['description'],
      evidence: json['evidence'],
      payloadUsed: json['payload_used'],
      recommendation: json['recommendation'],
      references: List<String>.from(json['references'] ?? []),
      discoveredAt: json['discovered_at'] != null
          ? DateTime.parse(json['discovered_at'])
          : null,
      confidence: (json['confidence'] ?? 1.0).toDouble(),
    );
  }
}

/// Résultat d'un scan de sécurité
class SecurityScanResult {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double durationMs;
  final int routesScanned;
  final List<Vulnerability> vulnerabilities;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final int securityScore;
  final String grade;

  SecurityScanResult({
    required this.id,
    required this.startedAt,
    this.completedAt,
    this.durationMs = 0,
    this.routesScanned = 0,
    this.vulnerabilities = const [],
    this.criticalCount = 0,
    this.highCount = 0,
    this.mediumCount = 0,
    this.lowCount = 0,
    this.securityScore = 100,
    this.grade = 'A',
  });

  Color get gradeColor {
    switch (grade) {
      case 'A':
        return const Color(0xFF4CAF50);
      case 'B':
        return const Color(0xFF8BC34A);
      case 'C':
        return const Color(0xFFFF9800);
      case 'D':
        return const Color(0xFFFF5722);
      case 'F':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  factory SecurityScanResult.fromJson(Map<String, dynamic> json) {
    return SecurityScanResult(
      id: json['id'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      durationMs: (json['duration_ms'] ?? 0).toDouble(),
      routesScanned: json['routes_scanned'] ?? 0,
      vulnerabilities: (json['vulnerabilities'] as List? ?? [])
          .map((v) => Vulnerability.fromJson(v))
          .toList(),
      criticalCount: json['critical_count'] ?? 0,
      highCount: json['high_count'] ?? 0,
      mediumCount: json['medium_count'] ?? 0,
      lowCount: json['low_count'] ?? 0,
      securityScore: json['security_score'] ?? 100,
      grade: json['grade'] ?? 'A',
    );
  }
}

// ============================================================================
// Test Models
// ============================================================================

/// Résultat d'un test
class TestResult {
  final String id;
  final String testId;
  final TestResultStatus status;
  final int assertionsPassed;
  final int assertionsFailed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double durationMs;
  final String? errorMessage;
  final Map<String, dynamic> extractedVariables;

  TestResult({
    required this.id,
    required this.testId,
    required this.status,
    this.assertionsPassed = 0,
    this.assertionsFailed = 0,
    required this.startedAt,
    this.completedAt,
    this.durationMs = 0,
    this.errorMessage,
    this.extractedVariables = const {},
  });

  Color get statusColor {
    switch (status) {
      case TestResultStatus.passed:
        return const Color(0xFF4CAF50);
      case TestResultStatus.failed:
        return const Color(0xFFF44336);
      case TestResultStatus.error:
        return const Color(0xFFFF9800);
      case TestResultStatus.skipped:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case TestResultStatus.passed:
        return Icons.check_circle;
      case TestResultStatus.failed:
        return Icons.cancel;
      case TestResultStatus.error:
        return Icons.error;
      case TestResultStatus.skipped:
        return Icons.skip_next;
    }
  }

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      testId: json['test_id'],
      status: TestResultStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TestResultStatus.error,
      ),
      assertionsPassed: json['assertions_passed'] ?? 0,
      assertionsFailed: json['assertions_failed'] ?? 0,
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      durationMs: (json['duration_ms'] ?? 0).toDouble(),
      errorMessage: json['error_message'],
      extractedVariables:
          Map<String, dynamic>.from(json['extracted_variables'] ?? {}),
    );
  }
}

// ============================================================================
// Capture Models
// ============================================================================

/// Requête capturée
class CapturedRequest {
  final String id;
  final DateTime timestamp;
  final String method;
  final String url;
  final String host;
  final String path;
  final Map<String, String> requestHeaders;
  final String? requestBodyText;
  final int? statusCode;
  final Map<String, String> responseHeaders;
  final String? responseBodyText;
  final double durationMs;
  final bool wasModified;
  final String? serverId;
  final String? routeId;

  CapturedRequest({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    required this.host,
    required this.path,
    this.requestHeaders = const {},
    this.requestBodyText,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseBodyText,
    this.durationMs = 0,
    this.wasModified = false,
    this.serverId,
    this.routeId,
  });

  Color get statusColor {
    if (statusCode == null) return const Color(0xFF9E9E9E);
    if (statusCode! >= 200 && statusCode! < 300) return const Color(0xFF4CAF50);
    if (statusCode! >= 300 && statusCode! < 400) return const Color(0xFF2196F3);
    if (statusCode! >= 400 && statusCode! < 500) return const Color(0xFFFF9800);
    if (statusCode! >= 500) return const Color(0xFFF44336);
    return const Color(0xFF9E9E9E);
  }

  Color get methodColor {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF4CAF50);
      case 'POST':
        return const Color(0xFF2196F3);
      case 'PUT':
        return const Color(0xFFFF9800);
      case 'DELETE':
        return const Color(0xFFF44336);
      case 'PATCH':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  factory CapturedRequest.fromJson(Map<String, dynamic> json) {
    return CapturedRequest(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      method: json['method'],
      url: json['url'],
      host: json['host'],
      path: json['path'],
      requestHeaders: Map<String, String>.from(json['request_headers'] ?? {}),
      requestBodyText: json['request_body_text'],
      statusCode: json['status_code'],
      responseHeaders: Map<String, String>.from(json['response_headers'] ?? {}),
      responseBodyText: json['response_body_text'],
      durationMs: (json['duration_ms'] ?? 0).toDouble(),
      wasModified: json['was_modified'] ?? false,
      serverId: json['server_id'],
      routeId: json['route_id'],
    );
  }
}

// ============================================================================
// Performance Models
// ============================================================================

/// Résultat de test de charge
class LoadTestResult {
  final String id;
  final LoadTestStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double durationSec;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double requestsPerSecond;
  final double avgResponseTimeMs;
  final double p95ResponseTimeMs;
  final double p99ResponseTimeMs;
  final double errorRate;
  final bool thresholdsPassed;

  LoadTestResult({
    required this.id,
    this.status = LoadTestStatus.pending,
    this.startedAt,
    this.completedAt,
    this.durationSec = 0,
    this.totalRequests = 0,
    this.successfulRequests = 0,
    this.failedRequests = 0,
    this.requestsPerSecond = 0,
    this.avgResponseTimeMs = 0,
    this.p95ResponseTimeMs = 0,
    this.p99ResponseTimeMs = 0,
    this.errorRate = 0,
    this.thresholdsPassed = true,
  });

  Color get statusColor {
    switch (status) {
      case LoadTestStatus.completed:
        return thresholdsPassed
            ? const Color(0xFF4CAF50)
            : const Color(0xFFFF9800);
      case LoadTestStatus.running:
        return const Color(0xFF2196F3);
      case LoadTestStatus.failed:
        return const Color(0xFFF44336);
      case LoadTestStatus.cancelled:
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  factory LoadTestResult.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] ?? {};
    final responseTimes = metrics['response_times'] ?? {};

    return LoadTestResult(
      id: json['id'],
      status: LoadTestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LoadTestStatus.pending,
      ),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      durationSec: (json['duration_sec'] ?? 0).toDouble(),
      totalRequests: metrics['total_requests'] ?? 0,
      successfulRequests: metrics['successful_requests'] ?? 0,
      failedRequests: metrics['failed_requests'] ?? 0,
      requestsPerSecond: (metrics['requests_per_second'] ?? 0).toDouble(),
      avgResponseTimeMs: (responseTimes['avg_ms'] ?? 0).toDouble(),
      p95ResponseTimeMs: (responseTimes['p95_ms'] ?? 0).toDouble(),
      p99ResponseTimeMs: (responseTimes['p99_ms'] ?? 0).toDouble(),
      errorRate: (metrics['error_rate'] ?? 0).toDouble(),
      thresholdsPassed: json['thresholds_passed'] ?? true,
    );
  }
}

// ============================================================================
// Analytics Models
// ============================================================================

/// Statistiques globales
class OverviewStats {
  final int totalServers;
  final int healthyServers;
  final int unhealthyServers;
  final int totalRoutes;
  final int testedRoutes;
  final int totalTestsRun;
  final int passedTests;
  final int failedTests;
  final double testSuccessRate;
  final int totalVulnerabilities;
  final int openVulnerabilities;
  final int criticalCount;
  final int highCount;
  final int totalCaptures;
  final double avgResponseTimeMs;

  OverviewStats({
    this.totalServers = 0,
    this.healthyServers = 0,
    this.unhealthyServers = 0,
    this.totalRoutes = 0,
    this.testedRoutes = 0,
    this.totalTestsRun = 0,
    this.passedTests = 0,
    this.failedTests = 0,
    this.testSuccessRate = 0,
    this.totalVulnerabilities = 0,
    this.openVulnerabilities = 0,
    this.criticalCount = 0,
    this.highCount = 0,
    this.totalCaptures = 0,
    this.avgResponseTimeMs = 0,
  });

  factory OverviewStats.fromJson(Map<String, dynamic> json) {
    return OverviewStats(
      totalServers: json['total_servers'] ?? 0,
      healthyServers: json['healthy_servers'] ?? 0,
      unhealthyServers: json['unhealthy_servers'] ?? 0,
      totalRoutes: json['total_routes'] ?? 0,
      testedRoutes: json['tested_routes'] ?? 0,
      totalTestsRun: json['total_tests_run'] ?? 0,
      passedTests: json['passed_tests'] ?? 0,
      failedTests: json['failed_tests'] ?? 0,
      testSuccessRate: (json['test_success_rate'] ?? 0).toDouble(),
      totalVulnerabilities: json['total_vulnerabilities'] ?? 0,
      openVulnerabilities: json['open_vulnerabilities'] ?? 0,
      criticalCount: json['critical_count'] ?? 0,
      highCount: json['high_count'] ?? 0,
      totalCaptures: json['total_captures'] ?? 0,
      avgResponseTimeMs: (json['avg_response_time_ms'] ?? 0).toDouble(),
    );
  }
}

// ============================================================================
// Console Models
// ============================================================================

/// Entrée de log de la console
class ConsoleLogEntry {
  final String timestamp;
  final String level;
  final String message;
  final String color;
  final String raw;
  final Map<String, dynamic>? request;
  final Map<String, dynamic>? response;

  ConsoleLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.color,
    required this.raw,
    this.request,
    this.response,
  });

  factory ConsoleLogEntry.fromJson(Map<String, dynamic> json) {
    return ConsoleLogEntry(
      timestamp: json['timestamp'] ?? '',
      level: json['level'] ?? 'INFO',
      message: json['message'] ?? '',
      color: json['color'] ?? '#FFFFFF',
      raw: json['raw'] ?? '',
      request: json['request'] != null ? Map<String, dynamic>.from(json['request']) : null,
      response: json['response'] != null ? Map<String, dynamic>.from(json['response']) : null,
    );
  }

  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.white;
    }
  }
  
  /// Vérifie si ce log contient des informations de requête HTTP
  bool get hasRequestDetails => request != null || response != null;
}