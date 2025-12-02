/// Service de notifications futuriste centralisé pour Notilus GX
library gx_notification_service;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/notilus_colors.dart';
import '../core/constants/notilus_fonts.dart';
import '../core/services/color_theme_manager.dart';
import '../services/settings_service.dart';
import 'dart:ui';

/// Type de notification
enum GxNotificationType {
  success,
  error,
  warning,
  info,
}

/// Modèle de notification
class GxNotification {
  final String id;
  final String title;
  final String? message;
  final GxNotificationType type;
  final IconData? icon;
  final Duration? duration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final double? progress; // Progression (0.0 - 1.0)
  final bool showProgress; // Afficher la barre de progression

  GxNotification({
    required this.id,
    required this.title,
    this.message,
    required this.type,
    this.icon,
    this.duration,
    this.onTap,
    this.onDismiss,
    this.progress,
    this.showProgress = false,
  });
}

/// Service de notifications centralisé
class GxNotificationService extends ChangeNotifier {
  static final GxNotificationService _instance = GxNotificationService._internal();
  factory GxNotificationService() => _instance;
  GxNotificationService._internal();

  final List<GxNotification> _notifications = [];
  final Map<String, OverlayEntry> _overlayEntries = {};

  List<GxNotification> get notifications => List.unmodifiable(_notifications);

  /// Affiche une notification
  void show({
    required String title,
    String? message,
    required GxNotificationType type,
    IconData? icon,
    Duration? duration,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    double? progress,
    bool showProgress = false,
    required BuildContext context,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = GxNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      icon: icon,
      duration: duration ?? const Duration(seconds: 4),
      onTap: onTap,
      onDismiss: onDismiss,
      progress: progress,
      showProgress: showProgress,
    );

    // Si la notification existe déjà, la mettre à jour
    final existingIndex = _notifications.indexWhere((n) => n.id == id);
    if (existingIndex != -1) {
      _notifications[existingIndex] = notification;
    } else {
      _notifications.insert(0, notification);
      // Afficher dans l'overlay seulement si c'est une nouvelle notification
      _showInOverlay(context, notification);
    }
    
    notifyListeners();

    // Auto-dismiss seulement si pas de progression
    if (notification.duration != null && !showProgress) {
      Future.delayed(notification.duration!, () {
        dismiss(id);
      });
    }
  }
  
  /// Met à jour la progression d'une notification existante
  void updateProgress(String id, double progress) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = GxNotification(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        icon: notification.icon,
        duration: notification.duration,
        onTap: notification.onTap,
        onDismiss: notification.onDismiss,
        progress: progress,
        showProgress: true,
      );
      notifyListeners();
    }
  }

  /// Affiche une notification de succès
  void showSuccess({
    required String title,
    String? message,
    IconData? icon,
    Duration? duration,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    show(
      title: title,
      message: message,
      type: GxNotificationType.success,
      icon: icon ?? Icons.check_circle_rounded,
      duration: duration,
      onTap: onTap,
      context: context,
    );
  }

  /// Affiche une notification d'erreur
  void showError({
    required String title,
    String? message,
    IconData? icon,
    Duration? duration,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    show(
      title: title,
      message: message,
      type: GxNotificationType.error,
      icon: icon ?? Icons.error_rounded,
      duration: duration,
      onTap: onTap,
      context: context,
    );
  }

  /// Affiche une notification d'avertissement
  void showWarning({
    required String title,
    String? message,
    IconData? icon,
    Duration? duration,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    show(
      title: title,
      message: message,
      type: GxNotificationType.warning,
      icon: icon ?? Icons.warning_rounded,
      duration: duration,
      onTap: onTap,
      context: context,
    );
  }

  /// Affiche une notification d'information
  void showInfo({
    required String title,
    String? message,
    IconData? icon,
    Duration? duration,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    show(
      title: title,
      message: message,
      type: GxNotificationType.info,
      icon: icon ?? Icons.info_rounded,
      duration: duration,
      onTap: onTap,
      context: context,
    );
  }

  /// Ferme une notification
  void dismiss(String id) {
    final notification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => throw StateError('Notification not found'),
    );

    notification.onDismiss?.call();
    _notifications.removeWhere((n) => n.id == id);

    // Retirer de l'overlay
    final overlayEntry = _overlayEntries.remove(id);
    overlayEntry?.remove();

    notifyListeners();
  }

  /// Ferme toutes les notifications
  void dismissAll() {
    for (final notification in _notifications) {
      notification.onDismiss?.call();
    }
    _notifications.clear();

    // Retirer tous les overlays
    for (final entry in _overlayEntries.values) {
      entry.remove();
    }
    _overlayEntries.clear();

    notifyListeners();
  }

  /// Affiche la notification dans l'overlay
  void _showInOverlay(BuildContext context, GxNotification notification) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _GxNotificationWidget(
        notification: notification,
        onDismiss: () => dismiss(notification.id),
      ),
    );

    _overlayEntries[notification.id] = overlayEntry;
    overlay.insert(overlayEntry);
  }
}

