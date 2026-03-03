import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_windows/webview_windows.dart';
import 'tab_webview_manager.dart';
import 'tab_manager.dart';
import '../models/tab_model.dart';

/// Données de preview d'un onglet
class TabPreviewData {
  final String tabId;
  final Uint8List? imageBytes;
  final DateTime lastUpdate;
  final bool isLoading;

  TabPreviewData({
    required this.tabId,
    this.imageBytes,
    DateTime? lastUpdate,
    this.isLoading = false,
  }) : lastUpdate = lastUpdate ?? DateTime.now();
}

/// Service pour gérer les snapshots/previews des onglets
class TabsPreviewService extends ChangeNotifier {
  static final TabsPreviewService _instance = TabsPreviewService._internal();
  factory TabsPreviewService() => _instance;
  TabsPreviewService._internal();

  // Cache LRU des previews (max 20 onglets)
  final Map<String, TabPreviewData> _previewCache = {};
  final int _maxCacheSize = 20;
  
  // Timers pour auto-capture
  final Map<String, Timer> _captureTimers = {};
  
  // Intervalle de capture (300ms pour fluidité)
  static const Duration _captureInterval = Duration(milliseconds: 500);
  
  // Flag pour vérifier si le service est disposé
  bool _disposed = false;
  
  TabWebViewManager? _tabWebViewManager;
  TabManager? _tabManager;

  /// Initialise le service avec les managers
  void initialize(TabWebViewManager tabWebViewManager, TabManager tabManager) {
    _tabWebViewManager = tabWebViewManager;
    _tabManager = tabManager;
    
    // Écouter les changements d'onglets pour capturer automatiquement
    _tabManager?.addListener(_onTabsChanged);
    
    // Délayer l'appel initial pour éviter setState pendant build
    Future.microtask(() => _onTabsChanged());
  }

