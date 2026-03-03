/// Performance Utils - Utilitaires pour les optimisations de performance
/// Inclut des widgets et helpers pour améliorer la réactivité
library performance_utils;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// =============================================================================
// DEBOUNCER - Évite les appels trop fréquents
// =============================================================================

/// Debouncer pour éviter les appels répétés
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Exécute l'action après le délai (annule l'action précédente)
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Annule le timer en cours
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose du debouncer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

// =============================================================================
// THROTTLER - Limite la fréquence des appels
// =============================================================================

/// Throttler pour limiter la fréquence des appels
class Throttler {
  final Duration interval;
  DateTime? _lastRun;

  Throttler({this.interval = const Duration(milliseconds: 100)});

  /// Exécute l'action si l'intervalle est écoulé
  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= interval) {
      _lastRun = now;
      action();
    }
  }

  /// Réinitialise le throttler
  void reset() {
    _lastRun = null;
  }
}

// =============================================================================
// OPTIMIZED BUILDER - Widget builder avec frame scheduling
// =============================================================================

/// Builder optimisé qui attend le prochain frame avant de rebuild
class OptimizedBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Object? rebuildKey;

  const OptimizedBuilder({
    super.key,
    required this.builder,
    this.rebuildKey,
  });

  @override
  State<OptimizedBuilder> createState() => _OptimizedBuilderState();
}

class _OptimizedBuilderState extends State<OptimizedBuilder> {
  Widget? _cachedWidget;
  Object? _lastKey;
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    if (_cachedWidget == null || _lastKey != widget.rebuildKey) {
      if (!_scheduled) {
        _scheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _cachedWidget = widget.builder(context);
              _lastKey = widget.rebuildKey;
              _scheduled = false;
            });
          }
        });
      }
      return _cachedWidget ?? const SizedBox.shrink();
    }
    return _cachedWidget!;
  }
}

// =============================================================================
// LAZY WIDGET - Widget chargé à la demande
// =============================================================================

/// Widget qui se charge uniquement quand il devient visible
class LazyWidget extends StatefulWidget {
  final WidgetBuilder builder;
  final Widget placeholder;
  final Duration delay;

  const LazyWidget({
    super.key,
    required this.builder,
    this.placeholder = const SizedBox.shrink(),
    this.delay = Duration.zero,
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  bool _isLoaded = false;
  Widget? _child;

  @override
  void initState() {
    super.initState();
    _loadWidget();
  }

  Future<void> _loadWidget() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }
    
    if (mounted) {
      setState(() {
        _child = widget.builder(context);
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoaded ? _child! : widget.placeholder;
  }
}

// =============================================================================
// KEEP ALIVE WRAPPER - Garde les widgets en vie dans les listes
// =============================================================================

/// Wrapper pour garder un widget en vie dans une liste
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// =============================================================================
// REPAINT BOUNDARY WRAPPER - Isole les repaints
// =============================================================================

/// Wrapper avec RepaintBoundary pour isoler les repaints
class IsolatedRepaint extends StatelessWidget {
  final Widget child;

  const IsolatedRepaint({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

// =============================================================================
// FRAME LIMITER - Limite le nombre de rebuilds par seconde
// =============================================================================

/// Mixin pour limiter les rebuilds
mixin FrameLimiter<T extends StatefulWidget> on State<T> {
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  static const int _maxFramesPerSecond = 60;

  bool shouldRebuild() {
    final now = DateTime.now();
    
    if (_lastFrameTime == null) {
      _lastFrameTime = now;
      _frameCount = 1;
      return true;
    }
    
    final elapsed = now.difference(_lastFrameTime!);
    
    if (elapsed >= const Duration(seconds: 1)) {
      _lastFrameTime = now;
      _frameCount = 1;
      return true;
    }
    
    if (_frameCount >= _maxFramesPerSecond) {
      return false;
    }
    
    _frameCount++;
    return true;
  }
}

// =============================================================================
// ASYNC VALUE BUILDER - Builder pour les valeurs async avec cache
// =============================================================================

/// Builder pour les valeurs asynchrones avec mise en cache
class AsyncValueBuilder<T> extends StatefulWidget {
  final Future<T> Function() future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context, Object error)? error;
  final Duration? cacheDuration;

  const AsyncValueBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.error,
    this.cacheDuration,
  });

  @override
  State<AsyncValueBuilder<T>> createState() => _AsyncValueBuilderState<T>();
}

class _AsyncValueBuilderState<T> extends State<AsyncValueBuilder<T>> {
  T? _cachedValue;
  DateTime? _cacheTime;
  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadValue();
  }

  bool get _isCacheValid {
    if (_cachedValue == null || _cacheTime == null) return false;
    if (widget.cacheDuration == null) return true;
    return DateTime.now().difference(_cacheTime!) < widget.cacheDuration!;
  }

  Future<void> _loadValue() async {
    if (_isCacheValid) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final value = await widget.future();
      if (mounted) {
        setState(() {
          _cachedValue = value;
          _cacheTime = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.error != null) {
      return widget.error!(context, _error!);
    }

    if (_isLoading && !_isCacheValid) {
      return widget.loading?.call(context) ?? 
          const Center(child: CircularProgressIndicator());
    }

    if (_cachedValue != null) {
      return widget.builder(context, _cachedValue as T);
    }

    return widget.loading?.call(context) ?? const SizedBox.shrink();
  }
}

// =============================================================================
// EXTENSIONS
// =============================================================================

extension PerformanceExtensions on Widget {
  /// Enveloppe le widget dans un RepaintBoundary
  Widget isolated() => RepaintBoundary(child: this);

  /// Enveloppe le widget pour le garder en vie
  Widget keepAlive() => KeepAliveWrapper(child: this);
}