/// Widget de notification futuriste
class _GxNotificationWidget extends StatefulWidget {
  final GxNotification notification;
  final VoidCallback onDismiss;

  const _GxNotificationWidget({
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_GxNotificationWidget> createState() => _GxNotificationWidgetState();
}

class _GxNotificationWidgetState extends State<_GxNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // L'animation de slide sera ajustée dans le build selon la position
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Color _getColorForType(GxNotificationType type) {
    switch (type) {
      case GxNotificationType.success:
        return const Color(0xFF22C55E);
      case GxNotificationType.error:
        return const Color(0xFFEF4444);
      case GxNotificationType.warning:
        return const Color(0xFFF59E0B);
      case GxNotificationType.info:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getColorForType(widget.notification.type);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;
    final position = settings.notificationPosition;

    // Calculer la position selon les paramètres
    double? top, bottom, left, right;
    Offset slideBegin;
    switch (position) {
      case 'top-right':
        top = MediaQuery.of(context).padding.top + 20;
        right = 20;
        slideBegin = const Offset(1.0, 0.0);
        break;
      case 'top-left':
        top = MediaQuery.of(context).padding.top + 20;
        left = 20;
        slideBegin = const Offset(-1.0, 0.0);
        break;
      case 'bottom-right':
        bottom = 20;
        right = 20;
        slideBegin = const Offset(1.0, 0.0);
        break;
      case 'bottom-left':
        bottom = 20;
        left = 20;
        slideBegin = const Offset(-1.0, 0.0);
        break;
      default:
        top = MediaQuery.of(context).padding.top + 20;
        right = 20;
        slideBegin = const Offset(1.0, 0.0);
    }

    // Créer l'animation de slide selon la position
    _slideAnimation ??= Tween<Offset>(
      begin: slideBegin,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: SlideTransition(
        position: _slideAnimation!,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: () {
                widget.notification.onTap?.call();
                _dismiss();
              },
              child: Container(
                width: 380,
                margin: const EdgeInsets.only(bottom: 12),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
                        border: Border.all(
                          color: accentColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          _NotificationGeometricBorders(accentColor: accentColor),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icône
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.15),
                                    border: Border.all(
                                      color: accentColor.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.notification.icon ??
                                        _getDefaultIcon(widget.notification.type),
                                    color: accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Contenu
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.notification.title,
                                        style: NotilusFonts.orbitron(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (widget.notification.message != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.notification.message!,
                                          style: NotilusFonts.rajdhani(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                      // Barre de progression
                                      if (widget.notification.showProgress && widget.notification.progress != null) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: widget.notification.progress,
                                            backgroundColor: Colors.white.withOpacity(0.1),
                                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                            minHeight: 4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(widget.notification.progress! * 100).toStringAsFixed(0)}%',
                                          style: NotilusFonts.rajdhani(
                                            fontSize: 10,
                                            color: Colors.white.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Bouton de fermeture
                                GestureDetector(
                                  onTap: _dismiss,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  IconData _getDefaultIcon(GxNotificationType type) {
    switch (type) {
      case GxNotificationType.success:
        return Icons.check_circle_rounded;
      case GxNotificationType.error:
        return Icons.error_rounded;
      case GxNotificationType.warning:
        return Icons.warning_rounded;
      case GxNotificationType.info:
        return Icons.info_rounded;
    }
  }
}

/// Contours géométriques pour les notifications
class _NotificationGeometricBorders extends StatelessWidget {
  final Color accentColor;

  const _NotificationGeometricBorders({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _NotificationBordersPainter(accentColor: accentColor),
      ),
    );
  }
}

class _NotificationBordersPainter extends CustomPainter {
  final Color accentColor;

  _NotificationBordersPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    const cornerSize = 15.0;
    const lineLength = 20.0;

    // Coin supérieur droit
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), glowPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), glowPaint);
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), paint);
    canvas.drawLine(Offset(size.width - cornerSize - lineLength, 0), Offset(size.width - cornerSize, 0), paint..strokeWidth = 1);
    canvas.drawLine(Offset(size.width, cornerSize), Offset(size.width, cornerSize + lineLength), paint..strokeWidth = 1);

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

