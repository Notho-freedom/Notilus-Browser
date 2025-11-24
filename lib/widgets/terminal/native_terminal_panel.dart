import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/native_terminal_service.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/constants/notilus_colors.dart';

/// Panneau terminal natif avec UI Flutter custom (sans xterm)
class NativeTerminalPanel extends StatefulWidget {
  final String? sessionId;
  final String? host;
  final String? user;
  final String? password;
  final bool useSSH;

  const NativeTerminalPanel({
    super.key,
    this.sessionId,
    this.host,
    this.user,
    this.password,
    this.useSSH = false,
  });

  @override
  State<NativeTerminalPanel> createState() => _NativeTerminalPanelState();
}

class _NativeTerminalPanelState extends State<NativeTerminalPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _outputLines = [];
  NativeTerminalSession? _session;
  bool _isInitialized = false;
  String _currentPrompt = '> ';

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    final service = Provider.of<NativeTerminalService>(context, listen: false);
    final sessionId = widget.sessionId ?? 'terminal_${DateTime.now().millisecondsSinceEpoch}';

    _session = service.createSession(
      sessionId,
      host: widget.host,
      user: widget.user,
      password: widget.password,
      useSSH: widget.useSSH,
    );

    await _session!.initialize();

    // Attendre que le shell soit prêt (important pour PowerShell)
    await Future.delayed(const Duration(milliseconds: 300));

    // Écouter la sortie
    _session!.output.listen(
      (data) {
        if (mounted) {
          setState(() {
            // Ajouter les lignes une par une pour éviter les problèmes de formatage
            final lines = data.split('\n');
            for (var line in lines) {
              if (line.isNotEmpty || _outputLines.isEmpty || _outputLines.last.isNotEmpty) {
                _outputLines.add(line);
              }
            }
            // Limiter à 10000 lignes pour la performance
            if (_outputLines.length > 10000) {
              _outputLines.removeRange(0, _outputLines.length - 10000);
            }
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _outputLines.add('❌ Erreur: $error');
          });
        }
      },
    );

    setState(() {
      _isInitialized = true;
    });

    // Envoyer une commande vide pour initialiser le prompt PowerShell
    await Future.delayed(const Duration(milliseconds: 200));
    _session?.writeLine('');
  }

  void _addOutputLine(String line) {
    setState(() {
      _outputLines.add(line);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendCommand(String command) {
    if (command.trim().isEmpty) return;

    // Afficher la commande dans l'output
    _addOutputLine('$_currentPrompt$command');

    // Envoyer au terminal
    _session?.writeLine(command);

    // Effacer l'input
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallpaperManager = context.watch<WallpaperManager>();

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
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: NotilusColors.neonRed.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.square_list,
                    color: NotilusColors.neonRed,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.useSSH && widget.host != null
                          ? 'SSH: ${widget.user ?? "user"}@${widget.host}'
                          : 'Terminal Local',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isInitialized
                          ? const Color(0xFF34C759).withOpacity(0.2)
                          : const Color(0xFFFF9500).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isInitialized ? 'ACTIF' : 'CONNEXION...',
                      style: TextStyle(
                        color: _isInitialized ? const Color(0xFF34C759) : const Color(0xFFFF9500),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Zone de sortie
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _isInitialized
                    ? _buildOutputArea(theme)
                    : const Center(
                        child: CircularProgressIndicator(
                          color: NotilusColors.neonRed,
                        ),
                      ),
              ),
            ),
            // Zone de saisie
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                    color: NotilusColors.neonRed.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: _buildInputArea(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: NotilusColors.neonRed.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Scrollbar(
        thickness: 2,
        radius: const Radius.circular(1),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: _outputLines.length,
          itemBuilder: (context, index) {
            final line = _outputLines[index];
            final isError = line.startsWith('❌') || line.startsWith('ERROR');
            final isSuccess = line.startsWith('✅');
            final isCommand = line.startsWith('> ') || line.startsWith(r'$ ');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SelectableText(
                line,
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 13,
                  color: isError
                      ? const Color(0xFFFF3B30)
                      : isSuccess
                          ? const Color(0xFF34C759)
                          : isCommand
                              ? NotilusColors.neonRed
                              : Colors.white70,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Row(
      children: [
        Text(
          _currentPrompt,
          style: const TextStyle(
            fontFamily: 'Courier New',
            fontSize: 13,
            color: NotilusColors.neonRed,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _inputController,
            autofocus: true,
            style: const TextStyle(
              fontFamily: 'Courier New',
              fontSize: 13,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Entrez une commande...',
              hintStyle: TextStyle(
                color: Colors.white38,
              ),
            ),
            onSubmitted: _sendCommand,
          ),
        ),
        IconButton(
          icon: const Icon(
            CupertinoIcons.arrow_right_circle_fill,
            color: NotilusColors.neonRed,
          ),
          onPressed: () => _sendCommand(_inputController.text),
          tooltip: 'Exécuter',
        ),
      ],
    );
  }
}

