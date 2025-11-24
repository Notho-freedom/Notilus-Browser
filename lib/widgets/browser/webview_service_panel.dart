import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/services/wallpaper_manager.dart';
import 'web_content_view.dart';

class WebViewServicePanel extends StatefulWidget {
  final String url;
  final String title;
  final IconData icon;
  final Color color;

  const WebViewServicePanel({
    super.key,
    required this.url,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  State<WebViewServicePanel> createState() => _WebViewServicePanelState();
}

class _WebViewServicePanelState extends State<WebViewServicePanel> {
  String? _tabId;

  @override
  void initState() {
    super.initState();
    _createServiceTab();
  }

  void _createServiceTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabManager = Provider.of<TabManager>(context, listen: false);
      final tab = tabManager.addTab(url: widget.url);
      setState(() {
        _tabId = tab.id;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallpaperManager = context.watch<WallpaperManager>();

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: widget.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // WebView content
            Expanded(
              child: Consumer<TabManager>(
                builder: (context, tabManager, _) {
                  if (_tabId == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final tab = tabManager.tabs.firstWhere(
                    (t) => t.id == _tabId,
                    orElse: () => tabManager.tabs.first,
                  );
                  return WebContentView(tab: tab);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

