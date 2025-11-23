import 'package:flutter/material.dart';
import '../../core/utils/theme_extensions.dart';
import '../../services/extension_service.dart';
import '../../models/extension.dart';
import '../../widgets/common/glassmorphic_container.dart';
import '../../widgets/common/neon_button.dart';

class ExtensionsPanel extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onClose;

  const ExtensionsPanel({
    super.key,
    this.isVisible = false,
    this.onClose,
  });

  @override
  State<ExtensionsPanel> createState() => _ExtensionsPanelState();
}

class _ExtensionsPanelState extends State<ExtensionsPanel> {
  final ExtensionService _extensionService = ExtensionService();

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final customTheme = context.customTheme;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
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
                  'Extensions',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                NeonButton(
                  text: '+',
                  variant: NeonButtonVariant.primary,
                  onPressed: () => _showInstallDialog(context),
                  width: 32,
                  height: 32,
                  padding: EdgeInsets.zero,
                ),
                if (widget.onClose != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onClose,
                    color: context.textSecondaryColor,
                    tooltip: 'Fermer',
                  ),
                ],
              ],
            ),
          ),
          
          // Extensions list
          Expanded(
            child: FutureBuilder<List<Extension>>(
              future: _extensionService.getExtensions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.extension,
                          size: 48,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune extension',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        NeonButton(
                          text: 'Installer une extension',
                          variant: NeonButtonVariant.primary,
                          onPressed: () => _showInstallDialog(context),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final extension = snapshot.data![index];
                    return _buildExtensionItem(context, theme, extension);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionItem(
      BuildContext context, ThemeData theme, Extension extension) {
    return GlassmorphicContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icon
          if (extension.icon != null)
            Image.network(
              extension.icon!,
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => Icon(
                Icons.extension,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            )
          else
            Icon(
              Icons.extension,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extension.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (extension.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    extension.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Text(
                  'v${extension.version}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Toggle
          Switch(
            value: extension.enabled,
            onChanged: (value) async {
              await _extensionService.toggleExtension(extension.id, value);
              setState(() {});
            },
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showInstallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Installer une extension',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        content: Text(
          'Fonctionnalité à venir : installation d\'extensions depuis un fichier manifest ou une URL.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

