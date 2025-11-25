/// Modèle pour représenter un téléchargement
class DownloadModel {
  final String id;
  final String url;
  final String fileName;
  final String? filePath;
  final int? totalBytes;
  final int? receivedBytes;
  final DownloadStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? error;

  DownloadModel({
    required this.id,
    required this.url,
    required this.fileName,
    this.filePath,
    this.totalBytes,
    this.receivedBytes,
    this.status = DownloadStatus.pending,
    required this.startTime,
    this.endTime,
    this.error,
  });

  double get progress {
    if (totalBytes == null || totalBytes == 0) return 0.0;
    if (receivedBytes == null) return 0.0;
    return (receivedBytes! / totalBytes!).clamp(0.0, 1.0);
  }

  String get progressText {
    if (status == DownloadStatus.completed) return 'Terminé';
    if (status == DownloadStatus.failed) return 'Échec';
    if (totalBytes == null || receivedBytes == null) return 'En attente...';
    final receivedMB = (receivedBytes! / 1024 / 1024).toStringAsFixed(2);
    final totalMB = (totalBytes! / 1024 / 1024).toStringAsFixed(2);
    return '$receivedMB MB / $totalMB MB';
  }

  DownloadModel copyWith({
    String? id,
    String? url,
    String? fileName,
    String? filePath,
    int? totalBytes,
    int? receivedBytes,
    DownloadStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? error,
  }) {
    return DownloadModel(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      totalBytes: totalBytes ?? this.totalBytes,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'fileName': fileName,
      'filePath': filePath,
      'totalBytes': totalBytes,
      'receivedBytes': receivedBytes,
      'status': status.toString().split('.').last,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'error': error,
    };
  }

  factory DownloadModel.fromJson(Map<String, dynamic> json) {
    return DownloadModel(
      id: json['id'] as String,
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String?,
      totalBytes: json['totalBytes'] as int?,
      receivedBytes: json['receivedBytes'] as int?,
      status: DownloadStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DownloadStatus.pending,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      error: json['error'] as String?,
    );
  }
}

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

