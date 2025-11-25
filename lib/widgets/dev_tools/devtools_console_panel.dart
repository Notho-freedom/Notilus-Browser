/// Panneau Console du DevTools natif Notilus
library devtools_console_panel;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/devtools_models.dart';
import '../../services/devtools_service.dart';
import '../../core/constants/notilus_colors.dart';

class DevToolsConsolePanel extends StatefulWidget {
  const DevToolsConsolePanel({super.key});

  @override
  State<DevToolsConsolePanel> createState() => _DevToolsConsolePanelState();
}

class _DevToolsConsolePanelState extends State<DevToolsConsolePanel> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  bool _autoScroll = true;

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _executeCommand() async {
    final command = _inputController.text.trim();
    if (command.isEmpty) return;

    // Ajouter à l'historique
    _commandHistory.add(command);
    _historyIndex = _commandHistory.length;

    // Exécuter
    final devTools = context.read<DevToolsService>();
    await devTools.executeScript(command);

    // Vider l'input
    _inputController.clear();

    // Scroll vers le bas
    if (_autoScroll) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _navigateHistory(bool up) {
    if (_commandHistory.isEmpty) return;

    setState(() {
      if (up) {
        if (_historyIndex > 0) {
          _historyIndex--;
          _inputController.text = _commandHistory[_historyIndex];
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        }
      } else {
        if (_historyIndex < _commandHistory.length - 1) {
          _historyIndex++;
          _inputController.text = _commandHistory[_historyIndex];
        } else {
          _historyIndex = _commandHistory.length;
          _inputController.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DevToolsService>(
      builder: (context, devTools, _) {
        final logs = devTools.consoleLogs;

        return Container(
          color: const Color(0xFF0D0D12),
          child: Column(
            children: [
              // Toolbar
              _buildToolbar(devTools),

              // Liste des logs
              Expanded(
                child: logs.isEmpty
                    ? _buildEmptyState()
                    : _buildLogsList(logs),
              ),

              // Input
              _buildInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(DevToolsService devTools) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(
          bottom: BorderSide(
            color: NotilusColors.neonRed.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Bouton effacer
          _ToolbarButton(
            icon: Icons.block_outlined,
            tooltip: 'Effacer la console',
            onPressed: devTools.clearConsole,
          ),
          const SizedBox(width: 4),

          // Filtre par niveau
          ...ConsoleLevel.values.map((level) {
            final isEnabled = devTools.enabledConsoleLevels.contains(level);
            final count = devTools.consoleLogs
                .where((l) => l.level == level)
                .length;

            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: _FilterChip(
                label: '${level.prefix}${count > 0 ? ' ($count)' : ''}',
                color: level.color,
                isSelected: isEnabled,
                onTap: () => devTools.toggleConsoleLevel(level),
              ),
            );
          }),

          const Spacer(),

          // Filtre texte
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: TextField(
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontFamily: 'JetBrains Mono',
              ),
              decoration: InputDecoration(
                hintText: 'Filtrer...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                isDense: true,
                prefixIcon: Icon(
                  Icons.search,
                  size: 14,
                  color: Colors.white.withOpacity(0.3),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 24,
                ),
              ),
              onChanged: devTools.setConsoleFilter,
            ),
          ),

          const SizedBox(width: 8),

          // Toggle auto-scroll
          _ToolbarButton(
            icon: _autoScroll
                ? Icons.vertical_align_bottom
                : Icons.vertical_align_center,
            tooltip: _autoScroll
                ? 'Défilement auto activé'
                : 'Défilement auto désactivé',
            isActive: _autoScroll,
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.terminal_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'Console vide',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Les logs JavaScript apparaîtront ici',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<ConsoleEntry> logs) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _LogEntry(
          entry: log,
          onCopy: () {
            Clipboard.setData(ClipboardData(text: log.message));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Copié dans le presse-papiers'),
                backgroundColor: NotilusColors.neonRed.withOpacity(0.9),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(
          top: BorderSide(
            color: NotilusColors.neonRed.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.chevron_right,
            size: 18,
            color: NotilusColors.neonRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _navigateHistory(true);
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _navigateHistory(false);
                  }
                }
              },
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontFamily: 'JetBrains Mono',
                ),
                decoration: InputDecoration(
                  hintText: 'Exécuter JavaScript...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                    fontFamily: 'JetBrains Mono',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: (_) => _executeCommand(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: NotilusColors.neonRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: _executeCommand,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: NotilusColors.neonRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Exécuter',
                      style: TextStyle(
                        color: NotilusColors.neonRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? NotilusColors.neonRed.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: isActive
                  ? NotilusColors.neonRed
                  : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : Colors.white.withOpacity(0.4),
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final ConsoleEntry entry;
  final VoidCallback onCopy;

  const _LogEntry({
    required this.entry,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        onSecondaryTap: onCopy,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.03),
              ),
            ),
            color: entry.level == ConsoleLevel.error
                ? Colors.red.withOpacity(0.05)
                : entry.level == ConsoleLevel.warn
                    ? Colors.orange.withOpacity(0.03)
                    : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône niveau
              Icon(
                entry.level.icon,
                size: 14,
                color: entry.level.color,
              ),
              const SizedBox(width: 8),

              // Timestamp
              Text(
                entry.formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(width: 12),

              // Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      entry.message,
                      style: TextStyle(
                        fontSize: 11,
                        color: entry.level.color,
                        fontFamily: 'JetBrains Mono',
                        height: 1.4,
                      ),
                    ),
                    if (entry.stackTrace != null &&
                        entry.level == ConsoleLevel.error) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          entry.stackTrace!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.withOpacity(0.7),
                            fontFamily: 'JetBrains Mono',
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                    if (entry.sourceLocation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.sourceLocation,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.2),
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bouton copier
              Tooltip(
                message: 'Copier',
                child: InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_outlined,
                      size: 12,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
