/// Factory pour créer les widgets de la page d'accueil
library widget_factory;

import 'package:flutter/material.dart';
import '../../../models/home_widget_models.dart';
import '../../home_widgets/home_widget_base.dart';
import '../../home_widgets/server_list_widget.dart';

class HomeWidgetFactory {
  static Widget buildWidget({
    required HomeWidget widget,
    VoidCallback? onMinimize,
    VoidCallback? onRemove,
    VoidCallback? onSettings,
  }) {
    Widget content;

    switch (widget.type) {
      case HomeWidgetType.serverList:
        content = ServerListWidget(widget: widget);
        break;
      
      case HomeWidgetType.systemMetrics:
        content = _SystemMetricsWidget(widget: widget);
        break;
      
      case HomeWidgetType.quickAccess:
        content = _QuickAccessWidget(widget: widget);
        break;
      
      case HomeWidgetType.recentHistory:
        content = _RecentHistoryWidget(widget: widget);
        break;
      
      case HomeWidgetType.bookmarks:
        content = _BookmarksWidget(widget: widget);
        break;
      
      case HomeWidgetType.quickTerminal:
        content = _QuickTerminalWidget(widget: widget);
        break;
      
      default:
        content = _PlaceholderWidget(widget: widget);
    }

    return HomeWidgetBase(
      widget: widget,
      onMinimize: onMinimize,
      onRemove: onRemove,
      onSettings: onSettings,
      child: content,
    );
  }
}

// Widgets placeholder (à implémenter)
class _SystemMetricsWidget extends StatelessWidget {
  final HomeWidget widget;
  const _SystemMetricsWidget({required this.widget});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Métriques Système'));
}

class _QuickAccessWidget extends StatelessWidget {
  final HomeWidget widget;
  const _QuickAccessWidget({required this.widget});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Accès Rapide'));
}

class _RecentHistoryWidget extends StatelessWidget {
  final HomeWidget widget;
  const _RecentHistoryWidget({required this.widget});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Historique Récent'));
}

class _BookmarksWidget extends StatelessWidget {
  final HomeWidget widget;
  const _BookmarksWidget({required this.widget});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Favoris'));
}

class _QuickTerminalWidget extends StatelessWidget {
  final HomeWidget widget;
  const _QuickTerminalWidget({required this.widget});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Terminal Rapide'));
}

class _PlaceholderWidget extends StatelessWidget {
  final HomeWidget widget;
  const _PlaceholderWidget({required this.widget});
  @override
  Widget build(BuildContext context) => Center(
    child: Text('Widget: ${widget.type.label}'),
  );
}

