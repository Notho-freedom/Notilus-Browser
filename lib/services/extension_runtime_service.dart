import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/extension.dart';
import 'browser_engine.dart';
import 'extension_service.dart';
import '../core/services/logger_service.dart';

/// Runtime basique pour exécuter les extensions Notilus
/// API minimale pour la bêta
class ExtensionRuntimeService {
  static final ExtensionRuntimeService _instance = ExtensionRuntimeService._internal();
  factory ExtensionRuntimeService() => _instance;
  ExtensionRuntimeService._internal();

  final ExtensionService _extensionService = ExtensionService();
  final Map<String, BrowserEngine> _engineMap = {};
  final Map<String, Timer> _extensionTimers = {};
  final Map<String, bool> _runningExtensions = {};

  /// Initialise le runtime avec un moteur de rendu
  void attachEngine(String tabId, BrowserEngine engine) {
    _engineMap[tabId] = engine;
    _loadExtensionsForTab(tabId);
  }

  /// Détache un moteur de rendu
  void detachEngine(String tabId) {
    _stopAllExtensionsForTab(tabId);
    _engineMap.remove(tabId);
  }

  /// Charge et exécute les extensions pour un onglet
  Future<void> _loadExtensionsForTab(String tabId) async {
    final engine = _engineMap[tabId];
    if (engine == null) return;

    try {
      final activeExtensions = await _extensionService.getActiveExtensions();
      
      for (final extension in activeExtensions) {
        if (extension.type == ExtensionType.contentScript) {
          await _injectContentScript(tabId, extension);
        } else if (extension.type == ExtensionType.background) {
          await _startBackgroundScript(extension);
        }
      }
    } catch (e) {
      LoggerService().error('Error loading extensions for tab', error: e);
    }
  }

  /// Injecte un script de contenu dans une page
  Future<void> _injectContentScript(String tabId, Extension extension) async {
    final engine = _engineMap[tabId];
    if (engine == null) return;

    // Récupérer le code depuis le manifest
    final contentScripts = extension.manifest['content_scripts'] as List<dynamic>?;
    if (contentScripts == null || contentScripts.isEmpty) {
      // Pour la bêta, si pas de content_scripts, on utilise un script par défaut du manifest
      final js = extension.manifest['js'] as String?;
      if (js == null || js.isEmpty) return;
      
      try {
        final wrappedScript = _wrapContentScript(js, extension.id);
        await engine.executeJavaScript(wrappedScript);
        LoggerService().info('✅ Extension ${extension.name} injectée dans l\'onglet $tabId');
      } catch (e) {
        LoggerService().error('Error injecting content script', error: e);
      }
      return;
    }

    // Injecter chaque script de contenu
    for (final scriptEntry in contentScripts) {
      final scripts = (scriptEntry as Map<String, dynamic>)['js'] as List<dynamic>?;
      if (scripts != null) {
        for (final script in scripts) {
          try {
            final scriptCode = script as String;
            final wrappedScript = _wrapContentScript(scriptCode, extension.id);
            await engine.executeJavaScript(wrappedScript);
          } catch (e) {
            LoggerService().error('Error injecting content script', error: e);
          }
        }
      }
    }
    
    LoggerService().info('✅ Extension ${extension.name} injectée dans l\'onglet $tabId');
  }

  /// Démarre un script en arrière-plan
  Future<void> _startBackgroundScript(Extension extension) async {
    if (_runningExtensions[extension.id] == true) return;
    
    // Récupérer le script background depuis le manifest
    final background = extension.manifest['background'] as Map<String, dynamic>?;
    final backgroundScript = background?['scripts'] as List<dynamic>?;
    if (backgroundScript == null || backgroundScript.isEmpty) return;

    try {
      // Pour la bêta, on exécute simplement le script dans un isolate Dart
      // Dans une version future, on pourrait utiliser un vrai isolate JavaScript
      _runningExtensions[extension.id] = true;
      
      // Note: Les scripts background sont exécutés une seule fois au démarrage
      // Pour la bêta, on simule juste l'exécution
      LoggerService().info('✅ Extension background ${extension.name} démarrée');
    } catch (e) {
      LoggerService().error('Error starting background script', error: e);
      _runningExtensions[extension.id] = false;
    }
  }

