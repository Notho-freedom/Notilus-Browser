/// Notilus Mosaic - Système de workspace dynamique avancé
/// Permet de combiner n'importe quel widget de l'interface dans une mosaïque
library mosaic_models;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Types de contenu disponibles dans une tile
enum MosaicTileType {
  web,           // Onglet navigateur web
  terminal,      // Terminal intégré
  devtools,      // Panneau DevTools
  widgets,       // Widgets système (CPU, RAM, etc.)
  bookmarks,     // Panneau des favoris
  history,       // Historique de navigation
  downloads,     // Téléchargements
  ai,            // Assistant IA
  settings,      // Paramètres
  webService,    // Service web (YouTube, WhatsApp, etc.)
  documentation, // Documentation
  backendLab,    // Backend Lab - Découverte et test de serveurs
  studio,        // Studio - Outils de test front-end
  lighthouse,    // Lighthouse - Analyse de performance
  github,        // GitHub - Gestion des dépôts
  extensions,    // Extensions - Gestion des extensions
  cloudinary,    // Cloudinary - Gestion des médias
  empty,         // Tile vide (placeholder)
  custom,        // Widget personnalisé
}

extension MosaicTileTypeExtension on MosaicTileType {
  String get label {
    switch (this) {
      case MosaicTileType.web: return 'Page Web';
      case MosaicTileType.terminal: return 'Terminal';
      case MosaicTileType.devtools: return 'DevTools';
      case MosaicTileType.widgets: return 'Widgets';
      case MosaicTileType.bookmarks: return 'Favoris';
      case MosaicTileType.history: return 'Historique';
      case MosaicTileType.downloads: return 'Téléchargements';
      case MosaicTileType.ai: return 'Assistant IA';
      case MosaicTileType.settings: return 'Paramètres';
      case MosaicTileType.webService: return 'Service Web';
      case MosaicTileType.documentation: return 'Documentation';
      case MosaicTileType.backendLab: return 'Backend Lab';
      case MosaicTileType.studio: return 'Studio';
      case MosaicTileType.lighthouse: return 'Lighthouse';
      case MosaicTileType.github: return 'GitHub';
      case MosaicTileType.extensions: return 'Extensions';
      case MosaicTileType.cloudinary: return 'Cloudinary';
      case MosaicTileType.empty: return 'Vide';
      case MosaicTileType.custom: return 'Personnalisé';
    }
  }

  IconData get icon {
    switch (this) {
      case MosaicTileType.web: return Icons.language_rounded;
      case MosaicTileType.terminal: return Icons.terminal_rounded;
      case MosaicTileType.devtools: return Icons.bug_report_rounded;
      case MosaicTileType.widgets: return Icons.widgets_rounded;
      case MosaicTileType.bookmarks: return Icons.bookmark_rounded;
      case MosaicTileType.history: return Icons.history_rounded;
      case MosaicTileType.downloads: return Icons.download_rounded;
      case MosaicTileType.ai: return Icons.auto_awesome_rounded;
      case MosaicTileType.settings: return Icons.settings_rounded;
      case MosaicTileType.webService: return Icons.public_rounded;
      case MosaicTileType.documentation: return Icons.menu_book_rounded;
      case MosaicTileType.backendLab: return Icons.dns_rounded;
      case MosaicTileType.studio: return Icons.palette_rounded;
      case MosaicTileType.lighthouse: return Icons.light_mode_rounded;
      case MosaicTileType.github: return Icons.code_rounded;
      case MosaicTileType.extensions: return Icons.extension_rounded;
      case MosaicTileType.cloudinary: return Icons.cloud_upload_rounded;
      case MosaicTileType.empty: return Icons.add_rounded;
      case MosaicTileType.custom: return Icons.extension_rounded;
    }
  }
}

/// Direction de split pour une tile
enum SplitDirection { horizontal, vertical }

/// Position de la zone de drop lors du drag
enum DropZone { left, right, top, bottom, center }

/// Configuration d'une tile dans la mosaïque
class MosaicTile {
  final String id;
  final MosaicTileType type;
  final double flexFactor; // Proportion relative (0.0 - 1.0)
  final String? tabId;     // ID de l'onglet si type == web
  final String? serviceId; // ID du service web si type == webService
  final Map<String, dynamic> metadata; // Données supplémentaires
  final List<MosaicTile>? children; // Pour les layouts imbriqués
  final SplitDirection? splitDirection; // Direction du split si children != null
  final bool isLocked; // Empêche le redimensionnement/fermeture
  final bool isMinimized; // État minimisé

  MosaicTile({
    String? id,
    required this.type,
    this.flexFactor = 1.0,
    this.tabId,
    this.serviceId,
    Map<String, dynamic>? metadata,
    this.children,
    this.splitDirection,
    this.isLocked = false,
    this.isMinimized = false,
  }) : id = id ?? const Uuid().v4(),
       metadata = metadata ?? {};

