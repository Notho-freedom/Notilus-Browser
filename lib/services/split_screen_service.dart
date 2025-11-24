import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/tab_model.dart';

enum SplitLayout { horizontal, vertical, grid }

class SplitPaneConfig {
  final String? tabId;
  final double size; // Proportion (0.0 - 1.0)

  SplitPaneConfig({
    this.tabId,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
    'tabId': tabId,
    'size': size,
  };

  factory SplitPaneConfig.fromJson(Map<String, dynamic> json) => SplitPaneConfig(
    tabId: json['tabId'],
    size: (json['size'] as num).toDouble(),
  );
}

class SplitScreenService extends ChangeNotifier {
  static const String _prefsKey = 'notilus_split_screen_config';
  
  bool _isActive = false;
  SplitLayout _layout = SplitLayout.horizontal;
  List<SplitPaneConfig> _panes = [
    SplitPaneConfig(size: 0.5),
    SplitPaneConfig(size: 0.5),
  ];

  bool get isActive => _isActive;
  SplitLayout get layout => _layout;
  List<SplitPaneConfig> get panes => List.unmodifiable(_panes);

  SplitScreenService() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_prefsKey);
      if (configJson != null) {
        final config = jsonDecode(configJson) as Map<String, dynamic>;
        _isActive = config['isActive'] ?? false;
        _layout = SplitLayout.values[config['layout'] ?? 0];
        _panes = (config['panes'] as List)
            .map((p) => SplitPaneConfig.fromJson(p as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // Ignore errors, use defaults
    }
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final config = {
        'isActive': _isActive,
        'layout': _layout.index,
        'panes': _panes.map((p) => p.toJson()).toList(),
      };
      await prefs.setString(_prefsKey, jsonEncode(config));
    } catch (e) {
      // Ignore save errors
    }
  }

  void toggle() {
    _isActive = !_isActive;
    if (!_isActive) {
      // Reset to default when deactivating
      _panes = [
        SplitPaneConfig(size: 0.5),
        SplitPaneConfig(size: 0.5),
      ];
    }
    notifyListeners();
    _saveConfig();
  }

  void setLayout(SplitLayout layout) {
    _layout = layout;
    notifyListeners();
    _saveConfig();
  }

  void addPane() {
    final newSize = 1.0 / (_panes.length + 1);
    _panes = _panes.map((p) => SplitPaneConfig(
      tabId: p.tabId,
      size: newSize,
    )).toList();
    _panes.add(SplitPaneConfig(size: newSize));
    notifyListeners();
    _saveConfig();
  }

  void removePane(int index) {
    if (_panes.length <= 1) return;
    
    final removedSize = _panes[index].size;
    _panes.removeAt(index);
    
    // Redistribute sizes
    final newSize = removedSize / _panes.length;
    _panes = _panes.map((p) => SplitPaneConfig(
      tabId: p.tabId,
      size: p.size + newSize,
    )).toList();
    
    notifyListeners();
    _saveConfig();
  }

  void setPaneTab(int paneIndex, String? tabId) {
    if (paneIndex >= 0 && paneIndex < _panes.length) {
      _panes[paneIndex] = SplitPaneConfig(
        tabId: tabId,
        size: _panes[paneIndex].size,
      );
      notifyListeners();
      _saveConfig();
    }
  }

  void resizePanes(int resizingIndex, double delta) {
    if (resizingIndex < 0 || resizingIndex >= _panes.length - 1) return;
    
    final minSize = 0.1;
    final maxSize = 0.9;
    
    if (_panes[resizingIndex].size + delta >= minSize &&
        _panes[resizingIndex].size + delta <= maxSize &&
        _panes[resizingIndex + 1].size - delta >= minSize &&
        _panes[resizingIndex + 1].size - delta <= maxSize) {
      _panes[resizingIndex] = SplitPaneConfig(
        tabId: _panes[resizingIndex].tabId,
        size: _panes[resizingIndex].size + delta,
      );
      _panes[resizingIndex + 1] = SplitPaneConfig(
        tabId: _panes[resizingIndex + 1].tabId,
        size: _panes[resizingIndex + 1].size - delta,
      );
      notifyListeners();
    }
  }

  void swapPanes(int index1, int index2) {
    if (index1 < 0 || index1 >= _panes.length ||
        index2 < 0 || index2 >= _panes.length) return;
    
    final temp = _panes[index1];
    _panes[index1] = _panes[index2];
    _panes[index2] = temp;
    notifyListeners();
    _saveConfig();
  }

  void clearAllPanes() {
    _panes = _panes.map((p) => SplitPaneConfig(size: p.size)).toList();
    notifyListeners();
    _saveConfig();
  }
}

