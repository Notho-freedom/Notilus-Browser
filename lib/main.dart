import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/modern_theme.dart';
import 'core/services/theme_mode_notifier.dart';
import 'core/services/wallpaper_manager.dart';
import 'core/services/color_theme_manager.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/tab_manager.dart';
import 'services/tab_webview_manager.dart';
import 'services/side_webview_manager.dart';
import 'services/system_metrics_service.dart';
import 'services/terminal_service.dart';
import 'services/terminal_manager.dart';
import 'services/native_terminal_service.dart';
import 'services/download_service.dart';
import 'services/devtools_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supprime le halo bleu Windows autour des champs focus
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
  
  // Initialisation du service de paramètres centralisé
  final settingsService = SettingsService();
  await settingsService.initialize();
  
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

  runApp(const NotilusApp());
}

/// Widget wrapper pour gérer l'affichage de la splash screen
class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper();

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper> {
  bool _showSplash = true;

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

class NotilusApp extends StatelessWidget {
  const NotilusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SettingsService()),
        ChangeNotifierProvider(create: (_) => ThemeModeNotifier()),
        ChangeNotifierProvider(create: (_) => ColorThemeManager()),
        ChangeNotifierProvider(create: (_) => WallpaperManager()),
        ChangeNotifierProvider(create: (_) => DownloadService()),
        ChangeNotifierProvider(create: (_) => TabManager()),
        ChangeNotifierProvider(create: (_) => DevToolsService()),
        ChangeNotifierProvider(
          create: (context) {
            final tabWebViewManager = TabWebViewManager();
            final downloadService = context.read<DownloadService>();
            tabWebViewManager.setDownloadService(downloadService);
            return tabWebViewManager;
          },
        ),
        ChangeNotifierProvider(create: (_) => SideWebViewManager()),
        ChangeNotifierProvider(create: (_) => SystemMetricsService()),
        ChangeNotifierProvider(create: (_) => TerminalService()..initialize()),
        ChangeNotifierProvider(create: (_) => TerminalManager()),
        ChangeNotifierProvider(create: (_) => NativeTerminalService()),
      ],
      child: Consumer<ThemeModeNotifier>(
        builder: (context, themeModeNotifier, _) {
          return MaterialApp(
            title: 'Notilus Browser',
            debugShowCheckedModeBanner: false,
            theme: ModernTheme.lightTheme.copyWith(
              scrollbarTheme: const ScrollbarThemeData(
                thumbVisibility: MaterialStatePropertyAll<bool>(true),
                trackVisibility: MaterialStatePropertyAll<bool>(false),
                thickness: MaterialStatePropertyAll<double>(2),
                radius: Radius.circular(1),
                minThumbLength: 20,
              ),
            ),
            darkTheme: ModernDarkTheme.darkTheme.copyWith(
              scrollbarTheme: const ScrollbarThemeData(
                thumbVisibility: MaterialStatePropertyAll<bool>(true),
                trackVisibility: MaterialStatePropertyAll<bool>(false),
                thickness: MaterialStatePropertyAll<double>(2),
                radius: Radius.circular(1),
                minThumbLength: 20,
              ),
            ),
            themeMode: themeModeNotifier.mode,
            home: const _SplashWrapper(),
          );
        },
      ),
    );
  }
}