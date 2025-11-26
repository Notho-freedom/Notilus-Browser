/// Panneau Mockup Comparator pour Notilus Studio
/// Compare des maquettes avec le site réel
library mockup_comparator_panel;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import '../../services/studio/studio_service.dart';
import '../../services/studio/mockup_comparator_service.dart';
import '../../models/studio/studio_models.dart';
import '../../core/services/color_theme_manager.dart';

/// Panneau Mockup Comparator
class MockupComparatorPanel extends StatefulWidget {
  const MockupComparatorPanel({super.key});

  @override
  State<MockupComparatorPanel> createState() => _MockupComparatorPanelState();
}

class _MockupComparatorPanelState extends State<MockupComparatorPanel> {
  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<StudioService>(
      builder: (context, studioService, _) {
        final comparator = studioService.mockupComparator;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 1000;
            final isVeryCompact = constraints.maxWidth < 600;
            
            if (isVeryCompact) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      child: _buildControlsPanel(comparator, accentColor),
                    ),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      child: _buildComparisonView(comparator, accentColor),
                    ),
                    if (comparator.lastResult != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: _buildResultsPanel(comparator, accentColor),
                      ),
                  ],
                ),
              );
            }
            
            if (isCompact) {
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 280,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                        ),
                        child: _buildControlsPanel(comparator, accentColor),
                      ),
                      Expanded(
                        child: _buildComparisonView(comparator, accentColor),
                      ),
                    ],
                  ),
                  if (comparator.lastResult != null)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      child: _buildResultsPanel(comparator, accentColor),
                    ),
                ],
              );
            }
            
            return Row(
              children: [
                // Controls panel
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: _buildControlsPanel(comparator, accentColor),
                ),
                // Comparison view
                Expanded(
                  child: _buildComparisonView(comparator, accentColor),
                ),
                // Results panel
                if (comparator.lastResult != null)
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    child: _buildResultsPanel(comparator, accentColor),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlsPanel(MockupComparatorService comparator, Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Load mockup
          _buildSection(
            'Maquette',
            [
              ElevatedButton.icon(
                onPressed: () => _loadMockupImage(comparator),
                icon: const Icon(CupertinoIcons.folder, size: 14),
                label: const Text('Charger une image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
              if (comparator.mockupImage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.checkmark_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Maquette chargée',
                        style: TextStyle(fontSize: 11, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            accentColor,
          ),
          const SizedBox(height: 24),
          // Capture site
          _buildSection(
            'Site',
            [
              ElevatedButton.icon(
                onPressed: comparator.isComparing ? null : comparator.captureSiteImage,
                icon: comparator.isComparing
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      )
                    : const Icon(CupertinoIcons.camera, size: 14),
                label: Text(comparator.isComparing ? 'Capture...' : 'Capturer le site'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
              if (comparator.siteImage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.checkmark_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Site capturé',
                        style: TextStyle(fontSize: 11, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            accentColor,
          ),
          const SizedBox(height: 24),
          // Comparison mode
          _buildSection(
            'Mode de comparaison',
            [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ComparisonMode.values.map((mode) {
                  final isSelected = comparator.comparisonMode == mode;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(mode.icon, size: 14),
                        const SizedBox(width: 4),
                        Text(mode.displayName),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => comparator.setComparisonMode(mode),
                    selectedColor: accentColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: isSelected ? accentColor : Colors.white.withOpacity(0.7),
                    ),
                  );
                }).toList(),
              ),
            ],
            accentColor,
          ),
          const SizedBox(height: 24),
          // Overlay opacity (si mode overlay)
          if (comparator.comparisonMode == ComparisonMode.overlay) ...[
            _buildSection(
              'Opacité',
              [
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: comparator.overlayOpacity,
                        onChanged: comparator.setOverlayOpacity,
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
                        '${(comparator.overlayOpacity * 100).round()}%',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              accentColor,
            ),
            const SizedBox(height: 24),
          ],
          // Slide position (si mode slide)
          if (comparator.comparisonMode == ComparisonMode.slide) ...[
            _buildSection(
              'Position du curseur',
              [
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: comparator.slidePosition,
                        onChanged: comparator.setSlidePosition,
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
                        '${(comparator.slidePosition * 100).round()}%',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              accentColor,
            ),
            const SizedBox(height: 24),
          ],
          // Compare button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (comparator.mockupImage != null &&
                      comparator.siteImage != null &&
                      !comparator.isComparing)
                  ? () => comparator.compare()
                  : null,
              icon: comparator.isComparing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    )
                  : const Icon(CupertinoIcons.search, size: 14),
              label: Text(comparator.isComparing ? 'Comparaison...' : 'Comparer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Clear button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: comparator.mockupImage != null || comparator.siteImage != null
                  ? comparator.clear
                  : null,
              icon: const Icon(CupertinoIcons.trash, size: 14),
              label: const Text('Effacer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.7),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonView(MockupComparatorService comparator, Color accentColor) {
    if (comparator.mockupImage == null && comparator.siteImage == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.doc_on_doc,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Charger une maquette et capturer le site',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparez votre maquette avec le site réel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildComparisonContent(comparator, accentColor),
      ),
    );
  }

  Widget _buildComparisonContent(MockupComparatorService comparator, Color accentColor) {
    final mockup = comparator.mockupImage;
    final site = comparator.siteImage;

    if (mockup == null && site == null) return const SizedBox();

    switch (comparator.comparisonMode) {
      case ComparisonMode.split:
        return _buildSplitView(mockup, site, accentColor);
      case ComparisonMode.overlay:
        return _buildOverlayView(mockup, site, comparator.overlayOpacity, accentColor);
      case ComparisonMode.diff:
        return _buildDiffView(comparator.lastResult, accentColor);
      case ComparisonMode.slide:
        return _buildSlideView(mockup, site, comparator.slidePosition, accentColor);
      case ComparisonMode.onion:
        return _buildOnionView(mockup, site, accentColor);
    }
  }

  Widget _buildSplitView(Uint8List? mockup, Uint8List? site, Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: _buildImagePreview(mockup, 'Maquette', accentColor),
        ),
        Container(
          width: 2,
          color: accentColor.withOpacity(0.3),
        ),
        Expanded(
          child: _buildImagePreview(site, 'Site', accentColor),
        ),
      ],
    );
  }

  Widget _buildOverlayView(Uint8List? mockup, Uint8List? site, double opacity, Color accentColor) {
    if (mockup == null || site == null) {
      return _buildImagePreview(mockup ?? site, mockup != null ? 'Maquette' : 'Site', accentColor);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        _buildImagePreview(site, 'Site', accentColor),
        Opacity(
          opacity: opacity,
          child: _buildImagePreview(mockup, 'Maquette', accentColor),
        ),
      ],
    );
  }

  Widget _buildDiffView(MockupComparisonResult? result, Color accentColor) {
    if (result?.diffImage == null) {
      return Center(
        child: Text(
          'Lancez une comparaison pour voir les différences',
          style: TextStyle(color: Colors.white.withOpacity(0.4)),
        ),
      );
    }

    return Column(
      children: [
        _buildImagePreview(result!.diffImage, 'Différences', accentColor),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF15151E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Similarité',
                value: '${result.conformityScore.toStringAsFixed(1)}%',
                color: _getScoreColor(result.conformityScore),
              ),
              _StatItem(
                label: 'Grade',
                value: result.conformityGrade,
                color: _getScoreColor(result.conformityScore),
              ),
              _StatItem(
                label: 'Différences',
                value: '${result.differenceCount}',
                color: Colors.white.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlideView(Uint8List? mockup, Uint8List? site, double position, Color accentColor) {
    if (mockup == null || site == null) {
      return _buildImagePreview(mockup ?? site, mockup != null ? 'Maquette' : 'Site', accentColor);
    }

    return Stack(
      children: [
        _buildImagePreview(site, 'Site', accentColor),
        Positioned.fill(
          left: MediaQuery.of(context).size.width * position * 0.5,
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: position,
              child: _buildImagePreview(mockup, 'Maquette', accentColor),
            ),
          ),
        ),
        Positioned(
          left: MediaQuery.of(context).size.width * position * 0.5 - 1,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            color: accentColor,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnionView(Uint8List? mockup, Uint8List? site, Color accentColor) {
    if (mockup == null || site == null) {
      return _buildImagePreview(mockup ?? site, mockup != null ? 'Maquette' : 'Site', accentColor);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0.3,
          child: _buildImagePreview(site, 'Site', accentColor),
        ),
        Opacity(
          opacity: 0.7,
          child: _buildImagePreview(mockup, 'Maquette', accentColor),
        ),
      ],
    );
  }

  Widget _buildImagePreview(Uint8List? imageData, String label, Color accentColor) {
    if (imageData == null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            'Aucune image',
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.photo, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Image.memory(
                imageData,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel(MockupComparatorService comparator, Color accentColor) {
    final result = comparator.lastResult;
    if (result == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉSULTATS',
            style: TextStyle(
              color: accentColor.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          // Score card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF15151E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '${result.conformityScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getScoreColor(result.conformityScore),
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grade: ${result.conformityGrade}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Differences list
          if (result.differences.isNotEmpty) ...[
            Text(
              'DIFFÉRENCES (${result.differences.length})',
              style: TextStyle(
                color: accentColor.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            ...result.differences.map((diff) => _DifferenceCard(
                  difference: diff,
                  accentColor: accentColor,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: accentColor.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Future<void> _loadMockupImage(MockupComparatorService comparator) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      await comparator.loadMockupImage(result.files.single.bytes!);
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _DifferenceCard extends StatelessWidget {
  final MockupDifference difference;
  final Color accentColor;

  const _DifferenceCard({
    required this.difference,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (difference.severity > 0.7 ? Colors.red : Colors.orange).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                difference.isColorDifference
                    ? CupertinoIcons.paintbrush
                    : difference.isSizeDifference
                        ? CupertinoIcons.resize
                        : CupertinoIcons.exclamationmark_circle,
                size: 14,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  difference.property,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendu:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      difference.expectedValue,
                      style: TextStyle(
                        color: Colors.green.withOpacity(0.8),
                        fontSize: 11,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actuel:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      difference.actualValue,
                      style: TextStyle(
                        color: Colors.red.withOpacity(0.8),
                        fontSize: 11,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (difference.suggestedFix != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.lightbulb, size: 12, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      difference.suggestedFix!,
                      style: TextStyle(
                        color: accentColor.withOpacity(0.9),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