  /// Créer une tile vide
  factory MosaicTile.empty({double flexFactor = 1.0}) => MosaicTile(
    type: MosaicTileType.empty,
    flexFactor: flexFactor,
  );

  /// Créer une tile web
  factory MosaicTile.web({
    required String tabId,
    double flexFactor = 1.0,
    String? title,
  }) => MosaicTile(
    type: MosaicTileType.web,
    tabId: tabId,
    flexFactor: flexFactor,
    metadata: {'title': title},
  );

  /// Créer une tile terminal
  factory MosaicTile.terminal({double flexFactor = 1.0}) => MosaicTile(
    type: MosaicTileType.terminal,
    flexFactor: flexFactor,
  );

  /// Créer une tile devtools
  factory MosaicTile.devtools({double flexFactor = 1.0}) => MosaicTile(
    type: MosaicTileType.devtools,
    flexFactor: flexFactor,
  );

  /// Créer un split de tiles
  factory MosaicTile.split({
    required List<MosaicTile> children,
    required SplitDirection direction,
    double flexFactor = 1.0,
  }) => MosaicTile(
    type: MosaicTileType.custom,
    children: children,
    splitDirection: direction,
    flexFactor: flexFactor,
  );

  /// Créer une tile service web
  factory MosaicTile.webService({
    required String serviceId,
    double flexFactor = 1.0,
  }) => MosaicTile(
    type: MosaicTileType.webService,
    serviceId: serviceId,
    flexFactor: flexFactor,
  );

  /// Vérifier si c'est un conteneur (avec enfants)
  bool get isContainer => children != null && children!.isNotEmpty;

  /// Vérifier si c'est une feuille (sans enfants)
  bool get isLeaf => children == null || children!.isEmpty;

  /// Copier avec modifications
  MosaicTile copyWith({
    String? id,
    MosaicTileType? type,
    double? flexFactor,
    String? tabId,
    String? serviceId,
    Map<String, dynamic>? metadata,
    List<MosaicTile>? children,
    SplitDirection? splitDirection,
    bool? isLocked,
    bool? isMinimized,
  }) => MosaicTile(
    id: id ?? this.id,
    type: type ?? this.type,
    flexFactor: flexFactor ?? this.flexFactor,
    tabId: tabId ?? this.tabId,
    serviceId: serviceId ?? this.serviceId,
    metadata: metadata ?? Map.from(this.metadata),
    children: children ?? (this.children != null ? List.from(this.children!) : null),
    splitDirection: splitDirection ?? this.splitDirection,
    isLocked: isLocked ?? this.isLocked,
    isMinimized: isMinimized ?? this.isMinimized,
  );

  /// Sérialisation JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'flexFactor': flexFactor,
    'tabId': tabId,
    'serviceId': serviceId,
    'metadata': metadata,
    'children': children?.map((c) => c.toJson()).toList(),
    'splitDirection': splitDirection?.index,
    'isLocked': isLocked,
    'isMinimized': isMinimized,
  };

  /// Désérialisation JSON
  factory MosaicTile.fromJson(Map<String, dynamic> json) => MosaicTile(
    id: json['id'],
    type: MosaicTileType.values[json['type']],
    flexFactor: (json['flexFactor'] as num).toDouble(),
    tabId: json['tabId'],
    serviceId: json['serviceId'],
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    children: json['children'] != null
        ? (json['children'] as List).map((c) => MosaicTile.fromJson(c)).toList()
        : null,
    splitDirection: json['splitDirection'] != null
        ? SplitDirection.values[json['splitDirection']]
        : null,
    isLocked: json['isLocked'] ?? false,
    isMinimized: json['isMinimized'] ?? false,
  );
}

/// Preset de layout pour la mosaïque
class MosaicLayoutPreset {
  final String id;
  final String name;
  final String description;
  final String icon;
  final MosaicTile rootTile;

