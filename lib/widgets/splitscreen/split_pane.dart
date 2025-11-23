import 'package:flutter/material.dart';
import '../../models/tab_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/glassmorphic_container.dart';
import '../../widgets/common/neon_button.dart';

class SplitPane extends StatefulWidget {
  final TabModel? tab;
  final VoidCallback? onClose;
  final VoidCallback? onSwap;
  final double? width;
  final double? height;

  const SplitPane({
    super.key,
    this.tab,
    this.onClose,
    this.onSwap,
    this.width,
    this.height,
  });

  @override
  State<SplitPane> createState() => _SplitPaneState();
}

class _SplitPaneState extends State<SplitPane> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeFromContext();
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.background,
        border: Border.all(
          color: _isHovered ? theme.primary : theme.border,
          width: _isHovered ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Content area
          Container(
            padding: const EdgeInsets.all(8),
            child: widget.tab != null
                ? _buildTabContent(widget.tab!, theme)
                : _buildEmptyState(theme),
          ),
          
          // Control bar (appears on hover)
          if (_isHovered)
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onSwap != null)
                    NeonButton(
                      text: '↔',
                      variant: NeonButtonVariant.accent,
                      onPressed: widget.onSwap,
                      width: 28,
                      height: 28,
                      padding: EdgeInsets.zero,
                    ),
                  const SizedBox(width: 4),
                  if (widget.onClose != null)
                    NeonButton(
                      text: '×',
                      variant: NeonButtonVariant.danger,
                      onPressed: widget.onClose,
                      width: 28,
                      height: 28,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          
          // Hover detector
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(TabModel tab, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab info
        Row(
          children: [
            if (tab.favicon != null)
              Image.network(
                tab.favicon!,
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.language,
                  size: 16,
                  color: theme.textSecondary,
                ),
              )
            else
              Icon(
                Icons.language,
                size: 16,
                color: theme.textSecondary,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tab.title ?? tab.url ?? 'Onglet',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 12,
                  fontFamily: 'Roboto Mono',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Content placeholder (CEF will be integrated here)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                'Zone de rendu - CEF sera intégré ici',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 11,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.open_in_browser,
            size: 48,
            color: theme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Panneau vide',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }

  AppTheme _getThemeFromContext() {
    return const AppTheme(
      name: 'Default',
      background: Color(0xFF0D0D0D),
      surface: Color(0xFF1A1A1A),
      primary: Color(0xFFFF0040),
      secondary: Color(0xFFFF3366),
      accent: Color(0xFF00FF88),
      text: Color(0xFFE0E0E0),
      textSecondary: Color(0xFF888888),
      error: Color(0xFFFF0040),
      success: Color(0xFF00FF88),
      warning: Color(0xFFFFAA00),
      border: Color(0xFF333333),
      hover: Color(0xFF2A2A2A),
      selected: Color(0xFFFF0040),
    );
  }
}

