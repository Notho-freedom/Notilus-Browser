/// Données de drag pour les widgets de la page d'accueil
library home_widget_drag_data;

import 'home_widget_models.dart';

/// Données transportées lors du drag d'un widget
class HomeWidgetDragData {
  final HomeWidget widget;
  final String sourceWidgetId;

  const HomeWidgetDragData({
    required this.widget,
    required this.sourceWidgetId,
  });
}

