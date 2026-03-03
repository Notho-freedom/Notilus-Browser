/// Modèles pour Notilus Studio
/// Définit les structures pour l'éditeur live, les captures et les comparaisons
library studio_models;

import 'dart:typed_data';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SCREENSHOT MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Type de capture d'écran
enum CaptureType {
  viewport,
  fullPage,
  element,
  area,
}

extension CaptureTypeExtension on CaptureType {
  String get displayName {
    switch (this) {
      case CaptureType.viewport:
        return 'Viewport';
      case CaptureType.fullPage:
        return 'Page complète';
      case CaptureType.element:
        return 'Élément';
      case CaptureType.area:
        return 'Zone';
    }
  }

  IconData get icon {
    switch (this) {
      case CaptureType.viewport:
        return Icons.crop_square;
      case CaptureType.fullPage:
        return Icons.crop_portrait;
      case CaptureType.element:
        return Icons.select_all;
      case CaptureType.area:
        return Icons.crop;
    }
  }
}

/// Format d'image
enum ImageFormat {
  png,
  jpeg,
  webp,
  pdf,
}

extension ImageFormatExtension on ImageFormat {
  String get extension {
    switch (this) {
      case ImageFormat.png:
        return 'png';
      case ImageFormat.jpeg:
        return 'jpg';
      case ImageFormat.webp:
        return 'webp';
      case ImageFormat.pdf:
        return 'pdf';
    }
  }

  String get mimeType {
    switch (this) {
      case ImageFormat.png:
        return 'image/png';
      case ImageFormat.jpeg:
        return 'image/jpeg';
      case ImageFormat.webp:
        return 'image/webp';
      case ImageFormat.pdf:
        return 'application/pdf';
    }
  }
}

/// Qualité d'image
enum ImageQuality {
  low,
  medium,
  high,
  maximum,
}

extension ImageQualityExtension on ImageQuality {
  int get value {
    switch (this) {
      case ImageQuality.low:
        return 60;
      case ImageQuality.medium:
        return 80;
      case ImageQuality.high:
        return 90;
      case ImageQuality.maximum:
        return 100;
    }
  }

  String get displayName {
    switch (this) {
      case ImageQuality.low:
        return 'Basse';
      case ImageQuality.medium:
        return 'Moyenne';
      case ImageQuality.high:
        return 'Haute';
      case ImageQuality.maximum:
        return 'Maximum';
    }
  }
}

/// Configuration de capture d'écran
class ScreenshotConfig {
  final CaptureType type;
  final ImageFormat format;
  final ImageQuality quality;
  final double scale;
  final bool hideScrollbars;
  final bool waitForAnimations;
  final bool captureHoverStates;
  final bool removeStickyElements;
  final bool simulateDarkMode;
  final Duration delay;
  final String? selector;
  final Rect? customArea;
  final String? mockupTemplate;
  final String? watermark;

  const ScreenshotConfig({
    this.type = CaptureType.viewport,
    this.format = ImageFormat.png,
    this.quality = ImageQuality.high,
    this.scale = 1.0,
    this.hideScrollbars = true,
    this.waitForAnimations = true,
    this.captureHoverStates = false,
    this.removeStickyElements = false,
    this.simulateDarkMode = false,
    this.delay = Duration.zero,
    this.selector,
    this.customArea,
    this.mockupTemplate,
    this.watermark,
  });

  ScreenshotConfig copyWith({
    CaptureType? type,
    ImageFormat? format,
    ImageQuality? quality,
    double? scale,
    bool? hideScrollbars,
    bool? waitForAnimations,
    bool? captureHoverStates,
    bool? removeStickyElements,
    bool? simulateDarkMode,
    Duration? delay,
    String? selector,
    Rect? customArea,
    String? mockupTemplate,
    String? watermark,
  }) {
    return ScreenshotConfig(
      type: type ?? this.type,
      format: format ?? this.format,
      quality: quality ?? this.quality,
      scale: scale ?? this.scale,
      hideScrollbars: hideScrollbars ?? this.hideScrollbars,
      waitForAnimations: waitForAnimations ?? this.waitForAnimations,
      captureHoverStates: captureHoverStates ?? this.captureHoverStates,
      removeStickyElements: removeStickyElements ?? this.removeStickyElements,
      simulateDarkMode: simulateDarkMode ?? this.simulateDarkMode,
      delay: delay ?? this.delay,
      selector: selector ?? this.selector,
      customArea: customArea ?? this.customArea,
      mockupTemplate: mockupTemplate ?? this.mockupTemplate,
      watermark: watermark ?? this.watermark,
    );
  }
}

