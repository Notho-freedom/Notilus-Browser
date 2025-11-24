import 'dart:io';
import 'dart:convert' show utf8;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/terminal_service.dart';
import '../../core/services/wallpaper_manager.dart';

/// Panneau pour afficher un terminal dans la sidemenu
class TerminalPanel extends StatefulWidget {
  const TerminalPanel({super.key});

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  Process? _terminalProcess;
  String _output = '';
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
  }

  @override
  void dispose() {
    _terminalProcess?.kill();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeTerminal() async {
    final terminalService = Provider.of<TerminalService>(context, listen: false);
    final terminal = terminalService.selectedTerminal;

    if (terminal == null) {
      setState(() {
        _output = 'Aucun terminal sélectionné';
      });
      return;
    }

    try {
      // Lancer le processus terminal
      final process = await Process.start(
        terminal.command,
        terminal.args ?? [],
        runInShell: true,
        mode: ProcessStartMode.normal,
      );

      // Écouter la sortie
      process.stdout.transform(utf8.decoder).listen((data) {
        setState(() {
          _output += data;
        });
        // Scroll vers le bas
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        setState(() {
          _output += 'ERROR: $data';
        });
      });

      setState(() {
        _terminalProcess = process;
        _output = 'Terminal ${terminal.name} initialisé\n';
      });
    } catch (e) {
      setState(() {
        _output = 'Erreur lors du lancement du terminal: $e\n';
      });
    }
  }

  void _sendCommand(String command) {
    if (_terminalProcess == null) return;

    try {
      _terminalProcess!.stdin.writeln(command);
      _inputController.clear();
    } catch (e) {
      setState(() {
        _output += 'Erreur: $e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallpaperManager = context.watch<WallpaperManager>();
    final terminalService = Provider.of<TerminalService>(context);
    final terminal = terminalService.selectedTerminal;

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
            // Header du terminal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFFF2D55).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    terminal?.icon ?? CupertinoIcons.square_list,
                    color: const Color(0xFFFF2D55),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      terminal?.name ?? 'Terminal',
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
                      color: const Color(0xFF34C759).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ACTIF',
                      style: TextStyle(
                        color: Color(0xFF34C759),
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
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SelectableText(
                    _output.isEmpty ? 'Terminal prêt...\n' : _output,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Courier New',
                      fontSize: 12,
                      color: Colors.white,
                    ),
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
                    color: const Color(0xFFFF2D55).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '> ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Courier New',
                      fontSize: 12,
                      color: const Color(0xFFFF2D55),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Courier New',
                        fontSize: 12,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

