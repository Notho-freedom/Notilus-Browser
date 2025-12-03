/// Notilus Mosaic Tile Content - Contenu des différentes tiles
/// Rend le contenu approprié selon le type de tile
library mosaic_tile_content;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/mosaic_models.dart';
import '../../models/tab_model.dart';
import '../../services/mosaic_service.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../browser/web_content_view.dart';
import '../browser/gx_futuristic_bookmarks_panel.dart';
import '../browser/gx_futuristic_history_panel.dart';
import '../browser/gx_futuristic_downloads_panel.dart';
import '../browser/modern_settings_panel.dart';
import '../browser/webview_service_panel.dart';
import '../terminal/native_terminal_panel.dart';
import '../dev_tools/notilus_devtools.dart';
import '../documentation/documentation_panel.dart';
import '../dev_tools/backend_lab_panel.dart';
import '../studio/studio_panel.dart';
import '../lighthouse/lighthouse_panel.dart';
import '../github/github_repos_panel.dart';
import '../browser/cloudinary_media_manager.dart';
import '../../services/cloudinary_service.dart';
// Widgets autonomes
import '../home_widgets/frontend_resources_widget.dart';
import '../home_widgets/frontend_tools_widget.dart';
import '../home_widgets/backend_languages_widget.dart';
import '../home_widgets/backend_tools_widget.dart';
import '../home_widgets/system_metrics_widget.dart';
import '../home_widgets/command_prompt_widget.dart';
import '../home_widgets/service_status_widget.dart';
import '../home_widgets/infrastructure_metrics_widget.dart';
import '../home_widgets/devops_tools_widget.dart';
import '../home_widgets/command_center_widget.dart';
import '../home_widgets/data_science_libraries_widget.dart';
import '../home_widgets/data_science_tools_widget.dart';
import '../home_widgets/quick_links_widget.dart';
import '../home_widgets/search_bar_widget.dart';
import '../home_widgets/developer_quotes_widget.dart';
import '../home_widgets/time_display_widget.dart';

/// Widget qui rend le contenu approprié selon le type de tile
class MosaicTileContent extends StatelessWidget {
  final MosaicTile tile;

  const MosaicTileContent({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    switch (tile.type) {
      case MosaicTileType.web:
        return _WebTileContent(tile: tile);
      case MosaicTileType.terminal:
        return const _TerminalTileContent();
      case MosaicTileType.devtools:
        return _DevToolsTileContent(tile: tile);
      case MosaicTileType.widgets:
        return const _WidgetsTileContent();
      case MosaicTileType.bookmarks:
        return const GxFuturisticBookmarksPanel();
      case MosaicTileType.history:
        return const GxFuturisticHistoryPanel();
      case MosaicTileType.downloads:
        return const GxFuturisticDownloadsPanel();
      case MosaicTileType.ai:
        return const _AITileContent();
      case MosaicTileType.settings:
        return ModernSettingsPanel();
      case MosaicTileType.webService:
        return _WebServiceTileContent(tile: tile);
      case MosaicTileType.documentation:
        return const DocumentationPanel();
      case MosaicTileType.backendLab:
        return const BackendLabPanel();
      case MosaicTileType.studio:
        return const StudioPanel();
      case MosaicTileType.lighthouse:
        return const LighthousePanel();
      case MosaicTileType.github:
        return const GitHubReposPanel();
      case MosaicTileType.extensions:
        // ExtensionsPanel désactivé - fonctionnalité en cours de développement
        return const Center(child: Text('Extensions - Bientôt disponible', style: TextStyle(color: Colors.white54)));
      case MosaicTileType.cloudinary:
        return CloudinaryMediaManager(
          resourceType: CloudinaryResourceType.auto,
          title: 'Cloudinary Media',
          allowMultiple: true,
        );
      case MosaicTileType.empty:
        return _EmptyTileContent(tile: tile);
      case MosaicTileType.custom:
        return const _CustomTileContent();
      // Widgets Frontend
      case MosaicTileType.frontendResources:
        return _FrontendResourcesTileContent(tile: tile);
      case MosaicTileType.frontendTools:
        return _FrontendToolsTileContent(tile: tile);
      // Widgets Backend
      case MosaicTileType.backendLanguages:
        return _BackendLanguagesTileContent(tile: tile);
      case MosaicTileType.backendTools:
        return _BackendToolsTileContent(tile: tile);
      case MosaicTileType.systemMetrics:
        return _SystemMetricsTileContent(tile: tile);
      case MosaicTileType.commandPrompt:
        return _CommandPromptTileContent(tile: tile);
      // Widgets DevOps
      case MosaicTileType.serviceStatus:
        return _ServiceStatusTileContent(tile: tile);
      case MosaicTileType.infrastructureMetrics:
        return _InfrastructureMetricsTileContent(tile: tile);
      case MosaicTileType.devopsTools:
        return _DevOpsToolsTileContent(tile: tile);
      case MosaicTileType.commandCenter:
        return _CommandCenterTileContent(tile: tile);
      // Widgets Data Science
      case MosaicTileType.dataScienceLibraries:
        return _DataScienceLibrariesTileContent(tile: tile);
      case MosaicTileType.dataScienceTools:
        return _DataScienceToolsTileContent(tile: tile);
      // Widgets génériques
      case MosaicTileType.quickLinks:
        return _QuickLinksTileContent(tile: tile);
      case MosaicTileType.searchBar:
        return _SearchBarTileContent(tile: tile);
      case MosaicTileType.developerQuotes:
        return _DeveloperQuotesTileContent(tile: tile);
      case MosaicTileType.timeDisplay:
        return _TimeDisplayTileContent(tile: tile);
    }
  }
}

/// Contenu Web (onglet navigateur)
class _WebTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _WebTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    if (tile.tabId == null) {
      return _TabSelector(
        tileId: tile.id,
        message: 'Sélectionnez un onglet web',
      );
    }

