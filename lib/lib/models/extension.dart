import 'package:uuid/uuid.dart';

enum ExtensionType { contentScript, background, popup, devtools }

class Extension {
  final String id;
  final String name;
  final String version;
  final String description;
  final String? author;
  final String? icon;
  final List<String> permissions;
  final ExtensionType type;
  final bool enabled;
  final Map<String, dynamic> manifest;

  Extension({
    String? id,
    required this.name,
    required this.version,
    this.description = '',
    this.author,
    this.icon,
    List<String>? permissions,
    required this.type,
    this.enabled = true,
    required this.manifest,
  })  : id = id ?? const Uuid().v4(),
        permissions = permissions ?? [];

  Extension copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    String? author,
    String? icon,
    List<String>? permissions,
    ExtensionType? type,
    bool? enabled,
    Map<String, dynamic>? manifest,
  }) {
    return Extension(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      author: author ?? this.author,
      icon: icon ?? this.icon,
      permissions: permissions ?? this.permissions,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      manifest: manifest ?? this.manifest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'author': author,
      'icon': icon,
      'permissions': permissions,
      'type': type.toString(),
      'enabled': enabled,
      'manifest': manifest,
    };
  }

  factory Extension.fromJson(Map<String, dynamic> json) {
    return Extension(
      id: json['id'],
      name: json['name'],
      version: json['version'],
      description: json['description'] ?? '',
      author: json['author'],
      icon: json['icon'],
      permissions: List<String>.from(json['permissions'] ?? []),
      type: ExtensionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ExtensionType.contentScript,
      ),
      enabled: json['enabled'] ?? true,
      manifest: Map<String, dynamic>.from(json['manifest'] ?? {}),
    );
  }
}

