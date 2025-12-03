/// Modèles de données pour le DevTools natif de Notilus
library devtools_models;

import 'package:flutter/material.dart';

/// Niveau de log console
enum ConsoleLevel {
  log,
  info,
  warn,
  error,
  debug,
  table,
}

/// Extension pour les couleurs des niveaux de log
extension ConsoleLevelExtension on ConsoleLevel {
  Color get color {
    switch (this) {
      case ConsoleLevel.log:
        return const Color(0xFFE0E0E0);
      case ConsoleLevel.info:
        return const Color(0xFF64B5F6);
      case ConsoleLevel.warn:
        return const Color(0xFFFFB74D);
      case ConsoleLevel.error:
        return const Color(0xFFEF5350);
      case ConsoleLevel.debug:
        return const Color(0xFF81C784);
      case ConsoleLevel.table:
        return const Color(0xFFBA68C8);
    }
  }

  IconData get icon {
    switch (this) {
      case ConsoleLevel.log:
        return Icons.circle_outlined;
      case ConsoleLevel.info:
        return Icons.info_outline;
      case ConsoleLevel.warn:
        return Icons.warning_amber_rounded;
      case ConsoleLevel.error:
        return Icons.error_outline;
      case ConsoleLevel.debug:
        return Icons.bug_report_outlined;
      case ConsoleLevel.table:
        return Icons.table_chart_outlined;
    }
  }

  String get prefix {
    switch (this) {
      case ConsoleLevel.log:
        return 'LOG';
      case ConsoleLevel.info:
        return 'INFO';
      case ConsoleLevel.warn:
        return 'WARN';
      case ConsoleLevel.error:
        return 'ERR';
      case ConsoleLevel.debug:
        return 'DBG';
      case ConsoleLevel.table:
        return 'TBL';
    }
  }
}

/// Entrée de console
class ConsoleEntry {
  final String id;
  final ConsoleLevel level;
  final String message;
  final DateTime timestamp;
  final String? source;
  final int? lineNumber;
  final int? columnNumber;
  final String? stackTrace;
  final List<dynamic>? args;

  ConsoleEntry({
    required this.id,
    required this.level,
    required this.message,
    required this.timestamp,
    this.source,
    this.lineNumber,
    this.columnNumber,
    this.stackTrace,
    this.args,
  });

  factory ConsoleEntry.fromJson(Map<String, dynamic> json) {
    return ConsoleEntry(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      level: _parseLevelFromString(json['level'] as String? ?? 'log'),
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      source: json['source'] as String?,
      lineNumber: json['lineNumber'] as int?,
      columnNumber: json['columnNumber'] as int?,
      stackTrace: json['stackTrace'] as String?,
      args: json['args'] as List<dynamic>?,
    );
  }

