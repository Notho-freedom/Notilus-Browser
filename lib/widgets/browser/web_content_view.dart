import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:webview_windows/webview_windows.dart';
import '../../models/tab_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/tab_manager.dart';
import '../../services/favicon_service.dart';
import '../../services/webview2_browser_engine.dart';
import '../../services/settings_service.dart';
import 'home_pages/home_page_factory.dart';

/// Widget pour afficher le contenu web avec WebView2
class WebContentView extends StatefulWidget {
  final TabModel? tab;

  const WebContentView({
    super.key,
    this.tab,
  });

  @override
  State<WebContentView> createState() => _WebContentViewState();
}

class _WebContentViewState extends State<WebContentView> with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _currentUrl;
  String? _currentTitle;
  WebviewController? _webView;
  bool _isVisible = true;
  bool _isTabActive = true;
  TabWebViewManager? _tabWebViewManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeEngine();
    _checkTabVisibility();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sauvegarder la référence au TabWebViewManager pour l'utiliser dans dispose()
    _tabWebViewManager = Provider.of<TabWebViewManager>(context, listen: false);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Suspendre le WebView si nécessaire
    if (_webView != null && _isTabActive && widget.tab?.id != null && _tabWebViewManager != null) {
      try {
        final engine = _tabWebViewManager!.getEngine(widget.tab!.id);
        if (engine != null && engine is WebView2BrowserEngine) {
          engine.setTabActive(false);
        }
      } catch (e) {
        // Ignorer les erreurs si le widget est déjà désactivé
        debugPrint('Erreur lors de la suspension du WebView dans dispose: $e');
      }
    }
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Suspendre le rendu quand l'app est en arrière-plan
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _setVisibility(false);
    } else if (state == AppLifecycleState.resumed) {
      _setVisibility(_isTabActive);
    }
  }
  
  void _checkTabVisibility() {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final isActive = widget.tab?.id == tabManager.activeTab?.id;
    if (_isTabActive != isActive) {
      _isTabActive = isActive;
      _setVisibility(isActive);
    }
  }
  
  void _setVisibility(bool isVisible) {
    if (_isVisible == isVisible) return;
    
    _isVisible = isVisible;
    
    // Mettre à jour l'état actif du WebView pour ajuster le polling
    if (_webView != null && widget.tab?.id != null) {
      final tabManager = Provider.of<TabWebViewManager>(context, listen: false);
      final engine = tabManager.getEngine(widget.tab!.id);
      if (engine != null && engine is WebView2BrowserEngine) {
        engine.setTabActive(isVisible);
      }
    }
    
    // Désactiver les animations CSS quand en arrière-plan
    if (_webView != null && !isVisible) {
      _webView!.executeScript('''
        document.body.style.animationPlayState = 'paused';
        document.body.style.transition = 'none';
      ''');
    } else if (_webView != null && isVisible) {
      _webView!.executeScript('''
        document.body.style.animationPlayState = 'running';
        document.body.style.transition = '';
      ''');
    }
  }

  @override
  void didUpdateWidget(WebContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab?.id != widget.tab?.id) {
      _initializeEngine();
      _checkTabVisibility();
    } else {
      _checkTabVisibility();
    }
  }

  Future<void> _initializeEngine() async {
    if (widget.tab == null) {
      setState(() {
        _webView = null;
      });
      return;
    }

    if (!Platform.isWindows) {
      return;
    }

    final tabManager = Provider.of<TabManager>(context, listen: false);
    final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
    // Utiliser le nouveau système avec URL pour le cache
    final engine = webViewManager.getEngineForTab(widget.tab!.id, url: widget.tab!.url);
    
    // Configurer les callbacks
    engine.onNewWindowRequest = (url) {
      // Créer un nouvel onglet dans Notilus pour tous les liens externes et target="_blank"
      tabManager.addTab(url: url);
    };
    
    engine.onUrlChanged = (url) {
      if (mounted) {
        setState(() {
          _currentUrl = url;
        });
        tabManager.updateTab(widget.tab!.id, url: url);
        // Charger le favicon automatiquement quand l'URL change
        _loadFavicon(url, widget.tab!.id, tabManager);
      }
    };
    
    engine.onTitleChanged = (title) {
      if (mounted) {
        setState(() {
          _currentTitle = title;
        });
        tabManager.updateTab(widget.tab!.id, title: title);
      }
    };
    
    engine.onStateChanged = (state) {
      if (mounted) {
        setState(() {
          _isLoading = state == TabState.loading;
        });
        if (state is TabState) {
          tabManager.updateTab(widget.tab!.id, state: state);
        }
      }
    };

    // Récupérer le WebView2
    final controller = await engine.getController();
    if (controller != null && controller is WebviewController) {
      setState(() {
        _webView = controller as WebviewController;
      });

      // Naviguer vers l'URL si elle existe
      if (widget.tab?.url != null && widget.tab!.url!.isNotEmpty) {
        await engine.navigate(widget.tab!.url!);
        // Charger le favicon pour l'URL initiale
        _loadFavicon(widget.tab!.url!, widget.tab!.id, tabManager);
      }
    } else if (widget.tab?.url != null && widget.tab!.url!.isNotEmpty) {
      // Si le WebView n'est pas encore créé, naviguer via l'engine
      await engine.navigate(widget.tab!.url!);
      // Charger le favicon pour l'URL initiale
      _loadFavicon(widget.tab!.url!, widget.tab!.id, tabManager);
      // Récupérer le controller après navigation
      final newController = await engine.getController();
      if (newController != null && newController is WebviewController) {
        setState(() {
          _webView = newController;
        });
      }
    }
  }

  /// Charge le favicon pour une URL et met à jour l'onglet
  Future<void> _loadFavicon(String url, String tabId, TabManager tabManager) async {
    // Ne pas charger de favicon pour les pages spéciales
    if (url.startsWith('about:') || url.isEmpty) {
      return;
    }

    try {
      final faviconUrl = await FaviconService.getFaviconWithCache(url);
      if (faviconUrl != null && mounted) {
        tabManager.updateTab(tabId, favicon: faviconUrl);
      }
    } catch (e) {
      debugPrint('Error loading favicon for $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeFromContext();

    // Afficher la page d'accueil si pas d'onglet ou URL vide
    // Utiliser HomePageFactory pour créer la bonne page selon les paramètres
    if (widget.tab == null || 
        widget.tab!.url == null || 
        widget.tab!.url!.isEmpty ||
        widget.tab!.url == 'about:blank' ||
        widget.tab!.url == 'about:newtab') {
      final settings = SettingsService();
      return HomePageFactory.create(
        style: settings.homePageStyle,
      );
    }

    if (!Platform.isWindows) {
      return Container(
        color: theme.background,
        child: Center(
          child: Text(
            'WebView2 non supporté sur cette plateforme',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ),
      );
    }

    if (_isLoading || widget.tab!.state == TabState.loading) {
      return Stack(
        children: [
          // Afficher le WebView même pendant le chargement
          if (_webView != null)
            Webview(_webView!),
          // Overlay de chargement
          Container(
            color: theme.background.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement...',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Roboto Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (widget.tab!.state == TabState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: theme.error,
                fontSize: 18,
                fontFamily: 'Roboto Mono',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.tab?.url ?? '',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ],
        ),
      );
    }

    // Afficher le WebView2 avec RepaintBoundary pour optimiser le rendu
    if (_webView != null) {
      return RepaintBoundary(
        child: Visibility(
          visible: _isVisible,
          maintainState: true, // Garder l'état même si invisible
          child: Webview(_webView!),
        ),
      );
    }

    // Fallback si le WebView n'est pas encore initialisé
    return Container(
      color: theme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Initialisation de WebView2...',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 14,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppTheme _getThemeFromContext() {
    return const AppTheme(
      name: 'Default',
      background: Color(0xFF0D0D0D),
      surface: Color(0xFF1A1A1A),
      primary: Color(0xFFFF0040),
      secondary: Color(0xFFFF3366),
      accent: Color(0xFF00FF88),
      text: Color(0xFFE0E0E0),
      textSecondary: Color(0xFF888888),
      error: Color(0xFFFF0040),
      success: Color(0xFF00FF88),
      warning: Color(0xFFFFAA00),
      border: Color(0xFF333333),
      hover: Color(0xFF2A2A2A),
      selected: Color(0xFFFF0040),
    );
  }
}
