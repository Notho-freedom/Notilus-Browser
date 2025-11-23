import 'package:flutter/material.dart';
import '../../core/utils/theme_extensions.dart';
import '../../widgets/common/glassmorphic_container.dart';
import '../../widgets/common/neon_button.dart';

enum DevToolsTab { console, network, performance, elements, sources, application }

class DevToolsPanel extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onClose;

  const DevToolsPanel({
    super.key,
    this.isVisible = false,
    this.onClose,
  });

  @override
  State<DevToolsPanel> createState() => _DevToolsPanelState();
}

class _DevToolsPanelState extends State<DevToolsPanel> {
  DevToolsTab _activeTab = DevToolsTab.console;
  final Map<DevToolsTab, String> _tabLabels = {
    DevToolsTab.console: 'Console',
    DevToolsTab.network: 'Network',
    DevToolsTab.performance: 'Performance',
    DevToolsTab.elements: 'Elements',
    DevToolsTab.sources: 'Sources',
    DevToolsTab.application: 'Application',
  };

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.border ?? Colors.grey.shade800,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // Tab bar
          Container(
            height: 40,
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
                // Tabs
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _tabLabels.entries.map((entry) {
                      final isActive = _activeTab == entry.key;
                      return GestureDetector(
                        onTap: () => setState(() => _activeTab = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.primary.withOpacity(0.2)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.textSecondary,
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontFamily: 'Roboto Mono',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                // Close button
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onClose,
                    color: context.textSecondaryColor,
                    tooltip: 'Fermer DevTools',
                  ),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: _buildTabContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    switch (_activeTab) {
      case DevToolsTab.console:
        return _buildConsoleTab(theme);
      case DevToolsTab.network:
        return _buildNetworkTab(theme);
      case DevToolsTab.performance:
        return _buildPerformanceTab(theme);
      case DevToolsTab.elements:
        return _buildElementsTab(theme);
      case DevToolsTab.sources:
        return _buildSourcesTab(theme);
      case DevToolsTab.application:
        return _buildApplicationTab(theme);
    }
  }

  Widget _buildConsoleTab(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Console',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassmorphicContainer(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '> Console prête\n> Les logs apparaîtront ici\n> Intégration CEF à venir',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Roboto Mono',
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: theme.textTheme.bodySmall,
                  decoration: InputDecoration(
                    hintText: 'Entrer une commande...',
                    hintStyle: TextStyle(
                      color: context.textSecondaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: context.borderColor,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NeonButton(
                text: 'Exécuter',
                variant: NeonButtonVariant.primary,
                onPressed: () {},
                height: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTab(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassmorphicContainer(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Requêtes réseau\nLes requêtes HTTP apparaîtront ici\nIntégration CEF à venir',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Roboto Mono',
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassmorphicContainer(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Métriques de performance\nGraphiques et statistiques\nIntégration CEF à venir',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Roboto Mono',
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementsTab(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elements',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassmorphicContainer(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Inspecteur DOM\nArborescence HTML\nIntégration CEF à venir',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Roboto Mono',
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesTab(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sources',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassmorphicContainer(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Éditeur de sources\nFichiers JS/CSS\nIntégration CEF à venir',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Roboto Mono',
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationTab(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassmorphicContainer(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Storage, Cookies, Cache\nInformations d\'application\nIntégration CEF à venir',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Roboto Mono',
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

