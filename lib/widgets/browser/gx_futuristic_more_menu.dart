/// Menu "Plus d'outils" avec style futuriste GX
library gx_futuristic_more_menu;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/settings_service.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/gx_notification_service.dart';
import '../common/gx_futuristic_components.dart';

class GXFuturisticMoreMenu extends StatefulWidget {
  final Color accentColor;
  final VoidCallback onClose;
  final LayerLink layerLink;

  const GXFuturisticMoreMenu({
    super.key,
    required this.accentColor,
    required this.onClose,
    required this.layerLink,
  });

  @override
  State<GXFuturisticMoreMenu> createState() => _GXFuturisticMoreMenuState();
}

class _GXFuturisticMoreMenuState extends State<GXFuturisticMoreMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final accentColor = widget.accentColor;
    final bgColor = colorThemeManager.nativeBackgroundColor; // Couleur primaire
    final settings = SettingsService();
    final screenWidth = MediaQuery.of(context).size.width;
    const menuWidth = 200.0;

    return Stack(
      children: [
        // Fond transparent pour fermer au clic
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu positionné - aligné avec le bord droit de l'écran
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: true, // Afficher même si le lien n'est pas connecté (pour debug)
          offset: const Offset(-200, 30), // Positionner à gauche du bouton, en dessous
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 200,
                      constraints: const BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.7), // Fond primaire semi-transparent
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: accentColor.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _GeometricBordersPainter(accentColor: accentColor),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMenuItem(
                                context,
                                CupertinoIcons.camera,
                                'Capturer la page',
                                accentColor,
                                () {
                                  widget.onClose();
                                  GxNotificationService().showInfo(
                                    title: 'Capture d\'écran',
                                    message: 'La fonctionnalité de capture d\'écran est en cours de développement.',
                                    icon: CupertinoIcons.camera,
                                    context: context,
                                  );
                                },
                              ),
                              _buildMenuItem(
                                context,
                                CupertinoIcons.printer,
                                'Imprimer',
                                accentColor,
                                () {
                                  widget.onClose();
                                  GxNotificationService().showInfo(
                                    title: 'Impression',
                                    message: 'La fonctionnalité d\'impression est en cours de développement.',
                                    icon: CupertinoIcons.printer,
                                    context: context,
                                  );
                                },
                              ),
                              _buildMenuItem(
                                context,
                                CupertinoIcons.share,
                                'Partager',
                                accentColor,
                                () {
                                  widget.onClose();
                                  GxNotificationService().showInfo(
                                    title: 'Partage',
                                    message: 'La fonctionnalité de partage est en cours de développement.',
                                    icon: CupertinoIcons.share,
                                    context: context,
                                  );
                                },
                              ),
                              _buildMenuItem(
                                context,
                                CupertinoIcons.doc_on_clipboard,
                                'Copier l\'URL',
                                accentColor,
                                () async {
                                  widget.onClose();
                                  final tabManager = Provider.of<TabManager>(context, listen: false);
                                  final url = tabManager.activeTab?.url;
                                  if (url != null && url.isNotEmpty) {
                                    await Clipboard.setData(ClipboardData(text: url));
                                    if (context.mounted) {
                                      GxNotificationService().showSuccess(
                                        title: 'URL copiée',
                                        message: 'L\'URL actuelle a été copiée dans le presse-papiers.',
                                        icon: CupertinoIcons.doc_on_doc,
                                        context: context,
                                      );
                                    }
                                  }
                                },
                              ),
                              _buildDivider(accentColor),
                              _buildMenuItem(
                                context,
                                CupertinoIcons.textformat,
                                'Mode lecture',
                                accentColor,
                                () {
                                  widget.onClose();
                                  GxNotificationService().showInfo(
                                    title: 'Mode lecture',
                                    message: 'La fonctionnalité de mode lecture est en cours de développement.',
                                    icon: CupertinoIcons.textformat,
                                    context: context,
                                  );
                                },
                              ),
                              _buildMenuItem(
                                context,
                                CupertinoIcons.moon,
                                'Mode sombre forcé',
                                accentColor,
                                () {
                                  widget.onClose();
                                  GxNotificationService().showInfo(
                                    title: 'Mode sombre forcé',
                                    message: 'La fonctionnalité de mode sombre forcé est en cours de développement.',
                                    icon: CupertinoIcons.moon,
                                    context: context,
                                  );
                                },
                              ),
                              _buildDivider(accentColor),
                              _buildMenuItem(
                                context,
                                CupertinoIcons.ant,
                                'DevTools (F12)',
                                accentColor,
                                () {
                                  widget.onClose();
                                  final tabManager = Provider.of<TabManager>(context, listen: false);
                                  final activeTab = tabManager.activeTab;
                                  if (activeTab != null) {
                                    final webViewManager = Provider.of<TabWebViewManager>(context, listen: false);
                                    final engine = webViewManager.getEngineForTab(activeTab.id);
                                    engine.openDevTools();
                                  }
                                },
                              ),
                              _buildMenuItem(
                                context,
                                CupertinoIcons.doc_text,
                                'Code source',
                                accentColor,
                                () {
                                  widget.onClose();
                                  final tabManager = Provider.of<TabManager>(context, listen: false);
                                  final url = tabManager.activeTab?.url;
                                  if (url != null && url.isNotEmpty && !url.startsWith('view-source:')) {
                                    tabManager.addTab(url: 'view-source:$url');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return _GXFuturisticMenuItem(
      icon: icon,
      label: label,
      accentColor: accentColor,
      onTap: onTap,
    );
  }

  Widget _buildDivider(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GxFuturisticDivider(
        accentColor: accentColor,
        height: 1,
      ),
    );
  }
}

class _GXFuturisticMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _GXFuturisticMenuItem({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_GXFuturisticMenuItem> createState() => _GXFuturisticMenuItemState();
}

class _GXFuturisticMenuItemState extends State<_GXFuturisticMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.accentColor.withOpacity(0.15)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: _isHovered
                    ? widget.accentColor.withOpacity(0.6)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: _isHovered
                    ? widget.accentColor
                    : Colors.white.withOpacity(0.7),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: NotilusFonts.rajdhani(
                    fontSize: 12,
                    color: _isHovered
                        ? widget.accentColor
                        : Colors.white.withOpacity(0.9),
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeometricBordersPainter extends CustomPainter {
  final Color accentColor;

  _GeometricBordersPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    const cornerSize = 16.0;
    const lineLength = 24.0;

    // Coin supérieur gauche
    canvas.drawLine(Offset(0, cornerSize), Offset(0, 0), glowPaint);
    canvas.drawLine(Offset(0, 0), Offset(cornerSize, 0), glowPaint);
    canvas.drawLine(Offset(0, cornerSize), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerSize, 0), paint);
    canvas.drawLine(Offset(cornerSize, 0), Offset(cornerSize + lineLength, 0), paint..strokeWidth = 1);
    canvas.drawLine(Offset(0, cornerSize), Offset(0, cornerSize + lineLength), paint..strokeWidth = 1);

    // Coin supérieur droit
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), glowPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), glowPaint);
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), paint);
    canvas.drawLine(Offset(size.width - cornerSize - lineLength, 0), Offset(size.width - cornerSize, 0), paint..strokeWidth = 1);
    canvas.drawLine(Offset(size.width, cornerSize), Offset(size.width, cornerSize + lineLength), paint..strokeWidth = 1);

    // Coin inférieur gauche
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height), glowPaint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), glowPaint);
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), paint);
    canvas.drawLine(Offset(0, size.height - cornerSize - lineLength), Offset(0, size.height - cornerSize), paint..strokeWidth = 1);
    canvas.drawLine(Offset(cornerSize, size.height), Offset(cornerSize + lineLength, size.height), paint..strokeWidth = 1);

    // Coin inférieur droit
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width, size.height), glowPaint);
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height), glowPaint);
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width - cornerSize - lineLength, size.height), Offset(size.width - cornerSize, size.height), paint..strokeWidth = 1);
    canvas.drawLine(Offset(size.width, size.height - cornerSize - lineLength), Offset(size.width, size.height - cornerSize), paint..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

