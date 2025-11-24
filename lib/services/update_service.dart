import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateItem {
  final String id;
  final String title;
  final String description;
  final String? icon;
  final DateTime date;
  final bool isRead;

  UpdateItem({
    String? id,
    required this.title,
    required this.description,
    this.icon,
    DateTime? date,
    this.isRead = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'date': date.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory UpdateItem.fromJson(Map<String, dynamic> json) {
    return UpdateItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      date: DateTime.parse(json['date']),
      isRead: json['isRead'] ?? false,
    );
  }
}

class UpdateService {
  static const String _updatesKey = 'notilus_updates';
  static const String _readUpdatesKey = 'notilus_read_updates';

  Future<List<UpdateItem>> getUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatesJsonString = prefs.getString(_updatesKey);
      final readIdsString = prefs.getString(_readUpdatesKey);
      final readIds = readIdsString != null 
          ? (jsonDecode(readIdsString) as List).map((e) => e.toString()).toSet()
          : <String>{};
      
      if (updatesJsonString != null) {
        final List<dynamic> updatesJson = jsonDecode(updatesJsonString);
        return updatesJson.map((json) {
          final item = UpdateItem.fromJson(json);
          return UpdateItem(
            id: item.id,
            title: item.title,
            description: item.description,
            icon: item.icon,
            date: item.date,
            isRead: readIds.contains(item.id),
          );
        }).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  Future<void> addUpdate(UpdateItem update) async {
    try {
      final updates = await getUpdates();
      // Remove existing update with same ID
      updates.removeWhere((u) => u.id == update.id);
      updates.insert(0, update);
      
      final prefs = await SharedPreferences.getInstance();
      final updatesJson = updates.map((u) => u.toJson()).toList();
      await prefs.setString(_updatesKey, jsonEncode(updatesJson));
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> markAsRead(String updateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIdsString = prefs.getString(_readUpdatesKey);
      final readIds = readIdsString != null 
          ? (jsonDecode(readIdsString) as List).map((e) => e.toString()).toSet()
          : <String>{};
      
      readIds.add(updateId);
      await prefs.setString(_readUpdatesKey, jsonEncode(readIds.toList()));
    } catch (e) {
      // Ignore errors
    }
  }

  Future<int> getUnreadCount() async {
    final updates = await getUpdates();
    return updates.where((u) => !u.isRead).length;
  }
}

