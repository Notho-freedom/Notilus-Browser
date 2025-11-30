/// Mini panel IA flottant "Notilus style"
/// Panel léger pour expliquer les erreurs et proposer des solutions
library notilus_mini_ai_panel;

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../models/devtools_models.dart';
import '../common/notilus_tooltip.dart';
import '../../services/gx_notification_service.dart';

/// Mini panel IA flottant avec style Notilus dans une carte futuriste
class NotilusMiniAiPanel extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isVisible;
  final ConsoleEntry? errorEntry; // L'erreur à expliquer
  final Duration animationDuration;

  const NotilusMiniAiPanel({
    super.key,
    this.onClose,
    this.isVisible = false,
    this.errorEntry,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  @override
  State<NotilusMiniAiPanel> createState() => _NotilusMiniAiPanelState();
}

class _NotilusMiniAiPanelState extends State<NotilusMiniAiPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final SettingsService _settings = SettingsService();
  
  bool _isLoading = false;
  String? _explanation;
  String? _solution;
  String? _error;
  
  // État pour le déplacement et collapse/expand
  bool _isCollapsed = false;
  Offset _position = const Offset(0, 0);
  bool _isDragging = false;
  Offset _dragStartPosition = Offset.zero;
  Offset _dragStartOffset = Offset.zero;
  
  // Constantes pour les dimensions
  static const double _expandedWidth = 380.0;
  static const double _expandedHeight = 350.0;
  static const double _collapsedWidth = 200.0;
  static const double _collapsedHeight = 28.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // En bas
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Position par défaut : coin bas-droit (à côté du devtools mini)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      _position = Offset(
        screenSize.width - _expandedWidth - 12, // Coin droit avec marge
        screenSize.height - _expandedHeight - 12,
      );
    });

    if (widget.isVisible) {
      _animationController.forward();
      _analyzeError();
    }
  }

  @override
  void didUpdateWidget(NotilusMiniAiPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
        if (widget.errorEntry != oldWidget.errorEntry) {
          _analyzeError();
        }
      } else {
        _animationController.reverse();
      }
    } else if (widget.errorEntry != oldWidget.errorEntry && widget.isVisible) {
      _analyzeError();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _analyzeError() async {
    if (widget.errorEntry == null) return;
    
    setState(() {
      _isLoading = true;
      _explanation = null;
      _solution = null;
      _error = null;
    });

    try {
      // Construire le prompt pour l'IA
      final errorMessage = widget.errorEntry!.message;
      final source = widget.errorEntry!.source;
      final lineNumber = widget.errorEntry!.lineNumber;
      final stackTrace = widget.errorEntry!.stackTrace;
      
      final prompt = '''Analyse cette erreur JavaScript/Web et explique-la de manière simple et concise, puis propose une solution rapide.

Erreur: $errorMessage
${source != null ? 'Source: $source' : ''}
${lineNumber != null ? 'Ligne: $lineNumber' : ''}
${stackTrace != null ? 'Stack trace:\n$stackTrace' : ''}

Réponds en format JSON avec deux champs:
- "explanation": Une explication simple et courte (2-3 phrases max)
- "solution": Une solution rapide et pratique (2-3 étapes max)

Réponds UNIQUEMENT en JSON, sans texte avant ou après.''';

      final response = await _aiService.chat(
        prompt: prompt,
        type: 'error_analysis',
        model: _settings.aiPreferredModel.isNotEmpty 
            ? _settings.aiPreferredModel 
            : null,
      );

      if (response != null && mounted) {
        try {
          final content = response['content'] as String? ?? response['response'] as String? ?? '';
          
          // Fonction pour extraire le JSON de la réponse
          String? extractJsonString(String text) {
            // Chercher le premier { qui commence un objet JSON
            int startIndex = text.indexOf('{');
            if (startIndex == -1) return null;
            
            // Compter les accolades pour trouver la fin de l'objet JSON
            int braceCount = 0;
            bool inString = false;
            bool escapeNext = false;
            
            for (int i = startIndex; i < text.length; i++) {
              final char = text[i];
              
              if (escapeNext) {
                escapeNext = false;
                continue;
              }
              
              if (char == '\\') {
                escapeNext = true;
                continue;
              }
              
              if (char == '"') {
                inString = !inString;
                continue;
              }
              
              if (!inString) {
                if (char == '{') {
                  braceCount++;
                } else if (char == '}') {
                  braceCount--;
                  if (braceCount == 0) {
                    // On a trouvé la fin de l'objet JSON
                    return text.substring(startIndex, i + 1);
                  }
                }
              }
            }
            
            return null;
          }
          
          // Essayer d'extraire le JSON
          String? jsonStr = extractJsonString(content);
          
          if (jsonStr != null) {
            try {
              // Nettoyer le JSON (enlever les backticks markdown si présents)
              jsonStr = jsonStr.replaceAll(RegExp(r'^```json\s*'), '');
              jsonStr = jsonStr.replaceAll(RegExp(r'^```\s*'), '');
              jsonStr = jsonStr.replaceAll(RegExp(r'\s*```$'), '');
              jsonStr = jsonStr.trim();
              
              final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
              
              setState(() {
                _explanation = parsed['explanation']?.toString().trim();
                _solution = parsed['solution']?.toString().trim();
                _isLoading = false;
              });
            } catch (e) {
              // Si le parsing échoue, essayer d'extraire manuellement
              _extractFromText(content);
            }
          } else {
            // Pas de JSON trouvé, essayer d'extraire depuis le texte
            _extractFromText(content);
          }
        } catch (e) {
          // Si tout échoue, afficher la réponse brute mais formatée
          final content = response['content'] as String? ?? response['response'] as String? ?? '';
          _extractFromText(content);
        }
      } else {
        setState(() {
          _error = 'Impossible de contacter l\'IA. Vérifiez la configuration.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors de l\'analyse: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_isCollapsed) return;
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.localPosition;
      _dragStartOffset = _position;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isCollapsed) return;
    
    final screenSize = MediaQuery.of(context).size;
    final delta = details.localPosition - _dragStartPosition;
    
    setState(() {
      _position = Offset(
        (_dragStartOffset.dx + delta.dx).clamp(0.0, screenSize.width - (_isCollapsed ? _collapsedWidth : _expandedWidth)),
        (_dragStartOffset.dy + delta.dy).clamp(0.0, screenSize.height - (_isCollapsed ? _collapsedHeight : _expandedHeight)),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  String _cleanQuotes(String? text) {
    if (text == null || text.isEmpty) return '';
    String cleaned = text.trim();
    // Enlever les guillemets au début et à la fin
    if (cleaned.startsWith('"') || cleaned.startsWith("'")) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.endsWith('"') || cleaned.endsWith("'")) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned.trim();
  }

  void _extractFromText(String content) {
    // Essayer d'extraire explanation et solution depuis le texte
    String? explanation;
    String? solution;
    
    // Chercher "explanation" (insensible à la casse)
    final explanationMatch = RegExp(
      r'"explanation"\s*:\s*"([^"]*(?:\\.[^"]*)*)"',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(content);
    
    if (explanationMatch != null) {
      explanation = explanationMatch.group(1)?.replaceAll('\\"', '"').replaceAll('\\n', '\n');
    } else {
      // Fallback : chercher après le mot "explanation"
      final explanationIndex = content.toLowerCase().indexOf('explanation');
      if (explanationIndex != -1) {
        final afterExplanation = content.substring(explanationIndex + 'explanation'.length);
        final colonIndex = afterExplanation.indexOf(':');
        if (colonIndex != -1) {
          final valueStart = afterExplanation.substring(colonIndex + 1).trim();
          // Prendre jusqu'à "solution" ou jusqu'à la fin
          final solutionIndex = valueStart.toLowerCase().indexOf('solution');
          if (solutionIndex != -1) {
            explanation = valueStart.substring(0, solutionIndex).trim();
            // Nettoyer les guillemets et autres caractères
            explanation = _cleanQuotes(explanation);
          } else {
            explanation = _cleanQuotes(valueStart);
          }
        }
      }
    }
    
    // Chercher "solution" (insensible à la casse)
    final solutionMatch = RegExp(
      r'"solution"\s*:\s*"([^"]*(?:\\.[^"]*)*)"',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(content);
    
    if (solutionMatch != null) {
      solution = solutionMatch.group(1)?.replaceAll('\\"', '"').replaceAll('\\n', '\n');
    } else {
      // Fallback : chercher après le mot "solution"
      final solutionIndex = content.toLowerCase().indexOf('solution');
      if (solutionIndex != -1) {
        final afterSolution = content.substring(solutionIndex + 'solution'.length);
        final colonIndex = afterSolution.indexOf(':');
        if (colonIndex != -1) {
          solution = afterSolution.substring(colonIndex + 1).trim();
          // Nettoyer les guillemets et autres caractères
          solution = _cleanQuotes(solution);
        }
      }
    }
    
    setState(() {
      _explanation = explanation?.isNotEmpty == true 
          ? explanation 
          : (content.length > 200 ? content.substring(0, 200) + '...' : content);
      _solution = solution?.isNotEmpty == true 
          ? solution 
          : 'Vérifiez la console pour plus de détails';
      _isLoading = false;
    });
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        // Ajuster la position pour le mode collapsed
        final screenSize = MediaQuery.of(context).size;
        _position = Offset(
          _position.dx,
          screenSize.height - _collapsedHeight - 12,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _animationController.value == 0) {
      return const SizedBox.shrink();
    }

    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final bgColor = colorThemeManager.nativeBackgroundColor;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Container(
              width: _isCollapsed ? _collapsedWidth : _expandedWidth,
              height: _isCollapsed ? _collapsedHeight : _expandedHeight,
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: gxRed.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: gxRed.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: _isCollapsed ? _buildCollapsedHeader(gxRed) : _buildExpandedContent(gxRed, bgColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedHeader(Color gxRed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(CupertinoIcons.sparkles, size: 14, color: gxRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'IA - Analyse d\'erreur',
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          NotilusTooltip(
            message: 'Développer',
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 20,
              onPressed: _toggleCollapse,
              child: Icon(CupertinoIcons.chevron_up, size: 12, color: gxRed),
            ),
          ),
          const SizedBox(width: 4),
          NotilusTooltip(
            message: 'Fermer',
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 20,
              onPressed: widget.onClose,
              child: Icon(CupertinoIcons.xmark, size: 12, color: gxRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(Color gxRed, Color bgColor) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: gxRed.withOpacity(0.2), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: gxRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(CupertinoIcons.sparkles, size: 16, color: gxRed),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Analyse IA de l\'erreur',
                  style: NotilusFonts.orbitron(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              NotilusTooltip(
                message: 'Réduire',
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 20,
                  onPressed: _toggleCollapse,
                  child: Icon(CupertinoIcons.chevron_down, size: 14, color: gxRed),
                ),
              ),
              const SizedBox(width: 4),
              NotilusTooltip(
                message: 'Fermer',
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 20,
                  onPressed: widget.onClose,
                  child: Icon(CupertinoIcons.xmark, size: 14, color: gxRed),
                ),
              ),
            ],
          ),
        ),
        // Contenu
        Expanded(
          child: _buildContent(gxRed),
        ),
      ],
    );
  }

  Widget _buildContent(Color gxRed) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(gxRed),
            ),
            const SizedBox(height: 12),
            Text(
              'Analyse en cours...',
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (widget.errorEntry == null) {
      return Center(
        child: Text(
          'Aucune erreur sélectionnée',
          style: NotilusFonts.rajdhani(
            fontSize: 11,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black.withOpacity(0.2),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Erreur originale
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.exclamationmark_circle, size: 14, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'Erreur',
                        style: NotilusFonts.orbitron(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.errorEntry!.message,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Consolas',
                    ),
                  ),
                  if (widget.errorEntry!.source != null || widget.errorEntry!.lineNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.errorEntry!.sourceLocation,
                        style: NotilusFonts.rajdhani(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Explication
            if (_explanation != null) ...[
              Row(
                children: [
                  Icon(CupertinoIcons.info_circle, size: 14, color: gxRed),
                  const SizedBox(width: 6),
                  Text(
                    'Explication',
                    style: NotilusFonts.orbitron(
                      fontSize: 11,
                      color: gxRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _explanation!,
                  style: NotilusFonts.rajdhani(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Solution
            if (_solution != null) ...[
              Row(
                children: [
                  Icon(CupertinoIcons.checkmark_seal, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Solution',
                    style: NotilusFonts.orbitron(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  _solution!,
                  style: NotilusFonts.rajdhani(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