/// Résultat d'une capture d'écran
class Screenshot {
  final String id;
  final DateTime timestamp;
  final String? url;
  final CaptureType type;
  final int width;
  final int height;
  final ImageFormat format;
  final Uint8List data;
  final String? deviceName;
  final Map<String, dynamic>? metadata;

  Screenshot({
    required this.id,
    required this.timestamp,
    this.url,
    required this.type,
    required this.width,
    required this.height,
    required this.format,
    required this.data,
    this.deviceName,
    this.metadata,
  });

  String get fileName {
    final ts = timestamp.toIso8601String().replaceAll(':', '-').split('.').first;
    final device = deviceName?.replaceAll(' ', '_') ?? 'capture';
    return '${device}_$ts.${format.extension}';
  }

  int get sizeInBytes => data.length;

  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Template de mockup
class MockupTemplate {
  final String id;
  final String name;
  final String category;
  final String assetPath;
  final Size frameSize;
  final Rect screenArea;
  final double cornerRadius;
  final Color? backgroundColor;

  const MockupTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    required this.frameSize,
    required this.screenArea,
    this.cornerRadius = 0,
    this.backgroundColor,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// MOCKUP COMPARISON MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Mode de comparaison
enum ComparisonMode {
  split,
  overlay,
  diff,
  slide,
  onion,
}

extension ComparisonModeExtension on ComparisonMode {
  String get displayName {
    switch (this) {
      case ComparisonMode.split:
        return 'Split';
      case ComparisonMode.overlay:
        return 'Superposition';
      case ComparisonMode.diff:
        return 'Différences';
      case ComparisonMode.slide:
        return 'Curseur';
      case ComparisonMode.onion:
        return 'Papier calque';
    }
  }

  IconData get icon {
    switch (this) {
      case ComparisonMode.split:
        return Icons.vertical_split;
      case ComparisonMode.overlay:
        return Icons.layers;
      case ComparisonMode.diff:
        return Icons.compare;
      case ComparisonMode.slide:
        return Icons.swap_horiz;
      case ComparisonMode.onion:
        return Icons.filter_none;
    }
  }
}

/// Différence détectée entre maquette et site
class MockupDifference {
  final String id;
  final String property;
  final String expectedValue;
  final String actualValue;
  final Rect? area;
  final String? cssSelector;
  final String? suggestedFix;
  final double severity;

  MockupDifference({
    required this.id,
    required this.property,
    required this.expectedValue,
    required this.actualValue,
    this.area,
    this.cssSelector,
    this.suggestedFix,
    this.severity = 0.5,
  });

  bool get isColorDifference =>
      property.toLowerCase().contains('color') ||
      property.toLowerCase().contains('background');

  bool get isSizeDifference =>
      property.toLowerCase().contains('size') ||
      property.toLowerCase().contains('width') ||
      property.toLowerCase().contains('height');
}

/// Résultat d'une comparaison maquette
class MockupComparisonResult {
  final String id;
  final DateTime timestamp;
  final String mockupSource;
  final String siteUrl;
  final List<MockupDifference> differences;
  final double overallSimilarity;
  final Uint8List? diffImage;

  MockupComparisonResult({
    required this.id,
    required this.timestamp,
    required this.mockupSource,
    required this.siteUrl,
    required this.differences,
    required this.overallSimilarity,
    this.diffImage,
  });

  int get differenceCount => differences.length;

  double get conformityScore => overallSimilarity * 100;

