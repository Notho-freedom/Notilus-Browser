/// Widget autonome pour une invite de commande terminal
library command_prompt_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/settings_service.dart';
import '../../core/services/color_theme_manager.dart';

/// Widget autonome pour une invite de commande terminal
class CommandPromptWidget extends StatefulWidget {
  final Color? accentColor;
  final double transparency;
  final String? greeting;
  final String? subtitle;
  final VoidCallback? onTerminalSelected;

  const CommandPromptWidget({
    super.key,
    this.accentColor,
    this.transparency = 0.0,
    this.greeting,
    this.subtitle,
    this.onTerminalSelected,
  });

  @override
  State<CommandPromptWidget> createState() => _CommandPromptWidgetState();
}

class _CommandPromptWidgetState extends State<CommandPromptWidget> {
  final TextEditingController _commandController = TextEditingController();
  final SettingsService _settings = SettingsService();

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  void _handleCommand(String cmd) {
    if (cmd.trim().isEmpty) return;
    
    // Commandes spéciales
    if (cmd.startsWith('./') || cmd.startsWith('curl') || cmd.startsWith('npm') || cmd.startsWith('docker')) {
      widget.onTerminalSelected?.call();
      _commandController.clear();
      return;
    }
    
    final tabManager = Provider.of<TabManager>(context, listen: false);
    String url = cmd.trim();
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(cmd)}';
      }
    }
    tabManager.addTab(url: url);
    _commandController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = widget.accentColor ?? colorTheme.nativeSecondaryColor;
    final customGreeting = _settings.customGreeting;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting
        Text(
          widget.greeting ?? (customGreeting.isNotEmpty ? customGreeting : '# Welcome back, Developer'),
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle ?? '// Ready to build scalable systems',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
            color: accentColor.withOpacity(0.7),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Command input
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity((1 - widget.transparency).clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
                child: Text(
                  '\$ ~',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _commandController,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'type a command, URL, or search...',
                    hintStyle: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                  cursorColor: accentColor,
                  onSubmitted: _handleCommand,
                ),
              ),
              IconButton(
                onPressed: () => _handleCommand(_commandController.text),
                icon: Icon(
                  CupertinoIcons.return_icon,
                  size: 18,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

