import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../core/utils/url_validator.dart';
import '../../services/history_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/favicon_service.dart';
import '../../models/bookmark.dart';
import '../../models/tab_model.dart';

class ModernAddressBar extends StatefulWidget {
  const ModernAddressBar({super.key});

  @override
  State<ModernAddressBar> createState() => _ModernAddressBarState();
}

class _ModernAddressBarState extends State<ModernAddressBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
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

      // Historique
      await _historyService.addHistoryItem(formattedUrl, domain);

      // Favicon
      _loadFavicon(formattedUrl, activeTab.id, tabManager);

      final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
      final engine = webViewManager.getEngineForTab(activeTab.id);
      engine.navigate(formattedUrl);
    }
  }

  Future<void> _loadFavicon(
      String url, String tabId, TabManager tabManager) async {
    try {
      final faviconUrl = await FaviconService.getFaviconWithCache(url);
      if (faviconUrl != null && mounted) {
        tabManager.updateTab(tabId, favicon: faviconUrl);
      }
    } catch (_) {
      // Ignorer les erreurs de favicon
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<TabManager>(
      builder: (context, tabManager, _) {
        final activeTab = tabManager.activeTab;
        if (!_isFocused) {
          if (activeTab != null &&
              activeTab.url != null &&
              activeTab.url!.isNotEmpty &&
              activeTab.url != 'about:newtab' &&
              activeTab.url != 'about:blank') {
            _controller.text = activeTab.url!;
          } else {
            _controller.text = '';
          }
        }
        
        return Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Boutons de navigation
              Consumer<TabWebViewManager>(
                builder: (context, webViewManager, _) {
                  final engine = activeTab != null
                      ? webViewManager.getEngine(activeTab.id)
                      : null;
                  
                  return Row(
                    children: [
                      _NavigationButton(
                        icon: CupertinoIcons.arrow_left,
                        onPressed: engine != null
                            ? () async {
                                await engine.goBack();
                                final url = await engine.getCurrentUrl();
                                if (url != null && activeTab != null) {
                                  tabManager.updateTab(activeTab.id, url: url);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(width: 4),
                      _NavigationButton(
                        icon: CupertinoIcons.arrow_right,
                        onPressed: engine != null
                            ? () async {
                                await engine.goForward();
                                final url = await engine.getCurrentUrl();
                                if (url != null && activeTab != null) {
                                  tabManager.updateTab(activeTab.id, url: url);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(width: 4),
                      _NavigationButton(
                        icon: activeTab?.state == TabState.loading
                            ? CupertinoIcons.xmark
                            : CupertinoIcons.arrow_clockwise,
                        onPressed: engine != null
                            ? () async {
                                if (activeTab?.state == TabState.loading) {
                                  await engine.stop();
                                } else {
                                  await engine.reload();
                                }
                              }
                            : null,
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(width: 12),
              
              // Barre d'adresse
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isFocused
                        ? (isDark ? const Color(0xFF2C2C2E) : Colors.white)
                        : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03)),
                    borderRadius: BorderRadius.circular(8),
                    border: _isFocused
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          )
                        : Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                            width: 1,
                          ),
                  ),
                  child: Row(
                    children: [
                      // Icône de sécurité
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(
                          activeTab?.url?.startsWith('https') == true
                              ? CupertinoIcons.lock_fill
                              : CupertinoIcons.globe,
                          size: 14,
                          color: activeTab?.url?.startsWith('https') == true
                              ? const Color(0xFF34C759)
                              : theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                      ),
                      
                      // Champ de texte
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Rechercher ou saisir une adresse web',
                            hintStyle: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          onSubmitted: _navigateToUrl,
                        ),
                      ),
                      
                      // Actions
                      if (_isFocused)
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                size: 16,
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.3),
                              ),
                              onPressed: () {
                                _controller.clear();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        )
                      else
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.star,
                                size: 16,
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                              ),
                              onPressed: activeTab?.url != null
                                  ? () async {
                                      final bookmark = Bookmark(
                                        url: activeTab!.url!,
                                        title: activeTab.title ?? activeTab.url!,
                                        favicon: activeTab.favicon,
                                      );
                                      await _bookmarkService.addBookmark(bookmark);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Ajouté aux favoris'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Actions supplémentaires
              Row(
                children: [
                  _NavigationButton(
                    icon: CupertinoIcons.shield,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  _NavigationButton(
                    icon: CupertinoIcons.ellipsis_vertical,
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

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavigationButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return _HoverNavButton(
      icon: icon,
      onPressed: onPressed,
    );
  }
}

class _HoverNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _HoverNavButton({
    required this.icon,
    this.onPressed,
  });

  @override
  State<_HoverNavButton> createState() => _HoverNavButtonState();
}

class _HoverNavButtonState extends State<_HoverNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = _hovered && widget.onPressed != null
        ? (isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05))
        : Colors.transparent;

    final iconColor = widget.onPressed != null
        ? theme.iconTheme.color
        : theme.iconTheme.color?.withOpacity(0.3);

    return MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
