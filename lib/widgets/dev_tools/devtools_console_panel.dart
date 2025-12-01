/// Panneau Console du DevTools natif Notilus
/// - Multilines collapsées par défaut, expand au clic
/// - Utilise la couleur secondaire du thème
library devtools_console_panel;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/devtools_models.dart';
import '../../services/devtools_service.dart';
import '../../core/services/color_theme_manager.dart';

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

    _commandHistory.add(command);
    _historyIndex = _commandHistory.length;

    final devTools = context.read<DevToolsService>();
    await devTools.executeScript(command);

    _inputController.clear();

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
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<DevToolsService>(
      builder: (context, devTools, _) {
        final logs = devTools.consoleLogs;

        return Container(
          color: const Color(0xFF0D0D12),
          child: Column(
            children: [
              _buildToolbar(devTools, accentColor),
              Expanded(
                child: logs.isEmpty
                    ? _buildEmptyState()
                    : _buildLogsList(logs, accentColor),
              ),
              _buildInput(accentColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(DevToolsService devTools, Color accentColor) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(
          bottom: BorderSide(color: accentColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.block_outlined,
            tooltip: 'Effacer la console',
            accentColor: accentColor,
            onPressed: devTools.clearConsole,
          ),
          const SizedBox(width: 4),

          ...ConsoleLevel.values.map((level) {
            final isEnabled = devTools.enabledConsoleLevels.contains(level);
            final count = devTools.consoleLogs.where((l) => l.level == level).length;

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

          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontFamily: 'JetBrains Mono',
              ),
              decoration: InputDecoration(
                hintText: 'Filtrer...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 14, color: Colors.white.withOpacity(0.3)),
                prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 24),
              ),
              onChanged: devTools.setConsoleFilter,
            ),
          ),

          const SizedBox(width: 8),

          _ToolbarButton(
            icon: _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
            tooltip: _autoScroll ? 'Défilement auto activé' : 'Défilement auto désactivé',
            isActive: _autoScroll,
            accentColor: accentColor,
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
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
          Icon(Icons.terminal_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text('Console vide', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
          const SizedBox(height: 4),
          Text('Les logs JavaScript apparaîtront ici', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<ConsoleEntry> logs, Color accentColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _CollapsibleLogEntry(
          entry: log,
          accentColor: accentColor,
          onCopy: () {
            Clipboard.setData(ClipboardData(text: log.message));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Copié dans le presse-papiers'),
                backgroundColor: accentColor.withOpacity(0.9),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(top: BorderSide(color: accentColor.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.chevron_right, size: 18, color: accentColor),
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
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onSubmitted: (_) => _executeCommand(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: _executeCommand,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 16, color: accentColor),
                    const SizedBox(width: 4),
                    Text('Exécuter', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600)),
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
  final Color accentColor;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.accentColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? accentColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: isActive ? accentColor : Colors.white.withOpacity(0.6),
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
            border: Border.all(color: isSelected ? color.withOpacity(0.5) : Colors.transparent),
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

/// Log entry avec collapse/expand pour les messages multilignes
class _CollapsibleLogEntry extends StatefulWidget {
  final ConsoleEntry entry;
  final Color accentColor;
  final VoidCallback onCopy;

  const _CollapsibleLogEntry({
    required this.entry,
    required this.accentColor,
    required this.onCopy,
  });

  @override
  State<_CollapsibleLogEntry> createState() => _CollapsibleLogEntryState();
}

class _CollapsibleLogEntryState extends State<_CollapsibleLogEntry> {
  bool _isExpanded = false;

  bool get _isMultiline => widget.entry.message.contains('\n') || widget.entry.message.length > 100;

  String get _previewText {
    final msg = widget.entry.message;
    if (msg.contains('\n')) {
      return '${msg.split('\n').first}...';
    }
    if (msg.length > 100) {
      return '${msg.substring(0, 100)}...';
    }
    return msg;
  }

  int get _lineCount => widget.entry.message.split('\n').length;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isMultiline ? () => setState(() => _isExpanded = !_isExpanded) : null,
        onSecondaryTap: widget.onCopy,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03))),
            color: widget.entry.level == ConsoleLevel.error
                ? Colors.red.withOpacity(0.05)
                : widget.entry.level == ConsoleLevel.warn
                    ? Colors.orange.withOpacity(0.03)
                    : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expand/collapse icon pour multilines
              if (_isMultiline)
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 14,
                      color: widget.accentColor.withOpacity(0.7),
                    ),
                  ),
                )
              else
                const SizedBox(width: 18),

              // Icône niveau
              Icon(widget.entry.level.icon, size: 14, color: widget.entry.level.color),
              const SizedBox(width: 8),

              // Timestamp
              Text(
                widget.entry.formattedTime,
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
                    // Message principal (collapsé ou expanded)
                    SelectableText(
                      _isExpanded || !_isMultiline ? widget.entry.message : _previewText,
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.entry.level.color,
                        fontFamily: 'JetBrains Mono',
                        height: 1.4,
                      ),
                    ),

                    // Badge nombre de lignes si collapsed
                    if (_isMultiline && !_isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_lineCount lignes',
                            style: TextStyle(
                              fontSize: 9,
                              color: widget.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Stack trace si erreur et expanded
                    if (widget.entry.stackTrace != null &&
                        widget.entry.level == ConsoleLevel.error &&
                        _isExpanded) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          widget.entry.stackTrace!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.withOpacity(0.7),
                            fontFamily: 'JetBrains Mono',
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],

                    // Source location
                    if (widget.entry.sourceLocation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.entry.sourceLocation,
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
                  onTap: widget.onCopy,
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
