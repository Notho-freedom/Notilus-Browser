import 'package:flutter/foundation.dart';
import 'dart:io';

class SystemMetricsService extends ChangeNotifier {
  double _cpuUsage = 0.0;
  double _ramUsage = 0.0;
  String _networkStatus = 'Stable';
  double _gpuTemp = 0.0;
  double _batteryLevel = 0.0;
  int _tabCount = 0;
  Duration _activeTime = Duration.zero;
  int _pagesVisited = 0;
  double _dataUsed = 0.0; // en GB

  double get cpuUsage => _cpuUsage;
  double get ramUsage => _ramUsage;
  String get networkStatus => _networkStatus;
  double get gpuTemp => _gpuTemp;
  double get batteryLevel => _batteryLevel;
  int get tabCount => _tabCount;
  Duration get activeTime => _activeTime;
  int get pagesVisited => _pagesVisited;
  double get dataUsed => _dataUsed;

  DateTime? _sessionStartTime;

  SystemMetricsService() {
    _sessionStartTime = DateTime.now();
    _startMetricsUpdate();
  }

  void _startMetricsUpdate() {
    // Simuler des métriques système (à remplacer par de vraies APIs système)
    Future.delayed(const Duration(seconds: 2), () {
      _updateMetrics();
    });
  }

  void _updateMetrics() {
    // Simuler des valeurs (à remplacer par de vraies APIs)
    _cpuUsage = 20.0 + (DateTime.now().millisecond % 50);
    _ramUsage = 40.0 + (DateTime.now().millisecond % 30);
    _gpuTemp = 50.0 + (DateTime.now().millisecond % 20);
    _batteryLevel = 80.0 + (DateTime.now().millisecond % 20);
    
    // Calculer le temps actif
    if (_sessionStartTime != null) {
      _activeTime = DateTime.now().difference(_sessionStartTime!);
    }
    
    notifyListeners();
    
    // Mettre à jour toutes les 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      _updateMetrics();
    });
  }

  void updateTabCount(int count) {
    if (_tabCount != count) {
      _tabCount = count;
      notifyListeners();
    }
  }

  void incrementPagesVisited() {
    _pagesVisited++;
    notifyListeners();
  }

  void addDataUsed(double mb) {
    _dataUsed += mb / 1024; // Convertir MB en GB
    notifyListeners();
  }

  String formatActiveTime() {
    final hours = _activeTime.inHours;
    final minutes = _activeTime.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String formatDataUsed() {
    if (_dataUsed < 1.0) {
      return '${(_dataUsed * 1024).toStringAsFixed(0)} MB';
    }
    return '${_dataUsed.toStringAsFixed(1)} GB';
  }
}

