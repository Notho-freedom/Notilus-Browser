import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/terminal_service.dart';
import '../../services/tab_manager.dart';
import '../../models/terminal_model.dart';
import '../../models/tab_model.dart' show TabType;

/// Widget pour afficher la liste des terminaux dans la colonne gauche
class TerminalListWidget extends StatelessWidget {
  const TerminalListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final terminalService = Provider.of<TerminalService>(context);
    final tabManager = Provider.of<TabManager>(context, listen: false);

    // Initialiser le service si pas déjà fait
    if (terminalService.availableTerminals.isEmpty) {
      terminalService.initialize();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TERMINAUX',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFF2D55),
          ),
        ),
        const SizedBox(height: 16),
        // Section Terminaux Natifs
        _buildSection(
          context,
          title: 'Natif',
          terminals: terminalService.nativeTerminals,
          tabManager: tabManager,
        ),
        const SizedBox(height: 16),
        // Section Terminaux Isolés
        _buildSection(
          context,
          title: 'Isolé',
          terminals: terminalService.isolatedTerminals,
          tabManager: tabManager,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<TerminalModel> terminals,
    required TabManager tabManager,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        ...terminals.map((terminal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TerminalItem(
                terminal: terminal,
                onTap: () {
                  // Créer directement un onglet terminal
                  tabManager.createNewTab(type: TabType.terminal);
                },
              ),
            )),
      ],
    );
  }
}

/// Widget pour un item de terminal dans la liste
class _TerminalItem extends StatelessWidget {
  final TerminalModel terminal;
  final VoidCallback onTap;

  const _TerminalItem({
    required this.terminal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = terminal.isLocked;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isLocked
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFFF2D55).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFFF2D55).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isLocked ? CupertinoIcons.lock : terminal.icon,
                  size: 18,
                  color: isLocked
                      ? Colors.white.withValues(alpha: 0.3)
                      : const Color(0xFFFF2D55),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      terminal.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? Colors.white.withValues(alpha: 0.4)
                            : null,
                      ),
                    ),
                    Text(
                      terminal.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Icon(
                  CupertinoIcons.lock_fill,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

