import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'ai_service.dart';
import 'settings_service.dart';
import '../widgets/common/gx_futuristic_dialog.dart';
import '../main.dart' as app;

/// Service pour gérer les sélections de texte globales dans l'application
class TextSelectionService extends ChangeNotifier {
  static final TextSelectionService _instance = TextSelectionService._internal();
  factory TextSelectionService() => _instance;
  TextSelectionService._internal();

  String? _selectedText;
  Offset? _selectionPosition;
  GlobalKey? _selectionKey;
  bool _isVisible = false;
  BuildContext? _rootContext;

  String? get selectedText => _selectedText;
  Offset? get selectionPosition => _selectionPosition;
  GlobalKey? get selectionKey => _selectionKey;
  bool get isVisible => _isVisible;
  
  /// Définit le contexte root qui contient le Navigator
  void setRootContext(BuildContext context) {
    _rootContext = context;
  }
  
  /// Obtient le GlobalKey du Navigator depuis NotilusApp
  GlobalKey<NavigatorState>? _getNavigatorKey() {
    try {
      return app.NotilusApp.navigatorKey;
    } catch (e) {
      debugPrint('⚠️ Impossible d\'accéder au navigatorKey: $e');
      return null;
    }
  }

  /// Affiche le menu pour une sélection de texte
  void showMenu(String text, Offset position, [GlobalKey? key]) {
    debugPrint('🎯 TextSelectionService.showMenu: "$text" à $position');
    _selectedText = text;
    _selectionPosition = position;
    _selectionKey = key;
    _isVisible = true;
    notifyListeners();
    debugPrint('✅ Menu visible: $_isVisible, position: $_selectionPosition');
  }

  /// Cache le menu
  void hideMenu() {
    _isVisible = false;
    _selectedText = null;
    _selectionPosition = null;
    _selectionKey = null;
    notifyListeners();
  }

