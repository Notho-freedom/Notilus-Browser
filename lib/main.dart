import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_manager.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const NotilusApp());
}

class NotilusApp extends StatelessWidget {
  const NotilusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, _) {
          return MaterialApp(
            title: 'Notilus Browser',
            debugShowCheckedModeBanner: false,
            theme: themeManager.currentTheme.toThemeData(),
            darkTheme: themeManager.currentTheme.toThemeData(),
            themeMode: ThemeMode.dark,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

