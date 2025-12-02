/// Widget autonome pour afficher des citations inspirantes de développeurs
library developer_quotes_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';

/// Widget autonome pour afficher des citations de développeurs
class DeveloperQuotesWidget extends StatelessWidget {
  final List<String> quotes;
  final Color? accentColor;
  final double transparency;

  const DeveloperQuotesWidget({
    super.key,
    required this.quotes,
    this.accentColor,
    this.transparency = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = accentColor ?? colorTheme.nativeSecondaryColor;
    
    if (quotes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final quote = quotes[DateTime.now().day % quotes.length];
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - transparency).clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gxRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.quote_bubble,
                size: 20,
                color: gxRed,
              ),
              const SizedBox(width: 12),
              Text(
                'INSPIRATION',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: gxRed.withOpacity(0.7),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            quote,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              height: 1.6,
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

