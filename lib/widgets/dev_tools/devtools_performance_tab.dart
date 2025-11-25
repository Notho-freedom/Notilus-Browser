import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../models/devtools_models.dart';
import '../../services/notilus_devtools_service.dart';

/// Onglet Performance pour le monitoring en temps réel
class DevToolsPerformanceTab extends StatefulWidget {
  const DevToolsPerformanceTab({super.key});

  @override
  State<DevToolsPerformanceTab> createState() => _DevToolsPerformanceTabState();
}

class _DevToolsPerformanceTabState extends State<DevToolsPerformanceTab> {
  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<NotilusDevToolsService>(
      builder: (context, devTools, _) {
        return Column(
          children: [
            // Toolbar
            _buildToolbar(accentColor, devTools),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FPS & Render Time
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'FPS',
                            value: devTools.currentFps.toStringAsFixed(1),
                            unit: 'frames/sec',
                            icon: CupertinoIcons.speedometer,
                            color: _getFpsColor(devTools.currentFps),
                            accentColor: accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Frame Time',
                            value: devTools.performanceHistory.isEmpty
                                ? '--'
                                : devTools.performanceHistory.last.renderTime.toString(),
                            unit: 'ms',
                            icon: CupertinoIcons.timer,
                            color: const Color(0xFF64B5F6),
                            accentColor: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Memory & CPU
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Memory',
                            value: devTools.performanceHistory.isEmpty
                                ? '--'
                                : devTools.performanceHistory.last.memoryUsedMB.toString(),
                            unit: 'MB / ${devTools.performanceHistory.isEmpty ? "--" : devTools.performanceHistory.last.memoryTotalMB} MB',
                            icon: Icons.memory,
                            color: const Color(0xFFBA68C8),
                            accentColor: accentColor,
                            progress: devTools.performanceHistory.isEmpty
                                ? null
                                : devTools.performanceHistory.last.memoryUsage / 100,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'CPU (est.)',
                            value: devTools.performanceHistory.isEmpty
                                ? '--'
                                : devTools.performanceHistory.last.cpuUsage.toStringAsFixed(1),
                            unit: '%',
                            icon: Icons.developer_board,
                            color: const Color(0xFFFFB74D),
                            accentColor: accentColor,
                            progress: devTools.performanceHistory.isEmpty
                                ? null
                                : devTools.performanceHistory.last.cpuUsage / 100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Widgets count
                    _MetricCard(
                      title: 'Active Widgets',
                      value: devTools.performanceHistory.isEmpty
                          ? '--'
                          : devTools.performanceHistory.last.activeWidgets.toString(),
                      unit: 'widgets in tree',
                      icon: CupertinoIcons.square_stack_3d_up,
                      color: const Color(0xFF81C784),
                      accentColor: accentColor,
                      isWide: true,
                    ),
                    const SizedBox(height: 16),

                    // FPS Chart
                    _buildFpsChart(accentColor, devTools),

                    const SizedBox(height: 16),

                    // Memory Chart
                    _buildMemoryChart(accentColor, devTools),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(Color accentColor, NotilusDevToolsService devTools) {
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
          // Recording status
          GestureDetector(
            onTap: () {
              if (devTools.isPerformanceMonitoring) {
                devTools.stopPerformanceMonitoring();
              } else {
                devTools.startPerformanceMonitoring();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: devTools.isPerformanceMonitoring
                    ? Colors.green.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    devTools.isPerformanceMonitoring
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    size: 12,
                    color: devTools.isPerformanceMonitoring
                        ? Colors.green
                        : Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    devTools.isPerformanceMonitoring ? 'Monitoring' : 'Paused',
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

          const Spacer(),

          // Data points
          Text(
            '${devTools.performanceHistory.length} samples',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontFamily: 'JetBrains Mono',
            ),
          ),

          const SizedBox(width: 8),

          // Clear button
          GestureDetector(
            onTap: devTools.clearPerformanceHistory,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                CupertinoIcons.trash,
                size: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFpsChart(Color accentColor, NotilusDevToolsService devTools) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 12,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                'FPS Timeline',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '60 fps target',
                  style: TextStyle(
                    color: const Color(0xFF66BB6A),
                    fontSize: 8,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _FpsChartPainter(
                data: devTools.performanceHistory.map((s) => s.fps).toList(),
                accentColor: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryChart(Color accentColor, NotilusDevToolsService devTools) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory,
                size: 12,
                color: const Color(0xFFBA68C8),
              ),
              const SizedBox(width: 6),
              Text(
                'Memory Usage',
                style: TextStyle(
                  color: const Color(0xFFBA68C8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _MemoryChartPainter(
                data: devTools.performanceHistory
                    .map((s) => s.memoryUsedMB.toDouble())
                    .toList(),
                maxMemory: devTools.performanceHistory.isEmpty
                    ? 2048
                    : devTools.performanceHistory.last.memoryTotalMB.toDouble(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFpsColor(double fps) {
    if (fps >= 55) return const Color(0xFF66BB6A);
    if (fps >= 30) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }
}

/// Carte de métrique
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color accentColor;
  final double? progress;
  final bool isWide;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.accentColor,
    this.progress,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Painter pour le graphique FPS
class _FpsChartPainter extends CustomPainter {
  final List<double> data;
  final Color accentColor;

  _FpsChartPainter({required this.data, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      // Grid lines only
      _drawGrid(canvas, size);
      return;
    }

    _drawGrid(canvas, size);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1).clamp(1, data.length);
    const maxFps = 70.0;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxFps * size.height).clamp(0.0, size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Color based on FPS
      paint.color = _getColor(data[i]);
    }

    // Fill gradient
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        accentColor.withOpacity(0.3),
        accentColor.withOpacity(0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    paint.color = accentColor;
    canvas.drawPath(path, paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // 60 FPS line
    final y60 = size.height - (60 / 70 * size.height);
    canvas.drawLine(
      Offset(0, y60),
      Offset(size.width, y60),
      gridPaint..color = const Color(0xFF66BB6A).withOpacity(0.3),
    );

    // 30 FPS line
    final y30 = size.height - (30 / 70 * size.height);
    canvas.drawLine(
      Offset(0, y30),
      Offset(size.width, y30),
      gridPaint..color = const Color(0xFFFFB74D).withOpacity(0.3),
    );
  }

  Color _getColor(double fps) {
    if (fps >= 55) return const Color(0xFF66BB6A);
    if (fps >= 30) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  @override
  bool shouldRepaint(covariant _FpsChartPainter oldDelegate) {
    return oldDelegate.data.length != data.length ||
        (data.isNotEmpty && oldDelegate.data.isNotEmpty && oldDelegate.data.last != data.last);
  }
}

/// Painter pour le graphique mémoire
class _MemoryChartPainter extends CustomPainter {
  final List<double> data;
  final double maxMemory;

  _MemoryChartPainter({required this.data, required this.maxMemory});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFBA68C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFBA68C8).withOpacity(0.3),
          const Color(0xFFBA68C8).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1).clamp(1, data.length);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxMemory * size.height).clamp(0.0, size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MemoryChartPainter oldDelegate) {
    return oldDelegate.data.length != data.length ||
        (data.isNotEmpty && oldDelegate.data.isNotEmpty && oldDelegate.data.last != data.last);
  }
}
