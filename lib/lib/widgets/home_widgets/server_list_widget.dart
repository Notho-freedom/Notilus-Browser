/// Widget liste des serveurs (Backend Lab)
library server_list_widget;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/home_widget_models.dart';
import '../../services/backend_lab/backend_lab_service.dart';
import '../../models/backend_lab/backend_lab_models.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import 'home_widget_base.dart';

class ServerListWidget extends StatelessWidget {
  final HomeWidget widget;

  const ServerListWidget({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = colorTheme.nativeSecondaryColor;
    
    // Instancier le service Backend Lab
    final labService = BackendLabService();
    
    return ListenableBuilder(
      listenable: labService,
      builder: (context, _) {
        final servers = labService.servers;

        return HomeWidgetBase(
          widget: widget,
          child: servers.isEmpty
              ? _buildEmptyState(context, accentColor)
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    return _ServerListItem(
                      server: server,
                      accentColor: accentColor,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun serveur',
            style: NotilusFonts.rajdhani(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scannez depuis Backend Lab',
            style: NotilusFonts.rajdhani(
              fontSize: 10,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerListItem extends StatelessWidget {
  final DiscoveredServer server;
  final Color accentColor;

  const _ServerListItem({
    required this.server,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(server.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: NotilusColors.chromeDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.name ?? 'Serveur inconnu',
                  style: NotilusFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${server.host}:${server.port}',
                  style: NotilusFonts.rajdhani(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (server.framework != ServerFramework.unknown)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getFrameworkName(server.framework),
                style: NotilusFonts.rajdhani(
                  fontSize: 8,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(ServerStatus status) {
    switch (status) {
      case ServerStatus.running:
        return const Color(0xFF22C55E);
      case ServerStatus.stopped:
        return Colors.grey;
      case ServerStatus.error:
        return const Color(0xFFEF4444);
      case ServerStatus.unknown:
        return Colors.orange;
    }
  }

  String _getFrameworkName(ServerFramework framework) {
    switch (framework) {
      case ServerFramework.express:
        return 'Express';
      case ServerFramework.fastapi:
        return 'FastAPI';
      case ServerFramework.django:
        return 'Django';
      case ServerFramework.flask:
        return 'Flask';
      case ServerFramework.springBoot:
        return 'Spring';
      case ServerFramework.rails:
        return 'Rails';
      case ServerFramework.laravel:
        return 'Laravel';
      case ServerFramework.nestjs:
        return 'NestJS';
      case ServerFramework.gin:
        return 'Gin';
      case ServerFramework.aspnet:
        return 'ASP.NET';
      default:
        return 'Unknown';
    }
  }
}

