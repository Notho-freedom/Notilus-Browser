import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service pour gérer les sélections de texte globales dans l'application
class TextSelectionService extends ChangeNotifier {
  static final TextSelectionService _instance = TextSelectionService._internal();
  factory TextSelectionService() => _instance;
  TextSelectionService._internal();

  String? _selectedText;
  Offset? _selectionPosition;
  GlobalKey? _selectionKey;
  bool _isVisible = false;

  String? get selectedText => _selectedText;
  Offset? get selectionPosition => _selectionPosition;
  GlobalKey? get selectionKey => _selectionKey;
  bool get isVisible => _isVisible;

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
}

