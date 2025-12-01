import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'core/theme/modern_theme.dart';
import 'core/services/theme_mode_notifier.dart';
import 'core/services/wallpaper_manager.dart';
import 'core/services/color_theme_manager.dart';
import 'core/services/background_music_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/tab_manager.dart';
import 'services/tab_group_service.dart';
import 'services/tab_webview_manager.dart';
import 'services/side_webview_manager.dart';
import 'services/system_metrics_service.dart';
import 'services/terminal_service.dart';
import 'services/terminal_manager.dart';
import 'services/native_terminal_service.dart';
import 'services/download_service.dart';
import 'services/devtools_service.dart';
import 'services/settings_service.dart';
import 'services/mosaic_service.dart';
import 'services/home_widget_service.dart';
import 'services/studio/studio_service.dart';
import 'services/lighthouse/lighthouse_service.dart';
import 'services/documentation_service.dart';
import 'services/adblocker_service.dart';
import 'services/cloudinary_service.dart';
import 'services/tabs_preview_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth/firebase_auth_service.dart';
import 'services/auth/config_sync_service.dart';
import 'services/github/github_repos_service.dart';
import 'services/text_selection_service.dart';
import 'services/cookie_manager_service.dart';
import 'services/backend_process_service.dart';
import 'services/backend_lab/backend_lab_service.dart';
import 'widgets/common/text_selection_wrapper.dart';
import 'core/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le service de logging
  await LoggerService().initialize(enableFileLogging: kDebugMode);
  LoggerService().info('Notilus Browser - Démarrage');

  // Initialiser Firebase (si configuré)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase non configuré, continuer sans
    LoggerService().error('Firebase non initialisé', context: 'main', error: e);
  }

  // Supprime le halo bleu Windows autour des champs focus
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
  
  // Initialisation des services centralisés en parallèle
  final settingsService = SettingsService();
  final mosaicService = NotilusMosaicService();
  
  // Paralléliser les initialisations pour accélérer le démarrage
  await Future.wait([
    settingsService.initialize(),
    mosaicService.initialize(),
  ]);
  
  // Pré-chauffer un WebView au lancement pour accélérer le premier chargement
  if (Platform.isWindows) {
    try {
      // Lancer le pré-chauffage en arrière-plan (ne pas attendre)
      // Le TabWebViewManager sera créé dans le Provider, donc on le fera après runApp
      Future.delayed(const Duration(seconds: 1), () {
        try {
          // Le pré-chauffage sera géré par TabWebViewManager lors de sa création
        } catch (e) {
          LoggerService().error('Erreur lors du pré-chauffage du WebView', context: 'main', error: e);
        }
      });
    } catch (e) {
      LoggerService().error('Impossible de pré-chauffer le WebView', context: 'main', error: e);
    }
  }

  // Initialiser Firebase Auth et Config Sync (si Firebase est configuré)
  FirebaseAuthService? authService;
  ConfigSyncService? syncService;
  GitHubReposService? githubReposService;
  try {
    authService = FirebaseAuthService();
    syncService = ConfigSyncService(authService, settingsService);
    githubReposService = GitHubReposService(authService);
  } catch (e) {
    LoggerService().error('Services Firebase non initialisés', context: 'main', error: e);
  }
  
  // Initialisation de window_manager AVANT runApp
  await windowManager.ensureInitialized();
  
  const WindowOptions windowOptions = WindowOptions(
    size: Size(1200, 800),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  // Configuration de la barre de statut transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Préférences de fenêtre
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  runApp(NotilusApp(
    settingsService: settingsService,
    mosaicService: mosaicService,
    authService: authService,
    syncService: syncService,
    githubReposService: githubReposService,
  ));
}

/// Widget wrapper pour gérer l'affichage de la splash screen
class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper();

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper> with WidgetsBindingObserver {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Arrêter le backend quand l'app se ferme
    BackendProcessService().stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      // Arrêter le backend si l'app se ferme ou passe en arrière-plan
      BackendProcessService().stop();
    }
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _showSplash
          ? NotilusSplashScreen(
              key: const ValueKey('splash'),
              onComplete: _onSplashComplete,
            )
          : const HomeScreen(key: ValueKey('home')),
    );
  }
}

/// ScrollBehavior personnalisé pour cacher toutes les scrollbars de l'application
class _InvisibleScrollBehavior extends ScrollBehavior {
  const _InvisibleScrollBehavior();
  
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Ne pas afficher de scrollbar
    return child;
  }
}

class NotilusApp extends StatelessWidget {
  final SettingsService settingsService;
  final NotilusMosaicService mosaicService;
  final FirebaseAuthService? authService;
  final ConfigSyncService? syncService;
  final GitHubReposService? githubReposService;
  
