import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tab_model.dart';
import '../models/tab_group_model.dart';

class StorageService {
  static const String _tabsKey = 'notilus_tabs';
  static const String _groupsKey = 'notilus_groups';
  static const String _activeTabKey = 'notilus_active_tab';

  Future<void> saveTabs(List<TabModel> tabs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tabsJson = tabs.map((tab) => tab.toJson()).toList();
      await prefs.setString(_tabsKey, jsonEncode(tabsJson));
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<List<TabModel>> loadTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tabsJsonString = prefs.getString(_tabsKey);
      if (tabsJsonString != null) {
        final List<dynamic> tabsJson = jsonDecode(tabsJsonString);
        return tabsJson.map((json) => TabModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  Future<void> saveGroups(List<TabGroupModel> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = groups.map((group) => group.toJson()).toList();
      await prefs.setString(_groupsKey, jsonEncode(groupsJson));
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<List<TabGroupModel>> loadGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJsonString = prefs.getString(_groupsKey);
      if (groupsJsonString != null) {
        final List<dynamic> groupsJson = jsonDecode(groupsJsonString);
        return groupsJson.map((json) => TabGroupModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  Future<void> saveActiveTab(String? tabId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (tabId != null) {
        await prefs.setString(_activeTabKey, tabId);
      } else {
        await prefs.remove(_activeTabKey);
      }
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<String?> loadActiveTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeTabKey);
    } catch (e) {
      return null;
    }
  }
}

