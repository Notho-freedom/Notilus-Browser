import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/webview2_browser_engine.dart';
import '../../core/utils/url_validator.dart';
import '../../services/history_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/favicon_service.dart';
import '../../models/bookmark.dart';
import '../../models/tab_model.dart';
import '../common/notilus_tooltip.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../services/adblocker_service.dart';
import '../../services/settings_service.dart';
import '../../core/animations/notilus_animations.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/gx_notification_service.dart';
import 'address_suggestions.dart';
import 'gx_address_suggestions.dart';
import 'gx_futuristic_more_menu.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';

// La couleur rouge est maintenant gérée par ColorThemeManager

class GXAddressBar extends StatefulWidget {
  final VoidCallback? onAccountPressed;
  final VoidCallback? onWidgetsPressed;
  final VoidCallback? onDownloadsPressed;
  final VoidCallback? onMoreToolsPressed;
  final VoidCallback? onMiniDevToolsToggle;
  final bool isMiniDevToolsVisible;
  
  const GXAddressBar({
    super.key,
    this.onAccountPressed,
    this.onWidgetsPressed,
    this.onDownloadsPressed,
    this.onMoreToolsPressed,
    this.onMiniDevToolsToggle,
    this.isMiniDevToolsVisible = false,
  });

  @override
  State<GXAddressBar> createState() => _GXAddressBarState();
}

