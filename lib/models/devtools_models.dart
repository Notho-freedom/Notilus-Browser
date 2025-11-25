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
    );
  }
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
