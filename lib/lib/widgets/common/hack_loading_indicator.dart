/// Hack-style loading indicator avec animation de terminal
/// Widget réutilisable pour afficher un indicateur de chargement style "hack"
library hack_loading_indicator;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Indicateur de chargement style hack avec animation de terminal
class HackLoadingIndicator extends StatefulWidget {
  /// Couleur d'accent pour le spinner et le texte
  final Color accentColor;
  
  /// Messages à afficher en rotation (optionnel)
  final List<String>? messages;
  
  /// Message personnalisé statique (optionnel)
  final String? message;
  
  /// Taille du spinner
  final double spinnerSize;
  
  /// Largeur de la barre de progression
  final double progressBarWidth;

  const HackLoadingIndicator({
    super.key,
    required this.accentColor,
    this.messages,
    this.message,
    this.spinnerSize = 40.0,
    this.progressBarWidth = 200.0,
  });

  @override
  State<HackLoadingIndicator> createState() => _HackLoadingIndicatorState();
}

class _HackLoadingIndicatorState extends State<HackLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _cursorController;
  late AnimationController _glitchController;
  
  final List<String> _defaultMessages = [
    '> Scanning server endpoints...',
    '> Analyzing route structure...',
    '> Extracting API metadata...',
    '> Building route map...',
    '> Validating HTTP methods...',
    '> Processing route parameters...',
  ];
  
  int _currentMessageIndex = 0;
  String _displayedText = '';
  
  List<String> get _messages => widget.messages ?? _defaultMessages;
  bool get _hasStaticMessage => widget.message != null;
  
  @override
  void initState() {
    super.initState();
    
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
    
    if (!_hasStaticMessage) {
      _startTyping();
    } else {
      _displayedText = widget.message!;
    }
  }
  
  void _startTyping() async {
    while (mounted && !_hasStaticMessage) {
      // Réinitialiser pour le nouveau message
      _displayedText = '';
      final message = _messages[_currentMessageIndex];
      
      // Taper le message caractère par caractère
      for (int i = 0; i < message.length; i++) {
        if (!mounted || _hasStaticMessage) return;
        await Future.delayed(const Duration(milliseconds: 30));
        if (mounted && !_hasStaticMessage) {
          setState(() {
            _displayedText = message.substring(0, i + 1);
          });
        }
      }
      
      // Attendre un peu avant de passer au message suivant
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted && !_hasStaticMessage) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _cursorController.dispose();
    _glitchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Spinner avec effet de glitch
        AnimatedBuilder(
          animation: _glitchController,
          builder: (context, child) {
            final offset = (math.sin(_glitchController.value * math.pi * 2) * 2);
            return Transform.translate(
              offset: Offset(offset, 0),
              child: SizedBox(
                width: widget.spinnerSize,
                height: widget.spinnerSize,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        
        // Terminal-style text avec curseur clignotant
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayedText,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: widget.accentColor,
                  letterSpacing: 0.5,
                ),
              ),
              if (!_hasStaticMessage)
                AnimatedBuilder(
                  animation: _cursorController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _cursorController.value,
                      child: Text(
                        '_',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          color: widget.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Barre de progression animée
        Container(
          width: widget.progressBarWidth,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(1),
          ),
          child: AnimatedBuilder(
            animation: _textController,
            builder: (context, child) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: widget.progressBarWidth * _textController.value,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor,
                        widget.accentColor.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

