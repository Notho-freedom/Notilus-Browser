import 'package:uuid/uuid.dart';

class HistoryItem {
  final String id;
  final String url;
  final String title;
  final DateTime visitedAt;
  final int visitCount;

  HistoryItem({
    String? id,
    required this.url,
    required this.title,
    DateTime? visitedAt,
    this.visitCount = 1,
  })  : id = id ?? const Uuid().v4(),
        visitedAt = visitedAt ?? DateTime.now();

  HistoryItem copyWith({
    String? id,
    String? url,
    String? title,
    DateTime? visitedAt,
    int? visitCount,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      visitedAt: visitedAt ?? this.visitedAt,
      visitCount: visitCount ?? this.visitCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'visitedAt': visitedAt.toIso8601String(),
      'visitCount': visitCount,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      url: json['url'],
      title: json['title'],
      visitedAt: DateTime.parse(json['visitedAt']),
      visitCount: json['visitCount'] ?? 1,
    );
  }
}

