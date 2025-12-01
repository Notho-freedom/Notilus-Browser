/// Service de gestion des widgets de la page d'accueil
library home_widget_service;

import 'dart:convert';
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_widget_models.dart';

class HomeWidgetService extends ChangeNotifier {
  static const String _prefsKey = 'notilus_home_widgets_config';
  
  HomePageConfig _config = HomePageConfig();
  bool _isInitialized = false;

  HomePageConfig get config => _config;
  bool get isInitialized => _isInitialized;
  List<HomeWidget> get widgets => _config.widgets;

  /// Initialiser le service
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadConfig();
    _isInitialized = true;
    notifyListeners();
  }

  /// Charger la configuration depuis le stockage
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_prefsKey);
      
      if (configJson != null) {
        final Map<String, dynamic> json = jsonDecode(configJson);
        _config = HomePageConfig.fromJson(json);
      } else {
        // Configuration par défaut avec quelques widgets
        _config = HomePageConfig(
          widgets: [
            HomeWidget(
              type: HomeWidgetType.quickAccess,
              size: WidgetSize.medium,
              position: Offset(0, 0),
            ),
            HomeWidget(
              type: HomeWidgetType.recentHistory,
              size: WidgetSize.medium,
              position: Offset(3, 0),
            ),
            HomeWidget(
              type: HomeWidgetType.systemMetrics,
              size: WidgetSize.large,
              position: Offset(6, 0),
            ),
          ],
        );
        await _saveConfig();
      }
    } catch (e) {
      debugPrint('Erreur chargement config widgets: $e');
      _config = HomePageConfig();
    }
  }

  /// Sauvegarder la configuration
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(_config.toJson());
      await prefs.setString(_prefsKey, configJson);
    } catch (e) {
      debugPrint('Erreur sauvegarde config widgets: $e');
    }
  }

  /// Ajouter un widget
  Future<void> addWidget(HomeWidget widget) async {
    _config = _config.copyWith(
      widgets: [..._config.widgets, widget],
    );
    await _saveConfig();
    notifyListeners();
  }

  /// Supprimer un widget
  Future<void> removeWidget(String widgetId) async {
    _config = _config.copyWith(
      widgets: _config.widgets.where((w) => w.id != widgetId).toList(),
    );
    await _saveConfig();
    notifyListeners();
  }

  /// Mettre à jour un widget
  Future<void> updateWidget(HomeWidget widget) async {
    final index = _config.widgets.indexWhere((w) => w.id == widget.id);
    if (index != -1) {
      final widgets = List<HomeWidget>.from(_config.widgets);
      widgets[index] = widget;
      _config = _config.copyWith(widgets: widgets);
      await _saveConfig();
      notifyListeners();
    }
  }

  /// Déplacer un widget
  Future<void> moveWidget(String widgetId, Offset newPosition) async {
    final widget = _config.widgets.firstWhere(
      (w) => w.id == widgetId,
      orElse: () => throw Exception('Widget not found'),
    );
    await updateWidget(widget.copyWith(position: newPosition));
  }

  /// Redimensionner un widget
  Future<void> resizeWidget(String widgetId, WidgetSize newSize) async {
    final widget = _config.widgets.firstWhere(
      (w) => w.id == widgetId,
      orElse: () => throw Exception('Widget not found'),
    );
    await updateWidget(widget.copyWith(size: newSize));
  }

  /// Minimiser/Restaurer un widget
  Future<void> toggleMinimize(String widgetId) async {
    final widget = _config.widgets.firstWhere(
      (w) => w.id == widgetId,
      orElse: () => throw Exception('Widget not found'),
    );
    await updateWidget(widget.copyWith(isMinimized: !widget.isMinimized));
  }

  /// Réinitialiser la configuration
  Future<void> resetConfig() async {
    _config = HomePageConfig();
    await _saveConfig();
    notifyListeners();
  }

  /// Mettre à jour la configuration de la grille
  Future<void> updateGridConfig({
    int? columns,
    int? rows,
    double? spacing,
    bool? snapToGrid,
  }) async {
    _config = _config.copyWith(
      gridColumns: columns,
      gridRows: rows,
      widgetSpacing: spacing,
      snapToGrid: snapToGrid,
    );
    await _saveConfig();
    notifyListeners();
  }
}

