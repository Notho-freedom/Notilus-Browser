import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/tab_model.dart';
import '../core/utils/url_validator.dart';
import '../core/constants/notilus_colors.dart';

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
}

