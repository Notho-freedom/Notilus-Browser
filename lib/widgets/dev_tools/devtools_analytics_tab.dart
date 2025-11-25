import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../core/services/color_theme_manager.dart';
import '../../services/notilus_devtools_service.dart';
import '../../models/devtools_models.dart';

/// Onglet Analytics - Statistiques et export
class DevToolsAnalyticsTab extends StatefulWidget {
  const DevToolsAnalyticsTab({super.key});

  @override
  State<DevToolsAnalyticsTab> createState() => _DevToolsAnalyticsTabState();
}

class _DevToolsAnalyticsTabState extends State<DevToolsAnalyticsTab> {
  bool _showExportPanel = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<NotilusDevToolsService>(
      builder: (context, devTools, _) {
        final stats = devTools.getGlobalAnalytics();
        final tabAnalytics = devTools.tabAnalytics;

        return Column(
          children: [
            // Toolbar
            _buildToolbar(context, accentColor, devTools),

            // Content
            Expanded(
              child: _showExportPanel
                  ? _buildExportPanel(devTools, accentColor)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Global stats cards
                          _buildStatsGrid(stats, accentColor),

                          const SizedBox(height: 16),

                          // Session info
                          _buildSessionInfo(devTools, accentColor),

                          const SizedBox(height: 16),

                          // Recording controls
                          _buildRecordingControls(devTools, accentColor),

                          const SizedBox(height: 16),

                          // Tab analytics
                          _buildTabAnalytics(tabAnalytics, accentColor),

                          const SizedBox(height: 16),

                          // Bookmarks
                          _buildBookmarks(devTools, accentColor),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, Color accentColor, NotilusDevToolsService devTools) {
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
          // View toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _showExportPanel = !_showExportPanel;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _showExportPanel
                    ? accentColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showExportPanel ? CupertinoIcons.chart_bar : CupertinoIcons.doc_text,
                    size: 12,
                    color: _showExportPanel ? accentColor : Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showExportPanel ? 'Analytics' : 'Export',
                    style: TextStyle(
                      color: _showExportPanel ? accentColor : Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Session duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.time,
                  size: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(DateTime.now().difference(devTools.sessionStartTime)),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
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

  Widget _buildStatsGrid(Map<String, dynamic> stats, Color accentColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatCard(
          title: 'Onglets',
          value: '${stats['activeTabs']}/${stats['totalTabs']}',
          subtitle: 'actifs',
          icon: CupertinoIcons.rectangle_stack,
          color: const Color(0xFF64B5F6),
        ),
        _StatCard(
          title: 'Requêtes',
          value: '${stats['totalRequests']}',
          subtitle: 'total',
          icon: CupertinoIcons.globe,
          color: const Color(0xFF81C784),
        ),
        _StatCard(
          title: 'Erreurs',
          value: '${stats['totalErrors']}',
          subtitle: 'détectées',
          icon: CupertinoIcons.exclamationmark_triangle,
          color: const Color(0xFFEF5350),
        ),
        _StatCard(
          title: 'Données',
          value: '${stats['totalDataMB']}',
          subtitle: 'MB transférés',
          icon: CupertinoIcons.arrow_down_circle,
          color: const Color(0xFFBA68C8),
        ),
        _StatCard(
          title: 'Réponse',
          value: '${stats['avgResponseTime']}',
          subtitle: 'ms moyenne',
          icon: CupertinoIcons.speedometer,
          color: const Color(0xFFFFB74D),
        ),
        _StatCard(
          title: 'Session',
          value: '${stats['sessionDuration']}',
          subtitle: 'minutes',
          icon: CupertinoIcons.clock,
          color: accentColor,
        ),
      ],
    );
  }

  Widget _buildSessionInfo(NotilusDevToolsService devTools, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.info_circle, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Session Info',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Démarrée', _formatDateTime(devTools.sessionStartTime)),
          _buildInfoRow('Logs', '${devTools.logs.length}'),
          _buildInfoRow('Requêtes', '${devTools.requests.length}'),
          _buildInfoRow('Alertes', '${devTools.alertCount} (${devTools.criticalAlertCount} critiques)'),
          _buildInfoRow('Sécurité', '${devTools.securityIssueCount} problèmes'),
          _buildInfoRow('Bookmarks', '${devTools.bookmarks.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls(NotilusDevToolsService devTools, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: devTools.isRecording
            ? Colors.red.withOpacity(0.1)
            : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: devTools.isRecording
              ? Colors.red.withOpacity(0.3)
              : accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.videocam,
                size: 14,
                color: devTools.isRecording ? Colors.red : accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Session Recording',
                style: TextStyle(
                  color: devTools.isRecording ? Colors.red : accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const Spacer(),
              if (devTools.isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (devTools.isRecording) {
                      devTools.stopRecording();
                    } else {
                      devTools.startRecording();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: devTools.isRecording
                          ? Colors.red.withOpacity(0.2)
                          : accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          devTools.isRecording
                              ? CupertinoIcons.stop_fill
                              : CupertinoIcons.play_fill,
                          size: 14,
                          color: devTools.isRecording ? Colors.red : accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          devTools.isRecording ? 'Stop Recording' : 'Start Recording',
                          style: TextStyle(
                            color: devTools.isRecording ? Colors.red : accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (devTools.sessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sessions enregistrées: ${devTools.sessions.length}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabAnalytics(Map<String, TabAnalytics> analytics, Color accentColor) {
    if (analytics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.rectangle_stack, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Tab Analytics',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...analytics.values.take(5).map((tab) => _buildTabRow(tab, accentColor)),
        ],
      ),
    );
  }

  Widget _buildTabRow(TabAnalytics tab, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab.tabTitle ?? tab.tabId,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontFamily: 'JetBrains Mono',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${tab.totalRequests} req • ${tab.formattedDataTransferred}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tab.successRate >= 95
                  ? const Color(0xFF66BB6A).withOpacity(0.2)
                  : const Color(0xFFFFB74D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${tab.successRate.toStringAsFixed(0)}%',
              style: TextStyle(
                color: tab.successRate >= 95
                    ? const Color(0xFF66BB6A)
                    : const Color(0xFFFFB74D),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarks(NotilusDevToolsService devTools, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.bookmark_fill, size: 14, color: const Color(0xFFFFD54F)),
              const SizedBox(width: 8),
              Text(
                'Bookmarks',
                style: TextStyle(
                  color: const Color(0xFFFFD54F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _showAddBookmarkDialog(context, devTools);
                },
                child: Icon(
                  CupertinoIcons.add,
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          if (devTools.bookmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Aucun bookmark. Utilisez "bookmark <titre>" dans la console.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            ...devTools.bookmarks.take(5).map((b) => _buildBookmarkRow(b, devTools)),
          ],
        ],
      ),
    );
  }

  Widget _buildBookmarkRow(DevToolsBookmark bookmark, NotilusDevToolsService devTools) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bookmark.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: bookmark.color, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookmark.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                Text(
                  _formatTime(bookmark.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => devTools.removeBookmark(bookmark.id),
            child: Icon(
              CupertinoIcons.xmark,
              size: 12,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportPanel(NotilusDevToolsService devTools, Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.doc_text_fill,
                  size: 32,
                  color: accentColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'Export Report',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Générez un rapport complet de votre session DevTools',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Export button
          GestureDetector(
            onTap: () {
              final json = devTools.exportReportToJson(title: 'Rapport Notilus DevTools');
              _showExportResult(context, json, accentColor);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.arrow_down_doc, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Générer le rapport JSON',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // What's included
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contenu du rapport:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildIncludedItem('Résumé de session'),
                _buildIncludedItem('Logs console (100 derniers)'),
                _buildIncludedItem('Requêtes réseau (100 dernières)'),
                _buildIncludedItem('Alertes et problèmes'),
                _buildIncludedItem('Audit de sécurité'),
                _buildIncludedItem('Bookmarks'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.checkmark,
            size: 12,
            color: const Color(0xFF66BB6A),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBookmarkDialog(BuildContext context, NotilusDevToolsService devTools) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1E),
        title: const Text('Ajouter un bookmark', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Titre du bookmark',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                devTools.addBookmark(title: controller.text, category: 'custom');
              }
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showExportResult(BuildContext context, String json, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1E),
        title: Row(
          children: [
            Icon(CupertinoIcons.checkmark_circle_fill, color: const Color(0xFF66BB6A)),
            const SizedBox(width: 8),
            const Text('Rapport généré', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Container(
          width: 400,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              json,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 9,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 9,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}

