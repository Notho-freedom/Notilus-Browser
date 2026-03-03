/// Modèles pour les widgets de la page d'accueil personnalisable
library home_widget_models;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Types de widgets disponibles
enum HomeWidgetType {
  // Widgets système
  systemMetrics,      // Métriques système (CPU, RAM, etc.)
  quickAccess,        // Accès rapide aux sites
  recentHistory,      // Historique récent
  bookmarks,          // Favoris rapides
  quickTerminal,      // Terminal rapide
  
  // Widgets développeur
  serverList,         // Liste des serveurs (Backend Lab)
  tasksNotes,         // Tâches et notes
  gitStatus,          // Statut Git
  apiEndpoints,       // Endpoints API découverts
  logsViewer,         // Visualiseur de logs
  codeSnippets,       // Snippets de code
  timeTracker,        // Suivi du temps
  pomodoro,           // Timer Pomodoro
  
  // Widgets personnalisés
  custom,             // Widget personnalisé
}

extension HomeWidgetTypeExtension on HomeWidgetType {
  String get label {
    switch (this) {
      case HomeWidgetType.systemMetrics: return 'Métriques Système';
      case HomeWidgetType.quickAccess: return 'Accès Rapide';
      case HomeWidgetType.recentHistory: return 'Historique Récent';
      case HomeWidgetType.bookmarks: return 'Favoris';
      case HomeWidgetType.quickTerminal: return 'Terminal Rapide';
      case HomeWidgetType.serverList: return 'Serveurs';
      case HomeWidgetType.tasksNotes: return 'Tâches & Notes';
      case HomeWidgetType.gitStatus: return 'Statut Git';
      case HomeWidgetType.apiEndpoints: return 'Endpoints API';
      case HomeWidgetType.logsViewer: return 'Logs';
      case HomeWidgetType.codeSnippets: return 'Snippets';
      case HomeWidgetType.timeTracker: return 'Suivi Temps';
      case HomeWidgetType.pomodoro: return 'Pomodoro';
      case HomeWidgetType.custom: return 'Personnalisé';
    }
  }

  IconData get icon {
    switch (this) {
      case HomeWidgetType.systemMetrics: return Icons.monitor_heart;
      case HomeWidgetType.quickAccess: return Icons.star;
      case HomeWidgetType.recentHistory: return Icons.history;
      case HomeWidgetType.bookmarks: return Icons.bookmark;
      case HomeWidgetType.quickTerminal: return Icons.terminal;
      case HomeWidgetType.serverList: return Icons.dns;
      case HomeWidgetType.tasksNotes: return Icons.task;
      case HomeWidgetType.gitStatus: return Icons.source;
      case HomeWidgetType.apiEndpoints: return Icons.api;
      case HomeWidgetType.logsViewer: return Icons.description;
      case HomeWidgetType.codeSnippets: return Icons.code;
      case HomeWidgetType.timeTracker: return Icons.timer;
      case HomeWidgetType.pomodoro: return Icons.timer_outlined;
      case HomeWidgetType.custom: return Icons.widgets;
    }
  }

  String get description {
    switch (this) {
      case HomeWidgetType.systemMetrics: return 'Affiche les métriques système en temps réel';
      case HomeWidgetType.quickAccess: return 'Accès rapide aux sites favoris';
      case HomeWidgetType.recentHistory: return 'Historique de navigation récent';
      case HomeWidgetType.bookmarks: return 'Favoris et bookmarks';
      case HomeWidgetType.quickTerminal: return 'Terminal intégré rapide';
      case HomeWidgetType.serverList: return 'Liste des serveurs découverts';
      case HomeWidgetType.tasksNotes: return 'Gestionnaire de tâches et notes';
      case HomeWidgetType.gitStatus: return 'Statut du dépôt Git actuel';
      case HomeWidgetType.apiEndpoints: return 'Endpoints API découverts';
      case HomeWidgetType.logsViewer: return 'Visualiseur de logs en temps réel';
      case HomeWidgetType.codeSnippets: return 'Bibliothèque de snippets de code';
      case HomeWidgetType.timeTracker: return 'Suivi du temps de travail';
      case HomeWidgetType.pomodoro: return 'Timer Pomodoro pour la productivité';
      case HomeWidgetType.custom: return 'Widget personnalisé';
    }
  }
}

