import 'package:flutter/material.dart';

/// Type de log dans la console
enum LogLevel {
  info,
  warning,
  error,
  debug,
  success,
  system,
}

/// Entrée de log dans la console native
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;
  final Map<String, dynamic>? data;
  final StackTrace? stackTrace;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
    this.data,
    this.stackTrace,
  });

  Color get color {
    switch (level) {
      case LogLevel.info:
        return const Color(0xFF64B5F6);
      case LogLevel.warning:
        return const Color(0xFFFFB74D);
      case LogLevel.error:
        return const Color(0xFFEF5350);
      case LogLevel.debug:
        return const Color(0xFF81C784);
      case LogLevel.success:
        return const Color(0xFF66BB6A);
      case LogLevel.system:
        return const Color(0xFFBA68C8);
    }
  }

  IconData get icon {
    switch (level) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.debug:
        return Icons.bug_report_outlined;
      case LogLevel.success:
        return Icons.check_circle_outline;
      case LogLevel.system:
        return Icons.settings_suggest_outlined;
    }
  }

  String get levelLabel {
    switch (level) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.success:
        return 'OK';
      case LogLevel.system:
        return 'SYS';
    }
  }
}

/// Méthode HTTP
enum HttpMethod {
  get,
  post,
  put,
  delete,
  patch,
  head,
  options,
}

/// État d'une requête réseau
enum RequestStatus {
  pending,
  success,
  error,
  cancelled,
}

/// Requête réseau interceptée
class NetworkRequest {
  final String id;
  final DateTime timestamp;
  final HttpMethod method;
  final String url;
  final Map<String, String> requestHeaders;
  final String? requestBody;
  final int? statusCode;
  final Map<String, String>? responseHeaders;
  final String? responseBody;
  final int? responseSize;
  final Duration? duration;
  final RequestStatus status;
  final String? error;
  final String? source; // Flutter, WebView:tabId, etc.

  NetworkRequest({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    this.requestHeaders = const {},
    this.requestBody,
    this.statusCode,
    this.responseHeaders,
    this.responseBody,
    this.responseSize,
    this.duration,
    this.status = RequestStatus.pending,
    this.error,
    this.source,
  });

  String get methodLabel => method.name.toUpperCase();

  Color get statusColor {
    if (status == RequestStatus.pending) {
      return const Color(0xFFFFB74D);
    }
    if (status == RequestStatus.error || error != null) {
      return const Color(0xFFEF5350);
    }
    if (statusCode == null) return const Color(0xFF9E9E9E);
    if (statusCode! >= 200 && statusCode! < 300) {
      return const Color(0xFF66BB6A);
    }
    if (statusCode! >= 300 && statusCode! < 400) {
      return const Color(0xFF64B5F6);
    }
    if (statusCode! >= 400 && statusCode! < 500) {
      return const Color(0xFFFFB74D);
    }
    return const Color(0xFFEF5350);
  }

  String get host {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
  }

  String get path {
    try {
      return Uri.parse(url).path;
    } catch (_) {
      return '';
    }
  }

  String get formattedSize {
    if (responseSize == null) return '-';
    if (responseSize! < 1024) return '$responseSize B';
    if (responseSize! < 1024 * 1024) {
      return '${(responseSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(responseSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDuration {
    if (duration == null) return '-';
    if (duration!.inMilliseconds < 1000) {
      return '${duration!.inMilliseconds} ms';
    }
    return '${(duration!.inMilliseconds / 1000).toStringAsFixed(2)} s';
  }

  NetworkRequest copyWith({
    int? statusCode,
    Map<String, String>? responseHeaders,
    String? responseBody,
    int? responseSize,
    Duration? duration,
    RequestStatus? status,
    String? error,
    String? source,
  }) {
    return NetworkRequest(
      id: id,
      timestamp: timestamp,
      method: method,
      url: url,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      responseSize: responseSize ?? this.responseSize,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      error: error ?? this.error,
      source: source ?? this.source,
    );
  }
  
  /// Indique si c'est une requête WebView
  bool get isFromWebView => source?.startsWith('WebView:') ?? false;
  
  /// Indique si c'est une requête Flutter native
  bool get isFromFlutter => source == null || source == 'Flutter';
}

/// Métrique de performance
class PerformanceMetric {
  final String id;
  final DateTime timestamp;
  final String name;
  final double value;
  final String unit;
  final String? category;

  PerformanceMetric({
    required this.id,
    required this.timestamp,
    required this.name,
    required this.value,
    required this.unit,
    this.category,
  });
}

/// Snapshot de performance du système
class PerformanceSnapshot {
  final DateTime timestamp;
  final double cpuUsage;
  final double memoryUsage;
  final int memoryUsedMB;
  final int memoryTotalMB;
  final int activeWidgets;
  final int renderTime;
  final double fps;
  final int gcCount;

