import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/history_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/favicon_service.dart';
import '../../models/tab_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/url_validator.dart';
import '../../core/utils/theme_extensions.dart';
import '../../widgets/common/glassmorphic_container.dart';
import '../../widgets/common/neon_button.dart';
import 'address_suggestions.dart';

class AddressBar extends StatefulWidget {
  final VoidCallback? onDevToolsToggle;
  final VoidCallback? onSplitScreenToggle;
  final VoidCallback? onGroupsToggle;
  final VoidCallback? onExtensionsToggle;
  final bool isDevToolsVisible;
  final bool isSplitScreenMode;
  final bool isGroupsVisible;
  final bool isExtensionsVisible;

  const AddressBar({
    super.key,
    this.onDevToolsToggle,
    this.onSplitScreenToggle,
    this.onGroupsToggle,
    this.onExtensionsToggle,
    this.isDevToolsVisible = false,
    this.isSplitScreenMode = false,
    this.isGroupsVisible = false,
    this.isExtensionsVisible = false,
  });

  @override
  State<AddressBar> createState() => AddressBarState();
}

class AddressBarState extends State<AddressBar> {

  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _showSuggestions = false;
  final HistoryService _historyService = HistoryService();
  final BookmarkService _bookmarkService = BookmarkService();

  void focus() {
    _focusNode.requestFocus();
  }

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
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateToUrl(String url) async {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final activeTab = tabManager.activeTab;
    
    if (activeTab != null) {
      setState(() {
        _showSuggestions = false;
      });
      
      // Valider et formater l'URL
      String? formattedUrl = UrlValidator.validateAndFormat(url);
      
      // Si ce n'est pas une URL valide, créer une URL de recherche
      if (formattedUrl == null) {
        formattedUrl = UrlValidator.createSearchUrl(url);
      }
      
      final domain = UrlValidator.extractDomain(formattedUrl) ?? formattedUrl;
      
      // Mettre à jour l'onglet
      tabManager.updateTab(
        activeTab.id,
        url: formattedUrl,
        title: domain,
        state: TabState.loading,
      );
      
      // Ajouter à l'historique
      await _historyService.addHistoryItem(formattedUrl, domain);
      
      // Récupérer le favicon
      _loadFavicon(formattedUrl, activeTab.id, tabManager);
      
      // Simuler le chargement (sera remplacé par CEF)
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && activeTab.id == tabManager.activeTab?.id) {
          tabManager.updateTab(
            activeTab.id,
            state: TabState.loaded,
            title: domain,
          );
        }
      });
    }
  }

  Future<List<SuggestionItem>> _getSuggestions(String query) async {
    final suggestions = <SuggestionItem>[];
    
    // Search history
    final history = await _historyService.searchHistory(query);
    for (var item in history.take(5)) {
      suggestions.add(SuggestionItem(
        title: item.title,
        subtitle: item.url,
        url: item.url,
        icon: Icons.history,
        type: SuggestionType.history,
      ));
    }
    
    // Search bookmarks
    final bookmarks = await _bookmarkService.searchBookmarks(query);
    for (var bookmark in bookmarks.take(5)) {
      suggestions.add(SuggestionItem(
        title: bookmark.title,
        subtitle: bookmark.url,
        url: bookmark.url,
        icon: Icons.bookmark,
        type: SuggestionType.bookmark,
      ));
    }
    
    // Add search suggestion if query doesn't look like URL
    if (!UrlValidator.isUrl(query) && query.isNotEmpty) {
      suggestions.add(SuggestionItem(
        title: 'Rechercher "$query"',
        subtitle: 'Google Search',
        url: UrlValidator.createSearchUrl(query),
        icon: Icons.search,
        type: SuggestionType.search,
      ));
    }
    
    return suggestions;
  }

  Future<void> _loadFavicon(String url, String tabId, TabManager tabManager) async {
    try {
      final faviconUrl = await FaviconService.getFaviconWithCache(url);
      if (faviconUrl != null && mounted) {
        tabManager.updateTab(tabId, favicon: faviconUrl);
      }
    } catch (e) {
      // Ignore favicon errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TabManager>(
      builder: (context, tabManager, _) {
        final activeTab = tabManager.activeTab;
        if (activeTab != null && _urlController.text != activeTab.url) {
          _urlController.text = activeTab.url ?? '';
        }

        return Container(
          height: AppConstants.addressBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: context.borderColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Navigation buttons
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () {},
                tooltip: 'Retour',
                color: theme.colorScheme.primary,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 20),
                onPressed: () {},
                tooltip: 'Avant',
                color: theme.colorScheme.primary,
              ),
              IconButton(
                icon: Icon(
                  activeTab?.state == TabState.loading
                      ? Icons.stop
                      : Icons.refresh,
                  size: 20,
                ),
                onPressed: () {},
                tooltip: activeTab?.state == TabState.loading
                    ? 'Arrêter'
                    : 'Recharger',
                color: theme.colorScheme.primary,
              ),
              
              const SizedBox(width: 8),
              
              // Address input
              Expanded(
                child: Stack(
                  children: [
                    GlassmorphicContainer(
                      showNeonBorder: _isFocused,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(24),
                      child: TextField(
                        controller: _urlController,
                        focusNode: _focusNode,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Roboto Mono',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher ou entrer une URL',
                          hintStyle: theme.textTheme.bodySmall,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          prefixIcon: activeTab?.favicon != null
                              ? Image.network(
                                  activeTab!.favicon!,
                                  width: 16,
                                  height: 16,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.language,
                                    size: 16,
                                  ),
                                )
                              : Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                        ),
                        onSubmitted: _navigateToUrl,
                        onChanged: (value) {
                          if (value.isNotEmpty && _isFocused) {
                            setState(() {
                              _showSuggestions = true;
                            });
                          } else {
                            setState(() {
                              _showSuggestions = false;
                            });
                          }
                        },
                        onTap: () {
                          setState(() {
                            if (_urlController.text.isNotEmpty) {
                              _showSuggestions = true;
                            }
                          });
                        },
                      ),
                    ),
                    // Suggestions dropdown
                    if (_showSuggestions && _urlController.text.isNotEmpty)
                      Positioned(
                        top: 48,
                        left: 0,
                        right: 0,
                        child: FutureBuilder<List<SuggestionItem>>(
                          future: _getSuggestions(_urlController.text),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              return AddressSuggestions(
                                items: snapshot.data!,
                                onSelect: (item) {
                                  _urlController.text = item.url;
                                  _navigateToUrl(item.url);
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Groups toggle
              NeonButton(
                text: 'Groupes',
                variant: widget.isGroupsVisible
                    ? NeonButtonVariant.primary
                    : NeonButtonVariant.secondary,
                icon: Icons.folder,
                onPressed: widget.onGroupsToggle,
                height: 32,
              ),
              
              const SizedBox(width: 4),
              
              // Extensions toggle
              NeonButton(
                text: 'Ext',
                variant: widget.isExtensionsVisible
                    ? NeonButtonVariant.primary
                    : NeonButtonVariant.secondary,
                icon: Icons.extension,
                onPressed: widget.onExtensionsToggle,
                height: 32,
              ),
              
              const SizedBox(width: 4),
              
              // SplitScreen toggle
              NeonButton(
                text: 'Split',
                variant: widget.isSplitScreenMode
                    ? NeonButtonVariant.primary
                    : NeonButtonVariant.secondary,
                icon: Icons.splitscreen,
                onPressed: widget.onSplitScreenToggle,
                height: 32,
              ),
              
              const SizedBox(width: 4),
              
              // DevTools toggle
              NeonButton(
                text: 'DevTools',
                variant: widget.isDevToolsVisible
                    ? NeonButtonVariant.primary
                    : NeonButtonVariant.accent,
                icon: Icons.code,
                onPressed: widget.onDevToolsToggle,
                height: 32,
              ),
              
              const SizedBox(width: 4),
              
              // Security indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.successColor,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.lock,
                  size: 16,
                  color: context.successColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

