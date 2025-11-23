import 'package:flutter/material.dart';
import '../widgets/browser/modern_browser_window.dart';
import '../widgets/browser/gx_title_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          GXTitleBar(),
          Expanded(child: ModernBrowserWindow()),
        ],
      ),
    );
  }
}