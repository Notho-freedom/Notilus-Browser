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
import 'package:flutter/services.dart';
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
  bool get wantKeepAlive => true;
  
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<String?> _currentUrl = ValueNotifier(null);
  final ValueNotifier<String?> _currentTitle = ValueNotifier(null);
  final ValueNotifier<bool> _isVisible = ValueNotifier(true);
  final ValueNotifier<bool> _isWebViewReady = ValueNotifier(false);
  
  WebviewController? _webView;
  bool _isTabActive = true;
  bool _isDisposed = false;
  TabWebViewManager? _tabWebViewManager;
  StreamSubscription<LoadingState>? _loadingStateSubscription;
  Debouncer? _stateDebouncer;
  Completer<void>? _initializationCompleter;

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
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    
    // Annuler la subscription au stream
    _loadingStateSubscription?.cancel();
    _loadingStateSubscription = null;
    
    // Disposer des ValueNotifiers
    _isLoading.dispose();
    _currentUrl.dispose();
    _currentTitle.dispose();
    _isVisible.dispose();
    _isWebViewReady.dispose();
    
    // Disposer du debouncer
    _stateDebouncer?.dispose();
    
    // Nettoyer le WebView
    _cleanupWebView();
    
    super.dispose();
  }

  Future<void> _cleanupWebView() async {
    try {
      // Suspendre le WebView si nécessaire
      if (_webView != null && _isTabActive && widget.tab?.id != null && _tabWebViewManager != null) {
        final engine = _tabWebViewManager!.getEngine(widget.tab!.id);
        if (engine != null && engine is WebView2BrowserEngine) {
          try {
            // Arrêter le polling mais ne pas désactiver complètement
            engine.setTabActive(false);
            // Attendre un peu pour que les opérations en cours se terminent
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (e) {
            debugPrint('Erreur lors de la suspension du WebView: $e');
          }
        }
      }
      
      // Le WebViewController sera géré par TabWebViewManager
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
      // Seulement suspendre quand l'app est vraiment en arrière-plan
      _setVisibility(false);
    } else if (state == AppLifecycleState.resumed) {
      // Toujours réactiver à la reprise
      _setVisibility(true);
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
        _setVisibility(isActive);
      }
    });
  }
  
  void _setVisibility(bool isVisible) {
    if (_isDisposed) return;
    
    // Toujours maintenir le WebView visible pour éviter les écrans noirs
    // Seulement ajuster l'état actif pour le polling
    _isVisible.value = true; // Toujours visible pour éviter les problèmes de rendu
    
    if (_webView != null && widget.tab?.id != null) {
      final tabManager = Provider.of<TabWebViewManager>(context, listen: false);
      final engine = tabManager.getEngine(widget.tab!.id);
      if (engine != null && engine is WebView2BrowserEngine) {
        // Seulement ajuster le polling, pas la visibilité du WebView
        engine.setTabActive(isVisible);
        
        // Si le WebView devient actif, s'assurer qu'il est visible
        if (isVisible) {
          _ensureWebViewVisible();
        }
      }
    }
  }
  
  void _ensureWebViewVisible() {
    // Cette méthode s'assure que le WebView est visible et fonctionnel
    if (_webView != null) {
      try {
        // Ne pas toucher aux animations CSS
        // Laisser WebView2 gérer son propre rendu
      } catch (e) {
        debugPrint('Erreur dans _ensureWebViewVisible: $e');
      }
    }
  }

  @override
  void didUpdateWidget(WebContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab?.id != widget.tab?.id) {
      _cleanupWebView();
      _initializeEngine();
    }
    _checkTabVisibility();
  }

  Future<void> _initializeEngine() async {
    if (_isDisposed || widget.tab == null) {
      _webView = null;
      _isWebViewReady.value = false;
      return;
    }

    if (!Platform.isWindows) {
      return;
    }

    final tabManager = Provider.of<TabManager>(context, listen: false);
    final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
    
    // Utiliser un Completer pour gérer l'initialisation asynchrone
    _initializationCompleter = Completer<void>();
    
    try {
      WebView2BrowserEngine? engine;
      
      // Essayer d'abord un engine pré-chauffé
      engine = webViewManager.getPreWarmedEngine(
        widget.tab!.id, 
        url: widget.tab!.url
      ) as WebView2BrowserEngine?;
      
      // Sinon, créer un nouvel engine normalement
      engine ??= webViewManager.getEngineForTab(widget.tab!.id, url: widget.tab!.url) as WebView2BrowserEngine?;
      
      if (engine == null) {
        _initializationCompleter?.complete();
        return;
      }
      
      // Attendre que l'engine soit prêt
      await engine.waitForInitialization();
      
      // Configuration des callbacks
      _setupEngineCallbacks(engine, tabManager);
      
      // Configurer le menu contextuel
      engine.onContextMenuRequest = (type, imageUrl, linkUrl, text, position) {
        _showContextMenu(type, imageUrl, linkUrl, text, position, tabManager);
      };

      // Récupération du controller
      final controller = await engine.getController();
      if (controller != null && controller is WebviewController) {
        _setupWebView(controller, engine, tabManager);
      } else {
        _isWebViewReady.value = false;
      }
      
      _initializationCompleter?.complete();
    } catch (e) {
      debugPrint('Erreur dans _initializeEngine: $e');
      _isWebViewReady.value = false;
      _initializationCompleter?.complete();
    }
  }
  
  void _setupEngineCallbacks(WebView2BrowserEngine engine, TabManager tabManager) {
    engine.onNewWindowRequest = (url) {
      tabManager.addTab(url: url);
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
    if (_isDisposed) return;
    
    // Annuler l'ancienne subscription
    _loadingStateSubscription?.cancel();
    
    _webView = controller;
    _isWebViewReady.value = true;
    
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
        
        // S'assurer que le WebView est visible après chargement
        _ensureWebViewVisible();
      }
    });

    // Navigation si nécessaire
    if (widget.tab?.url != null && widget.tab!.url!.isNotEmpty) {
      // Attendre un peu avant la navigation pour laisser le WebView s'initialiser
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isDisposed || !mounted) return;
        engine.navigate(widget.tab!.url!);
        _loadFavicon(widget.tab!.url!, widget.tab!.id, tabManager);
      });
    }
  }
  
  /// Affiche le menu contextuel
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
  
  /// Upload une image vers Cloudinary
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

  /// Charge le favicon pour une URL
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

    return ValueListenableBuilder3<bool, bool, bool>(
      first: _isLoading,
      second: _isWebViewReady,
      third: _isVisible,
      builder: (context, isLoading, isWebViewReady, isVisible, _) {
        return _buildWebContent(isLoading, isWebViewReady, theme);
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
  
  Widget _buildWebContent(bool isLoading, bool isWebViewReady, AppTheme theme) {
    // Afficher un indicateur de chargement seulement si le WebView n'est pas prêt
    if (!isWebViewReady && isLoading) {
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
        // WebView principal - toujours visible
        if (_webView != null && isWebViewReady)
          AbsorbPointer(
            // Permet aux interactions de passer à travers si le tab n'est pas actif
            absorbing: !_isTabActive,
            child: Webview(_webView!),
          ),
        
        // Overlay de chargement conditionnel
        if (isLoading && isWebViewReady)
          _buildLoadingOverlay(theme),
          
        // Overlay de non-initialisation
        if (!isWebViewReady && _webView == null)
          _buildInitializingOverlay(theme),
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
              'Initialisation du navigateur...',
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
  
  Widget _buildInitializingOverlay(AppTheme theme) {
    return Positioned.fill(
      child: Container(
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
                'Préparation de la page...',
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

/// Helper pour combiner plusieurs ValueListenableBuilder
class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final ValueListenable<C> third;
  final Widget Function(BuildContext context, A a, B b, C c, Widget? child) builder;
  final Widget? child;

  const ValueListenableBuilder3({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) {
            return ValueListenableBuilder<C>(
              valueListenable: third,
              builder: (context, c, _) {
                return builder(context, a, b, c, child);
              },
            );
          },
        );
      },
    );
  }
}