  const MosaicLayoutPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rootTile,
  });

  /// Presets prédéfinis
  static List<MosaicLayoutPreset> get presets => [
    // Single view
    MosaicLayoutPreset(
      id: 'single',
      name: 'Vue unique',
      description: 'Un seul panneau',
      icon: '▣',
      rootTile: MosaicTile.empty(),
    ),
    
    // Side by side
    MosaicLayoutPreset(
      id: 'side_by_side',
      name: 'Côte à côte',
      description: 'Deux panneaux horizontaux',
      icon: '◫',
      rootTile: MosaicTile.split(
        direction: SplitDirection.horizontal,
        children: [MosaicTile.empty(), MosaicTile.empty()],
      ),
    ),
    
    // Stacked
    MosaicLayoutPreset(
      id: 'stacked',
      name: 'Empilé',
      description: 'Deux panneaux verticaux',
      icon: '⬒',
      rootTile: MosaicTile.split(
        direction: SplitDirection.vertical,
        children: [MosaicTile.empty(), MosaicTile.empty()],
      ),
    ),
    
    // Triple columns
    MosaicLayoutPreset(
      id: 'triple_columns',
      name: 'Triple colonnes',
      description: 'Trois panneaux en colonnes',
      icon: '▥',
      rootTile: MosaicTile.split(
        direction: SplitDirection.horizontal,
        children: [
          MosaicTile.empty(flexFactor: 0.33),
          MosaicTile.empty(flexFactor: 0.34),
          MosaicTile.empty(flexFactor: 0.33),
        ],
      ),
    ),
    
    // Grid 2x2
    MosaicLayoutPreset(
      id: 'grid_2x2',
      name: 'Grille 2×2',
      description: 'Quatre panneaux en grille',
      icon: '⊞',
      rootTile: MosaicTile.split(
        direction: SplitDirection.vertical,
        children: [
          MosaicTile.split(
            direction: SplitDirection.horizontal,
            children: [MosaicTile.empty(), MosaicTile.empty()],
          ),
          MosaicTile.split(
            direction: SplitDirection.horizontal,
            children: [MosaicTile.empty(), MosaicTile.empty()],
          ),
        ],
      ),
    ),
    
    // Main + Sidebar
    MosaicLayoutPreset(
      id: 'main_sidebar',
      name: 'Principal + Sidebar',
      description: 'Grand panneau avec sidebar',
      icon: '◧',
      rootTile: MosaicTile.split(
        direction: SplitDirection.horizontal,
        children: [
          MosaicTile.empty(flexFactor: 0.7),
          MosaicTile.empty(flexFactor: 0.3),
        ],
      ),
    ),
    
    // Dev layout (main + bottom + sidebar)
    MosaicLayoutPreset(
      id: 'developer',
      name: 'Développeur',
      description: 'Layout idéal pour le développement',
      icon: '⌘',
      rootTile: MosaicTile.split(
        direction: SplitDirection.horizontal,
        children: [
          MosaicTile.split(
            direction: SplitDirection.vertical,
            flexFactor: 0.7,
            children: [
              MosaicTile.empty(flexFactor: 0.7),
              MosaicTile(type: MosaicTileType.terminal, flexFactor: 0.3),
            ],
          ),
          MosaicTile(type: MosaicTileType.devtools, flexFactor: 0.3),
        ],
      ),
    ),
    
    // Productivity (main + ai + widgets)
    MosaicLayoutPreset(
      id: 'productivity',
      name: 'Productivité',
      description: 'Avec AI et widgets',
      icon: '✧',
      rootTile: MosaicTile.split(
        direction: SplitDirection.horizontal,
        children: [
          MosaicTile.empty(flexFactor: 0.6),
          MosaicTile.split(
            direction: SplitDirection.vertical,
            flexFactor: 0.4,
            children: [
              MosaicTile(type: MosaicTileType.ai, flexFactor: 0.5),
              MosaicTile(type: MosaicTileType.widgets, flexFactor: 0.5),
            ],
          ),
        ],
      ),
    ),
    
    // Focus mode (main center, mini sidebars)
    MosaicLayoutPreset(
      id: 'focus',
      name: 'Mode Focus',
      description: 'Concentration maximale',
      icon: '◉',
      rootTile: MosaicTile.split(
        direction: SplitDirection.horizontal,
        children: [
          MosaicTile(type: MosaicTileType.bookmarks, flexFactor: 0.15),
          MosaicTile.empty(flexFactor: 0.7),
          MosaicTile(type: MosaicTileType.history, flexFactor: 0.15),
        ],
      ),
    ),
  ];
}

/// État de drag pour une tile
class MosaicDragData {
  final MosaicTile tile;
  final String sourceTileId;
  
  const MosaicDragData({
    required this.tile,
    required this.sourceTileId,
  });
}

/// Configuration du workspace mosaïque
class MosaicWorkspace {
  final String id;
  final String name;
  final MosaicTile rootTile;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isDefault;

  MosaicWorkspace({
    String? id,
    required this.name,
    required this.rootTile,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       modifiedAt = modifiedAt ?? DateTime.now();

  MosaicWorkspace copyWith({
    String? id,
    String? name,
    MosaicTile? rootTile,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDefault,
  }) => MosaicWorkspace(
    id: id ?? this.id,
    name: name ?? this.name,
    rootTile: rootTile ?? this.rootTile,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? DateTime.now(),
    isDefault: isDefault ?? this.isDefault,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rootTile': rootTile.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'modifiedAt': modifiedAt.toIso8601String(),
    'isDefault': isDefault,
  };

  factory MosaicWorkspace.fromJson(Map<String, dynamic> json) => MosaicWorkspace(
    id: json['id'],
    name: json['name'],
    rootTile: MosaicTile.fromJson(json['rootTile']),
    createdAt: DateTime.parse(json['createdAt']),
    modifiedAt: DateTime.parse(json['modifiedAt']),
    isDefault: json['isDefault'] ?? false,
  );
}
