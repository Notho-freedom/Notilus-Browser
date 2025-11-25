/// Notilus Performance Widgets - Widgets optimisés pour les performances
library performance_widgets;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget optimisé avec RepaintBoundary automatique
class OptimizedBox extends StatelessWidget {
  final Widget child;
  final bool enableBoundary;
  
  const OptimizedBox({
    super.key,
    required this.child,
    this.enableBoundary = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return enableBoundary ? RepaintBoundary(child: child) : child;
  }
}

/// Selector optimisé pour éviter les rebuilds inutiles
class OptimizedSelector<T, S> extends StatelessWidget {
  final S Function(T) selector;
  final Widget Function(BuildContext, S, Widget?) builder;
  final Widget? child;
  
  const OptimizedSelector({
    super.key,
    required this.selector,
    required this.builder,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Selector<T, S>(
      selector: (_, value) => selector(value),
      builder: builder,
      child: child,
    );
  }
}

/// Container avec lazy loading
class LazyContainer extends StatefulWidget {
  final Widget child;
  final Widget? placeholder;
  final Duration delay;
  
  const LazyContainer({
    super.key,
    required this.child,
    this.placeholder,
    this.delay = const Duration(milliseconds: 100),
  });
  
  @override
  State<LazyContainer> createState() => _LazyContainerState();
}

class _LazyContainerState extends State<LazyContainer> {
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoaded) return widget.child;
    return widget.placeholder ?? const SizedBox.shrink();
  }
}

/// ListView optimisé avec itemExtent et cacheExtent configurables
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double? itemExtent;
  final double cacheExtent;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final Axis scrollDirection;
  
  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent,
    this.cacheExtent = 250,
    this.controller,
    this.padding,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics ?? const ClampingScrollPhysics(),
      scrollDirection: scrollDirection,
      itemCount: itemCount,
      itemExtent: itemExtent,
      cacheExtent: cacheExtent,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// GridView optimisé
class OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final double cacheExtent;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  
  const OptimizedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.cacheExtent = 250,
    this.controller,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: physics ?? const ClampingScrollPhysics(),
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      cacheExtent: cacheExtent,
      shrinkWrap: shrinkWrap,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// Widget qui diffère le build pour améliorer les performances au démarrage
class DeferredWidget extends StatefulWidget {
  final Widget child;
  final Widget? placeholder;
  final int priority; // 0 = haute, 1 = moyenne, 2 = basse
  
  const DeferredWidget({
    super.key,
    required this.child,
    this.placeholder,
    this.priority = 1,
  });
  
  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  bool _shouldBuild = false;
  
  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }
  
  void _scheduleLoad() {
    final delay = Duration(milliseconds: 50 * (widget.priority + 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(delay, () {
        if (mounted) {
          setState(() => _shouldBuild = true);
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_shouldBuild) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    return widget.child;
  }
}

/// Widget pour mémoriser les widgets coûteux
class MemoizedWidget extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  final List<Object?> dependencies;
  
  const MemoizedWidget({
    super.key,
    required this.builder,
    required this.dependencies,
  });
  
  @override
  State<MemoizedWidget> createState() => _MemoizedWidgetState();
}

class _MemoizedWidgetState extends State<MemoizedWidget> {
  Widget? _cachedWidget;
  List<Object?>? _previousDependencies;
  
  bool _dependenciesChanged() {
    if (_previousDependencies == null) return true;
    if (_previousDependencies!.length != widget.dependencies.length) return true;
    
    for (int i = 0; i < widget.dependencies.length; i++) {
      if (widget.dependencies[i] != _previousDependencies![i]) return true;
    }
    return false;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_dependenciesChanged()) {
      _cachedWidget = widget.builder(context);
      _previousDependencies = List.from(widget.dependencies);
    }
    return _cachedWidget!;
  }
}

/// Extension pour ajouter facilement RepaintBoundary
extension WidgetPerformanceExtension on Widget {
  Widget withRepaintBoundary() => RepaintBoundary(child: this);
  
  Widget withKeyedSubtree(Key key) => KeyedSubtree(key: key, child: this);
}