  // GlobalKey pour le Navigator root
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  const NotilusApp({
    super.key,
    required this.settingsService,
    required this.mosaicService,
    this.authService,
    this.syncService,
    this.githubReposService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider(create: (_) => ThemeModeNotifier()),
        ChangeNotifierProvider(create: (_) => ColorThemeManager()),
        ChangeNotifierProvider(create: (_) => WallpaperManager()),
        ChangeNotifierProvider.value(value: BackgroundMusicService()),
        ChangeNotifierProvider(create: (_) => DownloadService()),
        ChangeNotifierProvider(create: (_) => TabManager()),
        ChangeNotifierProvider(create: (context) {
          final tabManager = context.read<TabManager>();
          return TabGroupService(tabManager);
        }),
        ChangeNotifierProvider(create: (_) => DevToolsService()),
        ChangeNotifierProvider(create: (_) => StudioService()),
        ChangeNotifierProvider(create: (_) => LighthouseService()),
        ChangeNotifierProvider(create: (_) => AdBlockerService()),
        ChangeNotifierProvider.value(value: CloudinaryService()),
        ChangeNotifierProvider.value(value: TabsPreviewService()),
        ChangeNotifierProvider.value(value: mosaicService),
        ChangeNotifierProvider(create: (_) => HomeWidgetService()..initialize()),
            ChangeNotifierProvider(
              create: (context) {
                final tabWebViewManager = TabWebViewManager();
                final tabManager = context.read<TabManager>();
                final downloadService = context.read<DownloadService>();
                final studioService = context.read<StudioService>();
                final lighthouseService = context.read<LighthouseService>();
                final adBlockerService = context.read<AdBlockerService>();
                tabWebViewManager.setDownloadService(downloadService);
                tabWebViewManager.setStudioService(studioService);
                tabWebViewManager.setLighthouseService(lighthouseService);
                tabWebViewManager.setAdBlockerService(adBlockerService);
                
                // Initialiser le service de preview
                final previewService = context.read<TabsPreviewService>();
                previewService.initialize(tabWebViewManager, tabManager);
                
                // Pré-chauffer un engine en arrière-plan
                if (Platform.isWindows) {
                  tabWebViewManager.preWarmEngine().catchError((e) {
                    LoggerService().error('Erreur lors du pré-chauffage', context: 'main', error: e);
                  });
                }
                
                return tabWebViewManager;
              },
            ),
        ChangeNotifierProvider(create: (_) => SideWebViewManager()),
        ChangeNotifierProvider(create: (_) => SystemMetricsService()),
        ChangeNotifierProvider(create: (_) => TerminalService()..initialize()),
        ChangeNotifierProvider(create: (_) => TerminalManager()),
        ChangeNotifierProvider(create: (_) => NativeTerminalService()),
        // Documentation Service
        ChangeNotifierProvider(create: (_) => DocumentationService()..initialize()),
        // Firebase Auth et Sync (si disponibles)
        if (authService != null)
          ChangeNotifierProvider.value(value: authService),
        if (syncService != null)
          ChangeNotifierProvider.value(value: syncService),
        if (githubReposService != null)
          ChangeNotifierProvider<GitHubReposService>.value(value: githubReposService!),
        ChangeNotifierProvider.value(value: TextSelectionService()),
        ChangeNotifierProvider(
          create: (context) {
            final tabWebViewManager = context.read<TabWebViewManager>();
            final tabManager = context.read<TabManager>();
            return CookieManagerService(
              webViewManager: tabWebViewManager,
              tabManager: tabManager,
            );
          },
        ),
        // Backend Process Service
        ChangeNotifierProvider.value(value: BackendProcessService()),
        ChangeNotifierProvider(create: (_) => BackendLabService()..checkConnection()),
      ],
      child: Consumer<ThemeModeNotifier>(
        builder: (context, themeModeNotifier, _) {
          // Configuration pour rendre les scrollbars invisibles
          const invisibleScrollbarTheme = ScrollbarThemeData(
            thumbVisibility: WidgetStatePropertyAll<bool>(false),
            trackVisibility: WidgetStatePropertyAll<bool>(false),
            thickness: WidgetStatePropertyAll<double>(0),
            thumbColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            trackColor: WidgetStatePropertyAll<Color>(Colors.transparent),
            radius: Radius.zero,
            minThumbLength: 0,
            interactive: false,
          );
          
          return MaterialApp(
            title: 'Notilus Browser',
            debugShowCheckedModeBanner: false,
            navigatorKey: NotilusApp.navigatorKey,
            // ScrollBehavior personnalisé pour cacher toutes les scrollbars
            scrollBehavior: const _InvisibleScrollBehavior(),
            theme: ModernTheme.lightTheme.copyWith(
              scrollbarTheme: invisibleScrollbarTheme,
            ),
            darkTheme: ModernDarkTheme.darkTheme.copyWith(
              scrollbarTheme: invisibleScrollbarTheme,
            ),
            themeMode: themeModeNotifier.mode,
            builder: (context, child) {
              return TextSelectionWrapper(
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _SplashWrapper(),
          );
        },
      ),
    );
  }
}