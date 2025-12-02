import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../../services/tab_manager.dart';
import '../../../core/services/wallpaper_manager.dart';
import '../../../services/settings_service.dart';
import '../../../core/services/color_theme_manager.dart';
import '../../common/notilus_monogram.dart';

/// Page d'accueil Data Science - Style analytique avec visualisations
class DataScienceHomePage extends StatefulWidget {
  final VoidCallback? onTerminalSelected;
  final VoidCallback? onDevToolsSelected;
  
  const DataScienceHomePage({
    super.key,
    this.onTerminalSelected,
    this.onDevToolsSelected,
  });

  @override
  State<DataScienceHomePage> createState() => _DataScienceHomePageState();
}

class _DataScienceHomePageState extends State<DataScienceHomePage> 
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final SettingsService _settings = SettingsService();
  late AnimationController _waveController;
  late AnimationController _particleController;
  String _currentTime = '';

  // Librairies Data Science
  final List<_DataLib> _libraries = [
    _DataLib('Python', '🐍', 'https://python.org', const Color(0xFF3776AB)),
    _DataLib('NumPy', '🔢', 'https://numpy.org', const Color(0xFF4DABCF)),
    _DataLib('Pandas', '🐼', 'https://pandas.pydata.org', const Color(0xFF150458)),
    _DataLib('Scikit-learn', '🔬', 'https://scikit-learn.org', const Color(0xFFF7931E)),
    _DataLib('TensorFlow', '🧠', 'https://tensorflow.org', const Color(0xFFFF6F00)),
    _DataLib('PyTorch', '🔥', 'https://pytorch.org', const Color(0xFFEE4C2C)),
    _DataLib('Jupyter', '📓', 'https://jupyter.org', const Color(0xFFF37626)),
    _DataLib('Matplotlib', '📊', 'https://matplotlib.org', const Color(0xFF11557C)),
  ];

  // Catégories d'outils
  final List<_DataCategory> _categories = [
    _DataCategory('Notebooks & IDE', CupertinoIcons.doc_text, [
      _DataTool('Jupyter Lab', 'https://jupyter.org', const Color(0xFFF37626)),
      _DataTool('Google Colab', 'https://colab.research.google.com', const Color(0xFFFFBC00)),
      _DataTool('Kaggle', 'https://kaggle.com', const Color(0xFF20BEFF)),
      _DataTool('Deepnote', 'https://deepnote.com', const Color(0xFF3793EF)),
    ]),
    _DataCategory('ML Platforms', CupertinoIcons.sparkles, [
      _DataTool('Hugging Face', 'https://huggingface.co', const Color(0xFFFFD21E)),
      _DataTool('MLflow', 'https://mlflow.org', const Color(0xFF0194E2)),
      _DataTool('Weights & Biases', 'https://wandb.ai', const Color(0xFFFFBE00)),
      _DataTool('Neptune.ai', 'https://neptune.ai', const Color(0xFF7157D9)),
    ]),
    _DataCategory('Data Visualization', CupertinoIcons.chart_bar, [
      _DataTool('Plotly', 'https://plotly.com', const Color(0xFF3F4F75)),
      _DataTool('Tableau', 'https://tableau.com', const Color(0xFFE97627)),
      _DataTool('D3.js', 'https://d3js.org', const Color(0xFFF9A03C)),
      _DataTool('Seaborn', 'https://seaborn.pydata.org', const Color(0xFF5A9BD5)),
    ]),
    _DataCategory('Databases & Warehouses', CupertinoIcons.tray_full, [
      _DataTool('BigQuery', 'https://cloud.google.com/bigquery', const Color(0xFF4285F4)),
      _DataTool('Snowflake', 'https://snowflake.com', const Color(0xFF29B5E8)),
      _DataTool('Databricks', 'https://databricks.com', const Color(0xFFFF3621)),
      _DataTool('Apache Spark', 'https://spark.apache.org', const Color(0xFFE25A1C)),
    ]),
  ];

  // Citations Data Science
  final List<String> _quotes = [
    "Data is the new oil. — Clive Humby",
    "Without data, you're just another person with an opinion. — W. Edwards Deming",
    "The goal is to turn data into information, and information into insight. — Carly Fiorina",
    "In God we trust, all others must bring data. — W. Edwards Deming",
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    
    _updateTime();
    _startClock();
    _settings.addListener(_onSettingsChanged);
  }

  void _startClock() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _updateTime();
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _waveController.dispose();
    _particleController.dispose();
    _searchController.dispose();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _openUrl(String url) {
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: url);
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;
    final tabManager = Provider.of<TabManager>(context, listen: false);
    String url = query.trim();
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      }
    }
    tabManager.addTab(url: url);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context, listen: true).nativeSecondaryColor;
    final wallpaperManager = context.watch<WallpaperManager>();
    final transparency = _settings.widgetTransparency;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.9),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Neural network background
          _buildNeuralBackground(gxRed),
          
          // Data wave effect
          _buildDataWave(),
          
          // Floating particles
          _buildFloatingParticles(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(gxRed),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeroSection(gxRed, transparency),
                        const SizedBox(height: 40),
                        _buildSearchBar(gxRed, transparency),
                        const SizedBox(height: 48),
                        _buildLibrariesSection(gxRed, transparency),
                        const SizedBox(height: 48),
                        _buildToolsGrid(gxRed, transparency),
                        const SizedBox(height: 48),
                        if (_settings.showQuotes)
                          _buildQuoteSection(gxRed, transparency),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuralBackground(Color gxRed) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: _NeuralNetworkPainter(
            progress: _particleController.value,
            primaryColor: const Color(0xFF8B5CF6),
            secondaryColor: const Color(0xFF3B82F6),
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildDataWave() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: _DataWavePainter(
            progress: _waveController.value,
            color: const Color(0xFF8B5CF6),
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(15, (index) {
            final random = math.Random(index);
            final startX = random.nextDouble() * 400;
            final startY = random.nextDouble() * 600;
            final speed = 0.5 + random.nextDouble() * 0.5;
            
            final y = startY + (_particleController.value * speed * 100);
            final opacity = (math.sin(_particleController.value * 2 * math.pi + index) * 0.5 + 0.5) * 0.3;
            
            return Positioned(
              left: startX + math.sin(_particleController.value * 2 * math.pi + index) * 20,
              top: y % 700,
              child: Container(
                width: 4 + random.nextDouble() * 4,
                height: 4 + random.nextDouble() * 4,
                decoration: BoxDecoration(
                  color: (random.nextBool() ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6))
                      .withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildHeader(Color gxRed) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const NotilusMonogram(size: 24),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                  const Color(0xFF3B82F6).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  'DATA SCIENCE',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8B5CF6),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_settings.showClock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
              ),
              child: Text(
                _currentTime,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHeroSection(Color gxRed, double transparency) {
    final customGreeting = _settings.customGreeting;
    return Column(
      children: [
        Text(
          '👋 Welcome, Data Explorer',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 1,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF06B6D4)],
          ).createShader(bounds),
          child: Text(
            customGreeting.isNotEmpty ? customGreeting : 'Analyze. Model. Predict.',
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
        ),
        const SizedBox(height: 16),
        Text(
          'Machine Learning • Deep Learning • Data Visualization • Statistical Analysis',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
      ],
    );
  }

  Widget _buildSearchBar(Color gxRed, double transparency) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.black.withOpacity(1 - transparency),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(CupertinoIcons.search, size: 18, color: const Color(0xFF8B5CF6)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search datasets, papers, documentation...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                cursorColor: const Color(0xFF8B5CF6),
                onSubmitted: _handleSearch,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.arrow_right,
                size: 16,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildLibrariesSection(Color gxRed, double transparency) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF8B5CF6), const Color(0xFF3B82F6)],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'ESSENTIAL LIBRARIES',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: _libraries.asMap().entries.map((entry) {
            return _buildLibraryCard(entry.value, transparency, entry.key);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLibraryCard(_DataLib lib, double transparency, int index) {
    return GestureDetector(
      onTap: () => _openUrl(lib.url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(1 - transparency),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lib.color.withOpacity(0.3)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                lib.color.withOpacity(0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              Text(lib.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                lib.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: lib.color,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: (400 + index * 50).ms,
    ).scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1));
  }

  Widget _buildToolsGrid(Color gxRed, double transparency) {
    return Column(
      children: _categories.asMap().entries.map((entry) {
        return _buildToolCategory(entry.value, transparency, entry.key);
      }).toList(),
    );
  }

  Widget _buildToolCategory(_DataCategory category, double transparency, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 16, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 10),
              Text(
                category.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: category.tools.map((tool) {
              return _buildToolCard(tool, transparency);
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (600 + index * 100).ms);
  }

  Widget _buildToolCard(_DataTool tool, double transparency) {
    return GestureDetector(
      onTap: () => _openUrl(tool.url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(1 - transparency),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tool.color.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tool.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tool.color.withOpacity(0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                tool.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteSection(Color gxRed, double transparency) {
    final quote = _quotes[DateTime.now().day % _quotes.length];
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(1 - transparency),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.05),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.lightbulb,
            size: 24,
            color: const Color(0xFF8B5CF6).withOpacity(0.6),
          ),
          const SizedBox(height: 14),
          Text(
            quote,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.65),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 900.ms);
  }
}

// === DATA CLASSES ===

class _DataLib {
  final String name;
  final String emoji;
  final String url;
  final Color color;

  const _DataLib(this.name, this.emoji, this.url, this.color);
}

class _DataCategory {
  final String name;
  final IconData icon;
  final List<_DataTool> tools;

  const _DataCategory(this.name, this.icon, this.tools);
}

class _DataTool {
  final String name;
  final String url;
  final Color color;

  const _DataTool(this.name, this.url, this.color);
}

// === PAINTERS ===

class _NeuralNetworkPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _NeuralNetworkPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final nodeCount = 20;
    final nodes = <Offset>[];
    
    for (int i = 0; i < nodeCount; i++) {
      nodes.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }
    
    // Draw connections
    final linePaint = Paint()
      ..strokeWidth = 0.5;
    
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < 200) {
          final opacity = (1 - dist / 200) * 0.1;
          linePaint.color = primaryColor.withOpacity(opacity);
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }
    
    // Draw nodes
    final nodePaint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < nodes.length; i++) {
      final pulse = math.sin(progress * 2 * math.pi + i) * 0.5 + 0.5;
      nodePaint.color = primaryColor.withOpacity(0.1 + pulse * 0.1);
      canvas.drawCircle(nodes[i], 3 + pulse * 2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_NeuralNetworkPainter oldDelegate) => 
      oldDelegate.progress != progress;
}

class _DataWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _DataWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    final waveHeight = 30.0;
    final frequency = 0.02;

    for (int w = 0; w < 3; w++) {
      path.reset();
      final yOffset = size.height * 0.7 + w * 50;
      
      for (double x = 0; x <= size.width; x += 2) {
        final y = yOffset + 
            math.sin((x * frequency) + (progress * 2 * math.pi) + w) * waveHeight;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DataWavePainter oldDelegate) => 
      oldDelegate.progress != progress;
}
