import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import '../../services/terminal_manager.dart';
import '../../models/tab_model.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';

/// Vue terminal intégrée dans Notilus (style VSCode)
class GXTerminalView extends StatefulWidget {
  final TabModel tab;

  const GXTerminalView({
    super.key,
    required this.tab,
  });

  @override
  State<GXTerminalView> createState() => _GXTerminalViewState();
}

class _GXTerminalViewState extends State<GXTerminalView> {
  late Terminal _terminal;
  TerminalSession? _session;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
  }

  @override
  void didUpdateWidget(GXTerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      _disposeSession();
      _initializeTerminal();
    }
  }

  Future<void> _initializeTerminal() async {
    // Créer le terminal xterm
    _terminal = Terminal(
      maxLines: 10000,
    );

    // Obtenir ou créer la session terminal
    final terminalManager = Provider.of<TerminalManager>(context, listen: false);
    _session = terminalManager.getSessionForTab(widget.tab.id);

    // Attendre que la session soit initialisée
    int retries = 0;
    while (!_session!.isInitialized && retries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (!_session!.isInitialized) {
      if (mounted) {
        _terminal.write('\r\n❌ Erreur: Impossible d\'initialiser le terminal\r\n');
      }
      setState(() {
        _isInitialized = true;
      });
      return;
    }

    // Écouter la sortie du terminal
    _session!.output.listen(
      (data) {
        if (mounted) {
          _terminal.write(data);
        }
      },
      onError: (error) {
        if (mounted) {
          _terminal.write('\r\n❌ Erreur: $error\r\n');
        }
      },
    );

    // Configurer le callback d'écriture du terminal (input utilisateur)
    _terminal.onOutput = (data) async {
      if (_session != null && _session!.isInitialized) {
        await _session!.write(data);
      } else {
        debugPrint('⚠️ Session not ready, cannot write: $data');
      }
    };

    // Écrire un message de bienvenue
    _terminal.write('\r\n\x1b[32m✅ Terminal Notilus initialisé\x1b[0m\r\n');
    _terminal.write('\x1b[36mTapez vos commandes ici...\x1b[0m\r\n\r\n');

    setState(() {
      _isInitialized = true;
    });
  }

  void _disposeSession() {
    // Ne pas fermer la session ici, elle sera gérée par TerminalManager
    // lors de la fermeture de l'onglet
  }

  @override
  void dispose() {
    _disposeSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallpaperManager = context.watch<WallpaperManager>();

    if (!_isInitialized) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(wallpaperManager.current),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.85),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Provider.of<ColorThemeManager>(context, listen: false).nativeSecondaryColor,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.85),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        padding: const EdgeInsets.all(16),
        child: Focus(
          autofocus: true,
          child: TerminalView(_terminal),
        ),
      ),
    );
  }
}

