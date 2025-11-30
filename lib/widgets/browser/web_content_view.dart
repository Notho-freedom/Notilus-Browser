import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:webview_windows/webview_windows.dart';
import '../../models/tab_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/tab_manager.dart';
import '../../services/favicon_service.dart';
import '../../services/webview2_browser_engine.dart';
import '../../services/settings_service.dart';
import '../../core/utils/debouncer.dart';
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

class _WebContentViewState extends State<WebContentView> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Garde l'état du widget
  
  // Remplacer les variables d'état par des ValueNotifier pour des updates plus rapides
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<String?> _currentUrl = ValueNotifier(null);
  final ValueNotifier<String?> _currentTitle = ValueNotifier(null);
  final ValueNotifier<bool> _isVisible = ValueNotifier(true);
  
  WebviewController? _webView;
  bool _isTabActive = true;
  TabWebViewManager? _tabWebViewManager;
  StreamSubscription<LoadingState>? _loadingStateSubscription;
  Debouncer? _stateDebouncer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stateDebouncer = Debouncer(milliseconds: 100);
    _initializeEngine();
    _checkTabVisibility();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Annuler la subscription au stream
    _loadingStateSubscription?.cancel();
    _loadingStateSubscription = null;
    // Disposer des ValueNotifiers
    _isLoading.dispose();
    _currentUrl.dispose();
    _currentTitle.dispose();
    _isVisible.dispose();
    // Disposer du debouncer
    _stateDebouncer?.dispose();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sauvegarder la référence au TabWebViewManager pour l'utiliser dans dispose()
    _tabWebViewManager = Provider.of<TabWebViewManager>(context, listen: false);
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
    final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
    final isActive = widget.tab?.id == tabManager.activeTab?.id;
    
    // Mettre à jour la priorité dans TabWebViewManager
    if (isActive) {
      webViewManager.setActiveTab(widget.tab!.id);
    }
    
    if (_isTabActive != isActive) {
      _isTabActive = isActive;
      _setVisibility(isActive);
    }
  }
  
  void _setVisibility(bool isVisible) {
    if (_isVisible.value == isVisible) return;
    
    _isVisible.value = isVisible;
    
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
      _webView = null;
      return;
    }

    if (!Platform.isWindows) {
      return;
    }

    final tabManager = Provider.of<TabManager>(context, listen: false);
    final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
    
    // Essayer d'abord un engine pré-chauffé
    WebView2BrowserEngine? engine = webViewManager.getPreWarmedEngine(
      widget.tab!.id, 
      url: widget.tab!.url
    ) as WebView2BrowserEngine?;
    
    // Sinon, créer un nouvel engine normalement
    engine ??= webViewManager.getEngineForTab(widget.tab!.id, url: widget.tab!.url) as WebView2BrowserEngine?;
    
    if (engine == null) return;
    
    // Configuration optimisée des callbacks
    _setupEngineCallbacks(engine, tabManager);

    // Récupération rapide du controller
    final controller = await engine.getController();
    if (controller != null && controller is WebviewController) {
      _setupWebView(controller, engine, tabManager);
    }
  }
  
  void _setupEngineCallbacks(WebView2BrowserEngine engine, TabManager tabManager) {
    engine.onNewWindowRequest = (url) {
      tabManager.addTab(url: url);
    };
    
    engine.onUrlChanged = (url) {
      _currentUrl.value = url;
      tabManager.updateTab(widget.tab!.id, url: url);
      _loadFavicon(url, widget.tab!.id, tabManager);
    };
    
    engine.onTitleChanged = (title) {
      _currentTitle.value = title;
      tabManager.updateTab(widget.tab!.id, title: title);
    };
    
    // Utiliser un debouncer pour éviter les updates trop fréquentes
    engine.onStateChanged = (state) {
      _stateDebouncer?.run(() {
        if (mounted) {
          _isLoading.value = state == TabState.loading;
          if (state is TabState) {
            tabManager.updateTab(widget.tab!.id, state: state);
          }
        }
      });
    };
  }
  
  void _setupWebView(WebviewController controller, WebView2BrowserEngine engine, TabManager tabManager) {
    // Annuler l'ancienne subscription
    _loadingStateSubscription?.cancel();
    
    _webView = controller;
    
    // Écouter l'état de chargement avec debouncer
    final loadingDebouncer = Debouncer(milliseconds: 50);
    _loadingStateSubscription = engine.loadingStateStream.listen((state) {
      if (!mounted) return;
      
      loadingDebouncer.run(() {
        if (!mounted) return;
        
        final isLoading = state == LoadingState.loading;
        _isLoading.value = isLoading;
        
        if (isLoading) {
          tabManager.updateTab(widget.tab!.id, state: TabState.loading);
        } else if (state == LoadingState.navigationCompleted) {
          _isLoading.value = false;
          tabManager.updateTab(widget.tab!.id, state: TabState.loaded);
        }
      });
    });

    // Navigation immédiate si nécessaire
    if (widget.tab?.url != null && widget.tab!.url!.isNotEmpty) {
      engine.navigate(widget.tab!.url!);
      _loadFavicon(widget.tab!.url!, widget.tab!.id, tabManager);
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
    super.build(context); // Pour AutomaticKeepAliveClientMixin
    final theme = _getThemeFromContext();

    // Afficher la page d'accueil si pas d'onglet ou URL vide
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
      return _buildUnsupportedPlatform(theme);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _isLoading,
      builder: (context, isLoading, _) {
        return _buildWebContent(isLoading, theme);
      },
    );
  }
  
  Widget _buildUnsupportedPlatform(AppTheme theme) {
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
  
  Widget _buildWebContent(bool isLoading, AppTheme theme) {
    if (isLoading && _webView == null) {
      return _buildLoadingIndicator(theme);
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

    return Stack(
      children: [
        // WebView principal
        if (_webView != null)
          RepaintBoundary(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isVisible,
              builder: (context, isVisible, _) {
                return Visibility(
                  visible: isVisible,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainInteractivity: false, // Désactive l'interactivité quand invisible
                  child: Webview(_webView!),
                );
              },
            ),
          ),
        
        // Overlay de chargement conditionnel
        if (isLoading)
          _buildLoadingOverlay(theme),
      ],
    );
  }
  
  Widget _buildLoadingIndicator(AppTheme theme) {
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
              'Initialisation...',
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
  
  Widget _buildLoadingOverlay(AppTheme theme) {
    return Positioned.fill(
      child: Container(
        color: theme.background.withOpacity(0.7),
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
