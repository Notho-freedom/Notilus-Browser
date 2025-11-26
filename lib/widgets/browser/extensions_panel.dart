import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/theme_extensions.dart';
import '../../services/extension_service.dart';
import '../../models/extension.dart';
import '../../widgets/common/glassmorphic_container.dart';
import '../../widgets/common/neon_button.dart';
import '../../core/services/color_theme_manager.dart';
import 'package:provider/provider.dart';

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
    final accentColor = Provider.of<ColorThemeManager>(context, listen: false).nativeSecondaryColor;
    
    showDialog(
      context: context,
      builder: (context) => _InstallExtensionDialog(accentColor: accentColor),
    );
  }
}

class _InstallExtensionDialog extends StatefulWidget {
  final Color accentColor;

  const _InstallExtensionDialog({required this.accentColor});

  @override
  State<_InstallExtensionDialog> createState() => _InstallExtensionDialogState();
}

class _InstallExtensionDialogState extends State<_InstallExtensionDialog> {
  final ExtensionService _extensionService = ExtensionService();
  final TextEditingController _urlController = TextEditingController();
  bool _isInstalling = false;
  String? _errorMessage;
  String _installMethod = 'file'; // 'file' or 'url'

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _installFromFile() async {
    setState(() {
      _isInstalling = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Sélectionner le fichier manifest.json',
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileContent = utf8.decode(fileBytes);

        try {
          final manifest = jsonDecode(fileContent) as Map<String, dynamic>;
          final extension = await _extensionService.installFromManifest(manifest);
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Extension "${extension.name}" installée'),
                backgroundColor: widget.accentColor,
              ),
            );
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Erreur lors du parsing du manifest: $e';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection du fichier: $e';
      });
    } finally {
      setState(() {
        _isInstalling = false;
      });
    }
  }

  Future<void> _installFromUrl() async {
    if (_urlController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer une URL';
      });
      return;
    }

    setState(() {
      _isInstalling = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(_urlController.text));
      
      if (response.statusCode == 200) {
        try {
          final manifest = jsonDecode(response.body) as Map<String, dynamic>;
          final extension = await _extensionService.installFromManifest(manifest);
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Extension "${extension.name}" installée'),
                backgroundColor: widget.accentColor,
              ),
            );
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Erreur lors du parsing du manifest: $e';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du téléchargement: $e';
      });
    } finally {
      setState(() {
        _isInstalling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(CupertinoIcons.square_grid_2x2, color: widget.accentColor, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Installer une extension',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection méthode
            Row(
              children: [
                Expanded(
                  child: _MethodButton(
                    label: 'Fichier',
                    icon: CupertinoIcons.doc,
                    isSelected: _installMethod == 'file',
                    accentColor: widget.accentColor,
                    onTap: () => setState(() => _installMethod = 'file'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MethodButton(
                    label: 'URL',
                    icon: CupertinoIcons.link,
                    isSelected: _installMethod == 'url',
                    accentColor: widget.accentColor,
                    onTap: () => setState(() => _installMethod = 'url'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Contenu selon méthode
            if (_installMethod == 'file') ...[
              Text(
                'Sélectionnez un fichier manifest.json',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isInstalling ? null : _installFromFile,
                icon: _isInstalling
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(widget.accentColor),
                        ),
                      )
                    : Icon(CupertinoIcons.folder, size: 16),
                label: Text(_isInstalling ? 'Installation...' : 'Choisir un fichier'),
                style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
              ),
            ] else ...[
              Text(
                'Entrez l\'URL du manifest.json',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://example.com/manifest.json',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.accentColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isInstalling ? null : _installFromUrl,
                style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isInstalling)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    else
                      const Icon(CupertinoIcons.arrow_down_circle, size: 16),
                    const SizedBox(width: 8),
                    Text(_isInstalling ? 'Installation...' : 'Installer depuis URL'),
                  ],
                ),
              ),
            ],
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: TextStyle(color: Colors.white.withOpacity(0.6))),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _MethodButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? accentColor : Colors.white.withOpacity(0.5), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

