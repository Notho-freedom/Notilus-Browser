import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tab_model.dart';
import '../models/tab_group_model.dart';

class StorageService {
  static const String _tabsKey = 'notilus_tabs';
  static const String _groupsKey = 'notilus_groups';
  static const String _activeTabKey = 'notilus_active_tab';
  static const String _tabsCompressedKey = 'notilus_tabs_compressed';
  static const String _groupsCompressedKey = 'notilus_groups_compressed';
  
  // Debouncing timers
  Timer? _saveTabsTimer;
  Timer? _saveGroupsTimer;
  Timer? _saveActiveTabTimer;
  
  // Cache des données sérialisées pour éviter la re-sérialisation
  String? _lastSerializedTabs;
  String? _lastSerializedGroups;
  
  // Debounce delay
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  /// Sauvegarde avec debouncing et compression
  Future<void> saveTabsDebounced(List<TabModel> tabs) async {
    _saveTabsTimer?.cancel();
    _saveTabsTimer = Timer(_debounceDelay, () async {
      await _saveTabs(tabs);
    });
  }
  
  /// Sauvegarde immédiate (pour les cas critiques)
  Future<void> saveTabs(List<TabModel> tabs) async {
    _saveTabsTimer?.cancel();
    await _saveTabs(tabs);
  }
  
  /// Sauvegarde interne avec compression
  Future<void> _saveTabs(List<TabModel> tabs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sérialiser dans un isolate pour ne pas bloquer l'UI
      final tabsJson = await compute(_serializeTabs, tabs);
      
      // Vérifier si les données ont changé
      if (tabsJson == _lastSerializedTabs) {
        return; // Pas de changement, pas besoin de sauvegarder
      }
      
      _lastSerializedTabs = tabsJson;
      
      // Compresser les données
      final compressed = await compute(_compressData, tabsJson);
      
      // Sauvegarder la version compressée
      await prefs.setString(_tabsCompressedKey, base64Encode(compressed));
      
      // Garder aussi la version non compressée pour compatibilité
      if (tabsJson.length < 10000) {
        // Seulement si petite taille
        await prefs.setString(_tabsKey, tabsJson);
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde tabs: $e');
    }
  }
  
  /// Sérialisation dans un isolate
  static String _serializeTabs(List<TabModel> tabs) {
    final tabsJson = tabs.map((tab) => tab.toJson()).toList();
    return jsonEncode(tabsJson);
  }
  
  /// Compression gzip dans un isolate
  static List<int> _compressData(String data) {
    final bytes = utf8.encode(data);
    return gzip.encode(bytes);
  }
  
  /// Décompression gzip dans un isolate
  static String _decompressData(List<int> compressed) {
    final decompressed = gzip.decode(compressed);
    return utf8.decode(decompressed);
  }

  Future<List<TabModel>> loadTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Essayer d'abord la version compressée
      final compressedString = prefs.getString(_tabsCompressedKey);
      if (compressedString != null) {
        try {
          final compressed = base64Decode(compressedString);
          final tabsJsonString = await compute(_decompressData, compressed);
          final List<dynamic> tabsJson = jsonDecode(tabsJsonString);
          final tabs = tabsJson.map((json) => TabModel.fromJson(json)).toList();
          _lastSerializedTabs = tabsJsonString;
          return tabs;
        } catch (e) {
          debugPrint('Erreur décompression tabs: $e');
        }
      }
      
      // Fallback vers version non compressée
      final tabsJsonString = prefs.getString(_tabsKey);
      if (tabsJsonString != null) {
        final List<dynamic> tabsJson = jsonDecode(tabsJsonString);
        final tabs = tabsJson.map((json) => TabModel.fromJson(json)).toList();
        _lastSerializedTabs = tabsJsonString;
        return tabs;
      }
    } catch (e) {
      debugPrint('Erreur chargement tabs: $e');
    }
    return [];
  }

  /// Sauvegarde avec debouncing et compression
  Future<void> saveGroupsDebounced(List<TabGroupModel> groups) async {
    _saveGroupsTimer?.cancel();
    _saveGroupsTimer = Timer(_debounceDelay, () async {
      await _saveGroups(groups);
    });
  }
  
  /// Sauvegarde immédiate
  Future<void> saveGroups(List<TabGroupModel> groups) async {
    _saveGroupsTimer?.cancel();
    await _saveGroups(groups);
  }
  
  /// Sauvegarde interne avec compression
  Future<void> _saveGroups(List<TabGroupModel> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sérialiser dans un isolate
      final groupsJson = await compute(_serializeGroups, groups);
      
      // Vérifier si les données ont changé
      if (groupsJson == _lastSerializedGroups) {
        return;
      }
      
      _lastSerializedGroups = groupsJson;
      
      // Compresser les données
      final compressed = await compute(_compressData, groupsJson);
      
      // Sauvegarder la version compressée
      await prefs.setString(_groupsCompressedKey, base64Encode(compressed));
      
      // Garder aussi la version non compressée pour compatibilité
      if (groupsJson.length < 10000) {
        await prefs.setString(_groupsKey, groupsJson);
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde groups: $e');
    }
  }
  
  /// Sérialisation dans un isolate
  static String _serializeGroups(List<TabGroupModel> groups) {
    final groupsJson = groups.map((group) => group.toJson()).toList();
    return jsonEncode(groupsJson);
  }

  Future<List<TabGroupModel>> loadGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Essayer d'abord la version compressée
      final compressedString = prefs.getString(_groupsCompressedKey);
      if (compressedString != null) {
        try {
          final compressed = base64Decode(compressedString);
          final groupsJsonString = await compute(_decompressData, compressed);
          final List<dynamic> groupsJson = jsonDecode(groupsJsonString);
          final groups = groupsJson.map((json) => TabGroupModel.fromJson(json)).toList();
          _lastSerializedGroups = groupsJsonString;
          return groups;
        } catch (e) {
          debugPrint('Erreur décompression groups: $e');
        }
      }
      
      // Fallback vers version non compressée
      final groupsJsonString = prefs.getString(_groupsKey);
      if (groupsJsonString != null) {
        final List<dynamic> groupsJson = jsonDecode(groupsJsonString);
        final groups = groupsJson.map((json) => TabGroupModel.fromJson(json)).toList();
        _lastSerializedGroups = groupsJsonString;
        return groups;
      }
    } catch (e) {
      debugPrint('Erreur chargement groups: $e');
    }
    return [];
  }

  /// Sauvegarde avec debouncing
  Future<void> saveActiveTabDebounced(String? tabId) async {
    _saveActiveTabTimer?.cancel();
    _saveActiveTabTimer = Timer(_debounceDelay, () async {
      await _saveActiveTab(tabId);
    });
  }
  
  /// Sauvegarde immédiate
  Future<void> saveActiveTab(String? tabId) async {
    _saveActiveTabTimer?.cancel();
    await _saveActiveTab(tabId);
  }
  
  /// Sauvegarde interne
  Future<void> _saveActiveTab(String? tabId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (tabId != null) {
        await prefs.setString(_activeTabKey, tabId);
      } else {
        await prefs.remove(_activeTabKey);
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde activeTab: $e');
    }
  }
  
  /// Annule tous les timers en attente (utile pour cleanup)
  void cancelPendingSaves() {
    _saveTabsTimer?.cancel();
    _saveGroupsTimer?.cancel();
    _saveActiveTabTimer?.cancel();
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

