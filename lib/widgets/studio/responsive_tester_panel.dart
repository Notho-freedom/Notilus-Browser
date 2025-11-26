/// Panneau du testeur responsive pour Notilus Studio
/// Affiche plusieurs viewports simultanément
library responsive_tester_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/studio/studio_service.dart';
import '../../services/studio/responsive_tester_service.dart';
import '../../models/studio/viewport_preset.dart';
import '../../core/services/color_theme_manager.dart';

/// Panneau du testeur responsive
class ResponsiveTesterPanel extends StatefulWidget {
  const ResponsiveTesterPanel({super.key});

  @override
  State<ResponsiveTesterPanel> createState() => _ResponsiveTesterPanelState();
}

class _ResponsiveTesterPanelState extends State<ResponsiveTesterPanel> {
  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<StudioService>(
      builder: (context, studioService, _) {
        final tester = studioService.responsiveTester;

        return Column(
          children: [
            _buildToolbar(tester, accentColor),
            Expanded(
              child: tester.activeViewports.isEmpty
                  ? _buildEmptyState(tester, accentColor)
                  : _buildViewportGrid(tester, accentColor),
            ),
            if (tester.showBreakpoints && tester.detectedBreakpoints.isNotEmpty)
              _buildBreakpointsBar(tester, accentColor),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(ResponsiveTesterService tester, Color accentColor) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181E),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          // Boutons de presets
          _ToolbarButton(
            icon: CupertinoIcons.device_phone_portrait,
            label: 'Défauts',
            accentColor: accentColor,
            onPressed: tester.addDefaultViewports,
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: CupertinoIcons.slider_horizontal_3,
            label: 'Breakpoints',
            accentColor: accentColor,
            onPressed: tester.addBreakpointViewports,
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: CupertinoIcons.add,
            label: 'Ajouter',
            accentColor: accentColor,
            onPressed: () => _showDeviceSelector(context, tester, accentColor),
          ),

          const Spacer(),

          // Options
          _ToolbarToggle(
            icon: CupertinoIcons.arrow_up_arrow_down,
            label: 'Sync Scroll',
            isActive: tester.syncScroll,
            accentColor: accentColor,
            onToggle: () => tester.setSyncScroll(!tester.syncScroll),
          ),
          const SizedBox(width: 8),
          _ToolbarToggle(
            icon: CupertinoIcons.chart_bar,
            label: 'Breakpoints',
            isActive: tester.showBreakpoints,
            accentColor: accentColor,
            onToggle: () => tester.setShowBreakpoints(!tester.showBreakpoints),
          ),
          const SizedBox(width: 8),
          _ToolbarToggle(
            icon: CupertinoIcons.exclamationmark_triangle,
            label: 'Issues',
            isActive: tester.highlightIssues,
            accentColor: accentColor,
            onToggle: () => tester.setHighlightIssues(!tester.highlightIssues),
          ),

          const SizedBox(width: 16),

          // Actions
          _ToolbarButton(
            icon: CupertinoIcons.arrow_clockwise,
            label: 'Analyser',
            accentColor: accentColor,
            onPressed: () async {
              await tester.analyzeBreakpoints();
              await tester.analyzeResponsiveIssues();
            },
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: CupertinoIcons.trash,
            label: 'Vider',
            accentColor: accentColor,
            onPressed: tester.clearViewports,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ResponsiveTesterService tester, Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.device_phone_portrait,
            size: 48,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Testeur Responsive',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visualisez votre site sur plusieurs appareils simultanément',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: tester.addDefaultViewports,
                icon: const Icon(CupertinoIcons.device_phone_portrait, size: 16),
                label: const Text('Appareils par défaut'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: tester.addBreakpointViewports,
                icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 16),
                label: const Text('Breakpoints CSS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewportGrid(ResponsiveTesterService tester, Color accentColor) {
    final viewports = tester.activeViewports;
    final crossAxisCount = viewports.length <= 2 ? viewports.length : (viewports.length <= 4 ? 2 : 3);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: viewports.length,
      itemBuilder: (context, index) {
        final viewport = viewports[index];
        return _ViewportCard(
          preset: viewport,
          accentColor: accentColor,
          onRotate: () => tester.rotateViewport(viewport.id),
          onRemove: () => tester.removeViewport(viewport.id),
        );
      },
    );
  }

  Widget _buildBreakpointsBar(ResponsiveTesterService tester, Color accentColor) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF18181E),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Breakpoints détectés:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tester.detectedBreakpoints.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final bp = tester.detectedBreakpoints[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${bp.width}px',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        bp.category,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeviceSelector(
    BuildContext context,
    ResponsiveTesterService tester,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181E),
      builder: (context) => _DeviceSelectorSheet(
        onSelect: (preset) {
          tester.addViewport(preset);
          Navigator.pop(context);
        },
        accentColor: accentColor,
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _ToolbarToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback? onToggle;

  const _ToolbarToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accentColor,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onToggle,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? accentColor : Colors.white.withOpacity(0.5),
        backgroundColor: isActive ? accentColor.withOpacity(0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _ViewportCard extends StatelessWidget {
  final ViewportPreset preset;
  final Color accentColor;
  final VoidCallback? onRotate;
  final VoidCallback? onRemove;

  const _ViewportCard({
    required this.preset,
    required this.accentColor,
    this.onRotate,
    this.onRemove,
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
          // Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                Icon(preset.category.icon, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        preset.dimensionsText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.rotate_right, size: 14, color: Colors.white.withOpacity(0.5)),
                  onPressed: onRotate,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.xmark, size: 14, color: Colors.white.withOpacity(0.5)),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          // Preview (placeholder)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      preset.category.icon,
                      size: 32,
                      color: accentColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preview',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSelectorSheet extends StatefulWidget {
  final Function(ViewportPreset) onSelect;
  final Color accentColor;

  const _DeviceSelectorSheet({
    required this.onSelect,
    required this.accentColor,
  });

  @override
  State<_DeviceSelectorSheet> createState() => _DeviceSelectorSheetState();
}

class _DeviceSelectorSheetState extends State<_DeviceSelectorSheet> {
  DeviceCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredDevices = DevicePresets.all.where((p) {
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un appareil...',
              prefixIcon: const Icon(CupertinoIcons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          // Categories
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'Tous',
                  isSelected: _selectedCategory == null,
                  accentColor: widget.accentColor,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...DeviceCategory.values.map((cat) => _CategoryChip(
                  label: cat.displayName,
                  icon: cat.icon,
                  isSelected: _selectedCategory == cat,
                  accentColor: widget.accentColor,
                  onTap: () => setState(() => _selectedCategory = cat),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Devices list
          Expanded(
            child: ListView.separated(
              itemCount: filteredDevices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final device = filteredDevices[index];
                return ListTile(
                  leading: Icon(device.category.icon, color: widget.accentColor),
                  title: Text(device.name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '${device.dimensionsText} • ${device.devicePixelRatio}x',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                  ),
                  trailing: device.isMobile
                      ? Icon(CupertinoIcons.hand_draw, size: 14, color: Colors.white.withOpacity(0.3))
                      : null,
                  onTap: () => widget.onSelect(device),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap?.call(),
        selectedColor: accentColor.withOpacity(0.2),
        checkmarkColor: accentColor,
        labelStyle: TextStyle(
          fontSize: 11,
          color: isSelected ? accentColor : Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
}

