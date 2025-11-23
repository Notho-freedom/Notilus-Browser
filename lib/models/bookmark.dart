import 'package:uuid/uuid.dart';

class Bookmark {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? favicon;
  final DateTime createdAt;
  final List<String> tags;

  Bookmark({
    String? id,
    required this.url,
    required this.title,
    this.description,
    this.favicon,
    DateTime? createdAt,
    List<String>? tags,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  Bookmark copyWith({
    String? id,
    String? url,
    String? title,
    String? description,
    String? favicon,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return Bookmark(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      favicon: favicon ?? this.favicon,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'description': description,
      'favicon': favicon,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      url: json['url'],
      title: json['title'],
      description: json['description'],
      favicon: json['favicon'],
      createdAt: DateTime.parse(json['createdAt']),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

