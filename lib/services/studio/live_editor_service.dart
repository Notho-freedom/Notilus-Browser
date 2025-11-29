/// Service d'édition live pour Notilus Studio
/// Permet l'édition en temps réel du HTML/CSS/JS
library live_editor_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../browser_engine.dart';
import '../../models/studio/studio_models.dart';
import 'studio_service.dart';

/// Service d'édition live
class LiveEditorService extends ChangeNotifier {
  final StudioService _studioService;
  BrowserEngine? _engine;

  // Sessions d'édition par URL
  final Map<String, EditSession> _sessions = {};
  String? _currentUrl;

  // État de l'éditeur
  String? _selectedSelector;
  Map<String, dynamic>? _selectedElementInfo;
  bool _isInspecting = false;

  // Suggestions intelligentes
  List<EditorSuggestion> _suggestions = [];

  LiveEditorService(this._studioService);

  // Getters
  EditSession? get currentSession => _currentUrl != null ? _sessions[_currentUrl] : null;
  String? get selectedSelector => _selectedSelector;
  Map<String, dynamic>? get selectedElementInfo => _selectedElementInfo;
  bool get isInspecting => _isInspecting;
  List<EditorSuggestion> get suggestions => List.unmodifiable(_suggestions);
  List<EditChange> get changes => currentSession?.changes ?? [];
  int get changeCount => currentSession?.changeCount ?? 0;
  int get activeChangeCount => currentSession?.activeChangeCount ?? 0;

  void attachEngine(BrowserEngine engine) {
    _engine = engine;
    notifyListeners();
  }

  void detachEngine() {
    _engine = null;
    notifyListeners();
  }

