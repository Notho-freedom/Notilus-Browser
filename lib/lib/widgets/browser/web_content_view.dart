import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
import '../../widgets/common/gx_context_menu.dart';
import '../../services/download_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/gx_notification_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/studio/studio_service.dart';
import 'package:flutter/services.dart';
import 'home_pages/home_page_factory.dart';

/// États d'initialisation du WebView
enum WebViewInitState {
  notInitialized,
  initializing,
  ready,
  error
}

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
  bool get wantKeepAlive => true;
  
  // État d'initialisation consolidé
  WebViewInitState _initState = WebViewInitState.notInitialized;
  
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<String?> _currentUrl = ValueNotifier(null);
  final ValueNotifier<String?> _currentTitle = ValueNotifier(null);
  
  WebviewController? _webView;
  bool _isTabActive = true;
  bool _isDisposed = false;
  bool _isInitializing = false; // Guard pour éviter les double init
  TabWebViewManager? _tabWebViewManager;
  StreamSubscription<LoadingState>? _loadingStateSubscription;
  Debouncer? _stateDebouncer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stateDebouncer = Debouncer(milliseconds: 100);
    
    // Initialisation asynchrone avec gestion d'état
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _initializeEngine();
      }
    });
    
    _checkTabVisibility();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    
    _loadingStateSubscription?.cancel();
    _loadingStateSubscription = null;
    
    _isLoading.dispose();
    _currentUrl.dispose();
    _currentTitle.dispose();
    
    _stateDebouncer?.dispose();
    
    _cleanupWebView();
    
    super.dispose();
  }

  Future<void> _cleanupWebView() async {
    try {
      if (_webView != null && _isTabActive && widget.tab?.id != null && _tabWebViewManager != null) {
        final engine = _tabWebViewManager!.getEngine(widget.tab!.id);
        if (engine != null && engine is WebView2BrowserEngine) {
          try {
            engine.setTabActive(false);
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (e) {
            debugPrint('Erreur lors de la suspension du WebView: $e');
          }
        }
      }
      
      _webView = null;
    } catch (e) {
      debugPrint('Erreur dans _cleanupWebView: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabWebViewManager = Provider.of<TabWebViewManager>(context, listen: false);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    
    if (state == AppLifecycleState.paused) {
      _setTabActive(false);
    } else if (state == AppLifecycleState.resumed) {
      _setTabActive(true);
    }
  }
  
  void _checkTabVisibility() {
    if (_isDisposed) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;
      
      final tabManager = Provider.of<TabManager>(context, listen: false);
      final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
      final isActive = widget.tab?.id == tabManager.activeTab?.id;
      
      if (isActive) {
        webViewManager.setActiveTab(widget.tab!.id);
      }
      
      if (_isTabActive != isActive) {
        _isTabActive = isActive;
        _setTabActive(isActive);
      }
    });
  }
  
  void _setTabActive(bool isActive) {
    if (_isDisposed || widget.tab?.id == null) return;
    
    _isTabActive = isActive;
    
    final tabManager = _tabWebViewManager;
    if (tabManager == null) return;
    
    final engine = tabManager.getEngine(widget.tab!.id);
    if (engine != null && engine is WebView2BrowserEngine) {
      engine.setTabActive(isActive);
    }
  }

  @override
  void didUpdateWidget(WebContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab?.id != widget.tab?.id) {
      _cleanupWebView();
      _initState = WebViewInitState.notInitialized;
      _initializeEngine();
    }
    _checkTabVisibility();
  }

  Future<void> _initializeEngine() async {
    // Guard contre les double initialisations
    if (_isInitializing || _isDisposed || widget.tab == null) {
      return;
    }
    
    if (!Platform.isWindows) {
      return;
    }

    // Marquer comme en cours d'initialisation
    _isInitializing = true;
    
    if (mounted) {
      setState(() {
        _initState = WebViewInitState.initializing;
      });
    }

    try {
      final tabManager = Provider.of<TabManager>(context, listen: false);
      final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
      
      WebView2BrowserEngine? engine;
      
      // Essayer d'abord un engine pré-chauffé
      engine = webViewManager.getPreWarmedEngine(
        widget.tab!.id, 
        url: widget.tab!.url
      ) as WebView2BrowserEngine?;
      
      // Sinon, créer un nouvel engine
      engine ??= webViewManager.getEngineForTab(
        widget.tab!.id, 
        url: widget.tab!.url
      ) as WebView2BrowserEngine?;
      
      if (engine == null) {
        if (mounted) {
          setState(() {
            _initState = WebViewInitState.error;
            _isInitializing = false;
          });
        }
        return;
      }
      
      // Attendre que l'engine soit complètement prêt
      await engine.waitForInitialization();
      
      // Vérifier si le widget est toujours monté et pas disposé
      if (_isDisposed || !mounted) {
        _isInitializing = false;
        return;
      }
      
      // Configuration des callbacks
      _setupEngineCallbacks(engine, tabManager);
      
      // Menu contextuel
      engine.onContextMenuRequest = (type, imageUrl, linkUrl, text, position) {
        if (mounted && !_isDisposed) {
          _showContextMenu(type, imageUrl, linkUrl, text, position, tabManager);
        }
      };

      // Récupération du controller
      final controller = await engine.getController();
      
      // Vérifier encore une fois avant de finaliser
      if (_isDisposed || !mounted) {
        _isInitializing = false;
        return;
      }
      
      if (controller != null && controller is WebviewController) {
        _setupWebView(controller, engine, tabManager);
        
        // IMPORTANT: Attendre un frame avant de marquer comme prêt
        await Future.delayed(const Duration(milliseconds: 150));
        
        if (_isDisposed || !mounted) {
          _isInitializing = false;
          return;
        }
        
        setState(() {
          _initState = WebViewInitState.ready;
          _isInitializing = false;
        });
      } else {
        setState(() {
          _initState = WebViewInitState.error;
          _isInitializing = false;
        });
      }
      
    } catch (e) {
      debugPrint('Erreur dans _initializeEngine: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _initState = WebViewInitState.error;
          _isInitializing = false;
        });
      }
    }
  }
  
  void _setupEngineCallbacks(WebView2BrowserEngine engine, TabManager tabManager) {
    engine.onNewWindowRequest = (url) {
      if (!_isDisposed) {
        tabManager.addTab(url: url);
      }
    };
    
    engine.onUrlChanged = (url) {
      if (_isDisposed) return;
      _currentUrl.value = url;
      tabManager.updateTab(widget.tab!.id, url: url);
      _loadFavicon(url, widget.tab!.id, tabManager);
    };
    
    engine.onTitleChanged = (title) {
      if (_isDisposed) return;
      _currentTitle.value = title;
      tabManager.updateTab(widget.tab!.id, title: title);
    };
    
    engine.onStateChanged = (state) {
      if (_isDisposed) return;
      _stateDebouncer?.run(() {
        if (_isDisposed || !mounted) return;
        _isLoading.value = state == TabState.loading;
        if (state is TabState) {
          tabManager.updateTab(widget.tab!.id, state: state);
        }
      });
    };
  }
  
  void _setupWebView(WebviewController controller, WebView2BrowserEngine engine, TabManager tabManager) {
    // IMPORTANT: Attacher l'engine à Studio si le tab est actif
    try {
      final studioService = Provider.of<StudioService>(context, listen: false);
      if (widget.tab?.id == tabManager.activeTab?.id) {
        studioService.attachEngine(engine);
        studioService.updateUrl(widget.tab?.url ?? '');
        debugPrint('✅ StudioService attaché au tab actif: ${widget.tab?.id}');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur attachement Studio: $e');
    }
    if (_isDisposed) return;
    
    _loadingStateSubscription?.cancel();
    
    _webView = controller;
    
    // Écouter l'état de chargement
    _loadingStateSubscription = engine.loadingStateStream.listen((state) {
      if (_isDisposed || !mounted) return;
      
      final isLoading = state == LoadingState.loading;
      _isLoading.value = isLoading;
      
      if (isLoading) {
        tabManager.updateTab(widget.tab!.id, state: TabState.loading);
      } else if (state == LoadingState.navigationCompleted) {
        _isLoading.value = false;
        tabManager.updateTab(widget.tab!.id, state: TabState.loaded);
      }
    });

    // Navigation si nécessaire
    if (widget.tab?.url != null && widget.tab!.url!.isNotEmpty) {
      // Attendre que le WebView soit bien attaché
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_isDisposed || !mounted) return;
        engine.navigate(widget.tab!.url!);
        _loadFavicon(widget.tab!.url!, widget.tab!.id, tabManager);
      });
    }
  }
  
  void _showContextMenu(
    String type,
    String? imageUrl,
    String? linkUrl,
    String? text,
    Offset position,
    TabManager tabManager,
  ) {
    if (_isDisposed || !mounted) return;
    
    final actions = <GxContextMenuAction>[];
    
    if (type == 'image' && imageUrl != null) {
      actions.add(
        GxContextMenuAction(
          label: 'Télécharger l\'image',
          icon: CupertinoIcons.arrow_down_circle,
          onTap: () {
            final downloadService = Provider.of<DownloadService>(context, listen: false);
            downloadService.addDownload(imageUrl);
          },
        ),
      );
      
      actions.add(
        GxContextMenuAction(
          label: 'Ouvrir l\'image dans un nouvel onglet',
          icon: CupertinoIcons.square_split_2x2,
          onTap: () {
            tabManager.addTab(url: imageUrl);
          },
        ),
      );
      
      actions.add(
        GxContextMenuAction(
          label: 'Copier le lien de l\'image',
          icon: CupertinoIcons.doc_on_clipboard,
          onTap: () {
            Clipboard.setData(ClipboardData(text: imageUrl));
          },
        ),
      );
      
      actions.add(
        GxContextMenuAction(
          label: 'Envoyer vers Cloudinary',
          icon: CupertinoIcons.cloud_upload,
          onTap: () {
            _uploadImageToCloudinary(context, imageUrl);
          },
        ),
      );
    }
    
    if (linkUrl != null && linkUrl.isNotEmpty && type != 'image') {
      actions.add(
        GxContextMenuAction(
          label: 'Ouvrir dans un nouvel onglet',
          icon: CupertinoIcons.square_split_2x2,
          onTap: () {
            tabManager.addTab(url: linkUrl);
          },
        ),
      );
      
      actions.add(
        GxContextMenuAction(
          label: 'Copier le lien',
          icon: CupertinoIcons.doc_on_clipboard,
          onTap: () {
            Clipboard.setData(ClipboardData(text: linkUrl));
          },
        ),
      );
    }
    
    if (text != null && text.isNotEmpty && type == 'text') {
      actions.add(
        GxContextMenuAction(
          label: 'Copier',
          icon: CupertinoIcons.doc_on_clipboard,
          onTap: () {
            Clipboard.setData(ClipboardData(text: text));
          },
        ),
      );
    }
    
    if (actions.isEmpty) return;
    
    GxContextMenu.show(
      context: context,
      actions: actions,
      position: position,
    );
  }
  
  Future<void> _uploadImageToCloudinary(BuildContext context, String imageUrl) async {
    final cloudinaryService = CloudinaryService();
    final notificationService = GxNotificationService();
    
    if (!cloudinaryService.isConfigured) {
      notificationService.showError(
        title: 'Cloudinary non configuré',
        message: 'Veuillez configurer Cloudinary dans les paramètres',
        context: context,
      );
      return;
    }
    
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = imageUrl.split('/').last.split('?').first;
    
    notificationService.show(
      title: 'Upload en cours...',
      message: fileName,
      type: GxNotificationType.info,
      icon: CupertinoIcons.cloud_upload,
      duration: null,
      showProgress: true,
      progress: 0.0,
      context: context,
    );
    
    try {
      final media = await cloudinaryService.uploadFromUrlWithProgress(
        url: imageUrl,
        resourceType: CloudinaryResourceType.image,
        folder: 'images',
        onProgress: (progress) {
          notificationService.updateProgress(notificationId, progress);
        },
      );
      
      if (media != null) {
        notificationService.dismiss(notificationId);
        notificationService.showSuccess(
          title: 'Upload réussi',
          message: 'L\'image a été uploadée vers Cloudinary',
          context: context,
        );
      } else {
        notificationService.dismiss(notificationId);
        notificationService.showError(
          title: 'Erreur d\'upload',
          message: cloudinaryService.error ?? 'Impossible d\'uploader l\'image',
          context: context,
        );
      }
    } catch (e) {
      notificationService.dismiss(notificationId);
      notificationService.showError(
        title: 'Erreur d\'upload',
        message: e.toString(),
        context: context,
      );
    }
  }

  Future<void> _loadFavicon(String url, String tabId, TabManager tabManager) async {
    if (url.startsWith('about:') || url.isEmpty) {
      return;
    }

    try {
      final faviconUrl = await FaviconService.getFaviconWithCache(url);
      if (faviconUrl != null && !_isDisposed && mounted) {
        tabManager.updateTab(tabId, favicon: faviconUrl);
      }
    } catch (e) {
      debugPrint('Error loading favicon for $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
    // Gérer les différents états d'initialisation
    switch (_initState) {
      case WebViewInitState.notInitialized:
      case WebViewInitState.initializing:
        return _buildLoadingIndicator(theme, 'Initialisation du navigateur...');
        
      case WebViewInitState.error:
        return _buildErrorView(theme);
        
      case WebViewInitState.ready:
        // WebView est prêt, on peut l'afficher
        if (_webView == null) {
          return _buildLoadingIndicator(theme, 'Préparation de la page...');
        }
        break;
    }

    if (widget.tab!.state == TabState.error) {
      return _buildErrorView(theme);
    }

    return Stack(
      children: [
        // WebView principal - seulement si ready
        if (_webView != null && _initState == WebViewInitState.ready)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: !_isTabActive,
              child: RepaintBoundary(
                child: Webview(_webView!),
              ),
            ),
          ),
        
        // Overlay de chargement
        if (isLoading && _initState == WebViewInitState.ready)
          _buildLoadingOverlay(theme),
      ],
    );
  }
  
  Widget _buildLoadingIndicator(AppTheme theme, String message) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final secondaryColor = colorTheme.nativeSecondaryColor;
    
    return Container(
      color: theme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              message,
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
  
  Widget _buildErrorView(AppTheme theme) {
    return Container(
      color: theme.background,
      child: Center(
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
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _initState = WebViewInitState.notInitialized;
                _initializeEngine();
              },
              child: Text(
                'Réessayer',
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 14,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingOverlay(AppTheme theme) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final secondaryColor = colorTheme.nativeSecondaryColor;
    
    return Positioned.fill(
      child: Container(
        color: theme.background.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
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