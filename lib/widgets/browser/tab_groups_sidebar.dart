import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../core/utils/theme_extensions.dart';
import '../../widgets/common/neon_button.dart';
import 'tab_group_view.dart';
import 'tab_group_dialog.dart';

class TabGroupsSidebar extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onClose;

  const TabGroupsSidebar({
    super.key,
    this.isVisible = false,
    this.onClose,
  });

  @override
  State<TabGroupsSidebar> createState() => _TabGroupsSidebarState();
}

class _TabGroupsSidebarState extends State<TabGroupsSidebar> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: customTheme.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              border: Border(
                bottom: BorderSide(
                  color: context.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Groupes d\'onglets',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _showCreateGroupDialog(context),
                  color: theme.colorScheme.primary,
                  tooltip: 'Nouveau groupe',
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onClose,
                    color: context.textSecondaryColor,
                    tooltip: 'Fermer',
                  ),
              ],
            ),
          ),
          
          // Groups list
          Expanded(
            child: Consumer<TabManager>(
              builder: (context, tabManager, _) {
                if (tabManager.groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 48,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun groupe',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        NeonButton(
                          text: 'Créer un groupe',
                          variant: NeonButtonVariant.primary,
                          onPressed: () => _showCreateGroupDialog(context),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: tabManager.groups.length,
                  itemBuilder: (context, index) {
                    final group = tabManager.groups[index];
                    return TabGroupView(
                      group: group,
                      onDelete: () {
                        tabManager.deleteGroup(group.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => TabGroupDialog(
        onCreate: (group) {
          tabManager.createGroup(group.name, group.color, icon: group.icon);
        },
      ),
    );
  }
}