class _GXAddressBarState extends State<GXAddressBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final LayerLink _moreMenuLayerLink = LayerLink();
  final GlobalKey _inputAreaKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _moreMenuOverlayEntry;
  bool _isFirstOverlayShow = true; // Pour éviter les animations à chaque ouverture
  bool _isFocused = false;
  bool _isSecure = false;
  bool _showSuggestions = false;
  bool _isSelectingItem = false; // Flag pour empêcher la fermeture pendant la sélection
  bool _isMoreMenuOpen = false;
  final HistoryService _historyService = HistoryService();
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      
      // Sélectionner automatiquement le texte au focus
      if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
      
      // Afficher/masquer les suggestions
      if (_focusNode.hasFocus) {
        _showSuggestionsOverlay();
      } else {
        // Ne pas fermer si on est en train de sélectionner un item
        if (!_isSelectingItem) {
          // Ne pas fermer immédiatement pour permettre le clic sur les items
          Future.delayed(const Duration(milliseconds: 200), () {
            if (!_focusNode.hasFocus && !_isSelectingItem && mounted) {
              _hideSuggestionsOverlay();
            }
          });
        }
      }
    });
    
    _controller.addListener(() {
      if (_isFocused) {
        _updateSuggestionsOverlay();
      }
    });
  }
  
  void _showSuggestionsOverlay() {
    if (_overlayEntry != null || !mounted) return;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context, rootOverlay: false).insert(_overlayEntry!);
    // Après la première ouverture, désactiver les animations
    if (_isFirstOverlayShow) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isFirstOverlayShow = false;
          });
        }
      });
    }
  }
  
  void _hideSuggestionsOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    // Ne pas appeler setState() si le widget est en train d'être démonté
    if (mounted) {
      setState(() {
        _showSuggestions = false;
      });
    } else {
      // Si le widget n'est plus monté, juste mettre à jour la variable
      _showSuggestions = false;
    }
  }
  
  void _updateSuggestionsOverlay() {
    if (!_isFocused || !mounted) {
      _hideSuggestionsOverlay();
      return;
    }
    
    if (_overlayEntry == null) {
      _showSuggestionsOverlay();
    } else {
      // Utiliser un microtask pour éviter les reconstructions pendant le build
      Future.microtask(() {
        if (mounted && _overlayEntry != null) {
          _overlayEntry!.markNeedsBuild();
        }
      });
    }
  }
  
  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      maintainState: true, // Maintenir l'état pour éviter les reconstructions
      builder: (overlayContext) {
        if (!mounted) return const SizedBox.shrink();
        
        final colorThemeManager = Provider.of<ColorThemeManager>(overlayContext, listen: false);
        final gxRed = colorThemeManager.nativeSecondaryColor;
        final query = _controller.text;
        
        return RepaintBoundary(
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 6), // Légèrement en dessous de la barre d'adresse
            followerAnchor: Alignment.topCenter,
            targetAnchor: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Utiliser 100% de la largeur de l'écran - Style Notilus GX Futurist
                  final screenWidth = MediaQuery.of(context).size.width;
                  final overlayWidth = screenWidth * 0.8;
                  
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: overlayWidth,
                        maxHeight: 300, // Limiter la hauteur pour éviter qu'il prenne tout l'écran
                        minHeight: 0, // Permettre à l'overlay de se réduire
                      ),
                      child: FutureBuilder<List<SuggestionItem>>(
                        future: _getSuggestions(query),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildLoadingState(gxRed, colorThemeManager);
                          }
                          
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final suggestionsWidget = GXAddressSuggestions(
                              key: ValueKey(query), // Clé pour forcer la reconstruction seulement si query change
                              items: snapshot.data!,
                              onSelect: (item) {
                                // Marquer qu'on est en train de sélectionner
                                _isSelectingItem = true;
                                // Fermer l'overlay d'abord pour éviter les conflits
                                _hideSuggestionsOverlay();
                                // Mettre à jour le texte et naviguer
                                _controller.text = item.url;
                                _navigateToUrl(item.url);
                                // Réinitialiser le flag après un court délai
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    _isSelectingItem = false;
                                  }
                                });
                              },
                            );
                            
                            // Animer seulement à la première ouverture
                            if (_isFirstOverlayShow) {
                              return FadeInWidget(
                                duration: NotilusAnimations.normal,
                                slideOffset: const Offset(0, -10),
                                child: suggestionsWidget,
                              );
                            }
                            
                            // Sinon, afficher directement sans animation
                            return suggestionsWidget;
                          }
                          
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLoadingState(Color gxRed, ColorThemeManager themeManager) {
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: panelOpacity.clamp(0.0, 1.0)),
            border: Border.all(
              color: gxRed.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: gxRed,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void _showMoreToolsMenu() {
    if (_moreMenuOverlayEntry != null || !mounted) return;
    
    setState(() {
      _isMoreMenuOpen = true;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
      final accentColor = colorThemeManager.nativeSecondaryColor;
      
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) {
        setState(() {
          _isMoreMenuOpen = false;
        });
        return;
      }
      
      _moreMenuOverlayEntry = OverlayEntry(
        builder: (overlayContext) => GXFuturisticMoreMenu(
          accentColor: accentColor,
          onClose: _hideMoreToolsMenu,
          layerLink: _moreMenuLayerLink,
          onMiniDevToolsToggle: widget.onMiniDevToolsToggle,
          isMiniDevToolsVisible: widget.isMiniDevToolsVisible,
        ),
      );
      
      overlay.insert(_moreMenuOverlayEntry!);
    });
  }
  
  void _hideMoreToolsMenu() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    setState(() {
      _isMoreMenuOpen = false;
    });
  }
  
  void _toggleMoreMenu() {
    if (_isMoreMenuOpen) {
      _hideMoreToolsMenu();
    } else {
      _showMoreToolsMenu();
    }
  }
  
  @override
  void dispose() {
    _hideSuggestionsOverlay();
    _hideMoreToolsMenu();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _navigateToUrl(String url) async {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final activeTab = tabManager.activeTab;
    
    if (activeTab != null) {
      setState(() {
        _showSuggestions = false;
      });
      
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

      // Ne pas sauvegarder l'historique pour les onglets privés
      if (!activeTab.isPrivate) {
        await _historyService.addHistoryItem(formattedUrl, domain);
      }
      _loadFavicon(formattedUrl, activeTab.id, tabManager);

      final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
      final engine = webViewManager.getEngineForTab(activeTab.id);
      engine.navigate(formattedUrl);
    }
  }

  Future<List<SuggestionItem>> _getSuggestions(String query) async {
    final suggestions = <SuggestionItem>[];
    
    if (query.isEmpty) {
      // Afficher l'historique récent si la query est vide
      final history = await _historyService.getHistory();
      for (var item in history.take(8)) {
        suggestions.add(SuggestionItem(
          title: item.title,
          subtitle: item.url,
          url: item.url,
          icon: Icons.history,
          type: SuggestionType.history,
        ));
      }
      return suggestions;
    }
    
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
    } catch (_) {}
  }

  void _showAccountDialog(BuildContext context, Color accentColor) {
    GxFuturisticDialog.show(
      context: context,
      title: 'Compte Notilus',
      titleIcon: CupertinoIcons.person_fill,
      accentColor: accentColor,
      width: 450,
      child: Builder(
        builder: (dialogContext) {
          final authService = Provider.of<FirebaseAuthService?>(dialogContext, listen: true);
          final isSignedIn = authService?.isSignedIn ?? false;
          final user = authService?.currentUser;
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec avatar
              Row(
                children: [
                  isSignedIn && user?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          user!.photoURL!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
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
                        ),
                      )
                    : Container(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSignedIn ? (user?.displayName ?? user?.email ?? 'Compte Notilus') : 'Compte Notilus',
                          style: NotilusFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSignedIn ? 'Connecté' : 'Non connecté',
                          style: NotilusFonts.rajdhani(
                            fontSize: 12,
                            color: isSignedIn ? accentColor : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Options
              _buildAccountOption(CupertinoIcons.cloud_upload, 'Synchroniser les données', accentColor, () {}),
              _buildAccountOption(CupertinoIcons.bookmark_fill, 'Favoris synchronisés', accentColor, () {}),
              _buildAccountOption(CupertinoIcons.clock_fill, 'Historique synchronisé', accentColor, () {}),
              _buildAccountOption(CupertinoIcons.gear, 'Paramètres du compte', accentColor, () {}),
            ],
          );
        },
      ),
      actions: [
        Builder(
          builder: (dialogContext) {
            final authService = Provider.of<FirebaseAuthService?>(dialogContext, listen: false);
            final isSignedIn = authService?.isSignedIn ?? false;
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GxFuturisticButton(
                  label: 'Fermer',
                  variant: GxFuturisticButtonVariant.secondary,
                  accentColor: accentColor,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                const SizedBox(width: 8),
                if (!isSignedIn)
                  GxFuturisticButton(
                    label: 'Se connecter',
                    icon: CupertinoIcons.person_fill,
                    variant: GxFuturisticButtonVariant.primary,
                    accentColor: accentColor,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      showDialog(
                        context: context,
                        builder: (ctx) => AuthDialog(authService: authService!),
                      );
                    },
                  )
                else
                  GxFuturisticButton(
                    label: 'Se déconnecter',
                    icon: CupertinoIcons.power,
                    variant: GxFuturisticButtonVariant.primary,
                    accentColor: Colors.red,
                    onPressed: () async {
                      await authService?.signOut();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: const Text('Déconnexion réussie'),
                            backgroundColor: accentColor,
                          ),
                        );
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ],
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
                  Consumer<TabWebViewManager>(
                    builder: (context, webViewManager, _) {
                      // Obtenir l'état réel du WebView (plus précis)
                      bool isLoading = false;
                      if (activeTab != null) {
                        final engine = webViewManager.getEngine(activeTab.id);
                        if (engine is WebView2BrowserEngine) {
                          isLoading = engine.isLoading;
                        } else {
                          // Fallback sur TabState si l'engine n'est pas WebView2
                          isLoading = activeTab.state == TabState.loading;
                        }
                      }
                      
                      return _GXNavButton(
                        icon: isLoading 
                            ? CupertinoIcons.xmark
                            : CupertinoIcons.arrow_clockwise,
                        size: 16,
                        tooltip: isLoading ? 'Arrêter' : 'Actualiser',
                        onPressed: activeTab != null ? () {
                          final engine = webViewManager.getEngineForTab(activeTab.id);
                          if (isLoading) {
                            engine.stop();
                          } else {
                            engine.reload();
                          }
                        } : null,
                      );
                    },
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
                    child: CompositedTransformTarget(
                      key: _inputAreaKey, // Cette clé est utilisée pour mesurer la largeur
                      link: _layerLink,
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
                            child: TextSelectionTheme(
                              data: TextSelectionThemeData(
                                selectionColor: gxRed.withValues(alpha: 0.3),
                                selectionHandleColor: gxRed,
                                cursorColor: gxRed,
                              ),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                cursorColor: gxRed,
                                selectionControls: MaterialTextSelectionControls(),
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
                                onSubmitted: (value) {
                                  _hideSuggestionsOverlay();
                                  _navigateToUrl(value);
                                },
                                onChanged: (value) {
                                  _updateSuggestionsOverlay();
                                },
                                onTap: () {
                                  // Sélectionner tout le texte au clic
                                  if (_controller.text.isNotEmpty) {
                                    _controller.selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: _controller.text.length,
                                    );
                                  }
                                  _updateSuggestionsOverlay();
                                },
                              ),
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
                          Consumer<AdBlockerService>(
                            builder: (context, adBlocker, _) {
                              return NotilusTooltip(
                                message: adBlocker.isEnabled 
                                    ? 'Bloqueur de pubs activé (${adBlocker.blockedCount} bloquées)\nCliquer pour désactiver'
                                    : 'Bloqueur de pubs désactivé\nCliquer pour activer',
                                child: GestureDetector(
                                  onTap: () => adBlocker.setEnabled(!adBlocker.isEnabled),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.transparent,
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minHeight: 26, minWidth: 26),
                                      icon: Icon(
                                        adBlocker.isEnabled 
                                            ? CupertinoIcons.shield_fill
                                            : CupertinoIcons.shield,
                                        size: 16,
                                        color: adBlocker.isEnabled ? gxRed : gxRed.withValues(alpha: 0.5),
                                      ),
                                      onPressed: () => adBlocker.setEnabled(!adBlocker.isEnabled),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),  // Fermeture du children du Row ligne 648
                    ),  // Fermeture du Row ligne 648 (MANQUANT - ajouté)
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Right side buttons
              Row(
                children: [
                  _GXAccountButton(
                    onPressed: widget.onAccountPressed ?? () => _showAccountDialog(context, gxRed),
                  ),
                  const SizedBox(width: 4),
                  _GXActionButton(
                    icon: CupertinoIcons.rectangle_badge_checkmark,
                    tooltip: widget.isMiniDevToolsVisible ? 'Masquer Mini DevTools' : 'Mini DevTools',
                    onPressed: widget.onMiniDevToolsToggle,
                    isActive: widget.isMiniDevToolsVisible,
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
                  CompositedTransformTarget(
                    link: _moreMenuLayerLink,
                    child: _GXActionButton(
                      icon: CupertinoIcons.ellipsis_vertical,
                      tooltip: 'Plus d\'outils',
                      onPressed: widget.onMoreToolsPressed ?? _toggleMoreMenu,
                    ),
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

class _GXAccountButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _GXAccountButton({
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseAuthService?>(
      builder: (context, authService, _) {
        final isSignedIn = authService?.isAnySignedIn ?? false;
        final user = authService?.currentUser;
        final githubUser = authService?.githubUser;
        final displayName = user?.displayName ?? user?.email ?? githubUser?.name ?? githubUser?.email ?? 'Utilisateur';
        final photoUrl = user?.photoURL ?? githubUser?.avatarUrl;
        
        final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
        final gxRed = colorThemeManager.nativeSecondaryColor;
        
        Widget accountWidget;
        
        if (isSignedIn && photoUrl != null) {
          // Afficher l'avatar si connecté avec photo
          accountWidget = Tooltip(
            message: displayName,
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gxRed, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(photoUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        } else if (isSignedIn) {
          // Afficher l'icône avec indicateur si connecté sans photo
          accountWidget = Tooltip(
            message: displayName,
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gxRed.withOpacity(0.2),
                  border: Border.all(color: gxRed, width: 2),
                ),
                child: Icon(
                  CupertinoIcons.person_crop_circle_fill,
                  size: 18,
                  color: gxRed,
                ),
              ),
            ),
          );
        } else {
          // Afficher l'icône normale si non connecté
          accountWidget = _GXActionButton(
            icon: CupertinoIcons.person_crop_circle,
            tooltip: 'Compte Notilus',
            onPressed: onPressed,
          );
        }
        
        return accountWidget;
      },
    );
  }
}

class _GXActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  const _GXActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isActive = false,
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
          color: (_isHovered && isEnabled) || widget.isActive
              ? gxRed.withValues(alpha: widget.isActive ? 0.2 : 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: widget.isActive
              ? Border.all(color: gxRed.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Builder(
          builder: (context) {
            final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
            final iconColor = colorThemeManager.getIconColor();
            return Icon(
              widget.icon,
              size: 18,
              color: isEnabled
                  ? (widget.isActive || _isHovered ? iconColor : iconColor.withValues(alpha: 0.8))
                  : iconColor.withValues(alpha: 0.3),
            );
          },
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
