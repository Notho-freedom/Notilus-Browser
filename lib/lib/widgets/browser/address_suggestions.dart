import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/glassmorphic_container.dart';

class AddressSuggestions extends StatelessWidget {
  final List<SuggestionItem> items;
  final Function(SuggestionItem) onSelect;

  const AddressSuggestions({
    super.key,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeFromContext();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassmorphicContainer(
      padding: const EdgeInsets.symmetric(vertical: 4),
      showNeonBorder: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.take(8).map((item) {
          return InkWell(
            onTap: () => onSelect(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: theme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 14,
                            fontFamily: 'Roboto Mono',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle!,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                              fontFamily: 'Roboto Mono',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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

class SuggestionItem {
  final String title;
  final String? subtitle;
  final String url;
  final IconData icon;
  final SuggestionType type;

  SuggestionItem({
    required this.title,
    this.subtitle,
    required this.url,
    required this.icon,
    required this.type,
  });
}

enum SuggestionType { history, bookmark, search }

