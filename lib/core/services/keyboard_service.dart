import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardService {
  // Service déprécié - utilisez Shortcuts et Actions directement
  @Deprecated('Use Shortcuts and Actions widgets directly')
  // Service déprécié - utilisez Shortcuts et Actions directement dans les widgets
  @Deprecated('Use Shortcuts and Actions widgets directly')
  static void setupShortcuts(BuildContext context, {
    required VoidCallback newTab,
    required VoidCallback closeTab,
    required VoidCallback nextTab,
    required VoidCallback previousTab,
    required VoidCallback reload,
    required VoidCallback goBack,
    required VoidCallback goForward,
    required VoidCallback focusAddressBar,
    required VoidCallback toggleDevTools,
  }) {
    // Cette méthode n'est plus utilisée - les raccourcis sont gérés dans browser_window.dart
    // Setup keyboard shortcuts
    // Shortcuts.of(context).addAll({
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT): _Action(
        onAction: newTab,
      ),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyW): _Action(
        onAction: closeTab,
      ),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.tab): _Action(
        onAction: nextTab,
      ),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.tab): _Action(
        onAction: previousTab,
      ),
      LogicalKeySet(LogicalKeyboardKey.f5): _Action(
        onAction: reload,
      ),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): _Action(
        onAction: reload,
      ),
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): _Action(
        onAction: goBack,
      ),
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): _Action(
        onAction: goForward,
      ),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL): _Action(
        onAction: focusAddressBar,
      ),
      LogicalKeySet(LogicalKeyboardKey.f12): _Action(
        onAction: toggleDevTools,
      ),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyI): _Action(
        onAction: toggleDevTools,
      ),
    // });
  }
}

class _Action extends Intent {
  final VoidCallback onAction;
  
  _Action({required this.onAction});
}