    return Consumer<TabManager>(
      builder: (context, tabManager, _) {
        final tab = tabManager.tabs.firstWhere(
          (t) => t.id == tile.tabId,
          orElse: () => TabModel(),
        );

        if (tab.url == null || tab.url!.isEmpty) {
          return _TabSelector(
            tileId: tile.id,
            message: 'Onglet vide ou invalide',
          );
        }

        return WebContentView(tab: tab);
      },
    );
  }
}

/// Sélecteur d'onglet pour les tiles web
class _TabSelector extends StatefulWidget {
  final String tileId;
  final String message;

  const _TabSelector({
    required this.tileId,
    required this.message,
  });

  @override
  State<_TabSelector> createState() => _TabSelectorState();
}

class _TabSelectorState extends State<_TabSelector> {
  bool _showTabs = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Container(
      color: const Color(0xFF0D0D12),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Icon(
                    CupertinoIcons.globe,
                    size: 40,
                    color: accentColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _showTabs = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.square_stack, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Choisir un onglet',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showTabs)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showTabs = false),
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: _TabListPopup(
                      tileId: widget.tileId,
                      accentColor: accentColor,
                      onClose: () => setState(() => _showTabs = false),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabListPopup extends StatelessWidget {
  final String tileId;
  final Color accentColor;
  final VoidCallback onClose;

  const _TabListPopup({
    required this.tileId,
    required this.accentColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TabManager>(
      builder: (context, tabManager, _) {
        return Container(
          width: 350,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF15151A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.square_stack, color: accentColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Onglets disponibles',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onClose,
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: tabManager.tabs.length,
                  itemBuilder: (context, index) {
                    final tab = tabManager.tabs[index];
                    return _TabListItem(
                      tab: tab,
                      accentColor: accentColor,
                      onTap: () {
                        context.read<NotilusMosaicService>().setTileTab(
                          tileId,
                          tab.id,
                          tabManager: tabManager,
                        );
                        onClose();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 200.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 200.ms);
      },
    );
  }
}

class _TabListItem extends StatefulWidget {
  final TabModel tab;
  final Color accentColor;
  final VoidCallback onTap;

  const _TabListItem({
    required this.tab,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_TabListItem> createState() => _TabListItemState();
}

class _TabListItemState extends State<_TabListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _isHovered ? widget.accentColor.withOpacity(0.1) : Colors.transparent,
          child: Row(
            children: [
              if (widget.tab.favicon != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    widget.tab.favicon!,
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => Icon(
                      CupertinoIcons.globe,
                      size: 20,
                      color: widget.accentColor,
                    ),
                  ),
                )
              else
                Icon(
                  CupertinoIcons.globe,
                  size: 20,
                  color: widget.accentColor,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tab.title ?? 'Sans titre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.tab.url != null)
                      Text(
                        widget.tab.url!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contenu Terminal
class _TerminalTileContent extends StatelessWidget {
  const _TerminalTileContent();

  @override
  Widget build(BuildContext context) {
    return const NativeTerminalPanel();
  }
}

/// Contenu DevTools
class _DevToolsTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _DevToolsTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Consumer<TabWebViewManager>(
      builder: (context, tabWebViewManager, _) {
        final tabManager = context.read<TabManager>();
        final activeTab = tabManager.activeTab;
        final engine = activeTab != null
            ? tabWebViewManager.getEngineForTab(activeTab.id)
            : null;

        return NotilusDevTools(
          engine: engine,
          onClose: () {
            context.read<NotilusMosaicService>().closeTile(tile.id);
          },
        );
      },
    );
  }
}

/// Contenu Widgets système
class _WidgetsTileContent extends StatelessWidget {
  const _WidgetsTileContent();

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Container(
      color: const Color(0xFF0D0D12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.gauge, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Système',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _SystemWidget(
                  icon: CupertinoIcons.gauge,
                  label: 'CPU',
                  value: '32%',
                  color: accentColor,
                ),
                _SystemWidget(
                  icon: Icons.memory,
                  label: 'RAM',
                  value: '45%',
                  color: accentColor,
                ),
                _SystemWidget(
                  icon: CupertinoIcons.thermometer,
                  label: 'GPU',
                  value: '58°C',
                  color: accentColor,
                ),
                _SystemWidget(
                  icon: CupertinoIcons.waveform_path,
                  label: 'Réseau',
                  value: '1.1 Gbps',
                  color: accentColor,
                ),
                _SystemWidget(
                  icon: CupertinoIcons.square_grid_2x2,
                  label: 'Onglets',
                  value: '12',
                  color: accentColor,
                ),
                _SystemWidget(
                  icon: CupertinoIcons.moon,
                  label: 'Veille',
                  value: 'Auto',
                  color: accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SystemWidget({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenu AI
class _AITileContent extends StatelessWidget {
  const _AITileContent();

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Container(
      color: const Color(0xFF0D0D12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hyper Assistant',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Notilus AI',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comment puis-je vous aider ?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _AIQuickAction(label: '📝 Résumer la page', color: accentColor),
                      _AIQuickAction(label: '🔍 Rechercher', color: accentColor),
                      _AIQuickAction(label: '🌐 Traduire', color: accentColor),
                      _AIQuickAction(label: '💡 Expliquer', color: accentColor),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble,
                          color: accentColor.withOpacity(0.6),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Posez votre question...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.arrow_up_circle_fill,
                          color: accentColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIQuickAction extends StatefulWidget {
  final String label;
  final Color color;

  const _AIQuickAction({required this.label, required this.color});

  @override
  State<_AIQuickAction> createState() => _AIQuickActionState();
}

class _AIQuickActionState extends State<_AIQuickAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isHovered ? widget.color.withOpacity(0.2) : widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? widget.color.withOpacity(0.6) : widget.color.withOpacity(0.3),
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: _isHovered ? widget.color : Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Contenu Service Web
class _WebServiceTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _WebServiceTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final serviceId = tile.serviceId;
    if (serviceId == null) {
      return const _EmptyTileContent(tile: null);
    }

    // Mapper les IDs de service aux URLs
    final serviceUrls = {
      'youtubeMusic': 'https://music.youtube.com',
      'youtube': 'https://www.youtube.com',
      'chatgpt': 'https://chat.openai.com',
      'deepseek': 'https://chat.deepseek.com',
      'whatsapp': 'https://web.whatsapp.com',
      'telegram': 'https://web.telegram.org',
    };

    final url = serviceUrls[serviceId];
    if (url == null) {
      return const _EmptyTileContent(tile: null);
    }

    return WebViewServicePanel(
      url: url,
      title: serviceId,
      icon: CupertinoIcons.globe,
      color: Colors.blue,
    );
  }
}

/// Contenu vide (placeholder)
class _EmptyTileContent extends StatelessWidget {
  final MosaicTile? tile;

  const _EmptyTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final mosaicService = context.read<NotilusMosaicService>();

    // Types de contenu disponibles (sans custom et empty)
    final availableTypes = MosaicTileType.values
        .where((t) => t != MosaicTileType.custom && t != MosaicTileType.empty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D0D12),
            const Color(0xFF101018),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adapter la grille selon la taille
          final isCompact = constraints.maxWidth < 300 || constraints.maxHeight < 300;
          
          if (isCompact) {
            // Mode compact - liste simple
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: availableTypes.map((type) => _CompactTypeButton(
                  type: type,
                  accentColor: accentColor,
                  onTap: () {
                    final currentTile = tile;
                    if (currentTile != null) {
                      mosaicService.setTileContent(currentTile.id, type);
                    }
                  },
                )).toList(),
              ),
            );
          }
          
          // Mode normal - grille
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Choisir un contenu',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ou glissez un onglet ici',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: availableTypes.map((type) => _TypeButton(
                    type: type,
                    accentColor: accentColor,
                    onTap: () {
                      final currentTile = tile;
                      if (currentTile != null) {
                        mosaicService.setTileContent(currentTile.id, type);
                      }
                    },
                  )).toList(),
                ),
              ],
            ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms);
  }
}

/// Bouton de type pour la grille
class _TypeButton extends StatefulWidget {
  final MosaicTileType type;
  final Color accentColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.type,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_TypeButton> createState() => _TypeButtonState();
}

class _TypeButtonState extends State<_TypeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 80,
          height: 70,
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.accentColor.withOpacity(0.15)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.type.icon,
                size: 24,
                color: _isHovered ? widget.accentColor : Colors.white.withOpacity(0.6),
              ),
              const SizedBox(height: 6),
              Text(
                widget.type.label,
                style: TextStyle(
                  color: _isHovered ? widget.accentColor : Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: _isHovered ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton de type compact
class _CompactTypeButton extends StatefulWidget {
  final MosaicTileType type;
  final Color accentColor;
  final VoidCallback onTap;

  const _CompactTypeButton({
    required this.type,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_CompactTypeButton> createState() => _CompactTypeButtonState();
}

class _CompactTypeButtonState extends State<_CompactTypeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.accentColor.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.type.icon,
                size: 14,
                color: _isHovered ? widget.accentColor : Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                widget.type.label,
                style: TextStyle(
                  color: _isHovered ? widget.accentColor : Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contenu personnalisé
class _CustomTileContent extends StatelessWidget {
  const _CustomTileContent();

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Container(
      color: const Color(0xFF0D0D12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.square_grid_2x2,
              size: 40,
              color: accentColor.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Widget personnalisé',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === WIDGETS FRONTEND ===

class _FrontendResourcesTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _FrontendResourcesTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final resourcesList = tile.metadata['resources'] as List<dynamic>?;
    final resources = resourcesList?.isEmpty == true 
        ? null 
        : (resourcesList
            ?.map((r) {
              try {
                return FrontendResource(
                  name: r['name'] as String? ?? '',
                  url: r['url'] as String? ?? '',
                  emoji: r['emoji'] as String? ?? '🔗',
                  color: r['color'] != null ? Color(r['color'] as int) : accentColor,
                );
              } catch (e) {
                return null;
              }
            })
            .whereType<FrontendResource>()
            .toList());
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFF0D0D12),
          padding: const EdgeInsets.all(16),
          width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity,
          child: FrontendResourcesWidget(
            resources: resources,
            accentColor: accentColor,
            transparency: transparency,
          ),
        );
      },
    );
  }
}

class _FrontendToolsTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _FrontendToolsTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final categories = (tile.metadata['categories'] as List<dynamic>?)
        ?.map((c) {
          try {
            return ToolCategory(
              name: c['name'] as String? ?? '',
              icon: c['icon'] != null ? IconData(c['icon'] as int, fontFamily: 'CupertinoIcons') : CupertinoIcons.square_grid_2x2,
              tools: (c['tools'] as List<dynamic>?)
                  ?.map((t) {
                    try {
                      return DevTool(
                        name: t['name'] as String? ?? '',
                        url: t['url'] as String? ?? '',
                        color: t['color'] != null ? Color(t['color'] as int) : accentColor,
                      );
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<DevTool>()
                  .toList() ?? [],
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<ToolCategory>()
        .toList() ?? [];
    
    return Container(
      color: const Color(0xFF0D0D12),
      padding: const EdgeInsets.all(16),
      child: FrontendToolsWidget(
        categories: categories,
        accentColor: accentColor,
        transparency: transparency,
      ),
    );
  }
}

// === WIDGETS BACKEND ===

class _BackendLanguagesTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _BackendLanguagesTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final languagesList = tile.metadata['languages'] as List<dynamic>?;
    final languages = languagesList?.isEmpty == true
        ? null
        : (languagesList
            ?.map((l) {
              try {
                return BackendLanguage(
                  name: l['name'] as String? ?? '',
                  url: l['url'] as String? ?? '',
                  emoji: l['emoji'] as String? ?? '💻',
                  color: l['color'] != null ? Color(l['color'] as int) : accentColor,
                );
              } catch (e) {
                return null;
              }
            })
            .whereType<BackendLanguage>()
            .toList());
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFF0D0D12),
          padding: const EdgeInsets.all(16),
          width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity,
          child: BackendLanguagesWidget(
            languages: languages,
            accentColor: accentColor,
            transparency: transparency,
          ),
        );
      },
    );
  }
}

class _BackendToolsTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _BackendToolsTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final sections = (tile.metadata['sections'] as List<dynamic>?)
        ?.map((s) {
          try {
            return ToolSection(
              name: s['name'] as String? ?? '',
              icon: s['icon'] != null ? IconData(s['icon'] as int, fontFamily: 'CupertinoIcons') : CupertinoIcons.square_grid_2x2,
              tools: (s['tools'] as List<dynamic>?)
                  ?.map((t) {
                    try {
                      return BackendTool(
                        name: t['name'] as String? ?? '',
                        url: t['url'] as String? ?? '',
                        color: t['color'] != null ? Color(t['color'] as int) : accentColor,
                      );
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<BackendTool>()
                  .toList() ?? [],
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<ToolSection>()
        .toList() ?? [];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFF0D0D12),
          padding: const EdgeInsets.all(16),
          width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity,
          child: BackendToolsWidget(
            sections: sections,
            accentColor: accentColor,
            transparency: transparency,
          ),
        );
      },
    );
  }
}

class _SystemMetricsTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _SystemMetricsTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFF0D0D12),
          width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity,
          child: SystemMetricsWidget(
            accentColor: accentColor,
            transparency: transparency,
          ),
        );
      },
    );
  }
}

class _CommandPromptTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _CommandPromptTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFF0D0D12),
          padding: const EdgeInsets.all(16),
          width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity,
          child: CommandPromptWidget(
            accentColor: accentColor,
            transparency: transparency,
            greeting: tile.metadata['greeting'] as String?,
            subtitle: tile.metadata['subtitle'] as String? ?? tile.metadata['description'] as String?,
          ),
        );
      },
    );
  }
}

