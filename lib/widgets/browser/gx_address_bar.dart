import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../core/utils/url_validator.dart';
import '../../services/history_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/favicon_service.dart';
import '../../models/bookmark.dart';
import '../../models/tab_model.dart';
import '../common/notilus_tooltip.dart';

const Color _gxRed = NotilusColors.neonRed;
const Color _chromeColor = NotilusColors.chrome;

class GXAddressBar extends StatefulWidget {
  const GXAddressBar({super.key});

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

        return Container(
          height: 34,
          color: _chromeColor,
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
                        const Color(0xFFFF2D55).withOpacity(0.9),
                        const Color(0x00FF2D55),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(1.2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      color: _chromeColor.withOpacity(0.88),
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
                              color: _gxRed,
                            ),
                          ),
                        ),

                        // URL field
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            cursorColor: _gxRed,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter search or web address',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
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
                              color: _gxRed.withOpacity(0.15),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minHeight: 26, minWidth: 26),
                              icon: Icon(
                                CupertinoIcons.arrow_right,
                                size: 16,
                                color: _gxRed,
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
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: CupertinoIcons.layers_alt,
                    tooltip: 'Panneau widgets',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: CupertinoIcons.tray_arrow_down,
                    tooltip: 'Téléchargements',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: CupertinoIcons.ellipsis_vertical,
                    tooltip: 'Plus d’outils',
                    onPressed: () {},
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
    final isEnabled = widget.onPressed != null;
    
    final button = GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: _isHovered && isEnabled
              ? _gxRed.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          widget.icon,
          size: widget.size,
          color: isEnabled
              ? (_isHovered ? _gxRed : _gxRed.withOpacity(0.8))
              : _gxRed.withOpacity(0.3),
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
    final isEnabled = widget.onPressed != null;
    
    final button = GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 28,
        height: 26,
        decoration: BoxDecoration(
          color: _isHovered && isEnabled
              ? _gxRed.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          widget.icon,
          size: 18,
          color: isEnabled
              ? (_isHovered ? _gxRed : _gxRed.withOpacity(0.8))
              : _gxRed.withOpacity(0.3),
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
