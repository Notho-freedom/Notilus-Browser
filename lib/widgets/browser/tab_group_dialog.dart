import 'package:flutter/material.dart';
import '../../models/tab_group_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/glassmorphic_container.dart';
import '../../widgets/common/neon_button.dart';

class TabGroupDialog extends StatefulWidget {
  final TabGroupModel? existingGroup;
  final Function(TabGroupModel) onCreate;

  const TabGroupDialog({
    super.key,
    this.existingGroup,
    required this.onCreate,
  });

  @override
  State<TabGroupDialog> createState() => _TabGroupDialogState();
}

class _TabGroupDialogState extends State<TabGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedColor = '#FF0040';
  String? _selectedIcon;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Rouge', 'value': '#FF0040'},
    {'name': 'Bleu', 'value': '#00D4FF'},
    {'name': 'Vert', 'value': '#00FF88'},
    {'name': 'Violet', 'value': '#BD93F9'},
    {'name': 'Orange', 'value': '#FFAA00'},
    {'name': 'Rose', 'value': '#FF3366'},
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'work', 'icon': Icons.work},
    {'name': 'shopping', 'icon': Icons.shopping_cart},
    {'name': 'entertainment', 'icon': Icons.movie},
    {'name': 'social', 'icon': Icons.people},
    {'name': 'dev', 'icon': Icons.code},
    {'name': 'folder', 'icon': Icons.folder},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingGroup != null) {
      _nameController.text = widget.existingGroup!.name;
      _selectedColor = widget.existingGroup!.color;
      _selectedIcon = widget.existingGroup!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFFF0040);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeFromContext();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicContainer(
        width: 400,
        padding: const EdgeInsets.all(24),
        showNeonBorder: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingGroup != null
                  ? 'Modifier le groupe'
                  : 'Nouveau groupe d\'onglets',
              style: TextStyle(
                color: theme.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto Mono',
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Name input
            TextField(
              controller: _nameController,
              style: TextStyle(
                color: theme.text,
                fontFamily: 'Roboto Mono',
              ),
              decoration: InputDecoration(
                labelText: 'Nom du groupe',
                labelStyle: TextStyle(color: theme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.primary, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Color selection
            Text(
              'Couleur',
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontFamily: 'Roboto Mono',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color['value']),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(color['value']),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.primary : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.primary.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Icon selection
            Text(
              'Icône (optionnel)',
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontFamily: 'Roboto Mono',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                // No icon option
                GestureDetector(
                  onTap: () => setState(() => _selectedIcon = null),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedIcon == null
                          ? theme.primary.withOpacity(0.2)
                          : theme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedIcon == null
                            ? theme.primary
                            : theme.border,
                        width: _selectedIcon == null ? 2 : 1,
                      ),
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
                ..._icons.map((icon) {
                  final isSelected = _selectedIcon == icon['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon['name']),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primary.withOpacity(0.2)
                            : theme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? theme.primary : theme.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon['icon'] as IconData,
                        color: isSelected ? theme.primary : theme.text,
                        size: 20,
                      ),
                    ),
                  );
                }),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                NeonButton(
                  text: 'Annuler',
                  variant: NeonButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                NeonButton(
                  text: widget.existingGroup != null ? 'Modifier' : 'Créer',
                  variant: NeonButtonVariant.primary,
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      final group = widget.existingGroup != null
                          ? widget.existingGroup!.copyWith(
                              name: _nameController.text,
                              color: _selectedColor,
                              icon: _selectedIcon,
                            )
                          : TabGroupModel(
                              name: _nameController.text,
                              color: _selectedColor,
                              icon: _selectedIcon,
                            );
                      widget.onCreate(group);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppTheme _getThemeFromContext() {
    return const AppTheme(
      name: 'Default',
      background: Color(0xFF0D0D0D),
      surface: Color(0xFF1A1A1A),
      primary: Color(0xFFFF0040),
      secondary: Color(0xFFFF3366),
      accent: Color(0xFF00FF88),
      text: Color(0xFFE0E0E0),
      textSecondary: Color(0xFF888888),
      error: Color(0xFFFF0040),
      success: Color(0xFF00FF88),
      warning: Color(0xFFFFAA00),
      border: Color(0xFF333333),
      hover: Color(0xFF2A2A2A),
      selected: Color(0xFFFF0040),
    );
  }
}