// === WIDGETS DEVOPS ===

class _ServiceStatusTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _ServiceStatusTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final services = (tile.metadata['services'] as List<dynamic>?)
        ?.map((s) {
          try {
            return ServiceStatus(
              name: s['name'] as String? ?? 'Unknown',
              status: s['status'] as String? ?? 'unknown',
              isHealthy: s['isHealthy'] as bool? ?? false,
              uptime: s['uptime'] as String? ?? 'N/A',
              latency: s['latency'] as int? ?? 0,
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<ServiceStatus>()
        .toList() ?? [];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFF0D0D12),
          width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity,
          child: ServiceStatusWidget(
            services: services,
            accentColor: accentColor,
            transparency: transparency,
          ),
        );
      },
    );
  }
}

class _InfrastructureMetricsTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _InfrastructureMetricsTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFF0D0D12),
          padding: const EdgeInsets.all(16),
          width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity,
          child: InfrastructureMetricsWidget(
            accentColor: accentColor,
            transparency: transparency,
          ),
        );
      },
    );
  }
}

class _DevOpsToolsTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _DevOpsToolsTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final categories = (tile.metadata['categories'] as List<dynamic>?)
        ?.map((c) {
          try {
            return DevOpsCategory(
              name: c['name'] as String? ?? '',
              emoji: c['emoji'] as String? ?? '🔧',
              tools: (c['tools'] as List<dynamic>?)
                  ?.map((t) {
                    try {
                      return DevOpsTool(
                        name: t['name'] as String? ?? '',
                        url: t['url'] as String? ?? '',
                        color: t['color'] != null ? Color(t['color'] as int) : accentColor,
                      );
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<DevOpsTool>()
                  .toList() ?? [],
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<DevOpsCategory>()
        .toList() ?? [];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFF0D0D12),
          padding: const EdgeInsets.all(16),
          width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity,
          child: DevOpsToolsWidget(
            categories: categories,
            accentColor: accentColor,
            transparency: transparency,
          ),
        );
      },
    );
  }
}

class _CommandCenterTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _CommandCenterTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFF0D0D12),
          padding: const EdgeInsets.all(16),
          width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
          height: constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity,
          child: CommandCenterWidget(
            accentColor: accentColor,
            transparency: transparency,
            greeting: tile.metadata['greeting'] as String?,
            subtitle: tile.metadata['subtitle'] as String? ?? tile.metadata['description'] as String?,
          ),
        );
      },
    );
  }
}

