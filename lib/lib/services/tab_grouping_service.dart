import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/tab_model.dart';
import '../core/utils/url_validator.dart';
import '../core/constants/notilus_colors.dart';
import 'dart:convert';

class TabGroupingService {
  /// Groupe automatiquement les onglets selon différents critères
  static Map<String, List<TabModel>> groupTabsByDomain(List<TabModel> tabs) {
    final Map<String, List<TabModel>> groups = {};
    
    for (final tab in tabs) {
      if (tab.url == null || tab.url!.isEmpty || tab.url!.startsWith('about:')) {
        continue;
      }
      
      final domain = UrlValidator.extractDomain(tab.url!) ?? 'unknown';
      if (!groups.containsKey(domain)) {
        groups[domain] = [];
      }
      groups[domain]!.add(tab);
    }
    
    return groups;
  }

  /// Détecte les doublons (même URL)
  static List<List<TabModel>> findDuplicates(List<TabModel> tabs) {
    final Map<String, List<TabModel>> urlGroups = {};
    
    for (final tab in tabs) {
      if (tab.url == null || tab.url!.isEmpty) continue;
      final url = tab.url!;
      if (!urlGroups.containsKey(url)) {
        urlGroups[url] = [];
      }
      urlGroups[url]!.add(tab);
    }
    
    return urlGroups.values.where((group) => group.length > 1).toList();
  }

  /// Suggère des groupes basés sur des critères pertinents
  /// Utilise compute() pour exécuter dans un isolate (non bloquant)
  static Future<List<TabGroupSuggestion>> suggestGroupsAsync(List<TabModel> tabs) async {
    // Sérialiser les tabs en JSON pour passer à l'isolate
    final tabsJson = tabs.map((t) => t.toJson()).toList();
    
    // Exécuter dans un isolate
    final result = await compute(_suggestGroupsIsolate, tabsJson);
    
    // Désérialiser les résultats
    return result.map((json) => TabGroupSuggestion.fromJson(json)).toList();
  }
  
  /// Suggère des groupes basés sur des critères pertinents (synchrone, pour compatibilité)
  static List<TabGroupSuggestion> suggestGroups(List<TabModel> tabs) {
    final suggestions = <TabGroupSuggestion>[];
    
    // Groupes par domaine
    final domainGroups = groupTabsByDomain(tabs);
    for (final entry in domainGroups.entries) {
      if (entry.value.length >= 2) {
        suggestions.add(TabGroupSuggestion(
          name: entry.key,
          tabIds: entry.value.map((t) => t.id).toList(),
          reason: '${entry.value.length} onglets du même domaine',
          color: _generateColorForDomain(entry.key),
        ));
      }
    }
    
    // Doublons
    final duplicates = findDuplicates(tabs);
    for (final dupGroup in duplicates) {
      if (dupGroup.length >= 2) {
        final url = dupGroup.first.url ?? 'unknown';
        suggestions.add(TabGroupSuggestion(
          name: 'Doublons: ${UrlValidator.extractDomain(url) ?? url}',
          tabIds: dupGroup.map((t) => t.id).toList(),
          reason: '${dupGroup.length} onglets avec la même URL',
          color: const Color(0xFFFF6B6B),
        ));
      }
    }
    
    return suggestions;
  }
  
  /// Fonction exécutée dans un isolate pour le groupement
  static List<Map<String, dynamic>> _suggestGroupsIsolate(List<Map<String, dynamic>> tabsJson) {
    // Désérialiser les tabs
    final tabs = tabsJson.map((json) => TabModel.fromJson(json)).toList();
    final suggestions = <TabGroupSuggestion>[];
    
    // Groupes par domaine
    final domainGroups = groupTabsByDomain(tabs);
    for (final entry in domainGroups.entries) {
      if (entry.value.length >= 2) {
        suggestions.add(TabGroupSuggestion(
          name: entry.key,
          tabIds: entry.value.map((t) => t.id).toList(),
          reason: '${entry.value.length} onglets du même domaine',
          color: _generateColorForDomain(entry.key),
        ));
      }
    }
    
    // Doublons
    final duplicates = findDuplicates(tabs);
    for (final dupGroup in duplicates) {
      if (dupGroup.length >= 2) {
        final url = dupGroup.first.url ?? 'unknown';
        suggestions.add(TabGroupSuggestion(
          name: 'Doublons: ${UrlValidator.extractDomain(url) ?? url}',
          tabIds: dupGroup.map((t) => t.id).toList(),
          reason: '${dupGroup.length} onglets avec la même URL',
          color: const Color(0xFFFF6B6B),
        ));
      }
    }
    
    // Sérialiser les résultats
    return suggestions.map((s) => s.toJson()).toList();
  }

  static Color _generateColorForDomain(String domain) {
    final hash = domain.hashCode.abs();
    final colors = [
      NotilusColors.neonRed, // Red
      const Color(0xFF5856D6), // Purple
      const Color(0xFF00C7BE), // Teal
      const Color(0xFFFF9500), // Orange
      const Color(0xFF34C759), // Green
    ];
    return colors[hash % colors.length];
  }
}

class TabGroupSuggestion {
  final String name;
  final List<String> tabIds;
  final String reason;
  final Color color;

  TabGroupSuggestion({
    required this.name,
    required this.tabIds,
    required this.reason,
    required this.color,
  });
  
  /// Sérialisation pour compute()
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tabIds': tabIds,
      'reason': reason,
      'color': color.value,
    };
  }
  
  /// Désérialisation depuis compute()
  factory TabGroupSuggestion.fromJson(Map<String, dynamic> json) {
    return TabGroupSuggestion(
      name: json['name'] as String,
      tabIds: List<String>.from(json['tabIds'] as List),
      reason: json['reason'] as String,
      color: Color(json['color'] as int),
    );
  }
}

