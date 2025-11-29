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
import '../../services/auth/firebase_auth_service.dart';
import '../../services/tab_manager.dart';
import '../common/gx_futuristic_components.dart';
import '../../services/gx_notification_service.dart';

// Enum pour les modes du panel AI
enum AiPanelMode { console, chat }

class GxFuturisticAiPanel extends StatefulWidget {
  const GxFuturisticAiPanel({super.key});

  @override
  State<GxFuturisticAiPanel> createState() => _GxFuturisticAiPanelState();
}

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
  AiPanelMode _currentMode = AiPanelMode.console;
  bool _showHistory = false;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _consoleScrollController = ScrollController();
  List<String> _availableModels = [];
  String? _selectedModel;
  Map<String, dynamic> _slidingMemory = {}; // Mémoire glissante pour le contexte

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadModels();
    _loadSlidingMemory();
    _updateContextFromBrowser();
    _promptController.addListener(() {
      if (mounted) setState(() {});
    });
    _consoleInputController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadModels() async {
    final models = await _aiService.getModels();
    if (mounted && models != null) {
      setState(() {
        _availableModels = models;
        if (_selectedModel == null && models.isNotEmpty) {
          _selectedModel = _settings.aiPreferredModel.isNotEmpty 
              ? (_availableModels.contains(_settings.aiPreferredModel) ? _settings.aiPreferredModel : models.first)
              : models.first;
        }
      });
    }
  }

  Future<void> _loadSlidingMemory() async {
    // Charger la mémoire depuis les préférences
    final memory = _settings.aiSlidingMemory;
    if (memory.isNotEmpty) {
      setState(() {
        _slidingMemory = memory;
      });
    }
  }

  void _updateContextFromBrowser() {
    try {
      final tabManager = Provider.of<TabManager>(context, listen: false);
      final activeTab = tabManager.activeTab;
      
      if (activeTab != null && activeTab.url != null && activeTab.url!.isNotEmpty) {
        setState(() {
          _slidingMemory['current_url'] = activeTab.url;
          _slidingMemory['current_title'] = activeTab.title ?? '';
          
          // Informations de la console (dernières lignes)
          if (_consoleOutput.isNotEmpty) {
            _slidingMemory['console_output'] = _consoleOutput.take(10).join('\n');
            _slidingMemory['console_lines_count'] = _consoleOutput.length;
          }
          
          // Informations réseau
          _slidingMemory['network_status'] = _aiService.isConnected ? 'connected' : 'disconnected';
          
          _slidingMemory['last_updated'] = DateTime.now().toIso8601String();
        });
        _saveSlidingMemory();
      }
    } catch (e) {
      // Ignorer les erreurs si TabManager n'est pas disponible
    }
  }

  void _saveSlidingMemory() {
    _settings.setAiSlidingMemory(_slidingMemory);
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

  void _handleQuickAction(String prompt) {
    _promptController.text = prompt;
    _sendMessage();
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
    
    // Construire le contexte avec la mémoire glissante
    final context = <String, dynamic>{
      ..._slidingMemory,
    };
    
    try {
      final result = await _aiService.chat(
        prompt: command,
        context: context.isNotEmpty ? context : null,
        type: 'general',
        model: _selectedModel,
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
                          filled: true,
                          fillColor: Colors.transparent,
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
        return Column(
          children: [
            // Messages
            Expanded(
              child: _conversationHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_2_fill,
                            size: 64,
                            color: accentColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Démarrez une conversation',
                            style: NotilusFonts.orbitron(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Posez une question ou utilisez une action rapide',
                            style: NotilusFonts.rajdhani(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Actions rapides
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
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24),
                      itemCount: _conversationHistory.length,
                      itemBuilder: (context, index) {
                        final conv = _conversationHistory[index];
                        return _ChatMessageBubble(
                          prompt: conv['prompt'] as String,
                          response: conv['response'] as String,
                          model: conv['model'] as String?,
                          tokens: conv['tokens'] as int?,
                          timestamp: conv['timestamp'] as DateTime?,
                          accentColor: accentColor,
                        );
                      },
                    ),
            ),
            // Zone de saisie
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: accentColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: GxFuturisticCard(
                accentColor: accentColor,
                padding: const EdgeInsets.all(12),
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        style: NotilusFonts.rajdhani(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tapez votre message...',
                          hintStyle: NotilusFonts.rajdhani(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) {
                          if (value.isNotEmpty && !_isLoading && _settings.groqApiKey.isNotEmpty) {
                            _sendMessage();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    GxFuturisticButton(
                      label: _isLoading ? '...' : '',
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
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NotilusColors.getSecondaryColor(context);
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
                  // Badge de statut de connexion (extrême gauche)
                  GxFuturisticBadge(
                    label: _aiService.isConnected ? 'Connecté' : 'Déconnecté',
                    icon: _aiService.isConnected 
                        ? CupertinoIcons.checkmark_circle_fill 
                        : CupertinoIcons.exclamationmark_circle,
                    color: _aiService.isConnected 
                        ? const Color(0xFF22C55E) 
                        : const Color(0xFFEF4444),
                    glow: _aiService.isConnected,
                  ),
                  const Spacer(),
                  // Sélecteur de modèle (centre)
                  if (_availableModels.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedModel,
                          isDense: true,
                          icon: Icon(
                            CupertinoIcons.chevron_down,
                            size: 14,
                            color: accentColor,
                          ),
                          dropdownColor: Colors.black,
                          style: NotilusFonts.rajdhani(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                          items: _availableModels.map((model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(
                                model.length > 20 ? '${model.substring(0, 20)}...' : model,
                                style: NotilusFonts.rajdhani(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newModel) {
                            if (newModel != null) {
                              setState(() {
                                _selectedModel = newModel;
                                _settings.setAiPreferredModel(newModel);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Switch entre console et chat (extrême droite)
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
                          isActive: _currentMode == AiPanelMode.console,
                          accentColor: accentColor,
                          onTap: () {
                            setState(() {
                              _currentMode = AiPanelMode.console;
                            });
                          },
                        ),
                        _ModeButton(
                          label: 'CHAT',
                          icon: CupertinoIcons.chat_bubble_2_fill,
                          isActive: _currentMode == AiPanelMode.chat,
                          accentColor: accentColor,
                          onTap: () {
                            setState(() {
                              _currentMode = AiPanelMode.chat;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: _currentMode == AiPanelMode.console
                  ? _buildConsoleMode(accentColor)
                  : _buildChatMode(accentColor),
            ),
          ],
        ),
      ),
    );
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

// Widget pour les bulles de message de chat
class _ChatMessageBubble extends StatelessWidget {
  final String prompt;
  final String response;
  final String? model;
  final int? tokens;
  final DateTime? timestamp;
  final Color accentColor;

  const _ChatMessageBubble({
    required this.prompt,
    required this.response,
    this.model,
    this.tokens,
    this.timestamp,
    required this.accentColor,
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer les infos utilisateur
    final authService = Provider.of<FirebaseAuthService?>(context, listen: false);
    final user = authService?.currentUser;
    final githubUser = authService?.githubUser;
    final displayName = user?.displayName ?? user?.email ?? githubUser?.name ?? githubUser?.email ?? 'Utilisateur';
    final photoUrl = user?.photoURL ?? githubUser?.avatarUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message utilisateur
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, left: 80),
            constraints: const BoxConstraints(maxWidth: 400),
            child: GxFuturisticCard(
              accentColor: accentColor,
              padding: const EdgeInsets.all(14),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (photoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            photoUrl,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                CupertinoIcons.person_fill,
                                color: accentColor,
                                size: 12,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            CupertinoIcons.person_fill,
                            color: accentColor,
                            size: 12,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayName,
                          style: NotilusFonts.orbitron(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    prompt,
                    style: NotilusFonts.rajdhani(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Message assistant
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 80),
            constraints: const BoxConstraints(maxWidth: 400),
            child: GxFuturisticCard(
              accentColor: accentColor.withOpacity(0.6),
              padding: const EdgeInsets.all(14),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.sparkles,
                        color: accentColor.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Assistant IA',
                        style: NotilusFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor.withOpacity(0.8),
                        ),
                      ),
                      if (model != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: GxFuturisticBadge(
                            label: model!.length > 15 ? '${model!.substring(0, 15)}...' : model!,
                            color: accentColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    response,
                    style: NotilusFonts.rajdhani(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                  if (tokens != null || timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          if (tokens != null)
                            GxFuturisticBadge(
                              label: '$tokens tokens',
                              icon: CupertinoIcons.number,
                              color: accentColor.withOpacity(0.4),
                            ),
                          if (tokens != null && timestamp != null)
                            const SizedBox(width: 6),
                          if (timestamp != null)
                            Text(
                              _formatTime(timestamp!),
                              style: NotilusFonts.rajdhani(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
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