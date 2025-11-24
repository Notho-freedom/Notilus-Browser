import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/modern_theme.dart';
import 'core/services/theme_mode_notifier.dart';
import 'core/services/wallpaper_manager.dart';
import 'screens/home_screen.dart';
import 'services/tab_manager.dart';
import 'services/tab_webview_manager.dart';
import 'services/side_webview_manager.dart';
import 'services/system_metrics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supprime le halo bleu Windows autour des champs focus
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
  
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

class NotilusApp extends StatelessWidget {
  const NotilusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModeNotifier()),
        ChangeNotifierProvider(create: (_) => WallpaperManager()),
        ChangeNotifierProvider(create: (_) => TabManager()),
        ChangeNotifierProvider(create: (_) => TabWebViewManager()),
        ChangeNotifierProvider(create: (_) => SideWebViewManager()),
        ChangeNotifierProvider(create: (_) => SystemMetricsService()),
      ],
      child: Consumer<ThemeModeNotifier>(
        builder: (context, themeModeNotifier, _) {
          return MaterialApp(
            title: 'Notilus Browser',
            debugShowCheckedModeBanner: false,
            theme: ModernTheme.lightTheme,
            darkTheme: ModernDarkTheme.darkTheme,
            themeMode: themeModeNotifier.mode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}