  /// Appelé quand l'URL change
  void onUrlChanged(String url) {
    _currentUrl = url;
    if (!_sessions.containsKey(url)) {
      _sessions[url] = EditSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        startTime: DateTime.now(),
      );
    }
    notifyListeners();
  }

  /// Active/désactive le mode inspection
  Future<void> toggleInspection() async {
    _isInspecting = !_isInspecting;

    if (_isInspecting) {
      await _enableInspection();
    } else {
      await _disableInspection();
    }

    notifyListeners();
  }

  /// Active le mode inspection
  Future<void> _enableInspection() async {
    await _studioService.executeScript('''
      (function() {
        if (window.__notilusLiveEditor) return;
        
        window.__notilusLiveEditor = {
          highlight: null,
          selectedElement: null,
          
          init: function() {
            // Créer l'élément de surbrillance
            this.highlight = document.createElement('div');
            this.highlight.id = '__notilus_editor_highlight';
            this.highlight.style.cssText = 'position:fixed;pointer-events:none;z-index:999999;border:2px solid #00D9FF;background:rgba(0,217,255,0.1);transition:all 0.1s;display:none;';
            document.body.appendChild(this.highlight);
            
            // Écouter les mouvements de souris
            document.addEventListener('mousemove', this.onMouseMove.bind(this));
            document.addEventListener('click', this.onClick.bind(this), true);
          },
          
          onMouseMove: function(e) {
            const el = document.elementFromPoint(e.clientX, e.clientY);
            if (el && el.id !== '__notilus_editor_highlight') {
              const rect = el.getBoundingClientRect();
              this.highlight.style.display = 'block';
              this.highlight.style.left = rect.left + 'px';
              this.highlight.style.top = rect.top + 'px';
              this.highlight.style.width = rect.width + 'px';
              this.highlight.style.height = rect.height + 'px';
            }
          },
          
          onClick: function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            const el = document.elementFromPoint(e.clientX, e.clientY);
            if (el && el.id !== '__notilus_editor_highlight') {
              this.selectedElement = el;
              this.highlight.style.borderColor = '#FF2D55';
              this.highlight.style.background = 'rgba(255,45,85,0.1)';
              
              // Envoyer les infos de l'élément
              window.chrome.webview.postMessage(JSON.stringify({
                type: 'element_selected',
                selector: this.getSelector(el),
                tagName: el.tagName.toLowerCase(),
                id: el.id || null,
                className: el.className || null,
                attributes: this.getAttributes(el),
                computedStyles: this.getComputedStyles(el),
                rect: el.getBoundingClientRect(),
                innerHTML: el.innerHTML.substring(0, 500),
                outerHTML: el.outerHTML.substring(0, 1000)
              }));
            }
          },
          
          getSelector: function(el) {
            if (el.id) return '#' + el.id;
            if (el.className) {
              const classes = el.className.split(' ').filter(c => c).slice(0, 2).join('.');
              return el.tagName.toLowerCase() + '.' + classes;
            }
            return el.tagName.toLowerCase();
          },
          
          getAttributes: function(el) {
            const attrs = {};
            for (const attr of el.attributes) {
              attrs[attr.name] = attr.value;
            }
            return attrs;
          },
          
          getComputedStyles: function(el) {
            const style = getComputedStyle(el);
            return {
              display: style.display,
              position: style.position,
              width: style.width,
              height: style.height,
              padding: style.padding,
              margin: style.margin,
              color: style.color,
              backgroundColor: style.backgroundColor,
              fontSize: style.fontSize,
              fontFamily: style.fontFamily,
              fontWeight: style.fontWeight,
              lineHeight: style.lineHeight,
              textAlign: style.textAlign,
              border: style.border,
              borderRadius: style.borderRadius,
              boxShadow: style.boxShadow,
              opacity: style.opacity,
              transform: style.transform,
              transition: style.transition
            };
          },
          
          destroy: function() {
            if (this.highlight) {
              this.highlight.remove();
            }
            document.removeEventListener('mousemove', this.onMouseMove);
            document.removeEventListener('click', this.onClick, true);
            delete window.__notilusLiveEditor;
          }
        };
        
        window.__notilusLiveEditor.init();
      })();
    ''');
  }

  /// Désactive le mode inspection
  Future<void> _disableInspection() async {
    await _studioService.executeScript('''
      (function() {
        if (window.__notilusLiveEditor) {
          window.__notilusLiveEditor.destroy();
        }
      })();
    ''');
    _selectedSelector = null;
    _selectedElementInfo = null;
  }

  /// Traite les messages du WebView
  void handleWebViewMessage(Map<String, dynamic> message) {
    if (message['type'] == 'element_selected') {
      _selectedSelector = message['selector'] as String?;
      _selectedElementInfo = message;
      _generateSuggestions();
      notifyListeners();
    }
  }

  /// Sélectionne un élément par son sélecteur
  Future<void> selectElement(String selector) async {
    final result = await _studioService.executeScript('''
      (function() {
        const el = document.querySelector('$selector');
        if (!el) return null;
        
        const style = getComputedStyle(el);
        return JSON.stringify({
          selector: '$selector',
          tagName: el.tagName.toLowerCase(),
          id: el.id || null,
          className: el.className || null,
          attributes: Array.from(el.attributes).reduce((acc, attr) => {
            acc[attr.name] = attr.value;
            return acc;
          }, {}),
          computedStyles: {
            display: style.display,
            position: style.position,
            width: style.width,
            height: style.height,
            padding: style.padding,
            margin: style.margin,
            color: style.color,
            backgroundColor: style.backgroundColor,
            fontSize: style.fontSize,
            fontFamily: style.fontFamily,
            border: style.border,
            borderRadius: style.borderRadius
          },
          rect: el.getBoundingClientRect(),
          innerHTML: el.innerHTML.substring(0, 500),
          outerHTML: el.outerHTML.substring(0, 1000)
        });
      })();
    ''');

    if (result != null && result != 'null') {
      _selectedSelector = selector;
      _selectedElementInfo = jsonDecode(result);
      _generateSuggestions();
      notifyListeners();
    }
  }

  /// Modifie un style CSS
  Future<void> editStyle(String property, String value) async {
    if (_selectedSelector == null) return;

    final oldValue = await _getCurrentStyleValue(property);

    await _studioService.executeScript('''
      (function() {
        const el = document.querySelector('$_selectedSelector');
        if (el) {
          el.style.setProperty('$property', '$value');
        }
      })();
    ''');

    _addChange(EditChange(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: EditType.style,
      selector: _selectedSelector!,
      property: property,
      oldValue: oldValue,
      newValue: value,
    ));

    // Mettre à jour les infos de l'élément
    await selectElement(_selectedSelector!);
  }

  /// Modifie un attribut
  Future<void> editAttribute(String name, String value) async {
    if (_selectedSelector == null) return;

    final oldValue = _selectedElementInfo?['attributes']?[name] as String?;

    await _studioService.executeScript('''
      (function() {
        const el = document.querySelector('$_selectedSelector');
        if (el) {
          el.setAttribute('$name', '$value');
        }
      })();
    ''');

    _addChange(EditChange(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: EditType.attribute,
      selector: _selectedSelector!,
      property: name,
      oldValue: oldValue,
      newValue: value,
    ));

    await selectElement(_selectedSelector!);
  }

  /// Modifie le contenu texte
  Future<void> editTextContent(String content) async {
    if (_selectedSelector == null) return;

    final oldValue = await _studioService.executeScript('''
      (function() {
        const el = document.querySelector('$_selectedSelector');
        return el ? el.textContent : null;
      })();
    ''');

    final escaped = content.replaceAll("'", "\\'").replaceAll('\n', '\\n');
    await _studioService.executeScript('''
      (function() {
        const el = document.querySelector('$_selectedSelector');
        if (el) {
          el.textContent = '$escaped';
        }
      })();
    ''');

    _addChange(EditChange(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: EditType.text,
      selector: _selectedSelector!,
      property: 'textContent',
      oldValue: oldValue,
      newValue: content,
    ));

    await selectElement(_selectedSelector!);
  }

  /// Modifie le HTML
  Future<void> editHTML(String html) async {
    if (_selectedSelector == null) return;

    final oldValue = _selectedElementInfo?['outerHTML'] as String?;

    final escaped = html.replaceAll('`', '\\`');
    await _studioService.executeScript('''
      (function() {
        const el = document.querySelector('$_selectedSelector');
        if (el) {
          el.outerHTML = \`$escaped\`;
        }
      })();
    ''');

    _addChange(EditChange(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: EditType.html,
      selector: _selectedSelector!,
      property: 'outerHTML',
      oldValue: oldValue,
      newValue: html,
    ));
  }

  /// Injecte du CSS personnalisé
  Future<void> injectCSS(String css) async {
    final escaped = css.replaceAll('`', '\\`');
    await _studioService.executeScript('''
      (function() {
        let style = document.getElementById('__notilus_custom_css');
        if (!style) {
          style = document.createElement('style');
          style.id = '__notilus_custom_css';
          document.head.appendChild(style);
        }
        style.textContent = \`$escaped\`;
      })();
    ''');
  }

  /// Annule une modification
  Future<void> undoChange(String changeId) async {
    final session = currentSession;
    if (session == null) return;

    final changeIndex = session.changes.indexWhere((c) => c.id == changeId);
    if (changeIndex == -1) return;

    final change = session.changes[changeIndex];
    if (change.isReverted || change.oldValue == null) return;

    // Appliquer l'ancienne valeur
    switch (change.type) {
      case EditType.style:
        await _studioService.executeScript('''
          (function() {
            const el = document.querySelector('${change.selector}');
            if (el) {
              el.style.setProperty('${change.property}', '${change.oldValue}');
            }
          })();
        ''');
        break;

      case EditType.attribute:
        await _studioService.executeScript('''
          (function() {
            const el = document.querySelector('${change.selector}');
            if (el) {
              el.setAttribute('${change.property}', '${change.oldValue}');
            }
          })();
        ''');
        break;

      case EditType.text:
        final escaped = change.oldValue!.replaceAll("'", "\\'");
        await _studioService.executeScript('''
          (function() {
            const el = document.querySelector('${change.selector}');
            if (el) {
              el.textContent = '$escaped';
            }
          })();
        ''');
        break;

      default:
        break;
    }

    // Marquer comme annulé
    final updatedChanges = List<EditChange>.from(session.changes);
    updatedChanges[changeIndex] = change.copyWith(isReverted: true);
    _sessions[_currentUrl!] = session.copyWith(changes: updatedChanges);

    notifyListeners();
  }

  /// Refait une modification annulée
  Future<void> redoChange(String changeId) async {
    final session = currentSession;
    if (session == null) return;

    final changeIndex = session.changes.indexWhere((c) => c.id == changeId);
    if (changeIndex == -1) return;

    final change = session.changes[changeIndex];
    if (!change.isReverted) return;

    // Appliquer la nouvelle valeur
    switch (change.type) {
      case EditType.style:
        await _studioService.executeScript('''
          (function() {
            const el = document.querySelector('${change.selector}');
            if (el) {
              el.style.setProperty('${change.property}', '${change.newValue}');
            }
          })();
        ''');
        break;

      case EditType.attribute:
        await _studioService.executeScript('''
          (function() {
            const el = document.querySelector('${change.selector}');
            if (el) {
              el.setAttribute('${change.property}', '${change.newValue}');
            }
          })();
        ''');
        break;

      case EditType.text:
        final escaped = change.newValue.replaceAll("'", "\\'");
        await _studioService.executeScript('''
          (function() {
            const el = document.querySelector('${change.selector}');
            if (el) {
              el.textContent = '$escaped';
            }
          })();
        ''');
        break;

      default:
        break;
    }

    // Marquer comme actif
    final updatedChanges = List<EditChange>.from(session.changes);
    updatedChanges[changeIndex] = change.copyWith(isReverted: false);
    _sessions[_currentUrl!] = session.copyWith(changes: updatedChanges);

    notifyListeners();
  }

  /// Exporte les modifications en CSS
  String exportCSS() {
    return currentSession?.exportCss() ?? '';
  }

  /// Exporte les modifications en patch
  String exportPatch() {
    return currentSession?.exportPatch() ?? '';
  }

  /// Récupère la valeur actuelle d'un style
  Future<String?> _getCurrentStyleValue(String property) async {
    if (_selectedSelector == null) return null;

    final result = await _studioService.executeScript('''
      (function() {
        const el = document.querySelector('$_selectedSelector');
        if (el) {
          return getComputedStyle(el).getPropertyValue('$property');
        }
        return null;
      })();
    ''');

    return result;
  }

  /// Ajoute une modification à la session
  void _addChange(EditChange change) {
    if (_currentUrl == null) return;

    final session = _sessions[_currentUrl]!;
    final updatedChanges = List<EditChange>.from(session.changes)..add(change);
    _sessions[_currentUrl!] = session.copyWith(changes: updatedChanges);

    notifyListeners();
  }

  /// Génère des suggestions intelligentes
  void _generateSuggestions() {
    _suggestions.clear();

    if (_selectedElementInfo == null) return;

    final styles = _selectedElementInfo!['computedStyles'] as Map<String, dynamic>?;
    if (styles == null) return;

    // Suggestion pour les couleurs
    final bgColor = styles['backgroundColor'] as String?;
    if (bgColor != null && bgColor != 'rgba(0, 0, 0, 0)') {
      _suggestions.add(EditorSuggestion(
        type: SuggestionType.info,
        message: 'Couleur de fond détectée: $bgColor',
        property: 'backgroundColor',
      ));
    }

    // Suggestion pour la lisibilité
    final fontSize = styles['fontSize'] as String?;
    if (fontSize != null) {
      final size = double.tryParse(fontSize.replaceAll('px', ''));
      if (size != null && size < 14) {
        _suggestions.add(EditorSuggestion(
          type: SuggestionType.warning,
          message: 'Texte petit ($fontSize). Considérez une taille >= 14px pour la lisibilité.',
          property: 'fontSize',
          suggestedValue: '14px',
        ));
      }
    }

    // Suggestion pour les images
    final tagName = _selectedElementInfo!['tagName'] as String?;
    if (tagName == 'img') {
      final attrs = _selectedElementInfo!['attributes'] as Map<String, dynamic>?;
      if (attrs != null) {
        if (!attrs.containsKey('alt')) {
          _suggestions.add(EditorSuggestion(
            type: SuggestionType.accessibility,
            message: 'Image sans attribut alt. Ajoutez une description pour l\'accessibilité.',
            property: 'alt',
          ));
        }
        if (!attrs.containsKey('loading')) {
          _suggestions.add(EditorSuggestion(
            type: SuggestionType.performance,
            message: 'Considérez ajouter loading="lazy" pour les images hors écran.',
            property: 'loading',
            suggestedValue: 'lazy',
          ));
        }
      }
    }

    // Suggestion pour le contraste
    final color = styles['color'] as String?;
    if (color != null && bgColor != null) {
      _suggestions.add(EditorSuggestion(
        type: SuggestionType.accessibility,
        message: 'Vérifiez le contraste entre le texte ($color) et le fond ($bgColor)',
        property: 'color',
      ));
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disableInspection();
    super.dispose();
  }
}

/// Type de suggestion
enum SuggestionType {
  info,
  warning,
  error,
  accessibility,
  performance,
}

/// Suggestion de l'éditeur
class EditorSuggestion {
  final SuggestionType type;
  final String message;
  final String? property;
  final String? suggestedValue;

  EditorSuggestion({
    required this.type,
    required this.message,
    this.property,
    this.suggestedValue,
  });
}

