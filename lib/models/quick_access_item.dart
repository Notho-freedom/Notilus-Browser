import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class QuickAccessItem {
  final String id;
  final String name;
  final String url;
  final IconData icon;
  final Color color;

  QuickAccessItem({
    String? id,
    required this.name,
    required this.url,
    IconData? icon,
    Color? color,
  })  : id = id ?? const Uuid().v4(),
        icon = icon ?? CupertinoIcons.globe,
        color = color ?? const Color(0xFF222235);

  QuickAccessItem copyWith({
    String? id,
    String? name,
    String? url,
    IconData? icon,
    Color? color,
  }) {
    return QuickAccessItem(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'color': color.value,
    };
  }

  factory QuickAccessItem.fromJson(Map<String, dynamic> json) {
    return QuickAccessItem(
      id: json['id'] as String?,
      name: json['name'] as String,
      url: json['url'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: 'cupertino_icons',
        matchTextDirection: false,
      ),
      color: Color(json['color'] as int),
    );
  }
}

