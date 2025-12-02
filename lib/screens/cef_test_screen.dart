// cef_test_screen.dart
// Écran de test pour l'intégration CEF Quantum-Bridge

import 'package:flutter/material.dart';
import 'package:notilus_cef/notilus_cef.dart';
import 'package:notilus_cef/widgets/quantum_browser.dart';

class CefTestScreen extends StatefulWidget {
  const CefTestScreen({super.key});

  @override
  State<CefTestScreen> createState() => _CefTestScreenState();
}

class _CefTestScreenState extends State<CefTestScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://flutter.dev',
  );
  bool _isInitialized = false;
  String _status = 'Non initialisé';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _loadUrl() {
    if (_urlController.text.isNotEmpty) {
      setState(() {
        _status = 'Chargement de ${_urlController.text}...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test CEF Quantum-Bridge'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de contrôle
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL',
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com',
                        ),
                        onSubmitted: (_) => _loadUrl(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loadUrl,
                      child: const Text('Charger'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isInitialized = false;
                          _status = 'Réinitialisation...';
                        });
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: $_status',
                  style: TextStyle(
                    color: _isInitialized ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Zone de rendu CEF
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: _isInitialized
                  ? QuantumBrowser(
                      initialUrl: _urlController.text,
                      enableEffects: true,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text('Initialisation du moteur CEF...'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isInitialized = true;
                                _status = 'Initialisé';
                              });
                            },
                            child: const Text('Démarrer CEF'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

