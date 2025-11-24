import 'package:flutter/widgets.dart';
import '../browser/gx_sidebar.dart';

/// Fournit un accès pour ouvrir ou fermer le panneau latéral flottant
/// depuis n'importe quel widget descendant (ex: page d'accueil).
class SidebarPanelScope extends InheritedWidget {
  final void Function(SidebarSection section) openPanel;
  final VoidCallback closePanel;

  const SidebarPanelScope({
    super.key,
    required this.openPanel,
    required this.closePanel,
    required super.child,
  });

  static SidebarPanelScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SidebarPanelScope>();
  }

  @override
  bool updateShouldNotify(SidebarPanelScope oldWidget) {
    return oldWidget.openPanel != openPanel || oldWidget.closePanel != closePanel;
  }
}