  static ConsoleLevel _parseLevelFromString(String level) {
    switch (level.toLowerCase()) {
      case 'info':
        return ConsoleLevel.info;
      case 'warn':
      case 'warning':
        return ConsoleLevel.warn;
      case 'error':
        return ConsoleLevel.error;
      case 'debug':
        return ConsoleLevel.debug;
      case 'table':
        return ConsoleLevel.table;
      default:
        return ConsoleLevel.log;
    }
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  String get sourceLocation {
    if (source == null) return '';
    if (lineNumber != null && columnNumber != null) {
      return '$source:$lineNumber:$columnNumber';
    }
    if (lineNumber != null) {
      return '$source:$lineNumber';
    }
    return source!;
  }
}

/// Type de requête HTTP
enum RequestMethod {
  GET,
  POST,
  PUT,
  DELETE,
  PATCH,
  HEAD,
  OPTIONS,
  CONNECT,
  TRACE,
  OTHER,
}

extension RequestMethodExtension on RequestMethod {
  Color get color {
    switch (this) {
      case RequestMethod.GET:
        return const Color(0xFF4CAF50);
      case RequestMethod.POST:
        return const Color(0xFF2196F3);
      case RequestMethod.PUT:
        return const Color(0xFFFF9800);
      case RequestMethod.DELETE:
        return const Color(0xFFF44336);
      case RequestMethod.PATCH:
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Status de la requête réseau
enum NetworkRequestStatus {
  pending,
  success,
  error,
  cancelled,
}

/// Requête réseau
class NetworkRequest {
  final String id;
  final RequestMethod method;
  final String url;
  final DateTime startTime;
  DateTime? endTime;
  int? statusCode;
  String? statusText;
  NetworkRequestStatus status;
  int? requestSize;
  int? responseSize;
  Map<String, String>? requestHeaders;
  Map<String, String>? responseHeaders;
  String? requestBody;
  String? responseBody;
  String? mimeType;
  String? initiator;
  double? duration;

  NetworkRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.startTime,
    this.endTime,
    this.statusCode,
    this.statusText,
    this.status = NetworkRequestStatus.pending,
    this.requestSize,
    this.responseSize,
    this.requestHeaders,
    this.responseHeaders,
    this.requestBody,
    this.responseBody,
    this.mimeType,
    this.initiator,
    this.duration,
  });

  factory NetworkRequest.fromJson(Map<String, dynamic> json) {
    return NetworkRequest(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      method: _parseMethod(json['method'] as String? ?? 'GET'),
      url: json['url'] as String? ?? '',
      startTime: json['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int)
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'] as int)
          : null,
      statusCode: json['statusCode'] as int?,
      statusText: json['statusText'] as String?,
      status: _parseStatus(json['status'] as String?),
      requestSize: json['requestSize'] as int?,
      responseSize: json['responseSize'] as int?,
      requestHeaders: (json['requestHeaders'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      responseHeaders: (json['responseHeaders'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      requestBody: json['requestBody'] as String?,
      responseBody: json['responseBody'] as String?,
      mimeType: json['mimeType'] as String?,
      initiator: json['initiator'] as String?,
      duration: (json['duration'] as num?)?.toDouble(),
    );
  }

  static RequestMethod _parseMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return RequestMethod.GET;
      case 'POST':
        return RequestMethod.POST;
      case 'PUT':
        return RequestMethod.PUT;
      case 'DELETE':
        return RequestMethod.DELETE;
      case 'PATCH':
        return RequestMethod.PATCH;
      case 'HEAD':
        return RequestMethod.HEAD;
      case 'OPTIONS':
        return RequestMethod.OPTIONS;
      default:
        return RequestMethod.OTHER;
    }
  }

  static NetworkRequestStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return NetworkRequestStatus.success;
      case 'error':
        return NetworkRequestStatus.error;
      case 'cancelled':
        return NetworkRequestStatus.cancelled;
      default:
        return NetworkRequestStatus.pending;
    }
  }

  String get formattedDuration {
    if (duration == null) return '-';
    if (duration! < 1000) return '${duration!.round()}ms';
    return '${(duration! / 1000).toStringAsFixed(2)}s';
  }

  String get formattedSize {
    final size = responseSize ?? 0;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get shortUrl {
    try {
      final uri = Uri.parse(url);
      return uri.path.isEmpty || uri.path == '/'
          ? uri.host
          : uri.path.split('/').last;
    } catch (_) {
      return url;
    }
  }

  Color get statusColor {
    if (statusCode == null) return const Color(0xFF9E9E9E);
    if (statusCode! >= 200 && statusCode! < 300) return const Color(0xFF4CAF50);
    if (statusCode! >= 300 && statusCode! < 400) return const Color(0xFF2196F3);
    if (statusCode! >= 400 && statusCode! < 500) return const Color(0xFFFF9800);
    if (statusCode! >= 500) return const Color(0xFFF44336);
    return const Color(0xFF9E9E9E);
  }
}

/// Métriques de performance
class PerformanceMetrics {
  final double? pageLoadTime;
  final double? domContentLoaded;
  final double? firstPaint;
  final double? firstContentfulPaint;
  final double? largestContentfulPaint;
  final double? timeToInteractive;
  final double? totalBlockingTime;
  final double? cumulativeLayoutShift;
  final int? jsHeapSize;
  final int? usedJsHeapSize;
  final int? domNodes;
  final int? resources;
  final double? transferSize;
  final DateTime timestamp;

  PerformanceMetrics({
    this.pageLoadTime,
    this.domContentLoaded,
    this.firstPaint,
    this.firstContentfulPaint,
    this.largestContentfulPaint,
    this.timeToInteractive,
    this.totalBlockingTime,
    this.cumulativeLayoutShift,
    this.jsHeapSize,
    this.usedJsHeapSize,
    this.domNodes,
    this.resources,
    this.transferSize,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      pageLoadTime: (json['pageLoadTime'] as num?)?.toDouble(),
      domContentLoaded: (json['domContentLoaded'] as num?)?.toDouble(),
      firstPaint: (json['firstPaint'] as num?)?.toDouble(),
      firstContentfulPaint: (json['firstContentfulPaint'] as num?)?.toDouble(),
      largestContentfulPaint:
          (json['largestContentfulPaint'] as num?)?.toDouble(),
      timeToInteractive: (json['timeToInteractive'] as num?)?.toDouble(),
      totalBlockingTime: (json['totalBlockingTime'] as num?)?.toDouble(),
      cumulativeLayoutShift:
          (json['cumulativeLayoutShift'] as num?)?.toDouble(),
      jsHeapSize: json['jsHeapSize'] as int?,
      usedJsHeapSize: json['usedJsHeapSize'] as int?,
      domNodes: json['domNodes'] as int?,
      resources: json['resources'] as int?,
      transferSize: (json['transferSize'] as num?)?.toDouble(),
    );
  }

  String formatMs(double? value) {
    if (value == null) return '-';
    if (value < 1000) return '${value.round()}ms';
    return '${(value / 1000).toStringAsFixed(2)}s';
  }

  String formatBytes(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Noeud DOM simplifié
class DOMNode {
  final String id;
  final String tagName;
  final String? nodeId;
  final Map<String, String> attributes;
  final List<DOMNode> children;
  final String? textContent;
  final bool isExpanded;
  final int depth;

  DOMNode({
    required this.id,
    required this.tagName,
    this.nodeId,
    Map<String, String>? attributes,
    List<DOMNode>? children,
    this.textContent,
    this.isExpanded = false,
    this.depth = 0,
  })  : attributes = attributes ?? {},
        children = children ?? [];

  factory DOMNode.fromJson(Map<String, dynamic> json, {int depth = 0}) {
    return DOMNode(
      id: json['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      tagName: json['tagName'] as String? ?? 'unknown',
      nodeId: json['nodeId'] as String?,
      attributes: (json['attributes'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => DOMNode.fromJson(c as Map<String, dynamic>,
                  depth: depth + 1))
              .toList() ??
          [],
      textContent: json['textContent'] as String?,
      depth: depth,
    );
  }

  DOMNode copyWith({
    String? id,
    String? tagName,
    String? nodeId,
    Map<String, String>? attributes,
    List<DOMNode>? children,
    String? textContent,
    bool? isExpanded,
    int? depth,
  }) {
    return DOMNode(
      id: id ?? this.id,
      tagName: tagName ?? this.tagName,
      nodeId: nodeId ?? this.nodeId,
      attributes: attributes ?? this.attributes,
      children: children ?? this.children,
      textContent: textContent ?? this.textContent,
      isExpanded: isExpanded ?? this.isExpanded,
      depth: depth ?? this.depth,
    );
  }

  bool get hasChildren => children.isNotEmpty;
  bool get hasText =>
      textContent != null &&
      textContent!.trim().isNotEmpty &&
      textContent!.trim() != '\n';
}

/// Élément de storage (localStorage/sessionStorage)
class StorageItem {
  final String key;
  final String value;
  final StorageType type;

  StorageItem({
    required this.key,
    required this.value,
    required this.type,
  });

  factory StorageItem.fromJson(Map<String, dynamic> json, StorageType type) {
    return StorageItem(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      type: type,
    );
  }
}

enum StorageType {
  localStorage,
  sessionStorage,
  cookie,
  indexedDB,
}

extension StorageTypeExtension on StorageType {
  String get displayName {
    switch (this) {
      case StorageType.localStorage:
        return 'Local Storage';
      case StorageType.sessionStorage:
        return 'Session Storage';
      case StorageType.cookie:
        return 'Cookies';
      case StorageType.indexedDB:
        return 'IndexedDB';
    }
  }

  IconData get icon {
    switch (this) {
      case StorageType.localStorage:
        return Icons.storage_outlined;
      case StorageType.sessionStorage:
        return Icons.timer_outlined;
      case StorageType.cookie:
        return Icons.cookie_outlined;
      case StorageType.indexedDB:
        return Icons.table_rows_outlined;
    }
  }
}

/// Source JavaScript
class SourceFile {
  final String id;
  final String url;
  final String? content;
  final String? mimeType;
  final int? size;

  SourceFile({
    required this.id,
    required this.url,
    this.content,
    this.mimeType,
    this.size,
  });

  factory SourceFile.fromJson(Map<String, dynamic> json) {
    return SourceFile(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      url: json['url'] as String? ?? '',
      content: json['content'] as String?,
      mimeType: json['mimeType'] as String?,
      size: json['size'] as int?,
    );
  }

  String get fileName {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      return path.isEmpty || path == '/'
          ? uri.host
          : path.split('/').last;
    } catch (_) {
      return url;
    }
  }

  bool get isJavaScript =>
      mimeType?.contains('javascript') == true ||
      url.endsWith('.js') ||
      url.endsWith('.mjs');

  bool get isCSS =>
      mimeType?.contains('css') == true || url.endsWith('.css');

  bool get isHTML =>
      mimeType?.contains('html') == true ||
      url.endsWith('.html') ||
      url.endsWith('.htm');
}
