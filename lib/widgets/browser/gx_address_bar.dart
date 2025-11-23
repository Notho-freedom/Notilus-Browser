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
          color: const Color(0xFF25252A),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Navigation buttons
              Row(
                children: [
                  _GXNavButton(
                    icon: Icons.arrow_back_ios_new,
                    size: 14,
                    onPressed: activeTab != null ? () {
                      final engine = Provider.of<TabWebViewManager>(context, listen: false)
                          .getEngineForTab(activeTab.id);
                      engine.goBack();
                    } : null,
                  ),
                  const SizedBox(width: 2),
                  _GXNavButton(
                    icon: Icons.arrow_forward_ios,
                    size: 14,
                    onPressed: activeTab != null ? () {
                      final engine = Provider.of<TabWebViewManager>(context, listen: false)
                          .getEngineForTab(activeTab.id);
                      engine.goForward();
                    } : null,
                  ),
                  const SizedBox(width: 2),
                  _GXNavButton(
                    icon: activeTab?.state == TabState.loading 
                        ? Icons.close 
                        : Icons.refresh,
                    size: 16,
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
                ],
              ),
              
              const SizedBox(width: 8),
              
              // Address field - Style GX avec bordure dégradée
              Expanded(
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
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
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: const Color(0xCC16161C),
                    ),
                    child: Row(
                      children: [
                        // Security/Search icon
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Icon(
                              _controller.text.isEmpty || _isFocused
                                  ? Icons.search
                                  : (_isSecure ? Icons.lock : Icons.info_outline),
                              size: 14,
                              color: _isSecure
                                  ? const Color(0xFF4CAF50)
                                  : Colors.white.withOpacity(0.45),
                            ),
                          ),
                        ),

                        // URL field
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            cursorColor: const Color(0xFFFF2D55),
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
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            onSubmitted: _navigateToUrl,
                          ),
                        ),

                        // Bookmark button
                        _GXActionButton(
                          icon: Icons.bookmark_outline,
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

                        const SizedBox(width: 8),
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
                    icon: Icons.account_circle_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: Icons.extension_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: Icons.download_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: Icons.more_vert,
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
  final VoidCallback? onPressed;

  const _GXNavButton({
    required this.icon,
    required this.size,
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
    
    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _isHovered && isEnabled
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: isEnabled
                ? (_isHovered 
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white.withOpacity(0.6))
                : Colors.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}

class _GXActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _GXActionButton({
    required this.icon,
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
    
    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 28,
          height: 26,
          decoration: BoxDecoration(
            color: _isHovered && isEnabled
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: isEnabled
                ? (_isHovered 
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white.withOpacity(0.5))
                : Colors.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}
