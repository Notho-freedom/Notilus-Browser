import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class HistoryService {
  static const String _historyKey = 'notilus_history';
  static const int _maxHistoryItems = 1000;

  Future<void> addHistoryItem(String url, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      
      // Remove existing entry if it exists
      history.removeWhere((item) => item.url == url);
      
      // Add new entry at the beginning
      history.insert(0, HistoryItem(url: url, title: title));
      
      // Limit history size
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }
      
      // Save
      final historyJson = history.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
    } catch (e) {
      // Ignore errors
    }
  }

  Future<List<HistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJsonString = prefs.getString(_historyKey);
      if (historyJsonString != null) {
        final List<dynamic> historyJson = jsonDecode(historyJsonString);
        return historyJson.map((json) => HistoryItem.fromJson(json)).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  Future<List<HistoryItem>> searchHistory(String query) async {
    final history = await getHistory();
    final lowerQuery = query.toLowerCase();
    return history.where((item) {
      return item.url.toLowerCase().contains(lowerQuery) ||
          item.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> removeHistoryItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      history.removeWhere((item) => item.id == id);
      
      final historyJson = history.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
    } catch (e) {
      // Ignore errors
    }
  }
}

