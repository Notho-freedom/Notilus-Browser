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
import '../browser/modern_bookmarks_panel.dart';
import '../browser/modern_history_panel.dart';
import '../browser/modern_downloads_panel.dart';
import '../browser/modern_settings_panel.dart';
import '../browser/webview_service_panel.dart';
import '../terminal/native_terminal_panel.dart';
import '../dev_tools/notilus_devtools.dart';
import '../documentation/documentation_panel.dart';

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
        return ModernBookmarksPanel();
      case MosaicTileType.history:
        return ModernHistoryPanel();
      case MosaicTileType.downloads:
        return ModernDownloadsPanel();
      case MosaicTileType.ai:
        return const _AITileContent();
      case MosaicTileType.settings:
        return ModernSettingsPanel();
      case MosaicTileType.webService:
        return _WebServiceTileContent(tile: tile);
      case MosaicTileType.documentation:
        return const DocumentationPanel();
      case MosaicTileType.empty:
        return _EmptyTileContent(tile: tile);
      case MosaicTileType.custom:
        return const _CustomTileContent();
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                CupertinoIcons.plus,
                size: 32,
                color: accentColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Panneau vide',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Glissez un élément ou cliquez sur ⋯',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms);
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
