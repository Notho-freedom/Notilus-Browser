/// Panneau Screenshot Studio pour Notilus Studio
/// Capture d'écran avancée avec templates mockup
library screenshot_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/studio/studio_service.dart';
import '../../services/studio/screenshot_service.dart';
import '../../models/studio/studio_models.dart';
import '../../models/studio/viewport_preset.dart';
import '../../core/services/color_theme_manager.dart';

/// Panneau Screenshot Studio
class ScreenshotPanel extends StatefulWidget {
  const ScreenshotPanel({super.key});

  @override
  State<ScreenshotPanel> createState() => _ScreenshotPanelState();
}

class _ScreenshotPanelState extends State<ScreenshotPanel> {
  CaptureType _captureType = CaptureType.viewport;
  ImageFormat _format = ImageFormat.png;
  ImageQuality _quality = ImageQuality.high;
  double _scale = 2.0;
  bool _hideScrollbars = true;
  bool _waitAnimations = true;
  String? _mockupTemplate;

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<StudioService>(
      builder: (context, studioService, _) {
        final screenshot = studioService.screenshot;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 800;
            
            if (isCompact) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            'Type de capture',
                            _buildCaptureTypeSelector(accentColor),
                            accentColor,
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            'Format',
                            _buildFormatSelector(accentColor),
                            accentColor,
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            'Qualité',
                            _buildQualitySelector(accentColor),
                            accentColor,
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            'Échelle',
                            _buildScaleSelector(accentColor),
                            accentColor,
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            'Options',
                            _buildOptionsToggle(accentColor),
                            accentColor,
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            'Template Mockup',
                            _buildMockupSelector(accentColor),
                            accentColor,
                          ),
                          const SizedBox(height: 24),
                          _buildCaptureButton(screenshot, accentColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHistoryPanel(screenshot, accentColor),
                  ],
                ),
              );
            }
            
            return Row(
              children: [
                // Options panel
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          'Type de capture',
                          _buildCaptureTypeSelector(accentColor),
                          accentColor,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Format',
                          _buildFormatSelector(accentColor),
                          accentColor,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Qualité',
                          _buildQualitySelector(accentColor),
                          accentColor,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Échelle',
                          _buildScaleSelector(accentColor),
                          accentColor,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Options',
                          _buildOptionsToggle(accentColor),
                          accentColor,
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Template Mockup',
                          _buildMockupSelector(accentColor),
                          accentColor,
                        ),
                        const SizedBox(height: 24),
                        _buildCaptureButton(screenshot, accentColor),
                      ],
                    ),
                  ),
                ),
                // Preview / History
                Expanded(
                  child: _buildHistoryPanel(screenshot, accentColor),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSection(String title, Widget content, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: accentColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildCaptureTypeSelector(Color accentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CaptureType.values.map((type) {
        final isSelected = _captureType == type;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 14),
              const SizedBox(width: 4),
              Text(type.displayName),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => setState(() => _captureType = type),
          selectedColor: accentColor.withOpacity(0.2),
          labelStyle: TextStyle(
            fontSize: 11,
            color: isSelected ? accentColor : Colors.white.withOpacity(0.7),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatSelector(Color accentColor) {
    return SegmentedButton<ImageFormat>(
      segments: ImageFormat.values.map((format) {
        return ButtonSegment(
          value: format,
          label: Text(format.extension.toUpperCase()),
        );
      }).toList(),
      selected: {_format},
      onSelectionChanged: (selected) {
        setState(() => _format = selected.first);
      },
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return Colors.white.withOpacity(0.6);
        }),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildQualitySelector(Color accentColor) {
    return SegmentedButton<ImageQuality>(
      segments: ImageQuality.values.map((q) {
        return ButtonSegment(
          value: q,
          label: Text(q.displayName),
        );
      }).toList(),
      selected: {_quality},
      onSelectionChanged: (selected) {
        setState(() => _quality = selected.first);
      },
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return Colors.white.withOpacity(0.6);
        }),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildScaleSelector(Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _scale,
            min: 1.0,
            max: 4.0,
            divisions: 6,
            onChanged: (value) => setState(() => _scale = value),
            activeColor: accentColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${_scale.toStringAsFixed(1)}x',
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsToggle(Color accentColor) {
    return Column(
      children: [
        _OptionRow(
          label: 'Masquer les scrollbars',
          value: _hideScrollbars,
          onChanged: (v) => setState(() => _hideScrollbars = v),
          accentColor: accentColor,
        ),
        _OptionRow(
          label: 'Attendre les animations',
          value: _waitAnimations,
          onChanged: (v) => setState(() => _waitAnimations = v),
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildMockupSelector(Color accentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MockupChip(
          label: 'Aucun',
          icon: CupertinoIcons.square,
          isSelected: _mockupTemplate == null,
          accentColor: accentColor,
          onTap: () => setState(() => _mockupTemplate = null),
        ),
        _MockupChip(
          label: 'iPhone',
          icon: CupertinoIcons.device_phone_portrait,
          isSelected: _mockupTemplate == 'iphone',
          accentColor: accentColor,
          onTap: () => setState(() => _mockupTemplate = 'iphone'),
        ),
        _MockupChip(
          label: 'MacBook',
          icon: CupertinoIcons.device_laptop,
          isSelected: _mockupTemplate == 'macbook',
          accentColor: accentColor,
          onTap: () => setState(() => _mockupTemplate = 'macbook'),
        ),
        _MockupChip(
          label: 'Browser',
          icon: CupertinoIcons.globe,
          isSelected: _mockupTemplate == 'browser',
          accentColor: accentColor,
          onTap: () => setState(() => _mockupTemplate = 'browser'),
        ),
      ],
    );
  }

  Widget _buildCaptureButton(StudioScreenshotService screenshot, Color accentColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: screenshot.isCapturing
            ? null
            : () async {
                final config = ScreenshotConfig(
                  type: _captureType,
                  format: _format,
                  quality: _quality,
                  scale: _scale,
                  hideScrollbars: _hideScrollbars,
                  waitForAnimations: _waitAnimations,
                  mockupTemplate: _mockupTemplate,
                );
                screenshot.updateConfig(config);
                await screenshot.captureViewport();
              },
        icon: screenshot.isCapturing
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withOpacity(0.5),
                ),
              )
            : const Icon(CupertinoIcons.camera, size: 16),
        label: Text(screenshot.isCapturing ? 'Capture en cours...' : 'Capturer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHistoryPanel(StudioScreenshotService screenshot, Color accentColor) {
    final captures = screenshot.captures;

    if (captures.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.camera,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune capture',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configurez les options et capturez votre page',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Historique (${captures.length})',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: screenshot.clearHistory,
                icon: Icon(CupertinoIcons.trash, size: 14, color: Colors.white.withOpacity(0.5)),
                label: Text(
                  'Vider',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: captures.length,
            itemBuilder: (context, index) {
              final capture = captures[index];
              return _CaptureCard(
                capture: capture,
                accentColor: accentColor,
                onDelete: () => screenshot.removeCapture(capture.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;

  const _OptionRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }
}

class _MockupChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _MockupChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? accentColor : Colors.white.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? accentColor : Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  final Screenshot capture;
  final Color accentColor;
  final VoidCallback? onDelete;

  const _CaptureCard({
    required this.capture,
    required this.accentColor,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Preview placeholder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Icon(
                  capture.type.icon,
                  size: 24,
                  color: accentColor.withOpacity(0.3),
                ),
              ),
            ),
          ),
          // Info
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${capture.width}×${capture.height}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        capture.formattedSize,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.trash, size: 14, color: Colors.white.withOpacity(0.4)),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

