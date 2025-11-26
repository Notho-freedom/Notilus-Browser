import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../core/utils/url_validator.dart';
import '../../services/history_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/favicon_service.dart';
import '../../models/bookmark.dart';
import '../../models/tab_model.dart';
import '../common/notilus_tooltip.dart';

// La couleur rouge est maintenant gérée par ColorThemeManager

class GXAddressBar extends StatefulWidget {
  final VoidCallback? onAccountPressed;
  final VoidCallback? onWidgetsPressed;
  final VoidCallback? onDownloadsPressed;
  final VoidCallback? onMoreToolsPressed;
  
  const GXAddressBar({
    super.key,
    this.onAccountPressed,
    this.onWidgetsPressed,
    this.onDownloadsPressed,
    this.onMoreToolsPressed,
  });

  @override
  State<GXAddressBar> createState() => _GXAddressBarState();
}

class _GXAddressBarState extends State<GXAddressBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isSecure = false;
  final HistoryService _historyService = HistoryService();
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _navigateToUrl(String url) async {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final activeTab = tabManager.activeTab;
    
    if (activeTab != null) {
      String? formattedUrl = UrlValidator.validateAndFormat(url);
      
      if (formattedUrl == null) {
        formattedUrl = UrlValidator.createSearchUrl(url);
      }
      
      final domain = UrlValidator.extractDomain(formattedUrl) ?? formattedUrl;

      tabManager.updateTab(
        activeTab.id,
        url: formattedUrl,
        title: domain,
        state: TabState.loading,
      );

      await _historyService.addHistoryItem(formattedUrl, domain);
      _loadFavicon(formattedUrl, activeTab.id, tabManager);

      final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
      final engine = webViewManager.getEngineForTab(activeTab.id);
      engine.navigate(formattedUrl);
    }
  }

  Future<void> _loadFavicon(String url, String tabId, TabManager tabManager) async {
    try {
      final faviconUrl = await FaviconService.getFaviconWithCache(url);
      if (faviconUrl != null && mounted) {
        tabManager.updateTab(tabId, favicon: faviconUrl);
      }
    } catch (_) {}
  }

  void _showAccountDialog(BuildContext context, Color accentColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.person_fill, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compte Notilus',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Non connecté',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAccountOption(CupertinoIcons.cloud_upload, 'Synchroniser les données', accentColor, () {}),
            _buildAccountOption(CupertinoIcons.bookmark_fill, 'Favoris synchronisés', accentColor, () {}),
            _buildAccountOption(CupertinoIcons.clock_fill, 'Historique synchronisé', accentColor, () {}),
            _buildAccountOption(CupertinoIcons.gear, 'Paramètres du compte', accentColor, () {}),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: accentColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Connexion au compte Notilus à venir'),
                  backgroundColor: accentColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  void _showMoreToolsMenu(BuildContext context, Color accentColor) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(
      Offset(button.size.width - 200, button.size.height),
      ancestor: overlay,
    );

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx - 200,
        overlay.size.height - position.dy,
      ),
      color: const Color(0xFF1A1A20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: <PopupMenuEntry<void>>[
        _buildMenuItem(CupertinoIcons.camera, 'Capturer la page', accentColor, () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Capture d\'écran à venir'), backgroundColor: accentColor),
          );
        }),
        _buildMenuItem(CupertinoIcons.printer, 'Imprimer', accentColor, () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Impression à venir'), backgroundColor: accentColor),
          );
        }),
        _buildMenuItem(CupertinoIcons.share, 'Partager', accentColor, () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Partage à venir'), backgroundColor: accentColor),
          );
        }),
        _buildMenuItem(CupertinoIcons.doc_on_clipboard, 'Copier l\'URL', accentColor, () async {
          Navigator.pop(context);
          final tabManager = Provider.of<TabManager>(context, listen: false);
          final url = tabManager.activeTab?.url;
          if (url != null && url.isNotEmpty) {
            await Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('URL copiée'), backgroundColor: accentColor),
            );
          }
        }),
        const PopupMenuDivider(),
        _buildMenuItem(CupertinoIcons.textformat, 'Mode lecture', accentColor, () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Mode lecture à venir'), backgroundColor: accentColor),
          );
        }),
        _buildMenuItem(CupertinoIcons.moon, 'Mode sombre forcé', accentColor, () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Mode sombre forcé à venir'), backgroundColor: accentColor),
          );
        }),
        const PopupMenuDivider(),
        _buildMenuItem(CupertinoIcons.ant, 'DevTools (F12)', accentColor, () {
          Navigator.pop(context);
          // Simuler la touche F12
          final tabManager = Provider.of<TabManager>(context, listen: false);
          final activeTab = tabManager.activeTab;
          if (activeTab != null) {
            final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
            final engine = webViewManager.getEngineForTab(activeTab.id);
            engine.openDevTools();
          }
        }),
        _buildMenuItem(CupertinoIcons.doc_text, 'Code source', accentColor, () {
          Navigator.pop(context);
          final tabManager = Provider.of<TabManager>(context, listen: false);
          final url = tabManager.activeTab?.url;
          if (url != null && url.isNotEmpty && !url.startsWith('view-source:')) {
            tabManager.addTab(url: 'view-source:$url');
          }
        }),
      ],
    );
  }

  PopupMenuItem<void> _buildMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return PopupMenuItem<void>(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TabManager>(
      builder: (context, tabManager, _) {
        final activeTab = tabManager.activeTab;
        
        // Update controller text with current URL
        if (!_isFocused) {
          if (activeTab != null &&
              activeTab.url != null &&
              activeTab.url!.isNotEmpty &&
              activeTab.url != 'about:newtab' &&
              activeTab.url != 'about:blank') {
            _controller.text = activeTab.url!;
            _isSecure = activeTab.url!.startsWith('https://');
          } else {
            _controller.clear();
            _isSecure = false;
          }
        }

        final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
        final gxRed = colorThemeManager.nativeSecondaryColor;
        return Container(
          height: 34,
          color: colorThemeManager.nativeBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Navigation buttons
              Row(
                children: [
                  _GXNavButton(
                    icon: CupertinoIcons.left_chevron,
                    size: 16,
                    tooltip: 'Retour',
                    onPressed: activeTab != null ? () {
                      final engine = Provider.of<TabWebViewManager>(context, listen: false)
                          .getEngineForTab(activeTab.id);
                      engine.goBack();
                    } : null,
                  ),
                  const SizedBox(width: 2),
                  _GXNavButton(
                    icon: CupertinoIcons.right_chevron,
                    size: 16,
                    tooltip: 'Avancer',
                    onPressed: activeTab != null ? () {
                      final engine = Provider.of<TabWebViewManager>(context, listen: false)
                          .getEngineForTab(activeTab.id);
                      engine.goForward();
                    } : null,
                  ),
                  const SizedBox(width: 2),
                  _GXNavButton(
                    icon: activeTab?.state == TabState.loading 
                        ? CupertinoIcons.xmark
                        : CupertinoIcons.arrow_clockwise,
                    size: 16,
                    tooltip: activeTab?.state == TabState.loading ? 'Arrêter' : 'Actualiser',
                    onPressed: activeTab != null ? () {
                      final engine = Provider.of<TabWebViewManager>(context, listen: false)
                          .getEngineForTab(activeTab.id);
                      if (activeTab.state == TabState.loading) {
                        engine.stop();
                      } else {
                        engine.reload();
                      }
                    } : null,
                  ),
                  const SizedBox(width: 2),
                  _GXNavButton(
                    icon: CupertinoIcons.house,
                    size: 16,
                    tooltip: 'Nouvel onglet d\'accueil',
                    onPressed: () {
                      tabManager.addTab(url: 'about:newtab');
                    },
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              
              // Address field - Style GX avec bordure dégradée
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        gxRed.withValues(alpha: 0.9),
                        gxRed.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(1.2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      color: colorThemeManager.nativeBackgroundColor.withValues(alpha: 0.88),
                    ),
                    child: Row(
                      children: [
                        // Security/Search icon
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Icon(
                              _controller.text.isEmpty || _isFocused
                                  ? CupertinoIcons.search
                                  : (_isSecure ? CupertinoIcons.lock : CupertinoIcons.info),
                              size: 16,
                              color: gxRed,
                            ),
                          ),
                        ),

                        // URL field
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            cursorColor: gxRed,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter search or web address',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha:0.35),
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                              fillColor: Colors.transparent,
                              filled: true,
                            ),
                            onSubmitted: _navigateToUrl,
                          ),
                        ),

                        // Bookmark button
                        _GXActionButton(
                          icon: CupertinoIcons.bookmark,
                          tooltip: 'Ajouter aux favoris',
                          onPressed: activeTab?.url != null &&
                                  activeTab!.url!.isNotEmpty &&
                                  !activeTab.url!.startsWith('about:')
                              ? () async {
                                  final bookmark = Bookmark(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    title: activeTab.title ?? 'Sans titre',
                                    url: activeTab.url!,
                                    favicon: activeTab.favicon,
                                    createdAt: DateTime.now(),
                                  );
                                  await _bookmarkService.addBookmark(bookmark);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ajouté aux favoris'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              : null,
                        ),

                        const SizedBox(width: 4),
                        NotilusTooltip(
                          message: 'Lancer la navigation',
                          child: Container(
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: gxRed.withValues(alpha:0.15),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minHeight: 26, minWidth: 26),
                              icon: Icon(
                                CupertinoIcons.arrow_right,
                                size: 16,
                                color: gxRed,
                              ),
                              onPressed: () => _navigateToUrl(_controller.text),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Right side buttons
              Row(
                children: [
                  _GXActionButton(
                    icon: CupertinoIcons.person_crop_circle,
                    tooltip: 'Compte Notilus',
                    onPressed: widget.onAccountPressed ?? () => _showAccountDialog(context, gxRed),
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: CupertinoIcons.layers_alt,
                    tooltip: 'Panneau widgets',
                    onPressed: widget.onWidgetsPressed,
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: CupertinoIcons.tray_arrow_down,
                    tooltip: 'Téléchargements',
                    onPressed: widget.onDownloadsPressed,
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: CupertinoIcons.ellipsis_vertical,
                    tooltip: 'Plus d\'outils',
                    onPressed: widget.onMoreToolsPressed ?? () => _showMoreToolsMenu(context, gxRed),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GXNavButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback? onPressed;

  const _GXNavButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    this.onPressed,
  });

  @override
  State<_GXNavButton> createState() => _GXNavButtonState();
}

class _GXNavButtonState extends State<_GXNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final isEnabled = widget.onPressed != null;
    
    final button = GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: _isHovered && isEnabled
              ? gxRed.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          widget.icon,
          size: widget.size,
          color: isEnabled
              ? (_isHovered ? gxRed : gxRed.withValues(alpha: 0.8))
              : gxRed.withValues(alpha: 0.3),
        ),
      ),
    );

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: NotilusTooltip(
        message: widget.tooltip,
        child: button,
      ),
    );
  }
}

class _GXActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _GXActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  State<_GXActionButton> createState() => _GXActionButtonState();
}

class _GXActionButtonState extends State<_GXActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final isEnabled = widget.onPressed != null;
    
    final button = GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 28,
        height: 26,
        decoration: BoxDecoration(
          color: _isHovered && isEnabled
              ? gxRed.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          widget.icon,
          size: 18,
          color: isEnabled
              ? (_isHovered ? gxRed : gxRed.withValues(alpha: 0.8))
              : gxRed.withValues(alpha: 0.3),
        ),
      ),
    );

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: NotilusTooltip(
        message: widget.tooltip,
        child: button,
      ),
    );
  }
}
