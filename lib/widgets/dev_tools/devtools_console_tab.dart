import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../models/devtools_models.dart';
import '../../services/notilus_devtools_service.dart';

/// Onglet Console avec logs et REPL
class DevToolsConsoleTab extends StatefulWidget {
  const DevToolsConsoleTab({super.key});

  @override
  State<DevToolsConsoleTab> createState() => _DevToolsConsoleTabState();
}

class _DevToolsConsoleTabState extends State<DevToolsConsoleTab> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  
  LogLevel? _filterLevel;
  String _searchQuery = '';
  final List<String> _commandHistory = [];
  int _historyIndex = -1;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeCommand() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    _commandHistory.add(input);
    _historyIndex = _commandHistory.length;
    _inputController.clear();

    final devTools = context.read<NotilusDevToolsService>();
    await devTools.executeCommand(input);
    _scrollToBottom();
  }

  void _navigateHistory(bool up) {
    if (_commandHistory.isEmpty) return;
    
    if (up) {
      if (_historyIndex > 0) {
        _historyIndex--;
        _inputController.text = _commandHistory[_historyIndex];
        _inputController.selection = TextSelection.collapsed(
          offset: _inputController.text.length,
        );
      }
    } else {
      if (_historyIndex < _commandHistory.length - 1) {
        _historyIndex++;
        _inputController.text = _commandHistory[_historyIndex];
        _inputController.selection = TextSelection.collapsed(
          offset: _inputController.text.length,
        );
      } else {
        _historyIndex = _commandHistory.length;
        _inputController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;
    
    return Column(
      children: [
        // Toolbar
        _buildToolbar(accentColor),
        
        // Logs list
        Expanded(
          child: Consumer<NotilusDevToolsService>(
            builder: (context, devTools, _) {
              final logs = _filterLevel != null || _searchQuery.isNotEmpty
                  ? devTools.filterLogs(level: _filterLevel, search: _searchQuery)
                  : devTools.logs;
              
              if (logs.isEmpty) {
                return _buildEmptyState(accentColor);
              }
              
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return _LogEntryWidget(log: logs[index]);
                },
              );
            },
          ),
        ),
        
        // REPL Input
        _buildReplInput(accentColor),
      ],
    );
  }

  Widget _buildToolbar(Color accentColor) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Filtres par niveau
          _FilterChip(
            label: 'All',
            isSelected: _filterLevel == null,
            onTap: () => setState(() => _filterLevel = null),
            color: Colors.white,
          ),
          _FilterChip(
            label: 'Info',
            isSelected: _filterLevel == LogLevel.info,
            onTap: () => setState(() => _filterLevel = LogLevel.info),
            color: const Color(0xFF64B5F6),
          ),
          _FilterChip(
            label: 'Warn',
            isSelected: _filterLevel == LogLevel.warning,
            onTap: () => setState(() => _filterLevel = LogLevel.warning),
            color: const Color(0xFFFFB74D),
          ),
          _FilterChip(
            label: 'Error',
            isSelected: _filterLevel == LogLevel.error,
            onTap: () => setState(() => _filterLevel = LogLevel.error),
            color: const Color(0xFFEF5350),
          ),
          
          const SizedBox(width: 8),
          
          // Recherche
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'JetBrains Mono',
                  color: Colors.white70,
                ),
                decoration: InputDecoration(
                  hintText: 'Filtrer...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  isDense: true,
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: 12,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 22,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Clear button
          _ToolbarButton(
            icon: CupertinoIcons.trash,
            tooltip: 'Vider la console',
            onTap: () {
              context.read<NotilusDevToolsService>().clearLogs();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.text_cursor,
            size: 48,
            color: accentColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Console prête',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tapez "help" pour voir les commandes',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplInput(Color accentColor) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(
          top: BorderSide(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Prompt
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '›',
              style: TextStyle(
                color: accentColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          
          // Input field
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
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
                  fontFamily: 'JetBrains Mono',
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Entrez une commande...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: (_) => _executeCommand(),
              ),
            ),
          ),
          
          // Execute button
          GestureDetector(
            onTap: _executeCommand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: accentColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                'Exécuter',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une entrée de log
class _LogEntryWidget extends StatelessWidget {
  final LogEntry log;

  const _LogEntryWidget({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: log.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: log.color.withOpacity(0.6),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          SizedBox(
            width: 70,
            child: Text(
              _formatTime(log.timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          
          // Level badge
          Container(
            width: 42,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: log.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              log.levelLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: log.color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          
          // Message
          Expanded(
            child: SelectableText(
              log.message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
                height: 1.4,
              ),
            ),
          ),
          
          // Source si présent
          if (log.source != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                log.source!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 9,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

/// Chip de filtre
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }
}

/// Bouton de toolbar
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
