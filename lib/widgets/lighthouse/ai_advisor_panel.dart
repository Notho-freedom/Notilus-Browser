/// Panneau AI Advisor pour Notilus Lighthouse
/// Affiche les recommandations intelligentes, quick wins et chat
library ai_advisor_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/lighthouse/lighthouse_service.dart';
import '../../services/lighthouse/ai_advisor_service.dart';
import '../../models/lighthouse/audit_models.dart';
import '../../core/services/color_theme_manager.dart';

/// Panneau AI Advisor
class AIAdvisorPanel extends StatefulWidget {
  const AIAdvisorPanel({super.key});

  @override
  State<AIAdvisorPanel> createState() => _AIAdvisorPanelState();
}

class _AIAdvisorPanelState extends State<AIAdvisorPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<LighthouseService>(
      builder: (context, lighthouse, _) {
        final aiAdvisor = lighthouse.aiAdvisorService;

        return Column(
          children: [
            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: accentColor,
                labelColor: accentColor,
                unselectedLabelColor: Colors.white.withOpacity(0.5),
                tabs: const [
                  Tab(
                    icon: Icon(CupertinoIcons.lightbulb, size: 16),
                    text: 'Quick Wins',
                  ),
                  Tab(
                    icon: Icon(CupertinoIcons.star, size: 16),
                    text: 'Recommandations',
                  ),
                  Tab(
                    icon: Icon(CupertinoIcons.chat_bubble, size: 16),
                    text: 'Chat',
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _QuickWinsTab(aiAdvisor: aiAdvisor, accentColor: accentColor),
                  _RecommendationsTab(
                      aiAdvisor: aiAdvisor, accentColor: accentColor),
                  _ChatTab(
                      aiAdvisor: aiAdvisor,
                      accentColor: accentColor,
                      chatController: _chatController),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Quick Wins Tab
class _QuickWinsTab extends StatelessWidget {
  final AIAdvisorService aiAdvisor;
  final Color accentColor;

  const _QuickWinsTab({
    required this.aiAdvisor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final quickWins = aiAdvisor.quickWins;

    if (quickWins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.check_mark_circled,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun quick win disponible',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tous les problèmes nécessitent plus d\'effort',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.bolt, size: 20, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${quickWins.length} Quick Wins disponibles',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gain estimé: +${quickWins.fold<int>(0, (sum, qw) => sum + qw.estimatedScoreGain)} points',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Quick wins list
          ...quickWins.map((qw) => _QuickWinCard(
                quickWin: qw,
                accentColor: accentColor,
              )),
        ],
      ),
    );
  }
}

class _QuickWinCard extends StatelessWidget {
  final QuickWin quickWin;
  final Color accentColor;

  const _QuickWinCard({
    required this.quickWin,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${quickWin.estimatedScoreGain} pts',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quickWin.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quickWin.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.wrench, size: 14, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      quickWin.fix.title,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  quickWin.fix.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                if (quickWin.fix.code != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      quickWin.fix.code!,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Recommendations Tab
class _RecommendationsTab extends StatelessWidget {
  final AIAdvisorService aiAdvisor;
  final Color accentColor;

  const _RecommendationsTab({
    required this.aiAdvisor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = aiAdvisor.smartRecommendations;

    if (recommendations.isEmpty) {
      return Center(
        child: Text(
          'Aucune recommandation disponible',
          style: TextStyle(color: Colors.white.withOpacity(0.4)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: recommendations.map((rec) => _RecommendationCard(
              recommendation: rec,
              accentColor: accentColor,
            )).toList(),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final SmartRecommendation recommendation;
  final Color accentColor;

  const _RecommendationCard({
    required this.recommendation,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommendation.priority.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: recommendation.priority.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recommendation.priority.displayName.toUpperCase(),
                  style: TextStyle(
                    color: recommendation.priority.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Metrics
          Row(
            children: [
              _MetricChip(
                label: 'Impact',
                value: '${recommendation.estimatedImpact}',
                color: accentColor,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                label: 'Effort',
                value: recommendation.effort.displayName,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action plan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.list_bullet, size: 14, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'Plan d\'action',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...recommendation.actionPlan.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(color: accentColor, fontSize: 12),
                          ),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Reasoning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.lightbulb, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.reasoning,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
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
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Chat Tab
class _ChatTab extends StatelessWidget {
  final AIAdvisorService aiAdvisor;
  final Color accentColor;
  final TextEditingController chatController;

  const _ChatTab({
    required this.aiAdvisor,
    required this.accentColor,
    required this.chatController,
  });

  @override
  Widget build(BuildContext context) {
    final messages = aiAdvisor.chatHistory;

    return Column(
      children: [
        // Messages
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.chat_bubble,
                        size: 48,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Posez-moi une question !',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Je peux vous aider avec le score, les performances, la sécurité...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _ChatMessageBubble(
                      message: message,
                      accentColor: accentColor,
                    );
                  },
                ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Posez une question...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: accentColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(context),
                ),
              ),
              const SizedBox(width: 8),
              if (aiAdvisor.isProcessing)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(CupertinoIcons.paperplane_fill, color: accentColor),
                  onPressed: () => _sendMessage(context),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage(BuildContext context) {
    final text = chatController.text.trim();
    if (text.isEmpty) return;

    chatController.clear();
    aiAdvisor.sendMessage(text);
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color accentColor;

  const _ChatMessageBubble({
    required this.message,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? accentColor.withOpacity(0.2)
              : const Color(0xFF15151E),
          borderRadius: BorderRadius.circular(12),
          border: isUser
              ? Border.all(color: accentColor.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

