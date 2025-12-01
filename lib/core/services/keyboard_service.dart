import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardService {
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
    // Le code a été déplacé vers modern_browser_window.dart
  }
}


