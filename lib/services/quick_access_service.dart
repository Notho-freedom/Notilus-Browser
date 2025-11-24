import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/favicon_service.dart';
import '../core/utils/url_validator.dart';

class QuickAccessItem {
  final String id;
  final String name;
  final String url;
  final String? iconUrl;
  final Color color;
  final DateTime createdAt;

  QuickAccessItem({
    String? id,
    required this.name,
    required this.url,
    this.iconUrl,
    required this.color,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'iconUrl': iconUrl,
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuickAccessItem.fromJson(Map<String, dynamic> json) {
    return QuickAccessItem(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      iconUrl: json['iconUrl'],
      color: Color(json['color']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class QuickAccessService {
  static const String _quickAccessKey = 'notilus_quick_access';
  static const int _maxItems = 20;

  Future<List<QuickAccessItem>> getQuickAccessItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJsonString = prefs.getString(_quickAccessKey);
      if (itemsJsonString != null) {
        final List<dynamic> itemsJson = jsonDecode(itemsJsonString);
        return itemsJson.map((json) => QuickAccessItem.fromJson(json)).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  Future<void> addQuickAccessItem(QuickAccessItem item) async {
    try {
      final items = await getQuickAccessItems();
      // Remove existing item with same URL
      items.removeWhere((i) => i.url == item.url);
      items.add(item);
      
      // Limit to max items
      if (items.length > _maxItems) {
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        items.removeRange(_maxItems, items.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = items.map((i) => i.toJson()).toList();
      await prefs.setString(_quickAccessKey, jsonEncode(itemsJson));
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> removeQuickAccessItem(String id) async {
    try {
      final items = await getQuickAccessItems();
      items.removeWhere((i) => i.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = items.map((i) => i.toJson()).toList();
      await prefs.setString(_quickAccessKey, jsonEncode(itemsJson));
    } catch (e) {
      // Ignore errors
    }
  }

  /// Extrait les informations d'un site depuis son URL
  Future<QuickAccessItem?> extractSiteInfo(String url) async {
    try {
      final domain = UrlValidator.extractDomain(url);
      if (domain == null) return null;

      // Récupérer le favicon
      final faviconUrl = await FaviconService.getFaviconWithCache(url);
      
      // Générer un nom à partir du domaine
      String name = domain.replaceAll('www.', '');
      if (name.contains('.')) {
        name = name.split('.').first;
        name = name[0].toUpperCase() + name.substring(1);
      }

      // Générer une couleur basée sur le domaine (hash simple)
      final colorValue = domain.hashCode.abs() % 0xFFFFFF;
      final color = Color(0xFF000000 | colorValue);

      return QuickAccessItem(
        name: name,
        url: url,
        iconUrl: faviconUrl,
        color: color,
      );
    } catch (e) {
      return null;
    }
  }
}

