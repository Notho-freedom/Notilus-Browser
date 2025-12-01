import 'package:flutter/material.dart';
import '../../models/tab_group_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../widgets/common/gx_futuristic_dialog.dart';
import '../../widgets/common/gx_futuristic_components.dart';

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
    final accentColor = NotilusColors.getSecondaryColor(context);

    return GxFuturisticDialog(
      title: widget.existingGroup != null
          ? 'Modifier le groupe'
          : 'Nouveau groupe d\'onglets',
      titleIcon: Icons.folder_rounded,
      accentColor: accentColor,
      width: 450,
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: accentColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GxFuturisticButton(
          label: widget.existingGroup != null ? 'Modifier' : 'Créer',
          icon: widget.existingGroup != null ? Icons.edit_rounded : Icons.add_rounded,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: accentColor,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            
          // Name input
          TextField(
            controller: _nameController,
            style: NotilusFonts.rajdhani(
              fontSize: 14,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              labelText: 'Nom du groupe',
              labelStyle: NotilusFonts.rajdhani(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
            
            const SizedBox(height: 24),
            
          const SizedBox(height: 24),
          
          // Color selection
          Text(
            'Couleur',
            style: NotilusFonts.rajdhani(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
                        color: isSelected ? accentColor : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.5),
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
            
          const SizedBox(height: 24),
          
          // Icon selection
          Text(
            'Icône (optionnel)',
            style: NotilusFonts.rajdhani(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
                          ? accentColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedIcon == null
                            ? accentColor
                            : Colors.white.withOpacity(0.2),
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
                            ? accentColor.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? accentColor : Colors.white.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon['icon'] as IconData,
                        color: isSelected ? accentColor : Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}

