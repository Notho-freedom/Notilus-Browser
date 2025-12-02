import 'package:flutter/material.dart';
import '../widgets/browser/modern_browser_window.dart';
import 'cef_test_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ModernBrowserWindow(),
      // Bouton flottant pour tester CEF (toujours visible)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CefTestScreen(),
            ),
          );
        },
        icon: const Icon(Icons.science),
        label: const Text('Test CEF'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
    );
  }
}