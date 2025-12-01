import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../services/native_terminal_service.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';

/// Panneau terminal natif avec UI Flutter custom (sans xterm)
/// Design totalement immersif Notilus
class NativeTerminalPanel extends StatefulWidget {
  final String? sessionId;
  final String? host;
  final String? user;
  final String? password;
  final bool useSSH;

  const NativeTerminalPanel({
    super.key,
    this.sessionId,
    this.host,
    this.user,
    this.password,
    this.useSSH = false,
  });

  @override
  State<NativeTerminalPanel> createState() => _NativeTerminalPanelState();
}

class _NativeTerminalPanelState extends State<NativeTerminalPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final List<_TerminalLine> _outputLines = [];
  NativeTerminalSession? _session;
  bool _isInitialized = false;
  final String _currentPrompt = 'PS> ';

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour éviter setState pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    final service = Provider.of<NativeTerminalService>(context, listen: false);
    final sessionId = widget.sessionId ?? 'terminal_${DateTime.now().millisecondsSinceEpoch}';

    _session = service.createSession(
      sessionId,
      host: widget.host,
      user: widget.user,
      password: widget.password,
      useSSH: widget.useSSH,
    );

    await _session!.initialize();

    // Attendre que le shell soit prêt (important pour PowerShell)
    await Future.delayed(const Duration(milliseconds: 300));

    // Écouter la sortie
    _session!.output.listen(
      (data) {
        if (mounted) {
          setState(() {
            // Parser la sortie avec coloration
            final parsedLines = _parseOutput(data);
            _outputLines.addAll(parsedLines);
            // Limiter à 10000 lignes pour la performance
            if (_outputLines.length > 10000) {
              _outputLines.removeRange(0, _outputLines.length - 10000);
            }
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _outputLines.add(_TerminalLine(
              text: '❌ Erreur: $error',
              type: _LineType.error,
            ));
          });
        }
      },
    );

    setState(() {
      _isInitialized = true;
    });

    // Envoyer une commande vide pour initialiser le prompt PowerShell
    await Future.delayed(const Duration(milliseconds: 200));
    _session?.writeLine('');
    
    // Focus automatique sur l'input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  /// Parse la sortie avec coloration syntaxique profonde
  List<_TerminalLine> _parseOutput(String data) {
    final lines = data.split('\n');
    final result = <_TerminalLine>[];
    
    for (var line in lines) {
      if (line.isEmpty && result.isNotEmpty && result.last.text.isEmpty) {
        continue; // Éviter les lignes vides multiples
      }
      
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) {
        result.add(_TerminalLine(text: '', type: _LineType.normal));
        continue;
      }

      // Détection du type de ligne avec coloration profonde
      _LineType type = _detectLineType(trimmed);
      final segments = _parseLineSegments(trimmed, type);
      
      result.add(_TerminalLine(
        text: trimmed,
        type: type,
        segments: segments,
      ));
    }
    
    return result;
  }

  /// Détecte le type de ligne pour la coloration
  _LineType _detectLineType(String line) {
    final lower = line.toLowerCase();
    
    // Erreurs (plus permissif)
    if (lower.contains(RegExp(r'\b(error|exception|failed|failure|❌|erreur|échec)\b'))) {
      return _LineType.error;
    }
    
    // Succès
    if (lower.contains(RegExp(r'\b(success|completed|done|ok|✅|succès|terminé)\b'))) {
      return _LineType.success;
    }
    
    // Avertissements
    if (lower.contains(RegExp(r'\b(warning|warn|⚠|avertissement)\b'))) {
      return _LineType.warning;
    }
    
    // Commandes PowerShell (détection améliorée)
    if (line.startsWith('PS> ') || line.startsWith('PS ') || line.startsWith('> ') || 
        line.startsWith('PS C:') || line.startsWith('PS D:')) {
      return _LineType.command;
    }
    
    // Informations
    if (lower.contains(RegExp(r'\b(info|information|ℹ)\b'))) {
      return _LineType.info;
    }
    
    // Chemins de fichiers (plus permissif)
    if (line.contains(RegExp(r'[A-Z]:\\[^\s]+|/[^\s]+|~/[^\s]+'))) {
      return _LineType.path;
    }
    
    // URLs
    if (line.contains(RegExp(r'https?://[^\s]+|www\.[^\s]+'))) {
      return _LineType.url;
    }
    
    // Nombres (plus permissif)
    if (line.contains(RegExp(r'\b\d+\.?\d*[KMGT]?[B]?\b'))) {
      return _LineType.number;
    }
    
    return _LineType.normal;
  }

  /// Parse les segments d'une ligne pour coloration syntaxique
  List<_ColoredSegment> _parseLineSegments(String line, _LineType baseType) {
    final segments = <_ColoredSegment>[];
    
    // Toujours parser avec coloration syntaxique, même pour les réponses
    // Coloration PowerShell spécifique
    if (baseType == _LineType.command || line.startsWith('PS> ') || line.startsWith('PS ')) {
      // Détecter les commandes PowerShell
      final cmdMatch = RegExp(r'^(\w+(-\w+)*)').firstMatch(line);
      if (cmdMatch != null) {
        segments.add(_ColoredSegment(
          text: cmdMatch.group(0)!,
          color: NotilusColors.neonRed,
          fontWeight: FontWeight.bold,
        ));
        final rest = line.substring(cmdMatch.end);
        if (rest.isNotEmpty) {
          segments.add(_ColoredSegment(text: rest, color: Colors.white70));
        }
        return segments;
      }
    }
    
    // Coloration multi-éléments : chemins, URLs, nombres dans la même ligne
    int lastIndex = 0;
    final allMatches = <_MatchInfo>[];
    
    // Chemins
    final pathMatches = RegExp(r'[A-Z]:\\[^\s]+|/[^\s]+|~/[^\s]+').allMatches(line);
    for (var match in pathMatches) {
      allMatches.add(_MatchInfo(
        start: match.start,
        end: match.end,
        text: match.group(0)!,
        type: _SegmentType.path,
      ));
    }
    
    // URLs
    final urlMatches = RegExp(r'https?://[^\s]+|www\.[^\s]+').allMatches(line);
    for (var match in urlMatches) {
      allMatches.add(_MatchInfo(
        start: match.start,
        end: match.end,
        text: match.group(0)!,
        type: _SegmentType.url,
      ));
    }
    
    // Nombres
    final numberMatches = RegExp(r'\b\d+\.?\d*[KMGT]?[B]?\b').allMatches(line);
    for (var match in numberMatches) {
      allMatches.add(_MatchInfo(
        start: match.start,
        end: match.end,
        text: match.group(0)!,
        type: _SegmentType.number,
      ));
    }
    
    // Trier par position
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    
    // Construire les segments
    for (var match in allMatches) {
      // Texte avant le match
      if (match.start > lastIndex) {
        final before = line.substring(lastIndex, match.start);
        if (before.isNotEmpty) {
          segments.add(_ColoredSegment(
            text: before,
            color: _getColorForType(baseType),
          ));
        }
      }
      
      // Le match coloré
      Color matchColor;
      FontWeight? matchWeight;
      TextDecoration? matchDecoration;
      
      switch (match.type) {
        case _SegmentType.path:
          matchColor = const Color(0xFF00D4FF);
          matchWeight = FontWeight.w500;
          break;
        case _SegmentType.url:
          matchColor = const Color(0xFF00FF88);
          matchDecoration = TextDecoration.underline;
          break;
        case _SegmentType.number:
          matchColor = const Color(0xFFFFD700);
          matchWeight = FontWeight.w600;
          break;
      }
      
      segments.add(_ColoredSegment(
        text: match.text,
        color: matchColor,
        fontWeight: matchWeight,
        decoration: matchDecoration,
      ));
      
      lastIndex = match.end;
    }
    
    // Texte après le dernier match
    if (lastIndex < line.length) {
      final after = line.substring(lastIndex);
      if (after.isNotEmpty) {
        segments.add(_ColoredSegment(
          text: after,
          color: _getColorForType(baseType),
        ));
      }
    }
    
    // Si aucun segment n'a été créé, utiliser la couleur de base
    if (segments.isEmpty) {
      segments.add(_ColoredSegment(
        text: line,
        color: _getColorForType(baseType),
      ));
    }
    
    return segments;
  }

  Color _getColorForType(_LineType type) {
    switch (type) {
      case _LineType.error:
        return const Color(0xFFFF3B30);
      case _LineType.success:
        return const Color(0xFF34C759);
      case _LineType.warning:
        return const Color(0xFFFF9500);
      case _LineType.command:
        return NotilusColors.neonRed;
      case _LineType.info:
        return const Color(0xFF5AC8FA);
      case _LineType.path:
        return const Color(0xFF00D4FF);
      case _LineType.url:
        return const Color(0xFF00FF88);
      case _LineType.number:
        return const Color(0xFFFFD700);
      case _LineType.normal:
      default:
        return Colors.white70;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendCommand(String command) {
    if (command.trim().isEmpty) return;

    // Afficher la commande dans l'output
    setState(() {
      _outputLines.add(_TerminalLine(
        text: '$_currentPrompt$command',
        type: _LineType.command,
        segments: [
          _ColoredSegment(
            text: _currentPrompt,
            color: NotilusColors.neonRed,
            fontWeight: FontWeight.bold,
          ),
          _ColoredSegment(
            text: command,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ],
      ));
    });

    // Envoyer au terminal
    _session?.writeLine(command);

    // Effacer l'input
    _inputController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final wallpaperManager = context.watch<WallpaperManager>();

    final wallpaperUrl = wallpaperManager.currentImageUrl;
    
    return Container(
      decoration: BoxDecoration(
        image: wallpaperUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(wallpaperUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.85),
                  BlendMode.srcOver,
                ),
              )
            : null,
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Column(
          children: [
            // Zone de sortie - totalement intégrée, pas de conteneur visible
            Expanded(
              child: _isInitialized
                  ? _buildOutputArea()
                  : const Center(
                      child: CircularProgressIndicator(
                        color: NotilusColors.neonRed,
                        strokeWidth: 2,
                      ),
                    ),
            ),
            // Zone de saisie - totalement transparente et fondue
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Scrollbar(
        controller: _scrollController,
        thickness: 1,
        radius: const Radius.circular(0),
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _outputLines.length,
          itemBuilder: (context, index) {
            final line = _outputLines[index];
            
            if (line.text.isEmpty) {
              return const SizedBox(height: 4);
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: _buildLine(line),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLine(_TerminalLine line) {
    if (line.segments != null && line.segments!.isNotEmpty) {
      // Ligne avec segments colorés
      return RichText(
        text: TextSpan(
          children: line.segments!.map((segment) {
            return TextSpan(
              text: segment.text,
              style: NotilusFonts.code(
                fontSize: 13,
                fontWeight: segment.fontWeight ?? FontWeight.w400,
                color: segment.color,
                height: 1.4,
              ).copyWith(
                decoration: segment.decoration,
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Ligne simple avec couleur de type
      return SelectableText(
        line.text,
        style: NotilusFonts.code(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: _getColorForType(line.type),
          height: 1.4,
        ),
      );
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Prompt - rouge Notilus
          Text(
            _currentPrompt,
            style: NotilusFonts.code(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: NotilusColors.neonRed,
              height: 1.4,
            ),
          ),
          // Input - totalement transparent, sans bordures
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus && mounted) {
                  // Maintenir le focus continu
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (mounted) {
                      _inputFocusNode.requestFocus();
                    }
                  });
                }
              },
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                autofocus: false,
                style: NotilusFonts.code(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: '',
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                cursorColor: NotilusColors.neonRed,
                cursorWidth: 2,
                onSubmitted: _sendCommand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Type de ligne pour la coloration
enum _LineType {
  normal,
  error,
  success,
  warning,
  command,
  info,
  path,
  url,
  number,
}

/// Segment coloré d'une ligne
class _ColoredSegment {
  final String text;
  final Color color;
  final FontWeight? fontWeight;
  final TextDecoration? decoration;

  _ColoredSegment({
    required this.text,
    required this.color,
    this.fontWeight,
    this.decoration,
  });
}

/// Ligne de terminal avec métadonnées
class _TerminalLine {
  final String text;
  final _LineType type;
  final List<_ColoredSegment>? segments;

  _TerminalLine({
    required this.text,
    required this.type,
    this.segments,
  });
}

/// Type de segment pour la coloration
enum _SegmentType {
  path,
  url,
  number,
}

/// Information sur un match pour la coloration
class _MatchInfo {
  final int start;
  final int end;
  final String text;
  final _SegmentType type;

  _MatchInfo({
    required this.start,
    required this.end,
    required this.text,
    required this.type,
  });
}
