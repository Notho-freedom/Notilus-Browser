import 'package:flutter/material.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import 'gx_futuristic_dialog.dart';

/// Dialog de sélection de couleur personnalisé pour Notilus
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String title;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.title,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();

  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    required String title,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: initialColor,
        title: title,
      ),
    );
  }
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;
  late double _red;
  late double _green;
  late double _blue;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _red = widget.initialColor.red.toDouble();
    _green = widget.initialColor.green.toDouble();
    _blue = widget.initialColor.blue.toDouble();
  }

  void _updateColor() {
    setState(() {
      _selectedColor = Color.fromRGBO(
        _red.round(),
        _green.round(),
        _blue.round(),
        1.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NotilusColors.getSecondaryColor(context);
    
    return GxFuturisticDialog(
      title: widget.title,
      titleIcon: Icons.palette_rounded,
      accentColor: accentColor,
      width: 450,
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: accentColor,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        GxFuturisticButton(
          label: 'Appliquer',
          icon: Icons.check_rounded,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: accentColor,
          onPressed: () => Navigator.of(context).pop(_selectedColor),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            
            // Aperçu de la couleur
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sliders RGB
            _buildColorSlider(
              'Rouge',
              _red,
              0,
              255,
              Colors.red,
              (value) {
                _red = value;
                _updateColor();
              },
            ),
            const SizedBox(height: 16),
            _buildColorSlider(
              'Vert',
              _green,
              0,
              255,
              Colors.green,
              (value) {
                _green = value;
                _updateColor();
              },
            ),
            const SizedBox(height: 16),
            _buildColorSlider(
              'Bleu',
              _blue,
              0,
              255,
              Colors.blue,
              (value) {
                _blue = value;
                _updateColor();
              },
            ),
            
            const SizedBox(height: 24),
            
            // Couleurs prédéfinies
            Text(
              'Couleurs rapides',
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetColor(Colors.black, 'Noir'),
                _buildPresetColor(const Color(0xFF09080D), 'Notilus'),
                _buildPresetColor(const Color(0xFF101018), 'Chrome'),
                _buildPresetColor(const Color(0xFF1A1A1A), 'Surface'),
                _buildPresetColor(const Color(0xFF0B0B11), 'Chrome Dark'),
                _buildPresetColor(const Color(0xFF181824), 'Chrome Light'),
                _buildPresetColor(const Color(0xFF1C1C28), 'Tooltip'),
                _buildPresetColor(Colors.white, 'Blanc'),
              ],
            ),
            
        ],
      ),
    );
  }

  Widget _buildColorSlider(
    String label,
    double value,
    double min,
    double max,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              value.round().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.3),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetColor(Color color, String label) {
    final isSelected = _selectedColor.value == color.value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _red = color.red.toDouble();
          _green = color.green.toDouble();
          _blue = color.blue.toDouble();
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? NotilusColors.neonRed
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }
}