  void _onTabsChanged() {
    if (_tabManager == null || _disposed) return;
    
    final tabs = _tabManager!.tabs;
    final currentTabIds = tabs.map((t) => t.id).toSet();
    
    // Nettoyer les timers des onglets fermés
    // Créer une copie de la liste des clés pour éviter la modification concurrente
    final timerKeys = _captureTimers.keys.toList();
    for (final tabId in timerKeys) {
      if (!currentTabIds.contains(tabId)) {
        _captureTimers[tabId]?.cancel();
        _captureTimers.remove(tabId);
        _previewCache.remove(tabId);
      }
    }
    
    // Démarrer la capture pour les nouveaux onglets
    for (final tab in tabs) {
      if (!_captureTimers.containsKey(tab.id) && 
          tab.url != null && 
          !tab.url!.startsWith('about:')) {
        _startAutoCapture(tab.id);
      }
    }
    
    // Ne pas appeler notifyListeners() si on est en train de build
    // Utiliser SchedulerBinding pour différer et vérifier que le service n'est pas disposé
    if (!_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          try {
            notifyListeners();
          } catch (e) {
            debugPrint('Erreur notifyListeners TabsPreviewService: $e');
          }
        }
      });
    }
  }

  /// Démarre la capture automatique pour un onglet
  void _startAutoCapture(String tabId) {
    if (_disposed) return;
    
    _captureTimers[tabId]?.cancel();
    
    _captureTimers[tabId] = Timer.periodic(_captureInterval, (_) async {
      if (!_disposed) {
        await captureTabPreview(tabId);
      }
    });
    
    // Capture immédiate
    if (!_disposed) {
      captureTabPreview(tabId);
    }
  }

  /// Capture une preview d'un onglet
  Future<void> captureTabPreview(String tabId) async {
    if (_tabWebViewManager == null || _disposed) return;
    
    try {
      final engine = _tabWebViewManager!.getEngine(tabId);
      if (engine == null) return;
      
      final controller = await engine.getController();
      if (controller == null || controller is! WebviewController) return;
      
      // Marquer comme en chargement
      if (!_disposed) {
        _previewCache[tabId] = TabPreviewData(
          tabId: tabId,
          imageBytes: _previewCache[tabId]?.imageBytes, // Garder l'ancienne image
          isLoading: true,
        );
        try {
          notifyListeners();
        } catch (e) {
          debugPrint('Erreur notifyListeners avant capture: $e');
        }
      }
      
      // Capturer le snapshot via JavaScript (html2canvas-like)
      Uint8List? imageBytes;
      try {
        // Utiliser html2canvas via CDN ou une méthode native si disponible
        // Pour l'instant, on utilise une méthode simple avec canvas
        final script = '''
          (function() {
            try {
              const canvas = document.createElement('canvas');
              const width = Math.max(document.documentElement.scrollWidth, window.innerWidth);
              const height = Math.max(document.documentElement.scrollHeight, window.innerHeight);
              canvas.width = Math.min(width, 1920); // Limiter la taille
              canvas.height = Math.min(height, 1080);
              const ctx = canvas.getContext('2d');
              
              // Fond blanc
              ctx.fillStyle = '#ffffff';
              ctx.fillRect(0, 0, canvas.width, canvas.height);
              
              // Essayer de capturer le body (méthode simplifiée)
              // Note: Cette méthode ne capture pas tout, mais donne une preview
              ctx.fillStyle = '#000000';
              ctx.font = '16px Arial';
              ctx.fillText(document.title || 'Page', 10, 30);
              
              return canvas.toDataURL('image/png');
            } catch(e) {
              return null;
            }
          })();
        ''';
        
        final result = await controller.executeScript(script);
        if (result != null && result is String && result.startsWith('data:image')) {
          // Extraire les bytes depuis data URL
          final base64 = result.split(',')[1];
          if (base64.isNotEmpty) {
            imageBytes = Uint8List.fromList(base64Decode(base64));
          }
        }
      } catch (e) {
        debugPrint('Erreur capture preview: $e');
      }
      
      // Mettre à jour le cache
      if (!_disposed && imageBytes != null && imageBytes.isNotEmpty) {
        // Valider que les bytes sont une image valide avant de stocker
        final isValidImage = imageBytes.length > 8 && (
          // PNG header: 89 50 4E 47 0D 0A 1A 0A
          (imageBytes[0] == 0x89 && imageBytes[1] == 0x50 && imageBytes[2] == 0x4E && imageBytes[3] == 0x47) ||
          // JPEG header: FF D8 FF
          (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8 && imageBytes[2] == 0xFF) ||
          // GIF header: 47 49 46 38
          (imageBytes[0] == 0x47 && imageBytes[1] == 0x49 && imageBytes[2] == 0x46 && imageBytes[3] == 0x38)
        );
        
        if (isValidImage) {
          _previewCache[tabId] = TabPreviewData(
            tabId: tabId,
            imageBytes: imageBytes,
            lastUpdate: DateTime.now(),
            isLoading: false,
          );
          
          // Nettoyer le cache si trop grand (LRU)
          if (_previewCache.length > _maxCacheSize) {
            final oldest = _previewCache.entries
                .reduce((a, b) => a.value.lastUpdate.isBefore(b.value.lastUpdate) ? a : b);
            _previewCache.remove(oldest.key);
          }
          
          if (!_disposed) {
            try {
              notifyListeners();
            } catch (e) {
              debugPrint('Erreur notifyListeners après capture: $e');
            }
          }
        } else {
          debugPrint('⚠️ Bytes invalides pour preview $tabId, ignorés');
        }
      } else if (!_disposed) {
        // Si la capture échoue, garder l'ancienne image mais marquer comme non-chargement
        _previewCache[tabId] = TabPreviewData(
          tabId: tabId,
          imageBytes: _previewCache[tabId]?.imageBytes,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('Erreur capture preview pour $tabId: $e');
      if (!_disposed) {
        _previewCache[tabId] = TabPreviewData(
          tabId: tabId,
          imageBytes: _previewCache[tabId]?.imageBytes,
          isLoading: false,
        );
      }
    }
  }

  /// Obtient la preview d'un onglet
  TabPreviewData? getPreview(String tabId) {
    return _previewCache[tabId];
  }

  /// Force la capture d'un onglet
  Future<void> forceCapture(String tabId) async {
    await captureTabPreview(tabId);
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    _disposed = true;
    _tabManager?.removeListener(_onTabsChanged);
    _captureTimers.forEach((_, timer) => timer.cancel());
    _captureTimers.clear();
    _previewCache.clear();
    super.dispose();
  }
}

