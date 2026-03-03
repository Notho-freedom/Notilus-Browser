/// Notilus Responsive Utils - Utilitaires pour le design responsive
library responsive_utils;

import 'package:flutter/material.dart';

/// Breakpoints pour le responsive design
class ResponsiveBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
  
  ResponsiveBreakpoints._();
}

/// Type d'écran basé sur la largeur
enum ScreenType { mobile, tablet, desktop, largeDesktop }

/// Extension pour BuildContext pour accéder facilement aux infos responsive
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  ScreenType get screenType {
    final width = screenWidth;
    if (width < ResponsiveBreakpoints.mobile) return ScreenType.mobile;
    if (width < ResponsiveBreakpoints.tablet) return ScreenType.tablet;
    if (width < ResponsiveBreakpoints.desktop) return ScreenType.desktop;
    return ScreenType.largeDesktop;
  }
  
  bool get isMobile => screenWidth < ResponsiveBreakpoints.mobile;
  bool get isTablet => screenWidth >= ResponsiveBreakpoints.mobile && 
                       screenWidth < ResponsiveBreakpoints.tablet;
  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.tablet;
  bool get isLargeDesktop => screenWidth >= ResponsiveBreakpoints.largeDesktop;
  
  /// Padding adaptatif selon la taille d'écran
  EdgeInsets get responsivePadding {
    if (isMobile) return const EdgeInsets.all(8);
    if (isTablet) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }
  
  /// Spacing adaptatif
  double get responsiveSpacing {
    if (isMobile) return 8;
    if (isTablet) return 12;
    return 16;
  }
}

/// Widget wrapper pour le responsive design
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType, BoxConstraints constraints) builder;
  
  const ResponsiveBuilder({super.key, required this.builder});
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = context.screenType;
        return builder(context, screenType, constraints);
      },
    );
  }
}

/// Widget qui empêche les overflows en rendant scrollable si nécessaire
class SafeScrollView extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  
  const SafeScrollView({
    super.key,
    required this.child,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.physics,
  });
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: scrollDirection,
      padding: padding,
      physics: physics ?? const ClampingScrollPhysics(),
      child: child,
    );
  }
}

/// Widget optimisé qui wrap le contenu dans un RepaintBoundary
class OptimizedWidget extends StatelessWidget {
  final Widget child;
  
  const OptimizedWidget({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// Column qui s'adapte automatiquement si overflow
class AdaptiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  
  const AdaptiveColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.scrollable = true,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
    
    if (scrollable) {
      return SingleChildScrollView(
        padding: padding,
        physics: const ClampingScrollPhysics(),
        child: column,
      );
    }
    
    return padding != null ? Padding(padding: padding!, child: column) : column;
  }
}

/// Row qui s'adapte automatiquement si overflow (wrap ou scroll)
class AdaptiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool wrap;
  final double spacing;
  final double runSpacing;
  
  const AdaptiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrap = true,
    this.spacing = 8,
    this.runSpacing = 8,
  });
  
  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(
        alignment: _wrapAlignment,
        crossAxisAlignment: _wrapCrossAlignment,
        spacing: spacing,
        runSpacing: runSpacing,
        children: children,
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
  
  WrapAlignment get _wrapAlignment {
    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        return WrapAlignment.start;
      case MainAxisAlignment.end:
        return WrapAlignment.end;
      case MainAxisAlignment.center:
        return WrapAlignment.center;
      case MainAxisAlignment.spaceBetween:
        return WrapAlignment.spaceBetween;
      case MainAxisAlignment.spaceAround:
        return WrapAlignment.spaceAround;
      case MainAxisAlignment.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }
  
  WrapCrossAlignment get _wrapCrossAlignment {
    switch (crossAxisAlignment) {
      case CrossAxisAlignment.start:
        return WrapCrossAlignment.start;
      case CrossAxisAlignment.end:
        return WrapCrossAlignment.end;
      default:
        return WrapCrossAlignment.center;
    }
  }
}

/// Widget helper pour flex avec min/max constraints
class FlexibleContainer extends StatelessWidget {
  final Widget child;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final int flex;
  
  const FlexibleContainer({
    super.key,
    required this.child,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.flex = 1,
  });
  
  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0,
          maxWidth: maxWidth ?? double.infinity,
          minHeight: minHeight ?? 0,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: child,
      ),
    );
  }
}

