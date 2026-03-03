import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/backend_lab/backend_lab_service.dart';
import '../services/backend_process_service.dart';
import '../widgets/browser/modern_browser_window.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ModernBrowserWindow(),
          Consumer<BackendProcessService>(
            builder: (context, backend, _) {
              if (backend.isRunning || backend.isStarting) {
                return const SizedBox.shrink();
              }

              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: const Color(0xFF2E1E00),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFFC107)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Le backend ne s\'est pas lancé automatiquement: fonctionnalités limitées.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFFFFE082),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final backendLab =
                                  context.read<BackendLabService>();
                              final launched =
                                  await backend.launchExecutableDirectly();
                              if (launched) {
                                await backendLab.runStartupScanIfNeeded();
                              }
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    launched
                                        ? 'Lancement manuel backend effectué'
                                        : 'Échec du lancement manuel backend',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text('Lancement manuel'),
                          ),
                          TextButton(
                            onPressed: () {
                              backend.start();
                            },
                            child: const Text('Relancer backend'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: backend.diagnosticSummary),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Diagnostic backend copié'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text('Copier diagnostic'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