  PerformanceSnapshot({
    required this.timestamp,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.memoryUsedMB,
    required this.memoryTotalMB,
    required this.activeWidgets,
    required this.renderTime,
    required this.fps,
    required this.gcCount,
  });
}

/// Entrée de stockage local
class StorageEntry {
  final String key;
  final String value;
  final String type;
  final int size;
  final DateTime? lastModified;

  StorageEntry({
    required this.key,
    required this.value,
    required this.type,
    required this.size,
    this.lastModified,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Information sur un widget Flutter
class WidgetInfo {
  final String id;
  final String type;
  final String? key;
  final int depth;
  final List<WidgetInfo> children;
  final Map<String, String> properties;
  final bool isSelected;

  WidgetInfo({
    required this.id,
    required this.type,
    this.key,
    required this.depth,
    this.children = const [],
    this.properties = const {},
    this.isSelected = false,
  });
}

/// Commande exécutée dans le REPL
class ReplCommand {
  final String id;
  final DateTime timestamp;
  final String input;
  final String? output;
  final bool isError;
  final Duration? executionTime;

  ReplCommand({
    required this.id,
    required this.timestamp,
    required this.input,
    this.output,
    this.isError = false,
    this.executionTime,
  });
}

// ============================================================================
// FONCTIONNALITÉS AVANCÉES NOTILUS DEVTOOLS
// ============================================================================

/// Statistiques analytiques par onglet
class TabAnalytics {
  final String tabId;
  final String? tabTitle;
  final String? tabUrl;
  final DateTime openedAt;
  DateTime? closedAt;
  Duration totalActiveTime;
  int totalRequests;
  int failedRequests;
  int totalDataTransferred; // bytes
  int peakMemoryMB;
  int errorCount;
  int warningCount;
  List<String> visitedUrls;
  Map<String, int> domainRequests; // domain -> count
  double avgResponseTime; // ms

  TabAnalytics({
    required this.tabId,
    this.tabTitle,
    this.tabUrl,
    required this.openedAt,
    this.closedAt,
    this.totalActiveTime = Duration.zero,
    this.totalRequests = 0,
    this.failedRequests = 0,
    this.totalDataTransferred = 0,
    this.peakMemoryMB = 0,
    this.errorCount = 0,
    this.warningCount = 0,
    this.visitedUrls = const [],
    this.domainRequests = const {},
    this.avgResponseTime = 0,
  });

  String get formattedDataTransferred {
    if (totalDataTransferred < 1024) return '$totalDataTransferred B';
    if (totalDataTransferred < 1024 * 1024) {
      return '${(totalDataTransferred / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalDataTransferred / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedActiveTime {
    final hours = totalActiveTime.inHours;
    final minutes = totalActiveTime.inMinutes % 60;
    final seconds = totalActiveTime.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  double get successRate => totalRequests > 0 
      ? ((totalRequests - failedRequests) / totalRequests) * 100 
      : 100;
}

/// Type d'événement de session
enum SessionEventType {
  navigation,
  click,
  scroll,
  input,
  keypress,
  resize,
  focus,
  blur,
  error,
  networkRequest,
  consoleLog,
  screenshot,
  custom,
}

/// Événement enregistré dans une session
class SessionEvent {
  final String id;
  final DateTime timestamp;
  final SessionEventType type;
  final String? tabId;
  final String? url;
  final Map<String, dynamic> data;
  final String? screenshotPath;

  SessionEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    this.tabId,
    this.url,
    this.data = const {},
    this.screenshotPath,
  });

  IconData get icon {
    switch (type) {
      case SessionEventType.navigation:
        return Icons.explore;
      case SessionEventType.click:
        return Icons.touch_app;
      case SessionEventType.scroll:
        return Icons.swap_vert;
      case SessionEventType.input:
        return Icons.keyboard;
      case SessionEventType.keypress:
        return Icons.keyboard_alt;
      case SessionEventType.resize:
        return Icons.aspect_ratio;
      case SessionEventType.focus:
        return Icons.center_focus_strong;
      case SessionEventType.blur:
        return Icons.blur_on;
      case SessionEventType.error:
        return Icons.error;
      case SessionEventType.networkRequest:
        return Icons.cloud;
      case SessionEventType.consoleLog:
        return Icons.terminal;
      case SessionEventType.screenshot:
        return Icons.camera_alt;
      case SessionEventType.custom:
        return Icons.star;
    }
  }

  Color get color {
    switch (type) {
      case SessionEventType.navigation:
        return const Color(0xFF64B5F6);
      case SessionEventType.click:
        return const Color(0xFF81C784);
      case SessionEventType.scroll:
        return const Color(0xFF9E9E9E);
      case SessionEventType.input:
        return const Color(0xFFFFB74D);
      case SessionEventType.keypress:
        return const Color(0xFFFFB74D);
      case SessionEventType.resize:
        return const Color(0xFF9E9E9E);
      case SessionEventType.focus:
        return const Color(0xFF64B5F6);
      case SessionEventType.blur:
        return const Color(0xFF9E9E9E);
      case SessionEventType.error:
        return const Color(0xFFEF5350);
      case SessionEventType.networkRequest:
        return const Color(0xFFBA68C8);
      case SessionEventType.consoleLog:
        return const Color(0xFF81C784);
      case SessionEventType.screenshot:
        return const Color(0xFF64B5F6);
      case SessionEventType.custom:
        return const Color(0xFFFFD54F);
    }
  }
}

/// Session enregistrée complète
class RecordedSession {
  final String id;
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  final List<SessionEvent> events;
  final Map<String, dynamic> metadata;
  bool isRecording;

  RecordedSession({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.events = const [],
    this.metadata = const {},
    this.isRecording = false,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  String get formattedDuration {
    final d = duration;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

/// Niveau de sévérité d'une alerte
enum AlertSeverity {
  info,
  warning,
  critical,
}

/// Alerte intelligente
class SmartAlert {
  final String id;
  final DateTime timestamp;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? suggestion;
  final Map<String, dynamic>? relatedData;
  final String category; // performance, security, memory, network, etc.
  bool isDismissed;
  bool isRead;

  SmartAlert({
    required this.id,
    required this.timestamp,
    required this.severity,
    required this.title,
    required this.message,
    this.suggestion,
    this.relatedData,
    required this.category,
    this.isDismissed = false,
    this.isRead = false,
  });

  Color get color {
    switch (severity) {
      case AlertSeverity.info:
        return const Color(0xFF64B5F6);
      case AlertSeverity.warning:
        return const Color(0xFFFFB74D);
      case AlertSeverity.critical:
        return const Color(0xFFEF5350);
    }
  }

  IconData get icon {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.critical:
        return Icons.dangerous;
    }
  }
}

/// Noeud de l'arbre de widgets Flutter
class WidgetTreeNode {
  final String id;
  final String widgetType;
  final String? key;
  final String? debugLabel;
  final int depth;
  final bool isExpanded;
  final bool hasChildren;
  final List<WidgetTreeNode> children;
  final Map<String, String> properties;
  final Rect? renderBounds;
  final int? buildCount;
  final Duration? lastBuildTime;

  WidgetTreeNode({
    required this.id,
    required this.widgetType,
    this.key,
    this.debugLabel,
    required this.depth,
    this.isExpanded = false,
    this.hasChildren = false,
    this.children = const [],
    this.properties = const {},
    this.renderBounds,
    this.buildCount,
    this.lastBuildTime,
  });

  String get displayName {
    if (debugLabel != null) return '$widgetType ($debugLabel)';
    if (key != null) return '$widgetType [key: $key]';
    return widgetType;
  }

  Color get typeColor {
    if (widgetType.contains('Scaffold') || widgetType.contains('App')) {
      return const Color(0xFFBA68C8);
    }
    if (widgetType.contains('Container') || widgetType.contains('Box')) {
      return const Color(0xFF64B5F6);
    }
    if (widgetType.contains('Text') || widgetType.contains('Icon')) {
      return const Color(0xFF81C784);
    }
    if (widgetType.contains('Button') || widgetType.contains('Gesture')) {
      return const Color(0xFFFFB74D);
    }
    if (widgetType.contains('ListView') || widgetType.contains('Grid')) {
      return const Color(0xFFEF5350);
    }
    return const Color(0xFF9E9E9E);
  }
}

/// État d'un Provider
class ProviderState {
  final String id;
  final String providerType;
  final String? debugName;
  final Map<String, dynamic> state;
  final DateTime lastUpdated;
  final int updateCount;
  final List<String> dependents;
  final bool isListening;

  ProviderState({
    required this.id,
    required this.providerType,
    this.debugName,
    required this.state,
    required this.lastUpdated,
    this.updateCount = 0,
    this.dependents = const [],
    this.isListening = false,
  });

  String get displayName => debugName ?? providerType;
}

/// Type de problème de sécurité
enum SecurityIssueType {
  mixedContent,       // HTTP dans HTTPS
  insecureForm,       // Formulaire non sécurisé
  exposedApiKey,      // Clé API visible
  noHttps,            // Pas de HTTPS
  weakCors,           // CORS trop permissif
  sensitiveData,      // Données sensibles exposées
  outdatedLibrary,    // Bibliothèque obsolète
  xssVulnerability,   // Vulnérabilité XSS potentielle
  csrfRisk,           // Risque CSRF
  insecureCookie,     // Cookie non sécurisé
}

/// Problème de sécurité détecté
class SecurityIssue {
  final String id;
  final DateTime timestamp;
  final SecurityIssueType type;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String? url;
  final String? recommendation;
  final Map<String, dynamic>? evidence;
  bool isResolved;

  SecurityIssue({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.url,
    this.recommendation,
    this.evidence,
    this.isResolved = false,
  });

  IconData get icon {
    switch (type) {
      case SecurityIssueType.mixedContent:
        return Icons.warning;
      case SecurityIssueType.insecureForm:
        return Icons.lock_open;
      case SecurityIssueType.exposedApiKey:
        return Icons.key_off;
      case SecurityIssueType.noHttps:
        return Icons.http;
      case SecurityIssueType.weakCors:
        return Icons.public_off;
      case SecurityIssueType.sensitiveData:
        return Icons.visibility_off;
      case SecurityIssueType.outdatedLibrary:
        return Icons.update;
      case SecurityIssueType.xssVulnerability:
        return Icons.code_off;
      case SecurityIssueType.csrfRisk:
        return Icons.security;
      case SecurityIssueType.insecureCookie:
        return Icons.cookie;
    }
  }

  Color get color {
    switch (severity) {
      case AlertSeverity.info:
        return const Color(0xFF64B5F6);
      case AlertSeverity.warning:
        return const Color(0xFFFFB74D);
      case AlertSeverity.critical:
        return const Color(0xFFEF5350);
    }
  }
}

/// Bookmark/Annotation DevTools
class DevToolsBookmark {
  final String id;
  final DateTime timestamp;
  final String title;
  final String? description;
  final String category; // log, network, performance, custom
  final String? referenceId; // ID du log/requête associé
  final Map<String, dynamic>? snapshot;
  final Color color;

  DevToolsBookmark({
    required this.id,
    required this.timestamp,
    required this.title,
    this.description,
    required this.category,
    this.referenceId,
    this.snapshot,
    this.color = const Color(0xFFFFD54F),
  });
}

/// Rapport DevTools exportable
class DevToolsReport {
  final String id;
  final DateTime generatedAt;
  final String title;
  final Duration sessionDuration;
  final Map<String, dynamic> summary;
  final List<LogEntry> logs;
  final List<NetworkRequest> requests;
  final List<PerformanceSnapshot> performanceHistory;
  final List<SmartAlert> alerts;
  final List<SecurityIssue> securityIssues;
  final List<DevToolsBookmark> bookmarks;
  final Map<String, TabAnalytics> tabAnalytics;

  DevToolsReport({
    required this.id,
    required this.generatedAt,
    required this.title,
    required this.sessionDuration,
    required this.summary,
    this.logs = const [],
    this.requests = const [],
    this.performanceHistory = const [],
    this.alerts = const [],
    this.securityIssues = const [],
    this.bookmarks = const [],
    this.tabAnalytics = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'generatedAt': generatedAt.toIso8601String(),
      'title': title,
      'sessionDuration': sessionDuration.inSeconds,
      'summary': summary,
      'logsCount': logs.length,
      'requestsCount': requests.length,
      'alertsCount': alerts.length,
      'securityIssuesCount': securityIssues.length,
      'bookmarksCount': bookmarks.length,
    };
  }
}

/// Configuration du monitoring intelligent
class SmartMonitorConfig {
  bool fpsDropAlert;
  int fpsThreshold;
  bool memorySpikAlert;
  int memoryThresholdMB;
  bool slowRequestAlert;
  int slowRequestThresholdMs;
  bool errorBurstAlert;
  int errorBurstThreshold;
  int errorBurstWindowSeconds;
  bool securityScanEnabled;
  bool autoScreenshots;
  int screenshotIntervalSeconds;

  SmartMonitorConfig({
    this.fpsDropAlert = true,
    this.fpsThreshold = 30,
    this.memorySpikAlert = true,
    this.memoryThresholdMB = 500,
    this.slowRequestAlert = true,
    this.slowRequestThresholdMs = 3000,
    this.errorBurstAlert = true,
    this.errorBurstThreshold = 5,
    this.errorBurstWindowSeconds = 60,
    this.securityScanEnabled = true,
    this.autoScreenshots = false,
    this.screenshotIntervalSeconds = 30,
  });
}
