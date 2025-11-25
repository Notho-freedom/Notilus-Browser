import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/notilus_devtools_service.dart';
import '../../models/devtools_models.dart';

/// Onglet Alertes pour les notifications intelligentes
class DevToolsAlertsTab extends StatelessWidget {
  const DevToolsAlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<NotilusDevToolsService>(
      builder: (context, devTools, _) {
        final activeAlerts = devTools.alerts.where((a) => !a.isDismissed).toList();
        final dismissedAlerts = devTools.alerts.where((a) => a.isDismissed).toList();

        return Column(
          children: [
            // Toolbar
            _buildToolbar(context, accentColor, devTools, activeAlerts.length),

            // Content
            Expanded(
              child: activeAlerts.isEmpty
                  ? _buildEmptyState(accentColor)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: activeAlerts.length,
                      itemBuilder: (context, index) {
                        final alert = activeAlerts[activeAlerts.length - 1 - index];
                        return _AlertCard(alert: alert, accentColor: accentColor);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, Color accentColor, NotilusDevToolsService devTools, int count) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status monitoring
          GestureDetector(
            onTap: () {
              if (devTools.alertCount > 0) {
                devTools.stopSmartMonitoring();
              } else {
                devTools.startSmartMonitoring();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.bell_fill,
                    size: 12,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Smart Monitor',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0 ? accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count alertes',
              style: TextStyle(
                color: count > 0 ? accentColor : Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),

          const Spacer(),

          // Clear all
          if (count > 0)
            GestureDetector(
              onTap: devTools.clearAlerts,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.trash,
                      size: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tout effacer',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.checkmark_shield,
            size: 48,
            color: const Color(0xFF66BB6A).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune alerte',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le Smart Monitor surveille les performances,\nla mémoire et les erreurs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SmartAlert alert;
  final Color accentColor;

  const _AlertCard({required this.alert, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final devTools = context.read<NotilusDevToolsService>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alert.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: alert.color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(alert.icon, size: 16, color: alert.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: TextStyle(
                      color: alert.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert.category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 8,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Dismiss button
                GestureDetector(
                  onTap: () => devTools.dismissAlert(alert.id),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 14,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                if (alert.suggestion != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF64B5F6).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.lightbulb,
                          size: 12,
                          color: const Color(0xFF64B5F6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.suggestion!,
                            style: TextStyle(
                              color: const Color(0xFF64B5F6),
                              fontSize: 10,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatTime(alert.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 9,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

