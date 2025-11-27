import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/terminal_service.dart';
import '../../services/settings_service.dart';
import 'native_terminal_panel.dart';
import 'gx_terminal_view.dart';
import '../../models/tab_model.dart';

/// Panneau pour afficher un terminal dans la sidemenu
/// Utilise soit NativeTerminalPanel soit GXTerminalView selon les paramètres
class TerminalPanel extends StatefulWidget {
  const TerminalPanel({super.key});

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final terminalService = Provider.of<TerminalService>(context);
    final terminal = terminalService.selectedTerminal;
    
    // Si aucun terminal sélectionné, afficher un message
    if (terminal == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Aucun terminal sélectionné',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez un terminal dans les paramètres',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    // Utiliser le type d'interface sélectionné
    if (settings.terminalInterfaceType == 'xterm') {
      // Pour xterm, on a besoin d'un TabModel
      // Créer un tab temporaire pour le terminal
      final tab = TabModel(
        id: 'terminal_${terminal.id}',
        title: terminal.name,
        url: null,
        favicon: null,
        state: TabState.loading,
      );
      return GXTerminalView(tab: tab);
    } else {
      // Interface native Notilus
      return const NativeTerminalPanel();
    }
  }
}

