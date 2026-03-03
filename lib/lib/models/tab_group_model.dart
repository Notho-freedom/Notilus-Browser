import 'package:uuid/uuid.dart';

class TabGroupModel {
  final String id;
  String name;
  final String color;
  final String? icon;
  final List<String> tabIds;
  final DateTime createdAt;
  bool isCollapsed;

  TabGroupModel({
    String? id,
    required this.name,
    required this.color,
    this.icon,
    List<String>? tabIds,
    DateTime? createdAt,
    this.isCollapsed = false,
  })  : id = id ?? const Uuid().v4(),
        tabIds = tabIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  TabGroupModel copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    List<String>? tabIds,
    DateTime? createdAt,
    bool? isCollapsed,
  }) {
    return TabGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      tabIds: tabIds ?? this.tabIds,
      createdAt: createdAt ?? this.createdAt,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'tabIds': tabIds,
      'createdAt': createdAt.toIso8601String(),
      'isCollapsed': isCollapsed,
    };
  }

  factory TabGroupModel.fromJson(Map<String, dynamic> json) {
    return TabGroupModel(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      icon: json['icon'],
      tabIds: List<String>.from(json['tabIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      isCollapsed: json['isCollapsed'] ?? false,
    );
  }
}