// === WIDGETS DATA SCIENCE ===

class _DataScienceLibrariesTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _DataScienceLibrariesTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final libraries = (tile.metadata['libraries'] as List<dynamic>?)
        ?.map((l) {
          try {
            return DataScienceLibrary(
              name: l['name'] as String? ?? '',
              emoji: l['emoji'] as String? ?? '📊',
              url: l['url'] as String? ?? '',
              color: l['color'] != null ? Color(l['color'] as int) : accentColor,
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<DataScienceLibrary>()
        .toList() ?? [
      DataScienceLibrary(name: 'Python', emoji: '🐍', url: 'https://python.org', color: const Color(0xFF3776AB)),
      DataScienceLibrary(name: 'NumPy', emoji: '🔢', url: 'https://numpy.org', color: const Color(0xFF4DABCF)),
      DataScienceLibrary(name: 'Pandas', emoji: '🐼', url: 'https://pandas.pydata.org', color: const Color(0xFF150458)),
      DataScienceLibrary(name: 'Scikit-learn', emoji: '🔬', url: 'https://scikit-learn.org', color: const Color(0xFFF7931E)),
      DataScienceLibrary(name: 'TensorFlow', emoji: '🧠', url: 'https://tensorflow.org', color: const Color(0xFFFF6F00)),
      DataScienceLibrary(name: 'PyTorch', emoji: '🔥', url: 'https://pytorch.org', color: const Color(0xFFEE4C2C)),
      DataScienceLibrary(name: 'Jupyter', emoji: '📓', url: 'https://jupyter.org', color: const Color(0xFFF37626)),
      DataScienceLibrary(name: 'Matplotlib', emoji: '📊', url: 'https://matplotlib.org', color: const Color(0xFF11557C)),
    ];
    
    return Container(
      color: const Color(0xFF0D0D12),
      padding: const EdgeInsets.all(16),
      child: DataScienceLibrariesWidget(
        libraries: libraries,
        accentColor: accentColor,
        transparency: transparency,
      ),
    );
  }
}

class _DataScienceToolsTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _DataScienceToolsTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final categories = (tile.metadata['categories'] as List<dynamic>?)
        ?.map((c) {
          try {
            return DataScienceCategory(
              name: c['name'] as String? ?? '',
              icon: c['icon'] != null ? IconData(c['icon'] as int, fontFamily: 'CupertinoIcons') : CupertinoIcons.square_grid_2x2,
              tools: (c['tools'] as List<dynamic>?)
                  ?.map((t) {
                    try {
                      return DataScienceTool(
                        name: t['name'] as String? ?? '',
                        url: t['url'] as String? ?? '',
                        color: t['color'] != null ? Color(t['color'] as int) : accentColor,
                      );
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<DataScienceTool>()
                  .toList() ?? [],
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<DataScienceCategory>()
        .toList() ?? [];
    
    return Container(
      color: const Color(0xFF0D0D12),
      padding: const EdgeInsets.all(16),
      child: DataScienceToolsWidget(
        categories: categories,
        accentColor: accentColor,
        transparency: transparency,
      ),
    );
  }
}

// === WIDGETS GÉNÉRIQUES ===

class _QuickLinksTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _QuickLinksTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final links = (tile.metadata['links'] as List<dynamic>?)
        ?.map((l) {
          try {
            return QuickLink(
              name: l['name'] as String? ?? '',
              url: l['url'] as String? ?? '',
              icon: l['icon'] != null ? IconData(l['icon'] as int, fontFamily: 'CupertinoIcons') : CupertinoIcons.link,
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<QuickLink>()
        .toList() ?? [
      QuickLink(name: 'Google', url: 'https://google.com', icon: CupertinoIcons.search),
      QuickLink(name: 'GitHub', url: 'https://github.com', icon: CupertinoIcons.chevron_left_slash_chevron_right),
      QuickLink(name: 'Gmail', url: 'https://mail.google.com', icon: CupertinoIcons.mail),
      QuickLink(name: 'Calendar', url: 'https://calendar.google.com', icon: CupertinoIcons.calendar),
    ];
    
    return Container(
      color: const Color(0xFF0D0D12),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: QuickLinksWidget(
          links: links,
          accentColor: accentColor,
          transparency: transparency,
        ),
      ),
    );
  }
}

class _SearchBarTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _SearchBarTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    return Container(
      color: const Color(0xFF0D0D12),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SearchBarWidget(
          accentColor: accentColor,
          transparency: transparency,
          hintText: tile.metadata['hintText'] as String?,
          maxWidth: tile.metadata['maxWidth'] as double?,
        ),
      ),
    );
  }
}

class _DeveloperQuotesTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _DeveloperQuotesTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;
    final transparency = tile.metadata['transparency'] as double? ?? 0.0;
    
    final quotes = (tile.metadata['quotes'] as List<dynamic>?)
        ?.map((q) => q as String)
        .toList();
    
    // Si pas de quotes personnalisées, utiliser les quotes par défaut
    final defaultQuotes = [
      "Design is not just what it looks like. Design is how it works. — Steve Jobs",
      "The details are not the details. They make the design. — Charles Eames",
      "Good design is obvious. Great design is transparent. — Joe Sparano",
      "Simplicity is the ultimate sophistication. — Leonardo da Vinci",
      "Any fool can write code that a computer can understand. Good programmers write code that humans can understand. — Martin Fowler",
      "First, solve the problem. Then, write the code. — John Johnson",
      "Talk is cheap. Show me the code. — Linus Torvalds",
      "The best error message is the one that never shows up. — Thomas Fuchs",
    ];
    
    return Container(
      color: const Color(0xFF0D0D12),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: DeveloperQuotesWidget(
          quotes: quotes ?? defaultQuotes,
          accentColor: accentColor,
          transparency: transparency,
        ),
      ),
    );
  }
}

class _TimeDisplayTileContent extends StatelessWidget {
  final MosaicTile tile;

  const _TimeDisplayTileContent({required this.tile});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final textColor = tile.metadata['textColor'] != null
        ? Color(tile.metadata['textColor'] as int)
        : null;
    final showSeconds = tile.metadata['showSeconds'] as bool? ?? true;
    final showDate = tile.metadata['showDate'] as bool? ?? false;
    final timezone = tile.metadata['timezone'] as String?;
    
    return Container(
      color: const Color(0xFF0D0D12),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: TimeDisplayWidget(
          textColor: textColor,
          showSeconds: showSeconds,
          showDate: showDate,
          timezone: timezone,
        ),
      ),
    );
  }
}
