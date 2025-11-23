import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/modern_theme.dart';
import 'screens/home_screen.dart';
import 'services/tab_manager.dart';
import 'services/tab_webview_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        ChangeNotifierProvider(create: (_) => TabManager()),
        ChangeNotifierProvider(create: (_) => TabWebViewManager()),
      ],
      child: MaterialApp(
        title: 'Notilus Browser',
        debugShowCheckedModeBanner: false,
        theme: ModernTheme.lightTheme,
        darkTheme: ModernDarkTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}