/// Taille d'un widget
enum WidgetSize {
  small,    // 1x1
  medium,   // 2x1 ou 1x2
  large,    // 2x2
  wide,     // 3x1
  tall,     // 1x3
  full,     // 3x2 ou plus
}

extension WidgetSizeExtension on WidgetSize {
  int get width {
    switch (this) {
      case WidgetSize.small: return 1;
      case WidgetSize.medium: return 2;
      case WidgetSize.large: return 2;
      case WidgetSize.wide: return 3;
      case WidgetSize.tall: return 1;
      case WidgetSize.full: return 3;
    }
  }

  int get height {
    switch (this) {
      case WidgetSize.small: return 1;
      case WidgetSize.medium: return 1;
      case WidgetSize.large: return 2;
      case WidgetSize.wide: return 1;
      case WidgetSize.tall: return 3;
      case WidgetSize.full: return 2;
    }
  }
}

/// Configuration d'un widget
class HomeWidget {
  final String id;
  final HomeWidgetType type;
  final WidgetSize size;
  final Offset position; // Position dans la grille (x, y)
  final Map<String, dynamic> config; // Configuration spécifique au widget
  final bool isMinimized;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HomeWidget({
    String? id,
    required this.type,
    this.size = WidgetSize.medium,
    Offset? position,
    Map<String, dynamic>? config,
    this.isMinimized = false,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        position = position ?? Offset.zero,
        config = config ?? {},
        createdAt = createdAt ?? DateTime.now();

  HomeWidget copyWith({
    HomeWidgetType? type,
    WidgetSize? size,
    Offset? position,
    Map<String, dynamic>? config,
    bool? isMinimized,
    DateTime? updatedAt,
  }) {
    return HomeWidget(
      id: id,
      type: type ?? this.type,
      size: size ?? this.size,
      position: position ?? this.position,
      config: config ?? this.config,
      isMinimized: isMinimized ?? this.isMinimized,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'size': size.name,
      'position': {'x': position.dx, 'y': position.dy},
      'config': config,
      'isMinimized': isMinimized,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory HomeWidget.fromJson(Map<String, dynamic> json) {
    return HomeWidget(
      id: json['id'] as String,
      type: HomeWidgetType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HomeWidgetType.custom,
      ),
      size: WidgetSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () => WidgetSize.medium,
      ),
      position: json['position'] != null
          ? Offset(
              (json['position'] as Map)['x']?.toDouble() ?? 0,
              (json['position'] as Map)['y']?.toDouble() ?? 0,
            )
          : Offset.zero,
      config: json['config'] as Map<String, dynamic>? ?? {},
      isMinimized: json['isMinimized'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

/// Configuration de la page d'accueil
class HomePageConfig {
  final List<HomeWidget> widgets;
  final int gridColumns;
  final int gridRows;
  final double widgetSpacing;
  final bool snapToGrid;
  final DateTime lastModified;

  HomePageConfig({
    List<HomeWidget>? widgets,
    this.gridColumns = 12,
    this.gridRows = 8,
    this.widgetSpacing = 16.0,
    this.snapToGrid = true,
    DateTime? lastModified,
  })  : widgets = widgets ?? [],
        lastModified = lastModified ?? DateTime.now();

  HomePageConfig copyWith({
    List<HomeWidget>? widgets,
    int? gridColumns,
    int? gridRows,
    double? widgetSpacing,
    bool? snapToGrid,
  }) {
    return HomePageConfig(
      widgets: widgets ?? this.widgets,
      gridColumns: gridColumns ?? this.gridColumns,
      gridRows: gridRows ?? this.gridRows,
      widgetSpacing: widgetSpacing ?? this.widgetSpacing,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      lastModified: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'gridColumns': gridColumns,
      'gridRows': gridRows,
      'widgetSpacing': widgetSpacing,
      'snapToGrid': snapToGrid,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory HomePageConfig.fromJson(Map<String, dynamic> json) {
    return HomePageConfig(
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((w) => HomeWidget.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      gridColumns: json['gridColumns'] as int? ?? 12,
      gridRows: json['gridRows'] as int? ?? 8,
      widgetSpacing: (json['widgetSpacing'] as num?)?.toDouble() ?? 16.0,
      snapToGrid: json['snapToGrid'] as bool? ?? true,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : DateTime.now(),
    );
  }
}