  /// Arrête toutes les extensions pour un onglet
  void _stopAllExtensionsForTab(String tabId) {
    // Nettoyer les timers et états
    _extensionTimers.forEach((extId, timer) {
      timer.cancel();
    });
    _extensionTimers.clear();
  }

  /// Enveloppe un script de contenu avec l'API Notilus minimale
  String _wrapContentScript(String script, String extensionId) {
    return '''
      (function() {
        // API Notilus minimale pour les extensions
        const Notilus = {
          // API de stockage
          storage: {
            local: {
              get: function(keys) {
                try {
                  const data = localStorage.getItem('notilus_ext_${extensionId}');
                  return data ? JSON.parse(data) : {};
                } catch (e) {
                  return {};
                }
              },
              set: function(items) {
                try {
                  localStorage.setItem('notilus_ext_${extensionId}', JSON.stringify(items));
                } catch (e) {
                  console.error('Notilus.storage.local.set error:', e);
                }
              },
              remove: function(keys) {
                try {
                  const data = JSON.parse(localStorage.getItem('notilus_ext_${extensionId}') || '{}');
                  if (Array.isArray(keys)) {
                    keys.forEach(key => delete data[key]);
                  } else {
                    delete data[keys];
                  }
                  localStorage.setItem('notilus_ext_${extensionId}', JSON.stringify(data));
                } catch (e) {
                  console.error('Notilus.storage.local.remove error:', e);
                }
              }
            }
          },
          
          // API de messages (basique)
          runtime: {
            sendMessage: function(message, callback) {
              // Pour la bêta, on log juste le message
              console.log('[Notilus Extension ${extensionId}]', message);
              if (callback) {
                setTimeout(() => callback({ success: true }), 0);
              }
            },
            onMessage: {
              addListener: function(callback) {
                // Pour la bêta, on ne supporte pas vraiment les messages
                console.warn('Notilus.runtime.onMessage.addListener not fully supported in beta');
              }
            }
          },
          
          // API de tabs (basique)
          tabs: {
            query: function(queryInfo, callback) {
              // Pour la bêta, on retourne juste l'onglet actuel
              if (callback) {
                callback([{
                  id: 1,
                  url: window.location.href,
                  title: document.title
                }]);
              }
            },
            sendMessage: function(tabId, message, callback) {
              console.log('[Notilus Extension ${extensionId}] Message to tab:', message);
              if (callback) {
                setTimeout(() => callback({ success: true }), 0);
              }
            }
          },
          
          // API de notifications (basique)
          notifications: {
            create: function(notificationId, options, callback) {
              console.log('[Notilus Extension ${extensionId}] Notification:', options.title, options.message);
              if (callback) {
                setTimeout(() => callback(notificationId), 0);
              }
            }
          }
        };
        
        // Exposer Notilus globalement
        window.Notilus = Notilus;
        
        // Exécuter le script de l'extension dans un contexte isolé
        try {
          ${script}
        } catch (e) {
          console.error('[Notilus Extension ${extensionId}] Error:', e);
        }
      })();
    ''';
  }

  /// Recharge toutes les extensions actives
  Future<void> reloadExtensions() async {
    // Arrêter toutes les extensions
    _stopAllExtensionsForTab('');
    _runningExtensions.clear();
    
    // Recharger pour tous les onglets actifs
    _engineMap.forEach((tabId, engine) {
      _loadExtensionsForTab(tabId);
    });
  }

  /// Vérifie si une extension est en cours d'exécution
  bool isExtensionRunning(String extensionId) {
    return _runningExtensions[extensionId] == true;
  }
}

