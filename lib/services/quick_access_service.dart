import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quick_access_item.dart';

class QuickAccessService {
  static const String _storageKey = 'quick_access_items';

  Future<List<QuickAccessItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      return _defaultItems;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => QuickAccessItem.fromJson(json))
          .toList();
    } catch (_) {
      return _defaultItems;
    }
  }

  Future<List<QuickAccessItem>> addItem(QuickAccessItem item) async {
    final items = await loadItems();
    items.add(item);
    await _saveItems(items);
    return items;
  }

  Future<void> removeItem(String id) async {
    final items = await loadItems();
    items.removeWhere((element) => element.id == id);
    await _saveItems(items);
  }

  Future<void> _saveItems(List<QuickAccessItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  List<QuickAccessItem> get _defaultItems => [
        QuickAccessItem(
          name: 'Flutter',
          url: 'https://flutter.dev',
          icon: CupertinoIcons.layers_alt,
          color: const Color(0xFF1D2D50),
        ),
        QuickAccessItem(
          name: 'GitHub',
          url: 'https://github.com',
          icon: CupertinoIcons.link,
          color: const Color(0xFF171515),
        ),
        QuickAccessItem(
          name: 'Dribbble',
          url: 'https://dribbble.com',
          icon: CupertinoIcons.paintbrush,
          color: const Color(0xFFEA4C89),
        ),
        QuickAccessItem(
          name: 'Product Hunt',
          url: 'https://www.producthunt.com',
          icon: CupertinoIcons.lightbulb,
          color: const Color(0xFFFF6F3C),
        ),
      ];
}

