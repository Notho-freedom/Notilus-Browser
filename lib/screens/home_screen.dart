import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/browser/browser_window.dart';
import '../widgets/common/animated_background.dart';
import '../core/theme/theme_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        showParticles: true,
        showGradient: true,
        child: const BrowserWindow(),
      ),
    );
  }
}

