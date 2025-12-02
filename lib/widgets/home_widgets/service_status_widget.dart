/// Widget autonome pour afficher le statut des services
library service_status_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';

/// Modèle pour le statut d'un service
class ServiceStatus {
  final String name;
  final String status;
  final bool isHealthy;
  final String uptime;
  final int latency;

  const ServiceStatus({
    required this.name,
    required this.status,
    required this.isHealthy,
    required this.uptime,
    required this.latency,
  });
}

/// Widget autonome pour afficher le statut des services
class ServiceStatusWidget extends StatelessWidget {
  final List<ServiceStatus> services;
  final Color? accentColor;
  final double transparency;
  final VoidCallback? onDeploy;
  final VoidCallback? onRollback;

  const ServiceStatusWidget({
    super.key,
    required this.services,
    this.accentColor,
    this.transparency = 0.0,
    this.onDeploy,
    this.onRollback,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    if (services.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - transparency * 0.5).clamp(0.0, 1.0)),
        border: Border(
          right: BorderSide(color: gxRed.withOpacity(0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.square_stack_3d_up,
                  size: 14,
                  color: gxRed,
                ),
                const SizedBox(width: 8),
                Text(
                  'SERVICE STATUS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: gxRed,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: services.length,
              itemBuilder: (context, index) {
                return _buildServiceRow(services[index], index, gxRed);
              },
            ),
          ),
          if (onDeploy != null || onRollback != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK DEPLOY',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: gxRed.withOpacity(0.7),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (onDeploy != null)
                        Expanded(
                          child: _buildDeployButton('Deploy', CupertinoIcons.rocket, gxRed, onDeploy!),
                        ),
                      if (onDeploy != null && onRollback != null)
                        const SizedBox(width: 8),
                      if (onRollback != null)
                        Expanded(
                          child: _buildDeployButton('Rollback', CupertinoIcons.arrow_counterclockwise, const Color(0xFFFFAA00), onRollback!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(ServiceStatus service, int index, Color accentColor) {
    final statusColor = service.isHealthy ? accentColor : const Color(0xFFFFAA00);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: service.isHealthy
              ? accentColor.withOpacity(0.2)
              : const Color(0xFFFFAA00).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: service.isHealthy ? accentColor : const Color(0xFFFFAA00),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      service.uptime,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        color: accentColor.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(color: Colors.white.withOpacity(0.3)),
                    ),
                    Text(
                      '${service.latency}ms',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: service.isHealthy
                  ? accentColor.withOpacity(0.1)
                  : const Color(0xFFFFAA00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              service.status,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: service.isHealthy ? accentColor : const Color(0xFFFFAA00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeployButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