  /// Copie le texte sélectionné
  Future<void> copyText() async {
    if (_selectedText != null && _selectedText!.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _selectedText!));
      hideMenu();
    }
  }

  /// Recherche le texte sélectionné (à implémenter selon les besoins)
  void searchText() {
    // TODO: Implémenter la recherche
    hideMenu();
  }

  /// Traduit le texte sélectionné
  Future<void> translateText(BuildContext context) async {
    // Sauvegarder le texte AVANT de fermer le menu
    final textToTranslate = _selectedText;
    if (textToTranslate == null || textToTranslate.isEmpty) {
      hideMenu();
      return;
    }
    
    // Utiliser le GlobalKey du Navigator pour obtenir un contexte valide
    NavigatorState? navigator;
    BuildContext? navigatorContext;
    
    try {
      // Importer NotilusApp pour accéder au navigatorKey
      final navigatorKey = _getNavigatorKey();
      if (navigatorKey != null && navigatorKey.currentState != null) {
        navigator = navigatorKey.currentState;
        navigatorContext = navigator!.overlay?.context;
        debugPrint('✅ Navigator obtenu via GlobalKey');
      } else {
        throw Exception('NavigatorKey non disponible');
      }
    } catch (e) {
      debugPrint('⚠️ Impossible d\'obtenir le Navigator via GlobalKey: $e');
      // Fallback: essayer avec le contexte root ou passé
      BuildContext? contextToUse = _rootContext ?? context;
      try {
        navigator = Navigator.maybeOf(contextToUse, rootNavigator: true);
        if (navigator != null) {
          navigatorContext = navigator.overlay?.context;
          debugPrint('✅ Navigator obtenu via contexte');
        }
      } catch (e2) {
        debugPrint('⚠️ Fallback Navigator a échoué: $e2');
      }
    }
    
    hideMenu(); // Fermer le menu immédiatement
    
    try {
      final aiService = AiService();
      final settings = SettingsService();
      
      debugPrint('🌐 Traduction: "$textToTranslate"');
      
      final prompt = 'Traduis ce texte en français de manière naturelle et fluide. Réponds uniquement avec la traduction, sans explications:\n\n$textToTranslate';
      
      final response = await aiService.chat(
        prompt: prompt,
        type: 'translation',
        model: settings.aiPreferredModel.isNotEmpty ? settings.aiPreferredModel : null,
      );
      
      debugPrint('📥 Réponse IA: $response');
      
      if (response != null) {
        // Essayer différentes clés possibles pour la réponse
        String? translatedText = response['content'] as String?;
        translatedText ??= response['response'] as String?;
        translatedText ??= response['message'] as String?;
        translatedText ??= response['text'] as String?;
        
        // Si c'est une Map, essayer de trouver une valeur String
        if (translatedText == null && response is Map) {
          for (var value in response.values) {
            if (value is String && value.isNotEmpty && value != textToTranslate) {
              translatedText = value;
              break;
            }
          }
        }
        
        if (translatedText != null && translatedText.isNotEmpty) {
          final finalTranslatedText = translatedText.trim();
          await Clipboard.setData(ClipboardData(text: finalTranslatedText));
          
          // Utiliser le contexte capturé ou essayer de le récupérer
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              BuildContext? dialogContext;
              if (navigatorContext != null && navigatorContext!.mounted) {
                dialogContext = navigatorContext;
              } else if (navigator != null) {
                try {
                  dialogContext = navigator!.overlay?.context;
                  if (dialogContext != null && !dialogContext.mounted) {
                    dialogContext = null;
                  }
                } catch (_) {}
              }
              
              if (dialogContext != null && dialogContext.mounted) {
                _showTranslationDialog(dialogContext, textToTranslate, finalTranslatedText);
              } else {
                debugPrint('⚠️ Aucun contexte valide pour afficher le dialogue');
              }
            } catch (e) {
              debugPrint('⚠️ Erreur affichage dialogue traduction: $e');
            }
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              BuildContext? dialogContext;
              if (navigatorContext != null && navigatorContext!.mounted) {
                dialogContext = navigatorContext;
              } else if (navigator != null) {
                try {
                  dialogContext = navigator!.overlay?.context;
                  if (dialogContext != null && !dialogContext.mounted) {
                    dialogContext = null;
                  }
                } catch (_) {}
              }
              
              if (dialogContext != null && dialogContext.mounted) {
                _showErrorDialog(dialogContext, 'Traduction', 'Aucune traduction reçue de l\'IA.');
              }
            } catch (e) {
              debugPrint('⚠️ Erreur affichage dialogue erreur: $e');
            }
          });
        }
      } else {
        final error = aiService.lastError ?? 'Erreur inconnue';
        debugPrint('❌ Erreur traduction: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            BuildContext? dialogContext;
            if (navigatorContext != null && navigatorContext!.mounted) {
              dialogContext = navigatorContext;
            } else if (navigator != null) {
              try {
                dialogContext = navigator!.overlay?.context;
                if (dialogContext != null && !dialogContext.mounted) {
                  dialogContext = null;
                }
              } catch (_) {}
            }
            
            if (dialogContext != null && dialogContext.mounted) {
              _showErrorDialog(dialogContext, 'Traduction', error);
            }
          } catch (e) {
            debugPrint('⚠️ Erreur affichage dialogue erreur: $e');
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception traduction: $e');
      debugPrint('Stack trace: $stackTrace');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          BuildContext? dialogContext;
          if (navigatorContext != null && navigatorContext!.mounted) {
            dialogContext = navigatorContext;
          } else if (navigator != null) {
            try {
              dialogContext = navigator!.overlay?.context;
              if (dialogContext != null && !dialogContext.mounted) {
                dialogContext = null;
              }
            } catch (_) {}
          }
          
          if (dialogContext != null && dialogContext.mounted) {
            _showErrorDialog(dialogContext, 'Traduction', 'Erreur: ${e.toString()}');
          }
        } catch (_) {
          debugPrint('⚠️ Impossible d\'afficher le dialogue d\'erreur');
        }
      });
    }
  }

  /// Analyse le texte sélectionné avec l'IA
  Future<void> analyzeText(BuildContext context) async {
    // Sauvegarder le texte AVANT de fermer le menu
    final textToAnalyze = _selectedText;
    if (textToAnalyze == null || textToAnalyze.isEmpty) {
      hideMenu();
      return;
    }
    
    // Utiliser le GlobalKey du Navigator pour obtenir un contexte valide
    NavigatorState? navigator;
    BuildContext? navigatorContext;
    
    try {
      // Importer NotilusApp pour accéder au navigatorKey
      final navigatorKey = _getNavigatorKey();
      if (navigatorKey != null && navigatorKey.currentState != null) {
        navigator = navigatorKey.currentState;
        navigatorContext = navigator!.overlay?.context;
        debugPrint('✅ Navigator obtenu via GlobalKey');
      } else {
        throw Exception('NavigatorKey non disponible');
      }
    } catch (e) {
      debugPrint('⚠️ Impossible d\'obtenir le Navigator via GlobalKey: $e');
      // Fallback: essayer avec le contexte root ou passé
      BuildContext? contextToUse = _rootContext ?? context;
      try {
        navigator = Navigator.maybeOf(contextToUse, rootNavigator: true);
        if (navigator != null) {
          navigatorContext = navigator.overlay?.context;
          debugPrint('✅ Navigator obtenu via contexte');
        }
      } catch (e2) {
        debugPrint('⚠️ Fallback Navigator a échoué: $e2');
      }
    }
    
    hideMenu(); // Fermer le menu immédiatement
    
    try {
      final aiService = AiService();
      final settings = SettingsService();
      
      debugPrint('🤖 Analyse IA: "$textToAnalyze"');
      
      final prompt = 'Analyse ce texte et donne-moi un résumé concis et des informations clés. Sois bref et précis:\n\n$textToAnalyze';
      
      final response = await aiService.chat(
        prompt: prompt,
        type: 'text_analysis',
        model: settings.aiPreferredModel.isNotEmpty ? settings.aiPreferredModel : null,
      );
      
      debugPrint('📥 Réponse IA: $response');
      
      if (response != null) {
        // Essayer différentes clés possibles pour la réponse
        String? analysis = response['content'] as String?;
        analysis ??= response['response'] as String?;
        analysis ??= response['message'] as String?;
        analysis ??= response['text'] as String?;
        
        // Si c'est une Map, essayer de trouver une valeur String
        if (analysis == null && response is Map) {
          for (var value in response.values) {
            if (value is String && value.isNotEmpty && value != textToAnalyze) {
              analysis = value;
              break;
            }
          }
        }
        
        if (analysis != null && analysis.isNotEmpty) {
          final finalAnalysis = analysis.trim();
          await Clipboard.setData(ClipboardData(text: finalAnalysis));
          
          // Utiliser le contexte capturé ou essayer de le récupérer
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              BuildContext? dialogContext;
              if (navigatorContext != null && navigatorContext!.mounted) {
                dialogContext = navigatorContext;
              } else if (navigator != null) {
                try {
                  dialogContext = navigator!.overlay?.context;
                  if (dialogContext != null && !dialogContext.mounted) {
                    dialogContext = null;
                  }
                } catch (_) {}
              }
              
              if (dialogContext != null && dialogContext.mounted) {
                _showAnalysisDialog(dialogContext, textToAnalyze, finalAnalysis);
              } else {
                debugPrint('⚠️ Aucun contexte valide pour afficher le dialogue');
              }
            } catch (e) {
              debugPrint('⚠️ Erreur affichage dialogue analyse: $e');
            }
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              BuildContext? dialogContext;
              if (navigatorContext != null && navigatorContext!.mounted) {
                dialogContext = navigatorContext;
              } else if (navigator != null) {
                try {
                  dialogContext = navigator!.overlay?.context;
                  if (dialogContext != null && !dialogContext.mounted) {
                    dialogContext = null;
                  }
                } catch (_) {}
              }
              
              if (dialogContext != null && dialogContext.mounted) {
                _showErrorDialog(dialogContext, 'Analyse IA', 'Aucune analyse reçue de l\'IA.');
              }
            } catch (e) {
              debugPrint('⚠️ Erreur affichage dialogue erreur: $e');
            }
          });
        }
      } else {
        final error = aiService.lastError ?? 'Erreur inconnue';
        debugPrint('❌ Erreur analyse: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            BuildContext? dialogContext;
            if (navigatorContext != null && navigatorContext!.mounted) {
              dialogContext = navigatorContext;
            } else if (navigator != null) {
              try {
                dialogContext = navigator!.overlay?.context;
                if (dialogContext != null && !dialogContext.mounted) {
                  dialogContext = null;
                }
              } catch (_) {}
            }
            
            if (dialogContext != null && dialogContext.mounted) {
              _showErrorDialog(dialogContext, 'Analyse IA', error);
            }
          } catch (e) {
            debugPrint('⚠️ Erreur affichage dialogue erreur: $e');
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception analyse: $e');
      debugPrint('Stack trace: $stackTrace');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          BuildContext? dialogContext;
          if (navigatorContext != null && navigatorContext!.mounted) {
            dialogContext = navigatorContext;
          } else if (navigator != null) {
            try {
              dialogContext = navigator!.overlay?.context;
              if (dialogContext != null && !dialogContext.mounted) {
                dialogContext = null;
              }
            } catch (_) {}
          }
          
          if (dialogContext != null && dialogContext.mounted) {
            _showErrorDialog(dialogContext, 'Analyse IA', 'Erreur: ${e.toString()}');
          }
        } catch (_) {
          debugPrint('⚠️ Impossible d\'afficher le dialogue d\'erreur');
        }
      });
    }
  }

  /// Affiche un dialogue avec la traduction
  void _showTranslationDialog(BuildContext context, String original, String translated) {
    GxFuturisticDialog.show(
      context: context,
      title: 'Traduction',
      titleIcon: CupertinoIcons.textformat_abc,
      width: 600,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Texte original:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                original,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Traduction:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                translated,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '✓ Copié dans le presse-papiers',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche un dialogue avec l'analyse IA
  void _showAnalysisDialog(BuildContext context, String original, String analysis) {
    GxFuturisticDialog.show(
      context: context,
      title: 'Analyse IA',
      titleIcon: CupertinoIcons.sparkles,
      width: 600,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Texte analysé:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                original,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Analyse:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                analysis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '✓ Copié dans le presse-papiers',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche un dialogue d'erreur
  void _showErrorDialog(BuildContext context, String title, String message) {
    GxFuturisticDialog.show(
      context: context,
      title: title,
      titleIcon: CupertinoIcons.exclamationmark_triangle,
      width: 500,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Vérifiez que le service IA est configuré et accessible.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

