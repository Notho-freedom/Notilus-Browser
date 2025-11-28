/// Panel AI futuriste Notilus GX
library gx_futuristic_ai_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/wallpaper_manager.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/settings_service.dart';
import '../../services/ai_service.dart';
import '../common/gx_futuristic_components.dart';
import '../../services/gx_notification_service.dart';

class GxFuturisticAiPanel extends StatefulWidget {
  const GxFuturisticAiPanel({super.key});

  @override
  State<GxFuturisticAiPanel> createState() => _GxFuturisticAiPanelState();
}

enum _AiPanelMode { console, chat }

class _GxFuturisticAiPanelState extends State<GxFuturisticAiPanel> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _consoleInputController = TextEditingController();
  final SettingsService _settings = SettingsService();
  final AiService _aiService = AiService();
  bool _isLoading = false;
  String? _lastResponse;
  String? _lastModelUsed;
  int? _lastTokensUsed;
  List<Map<String, dynamic>> _conversationHistory = [];
  List<String> _consoleOutput = [];
  _AiPanelMode _currentMode = _AiPanelMode.console;
  bool _showHistory = false;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _consoleScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _promptController.addListener(() {
      if (mounted) setState(() {});
    });
    _consoleInputController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkConnection() async {
    await _aiService.checkConnection();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _promptController.dispose();
    _consoleInputController.dispose();
    _scrollController.dispose();
    _consoleScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NotilusColors.getSecondaryColor(context);
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;
    final wallpaperManager = context.watch<WallpaperManager>();

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(wallpaperManager.current),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    color: accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'HYPER ASSISTANT',
                    style: NotilusFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  // Switch entre console et chat
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ModeButton(
                          label: 'CONSOLE',
                          icon: CupertinoIcons.square_grid_2x2,
                          isActive: _currentMode == _AiPanelMode.console,
                          accentColor: accentColor,
                          onTap: () {
                            setState(() {
                              _currentMode = _AiPanelMode.console;
                            });
                          },
                        ),
                        _ModeButton(
                          label: 'CHAT',
                          icon: CupertinoIcons.chat_bubble_2_fill,
                          isActive: _currentMode == _AiPanelMode.chat,
                          accentColor: accentColor,
                          onTap: () {
                            setState(() {
                              _currentMode = _AiPanelMode.chat;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GxFuturisticBadge(
                    label: 'BETA',
                    color: accentColor,
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: _currentMode == _AiPanelMode.console
                  ? _buildConsoleMode(accentColor)
                  : _buildChatMode(accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleCard(Color accentColor) {
    final themeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final bgColor = themeManager.nativeBackgroundColor;
    final settings = SettingsService();
    final panelOpacity = 1.0 - settings.panelTransparency;

    return Container(
      decoration: BoxDecoration(
        color: bgColor.withOpacity(panelOpacity.clamp(0.0, 1.0)),
        border: Border.all(
          color: accentColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header console
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: accentColor.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.square_grid_2x2,
                  color: accentColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'CONSOLE GX',
                  style: NotilusFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (_consoleOutput.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _consoleOutput.clear();
                      });
                    },
                    icon: const Icon(CupertinoIcons.trash, size: 12),
                    label: const Text('Effacer', style: TextStyle(fontSize: 10)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          // Sortie console
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: _consoleOutput.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.square_grid_2x2,
                            color: accentColor.withOpacity(0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Console prête',
                            style: NotilusFonts.rajdhani(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tapez votre commande ci-dessous',
                            style: NotilusFonts.rajdhani(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _consoleScrollController,
                      itemCount: _consoleOutput.length,
                      itemBuilder: (context, index) {
                        final line = _consoleOutput[index];
                        final isCommand = line.startsWith('> ');
                        final isError = line.contains('[ERROR]');
                        final isSuccess = line.contains('[SUCCESS]');
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: SelectableText(
                            line,
                            style: NotilusFonts.rajdhani(
                              fontSize: 11,
                              color: isError
                                  ? Colors.redAccent
                                  : isSuccess
                                      ? accentColor
                                      : isCommand
                                          ? accentColor.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.7),
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleMode(Color accentColor) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Statut de connexion
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: GxFuturisticCard(
                accentColor: _aiService.isConnected ? accentColor : Colors.orange,
                padding: const EdgeInsets.all(12),
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Icon(
                      _aiService.isConnected 
                          ? CupertinoIcons.checkmark_circle_fill 
                          : CupertinoIcons.exclamationmark_circle,
                      color: _aiService.isConnected ? accentColor : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _aiService.isConnected 
                            ? 'Système connecté - Prêt pour les commandes' 
                            : 'Système déconnecté - ${_aiService.lastError ?? "Vérifiez le backend"}',
                        style: NotilusFonts.rajdhani(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    if (!_aiService.isConnected)
                      TextButton(
                        onPressed: _checkConnection,
                        child: const Text('Réessayer', style: TextStyle(fontSize: 10)),
                      ),
                  ],
                ),
              ),
            ),
            // Zone de sortie console
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildConsoleCard(accentColor),
              ),
            ),
            // Zone de saisie console
            Padding(
              padding: const EdgeInsets.all(24),
              child: GxFuturisticCard(
                accentColor: accentColor,
                padding: const EdgeInsets.all(12),
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Text(
                      '> ',
                      style: NotilusFonts.rajdhani(
                        fontSize: 14,
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _consoleInputController,
                        style: NotilusFonts.rajdhani(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Entrez une commande...',
                          hintStyle: NotilusFonts.rajdhani(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty && !_isLoading && _settings.groqApiKey.isNotEmpty) {
                            _executeConsoleCommand(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _consoleInputController.text.isEmpty || 
                                _isLoading || 
                                _settings.groqApiKey.isEmpty
                          ? null
                          : () => _executeConsoleCommand(_consoleInputController.text),
                      icon: Icon(
                        _isLoading ? CupertinoIcons.hourglass : CupertinoIcons.arrow_right_circle_fill,
                        color: _consoleInputController.text.isEmpty || 
                               _isLoading || 
                               _settings.groqApiKey.isEmpty
                            ? Colors.white.withOpacity(0.2)
                            : accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatMode(Color accentColor) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Statut de connexion
            GxFuturisticCard(
              accentColor: _aiService.isConnected ? accentColor : Colors.orange,
              padding: const EdgeInsets.all(12),
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  Icon(
                    _aiService.isConnected 
                        ? CupertinoIcons.checkmark_circle_fill 
                        : CupertinoIcons.exclamationmark_circle,
                    color: _aiService.isConnected ? accentColor : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _aiService.isConnected 
                          ? 'Connecté au backend AI' 
                          : 'Non connecté - ${_aiService.lastError ?? "Vérifiez le backend"}',
                      style: NotilusFonts.rajdhani(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  if (!_aiService.isConnected)
                    TextButton(
                      onPressed: _checkConnection,
                      child: const Text('Réessayer', style: TextStyle(fontSize: 10)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Actions rapides
            GxFuturisticCard(
              accentColor: accentColor,
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.bolt_fill,
                        color: accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ACTIONS RAPIDES',
                        style: NotilusFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickActionButton(
                        label: 'Résumer',
                        icon: CupertinoIcons.doc_text,
                        accentColor: accentColor,
                        onPressed: _settings.groqApiKey.isEmpty ? null : () => _handleQuickAction('Résume cette page en quelques points clés.'),
                      ),
                      _QuickActionButton(
                        label: 'Traduire',
                        icon: CupertinoIcons.globe,
                        accentColor: accentColor,
                        onPressed: _settings.groqApiKey.isEmpty ? null : () => _handleQuickAction('Traduis cette page en français de manière naturelle.'),
                      ),
                      _QuickActionButton(
                        label: 'Expliquer',
                        icon: CupertinoIcons.question_circle,
                        accentColor: accentColor,
                        onPressed: _settings.groqApiKey.isEmpty ? null : () => _handleQuickAction('Explique-moi cette page de manière simple et claire.'),
                      ),
                      _QuickActionButton(
                        label: 'Simplifier',
                        icon: CupertinoIcons.wand_stars,
                        accentColor: accentColor,
                        onPressed: _settings.groqApiKey.isEmpty ? null : () => _handleQuickAction('Simplifie le contenu de cette page pour le rendre plus accessible.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Zone de prompt
            GxFuturisticCard(
              accentColor: accentColor,
              padding: const EdgeInsets.all(20),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.text_cursor,
                        color: accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HYPER PROMPT',
                        style: NotilusFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GxFuturisticTextArea(
                    controller: _promptController,
                    hint: 'Décrivez ce que vous voulez faire...',
                    minLines: 3,
                    maxLines: 5,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  // Suggestions de prompts
                  if (_promptController.text.isEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _PromptSuggestionChip(
                          text: 'Résume cette page',
                          onTap: () => _promptController.text = 'Résume cette page',
                          accentColor: accentColor,
                        ),
                        _PromptSuggestionChip(
                          text: 'Trouve des alternatives',
                          onTap: () => _promptController.text = 'Trouve des alternatives',
                          accentColor: accentColor,
                        ),
                        _PromptSuggestionChip(
                          text: 'Explique simplement',
                          onTap: () => _promptController.text = 'Explique simplement',
                          accentColor: accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _promptController.text.isEmpty
                              ? 'Tapez votre question ou utilisez une action rapide'
                              : '${_promptController.text.length} caractères',
                          style: NotilusFonts.rajdhani(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GxFuturisticButton(
                        label: _isLoading ? 'Envoi...' : 'Envoyer',
                        icon: _isLoading 
                            ? CupertinoIcons.hourglass 
                            : CupertinoIcons.paperplane_fill,
                        variant: GxFuturisticButtonVariant.primary,
                        accentColor: accentColor,
                        onPressed: _isLoading || _settings.groqApiKey.isEmpty || _promptController.text.isEmpty
                            ? null
                            : _sendMessage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Historique des conversations
            if (_conversationHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              GxFuturisticCard(
                accentColor: accentColor,
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          color: accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'HISTORIQUE',
                          style: NotilusFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _conversationHistory.clear();
                            });
                          },
                          icon: const Icon(CupertinoIcons.trash, size: 12),
                          label: const Text('Effacer', style: TextStyle(fontSize: 10)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_conversationHistory.reversed.take(5).map((conv) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accentColor.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.person_fill,
                                  color: accentColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    conv['prompt'] as String,
                                    style: NotilusFonts.rajdhani(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.chat_bubble_2,
                                  color: accentColor.withOpacity(0.7),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    conv['response'] as String,
                                    style: NotilusFonts.rajdhani(
                                      fontSize: 9,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (conv['model'] != null || conv['tokens'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    if (conv['model'] != null)
                                      Text(
                                        conv['model'] as String,
                                        style: NotilusFonts.rajdhani(
                                          fontSize: 8,
                                          color: accentColor.withOpacity(0.7),
                                        ),
                                      ),
                                    if (conv['tokens'] != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${conv['tokens']} tokens',
                                        style: NotilusFonts.rajdhani(
                                          fontSize: 8,
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ))),
                  ],
                ),
              ),
            ],
            // Affichage de la réponse
            if (_lastResponse != null) ...[
              const SizedBox(height: 24),
              GxFuturisticCard(
                accentColor: accentColor,
                padding: const EdgeInsets.all(20),
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_2,
                          color: accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'RÉPONSE',
                          style: NotilusFonts.orbitron(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        if (_lastModelUsed != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: accentColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _lastModelUsed!,
                              style: NotilusFonts.rajdhani(
                                fontSize: 9,
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_lastTokensUsed != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tokens utilisés: $_lastTokensUsed',
                        style: NotilusFonts.rajdhani(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: SelectableText(
                        _lastResponse!,
                        style: NotilusFonts.rajdhani(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _lastResponse = null;
                              _lastModelUsed = null;
                              _lastTokensUsed = null;
                            });
                          },
                          icon: const Icon(CupertinoIcons.xmark_circle, size: 14),
                          label: const Text('Fermer', style: TextStyle(fontSize: 10)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _lastResponse!));
                            GxNotificationService().showSuccess(
                              title: 'Copié',
                              message: 'Réponse copiée dans le presse-papiers',
                              context: context,
                            );
                          },
                          icon: const Icon(CupertinoIcons.doc_on_doc, size: 14),
                          label: const Text('Copier', style: TextStyle(fontSize: 10)),
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            // Avertissement si pas de clé API
            if (_settings.groqApiKey.isEmpty) ...[
              const SizedBox(height: 24),
              GxFuturisticCard(
                accentColor: Colors.orange,
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clé API requise',
                            style: NotilusFonts.rajdhani(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configurez votre clé API Groq dans les paramètres pour utiliser l\'assistant IA.',
                            style: NotilusFonts.rajdhani(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_promptController.text.isEmpty) return;
    
    final prompt = _promptController.text;
    
    setState(() {
      _isLoading = true;
      _lastResponse = null;
      _lastModelUsed = null;
      _lastTokensUsed = null;
    });
    
    try {
      final result = await _aiService.chat(
        prompt: prompt,
        type: 'general',
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result != null) {
            _lastResponse = result['response'] as String? ?? 'Aucune réponse';
            _lastModelUsed = result['model_used'] as String?;
            _lastTokensUsed = result['tokens_used'] as int?;
            
            // Ajouter à l'historique
            _conversationHistory.add({
              'prompt': prompt,
              'response': _lastResponse!,
              'model': _lastModelUsed,
              'tokens': _lastTokensUsed,
              'timestamp': DateTime.now(),
            });
            
            // Limiter l'historique à 20 entrées
            if (_conversationHistory.length > 20) {
              _conversationHistory.removeAt(0);
            }
          } else {
            _lastResponse = 'Erreur: ${_aiService.lastError ?? "Impossible de générer une réponse"}';
          }
        });
        
        if (result != null) {
          GxNotificationService().showSuccess(
            title: 'Réponse générée',
            message: 'Modèle utilisé: ${_lastModelUsed ?? "N/A"}',
            context: context,
          );
          
          // Vider le champ de texte après envoi réussi
          _promptController.clear();
        } else {
          GxNotificationService().showError(
            title: 'Erreur',
            message: _aiService.lastError ?? 'Impossible de générer une réponse',
            context: context,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastResponse = 'Erreur: $e';
        });
        GxNotificationService().showError(
          title: 'Erreur',
          message: 'Erreur lors de la communication avec l\'IA: $e',
          context: context,
        );
      }
    }
  }

  Future<void> _executeConsoleCommand(String command) async {
    if (command.isEmpty) return;
    
    setState(() {
      _consoleOutput.add('> $command');
      _consoleInputController.clear();
      _isLoading = true;
    });
    
    // Scroll vers le bas
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.animateTo(
          _consoleScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    try {
      final result = await _aiService.chat(
        prompt: command,
        type: 'general',
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result != null) {
            final response = result['response'] as String? ?? 'Aucune réponse';
            final model = result['model_used'] as String?;
            final tokens = result['tokens_used'] as int?;
            
            _consoleOutput.add('[SUCCESS] Commande exécutée');
            _consoleOutput.add('Modèle: ${model ?? "N/A"}');
            if (tokens != null) {
              _consoleOutput.add('Tokens: $tokens');
            }
            _consoleOutput.add('');
            _consoleOutput.add(response);
            _consoleOutput.add('');
            
            // Ajouter à l'historique
            _conversationHistory.add({
              'prompt': command,
              'response': response,
              'model': model,
              'tokens': tokens,
              'timestamp': DateTime.now(),
            });
            
            if (_conversationHistory.length > 20) {
              _conversationHistory.removeAt(0);
            }
          } else {
            _consoleOutput.add('[ERROR] ${_aiService.lastError ?? "Impossible d\'exécuter la commande"}');
          }
        });
        
        // Scroll vers le bas après la réponse
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_consoleScrollController.hasClients) {
            _consoleScrollController.animateTo(
              _consoleScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _consoleOutput.add('[ERROR] $e');
        });
      }
    }
  }

  Future<void> _handleQuickAction(String prompt) async {
    _promptController.text = prompt;
    await _sendMessage();
  }
}

// Widget pour les boutons d'action rapide
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: onPressed != null 
              ? accentColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: onPressed != null
                ? accentColor.withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onPressed != null ? accentColor : Colors.white.withOpacity(0.3),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                color: onPressed != null ? accentColor : Colors.white.withOpacity(0.3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour le switch de mode
class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? accentColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive 
                ? accentColor
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? accentColor : Colors.white.withOpacity(0.5),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: NotilusFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? accentColor : Colors.white.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les suggestions de prompts
class _PromptSuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color accentColor;

  const _PromptSuggestionChip({
    required this.text,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          text,
          style: NotilusFonts.rajdhani(
            fontSize: 10,
            color: accentColor,
          ),
        ),
      ),
    );
  }
}