  String get conformityGrade {
    if (conformityScore >= 95) return 'A+';
    if (conformityScore >= 90) return 'A';
    if (conformityScore >= 80) return 'B';
    if (conformityScore >= 70) return 'C';
    if (conformityScore >= 60) return 'D';
    return 'F';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVE EDITOR MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Type de modification
enum EditType {
  html,
  css,
  attribute,
  text,
  style,
}

extension EditTypeExtension on EditType {
  String get displayName {
    switch (this) {
      case EditType.html:
        return 'HTML';
      case EditType.css:
        return 'CSS';
      case EditType.attribute:
        return 'Attribut';
      case EditType.text:
        return 'Texte';
      case EditType.style:
        return 'Style';
    }
  }

  Color get color {
    switch (this) {
      case EditType.html:
        return const Color(0xFFE34C26);
      case EditType.css:
        return const Color(0xFF264DE4);
      case EditType.attribute:
        return const Color(0xFF41B883);
      case EditType.text:
        return const Color(0xFFFFD43B);
      case EditType.style:
        return const Color(0xFF9C27B0);
    }
  }
}

/// Modification apportée
class EditChange {
  final String id;
  final DateTime timestamp;
  final EditType type;
  final String selector;
  final String property;
  final String? oldValue;
  final String newValue;
  final bool isReverted;

  EditChange({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.selector,
    required this.property,
    this.oldValue,
    required this.newValue,
    this.isReverted = false,
  });

  EditChange copyWith({bool? isReverted}) {
    return EditChange(
      id: id,
      timestamp: timestamp,
      type: type,
      selector: selector,
      property: property,
      oldValue: oldValue,
      newValue: newValue,
      isReverted: isReverted ?? this.isReverted,
    );
  }

  String get displayText {
    switch (type) {
      case EditType.css:
      case EditType.style:
        return '$property: $newValue';
      case EditType.attribute:
        return '[$property]="$newValue"';
      case EditType.text:
        return newValue.length > 50 ? '${newValue.substring(0, 50)}...' : newValue;
      case EditType.html:
        return selector;
    }
  }

  /// Génère le code CSS pour cette modification
  String? toCss() {
    if (type == EditType.css || type == EditType.style) {
      return '$selector { $property: $newValue; }';
    }
    return null;
  }
}

/// Session d'édition
class EditSession {
  final String id;
  final String url;
  final DateTime startTime;
  final List<EditChange> changes;
  final bool isSaved;

  EditSession({
    required this.id,
    required this.url,
    required this.startTime,
    this.changes = const [],
    this.isSaved = false,
  });

  EditSession copyWith({
    List<EditChange>? changes,
    bool? isSaved,
  }) {
    return EditSession(
      id: id,
      url: url,
      startTime: startTime,
      changes: changes ?? this.changes,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  int get changeCount => changes.length;

  int get activeChangeCount => changes.where((c) => !c.isReverted).length;

  /// Génère le CSS de toutes les modifications actives
  String exportCss() {
    final buffer = StringBuffer();
    buffer.writeln('/* Notilus Studio - Exported CSS */');
    buffer.writeln('/* URL: $url */');
    buffer.writeln('/* Date: ${DateTime.now().toIso8601String()} */');
    buffer.writeln();

    final cssChanges =
        changes.where((c) => !c.isReverted && c.toCss() != null);
    for (final change in cssChanges) {
      buffer.writeln(change.toCss());
    }

    return buffer.toString();
  }

  /// Génère un patch des modifications
  String exportPatch() {
    final buffer = StringBuffer();
    buffer.writeln('# Notilus Studio - Change Patch');
    buffer.writeln('# URL: $url');
    buffer.writeln('# Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    for (final change in changes.where((c) => !c.isReverted)) {
      buffer.writeln('## ${change.type.displayName} - ${change.selector}');
      buffer.writeln('- Property: ${change.property}');
      if (change.oldValue != null) {
        buffer.writeln('- Old: ${change.oldValue}');
      }
      buffer.writeln('- New: ${change.newValue}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INTERACTION RECORDER MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Type d'événement enregistré
enum InteractionEventType {
  click,
  doubleClick,
  rightClick,
  type,
  scroll,
  hover,
  focus,
  blur,
  resize,
  navigate,
  wait,
  screenshot,
  assertion,
}

extension InteractionEventTypeExtension on InteractionEventType {
  String get displayName {
    switch (this) {
      case InteractionEventType.click:
        return 'Clic';
      case InteractionEventType.doubleClick:
        return 'Double-clic';
      case InteractionEventType.rightClick:
        return 'Clic droit';
      case InteractionEventType.type:
        return 'Saisie';
      case InteractionEventType.scroll:
        return 'Scroll';
      case InteractionEventType.hover:
        return 'Survol';
      case InteractionEventType.focus:
        return 'Focus';
      case InteractionEventType.blur:
        return 'Blur';
      case InteractionEventType.resize:
        return 'Redim.';
      case InteractionEventType.navigate:
        return 'Navigation';
      case InteractionEventType.wait:
        return 'Attente';
      case InteractionEventType.screenshot:
        return 'Capture';
      case InteractionEventType.assertion:
        return 'Assertion';
    }
  }

  IconData get icon {
    switch (this) {
      case InteractionEventType.click:
        return Icons.touch_app;
      case InteractionEventType.doubleClick:
        return Icons.mouse;
      case InteractionEventType.rightClick:
        return Icons.menu;
      case InteractionEventType.type:
        return Icons.keyboard;
      case InteractionEventType.scroll:
        return Icons.unfold_more;
      case InteractionEventType.hover:
        return Icons.pan_tool;
      case InteractionEventType.focus:
        return Icons.center_focus_strong;
      case InteractionEventType.blur:
        return Icons.center_focus_weak;
      case InteractionEventType.resize:
        return Icons.aspect_ratio;
      case InteractionEventType.navigate:
        return Icons.open_in_browser;
      case InteractionEventType.wait:
        return Icons.hourglass_empty;
      case InteractionEventType.screenshot:
        return Icons.camera_alt;
      case InteractionEventType.assertion:
        return Icons.check_circle;
    }
  }
}

/// Événement d'interaction enregistré
class RecordedInteraction {
  final String id;
  final InteractionEventType type;
  final Duration timestamp;
  final String? selector;
  final String? value;
  final Offset? position;
  final Size? viewportSize;
  final Map<String, dynamic>? metadata;

  RecordedInteraction({
    required this.id,
    required this.type,
    required this.timestamp,
    this.selector,
    this.value,
    this.position,
    this.viewportSize,
    this.metadata,
  });

  String get formattedTime {
    final minutes = timestamp.inMinutes;
    final seconds = timestamp.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get description {
    switch (type) {
      case InteractionEventType.click:
        return 'Clic sur ${selector ?? 'élément'}';
      case InteractionEventType.type:
        return 'Saisie "${value ?? ''}"';
      case InteractionEventType.scroll:
        return 'Scroll (${position?.dy.round() ?? 0}px)';
      case InteractionEventType.navigate:
        return 'Navigation vers ${value ?? 'page'}';
      case InteractionEventType.resize:
        return 'Redimensionnement (${viewportSize?.width.round() ?? 0}x${viewportSize?.height.round() ?? 0})';
      default:
        return '${type.displayName} ${selector ?? ''}';
    }
  }

  /// Génère le code Playwright pour cette interaction
  String toPlaywright() {
    switch (type) {
      case InteractionEventType.click:
        return "await page.click('$selector');";
      case InteractionEventType.doubleClick:
        return "await page.dblclick('$selector');";
      case InteractionEventType.type:
        return "await page.fill('$selector', '${value ?? ''}');";
      case InteractionEventType.scroll:
        return 'await page.evaluate(() => window.scrollTo(0, ${position?.dy.round() ?? 0}));';
      case InteractionEventType.hover:
        return "await page.hover('$selector');";
      case InteractionEventType.navigate:
        return "await page.goto('${value ?? ''}');";
      case InteractionEventType.resize:
        return 'await page.setViewportSize({ width: ${viewportSize?.width.round() ?? 1920}, height: ${viewportSize?.height.round() ?? 1080} });';
      case InteractionEventType.wait:
        return 'await page.waitForTimeout(${timestamp.inMilliseconds});';
      case InteractionEventType.assertion:
        return "await expect(page.locator('$selector')).toBeVisible();";
      default:
        return '// ${type.displayName}';
    }
  }

  /// Génère le code Cypress pour cette interaction
  String toCypress() {
    switch (type) {
      case InteractionEventType.click:
        return "cy.get('$selector').click();";
      case InteractionEventType.doubleClick:
        return "cy.get('$selector').dblclick();";
      case InteractionEventType.type:
        return "cy.get('$selector').type('${value ?? ''}');";
      case InteractionEventType.scroll:
        return 'cy.scrollTo(0, ${position?.dy.round() ?? 0});';
      case InteractionEventType.hover:
        return "cy.get('$selector').trigger('mouseover');";
      case InteractionEventType.navigate:
        return "cy.visit('${value ?? ''}');";
      case InteractionEventType.resize:
        return 'cy.viewport(${viewportSize?.width.round() ?? 1920}, ${viewportSize?.height.round() ?? 1080});';
      case InteractionEventType.wait:
        return 'cy.wait(${timestamp.inMilliseconds});';
      case InteractionEventType.assertion:
        return "cy.get('$selector').should('be.visible');";
      default:
        return '// ${type.displayName}';
    }
  }
}

/// Session d'enregistrement
class RecordingSession {
  final String id;
  final String url;
  final DateTime startTime;
  final Duration duration;
  final List<RecordedInteraction> interactions;
  final bool isRecording;

  RecordingSession({
    required this.id,
    required this.url,
    required this.startTime,
    required this.duration,
    this.interactions = const [],
    this.isRecording = false,
  });

  RecordingSession copyWith({
    Duration? duration,
    List<RecordedInteraction>? interactions,
    bool? isRecording,
  }) {
    return RecordingSession(
      id: id,
      url: url,
      startTime: startTime,
      duration: duration ?? this.duration,
      interactions: interactions ?? this.interactions,
      isRecording: isRecording ?? this.isRecording,
    );
  }

  int get eventCount => interactions.length;

  /// Exporte en code Playwright
  String exportPlaywright({String testName = 'Recorded Test'}) {
    final buffer = StringBuffer();
    buffer.writeln("import { test, expect } from '@playwright/test';");
    buffer.writeln();
    buffer.writeln("test('$testName', async ({ page }) => {");
    buffer.writeln("  await page.goto('$url');");
    buffer.writeln();

    for (final interaction in interactions) {
      buffer.writeln('  ${interaction.toPlaywright()}');
    }

    buffer.writeln('});');
    return buffer.toString();
  }

  /// Exporte en code Cypress
  String exportCypress({String testName = 'Recorded Test'}) {
    final buffer = StringBuffer();
    buffer.writeln("describe('$testName', () => {");
    buffer.writeln("  it('should replay recorded interactions', () => {");
    buffer.writeln("    cy.visit('$url');");
    buffer.writeln();

    for (final interaction in interactions) {
      buffer.writeln('    ${interaction.toCypress()}');
    }

    buffer.writeln('  });');
    buffer.writeln('});');
    return buffer.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BREAKPOINT ANALYSIS MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Point de rupture CSS détecté
class CSSBreakpoint {
  final int width;
  final String mediaQuery;
  final int ruleCount;
  final bool hasIssues;
  final List<String>? issues;

  CSSBreakpoint({
    required this.width,
    required this.mediaQuery,
    required this.ruleCount,
    this.hasIssues = false,
    this.issues,
  });

  String get category {
    if (width < 480) return 'Mobile S';
    if (width < 768) return 'Mobile';
    if (width < 1024) return 'Tablet';
    if (width < 1440) return 'Desktop';
    return 'Large Desktop';
  }
}

/// Résultat d'analyse responsive
class ResponsiveAnalysis {
  final List<CSSBreakpoint> breakpoints;
  final List<ResponsiveIssue> issues;
  final double responsiveScore;

  ResponsiveAnalysis({
    required this.breakpoints,
    required this.issues,
    required this.responsiveScore,
  });

  int get breakpointCount => breakpoints.length;
  int get issueCount => issues.length;
}

/// Problème responsive détecté
class ResponsiveIssue {
  final String id;
  final String description;
  final int? atWidth;
  final String? selector;
  final String type;

  ResponsiveIssue({
    required this.id,
    required this.description,
    this.atWidth,
    this.selector,
    required this.type,
  });
}

