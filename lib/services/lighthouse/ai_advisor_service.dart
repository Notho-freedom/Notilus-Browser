/// Service AI Advisor pour Notilus Lighthouse
/// Fournit des recommandations intelligentes, quick wins et chat
library ai_advisor_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/lighthouse/audit_models.dart';
import '../../services/ai_service.dart';
import 'lighthouse_service.dart';

/// Service AI Advisor
class AIAdvisorService extends ChangeNotifier {
  final LighthouseService _lighthouseService;
  final AiService _aiService = AiService();

  // État du chat
  final List<ChatMessage> _chatHistory = [];
  bool _isProcessing = false;
  bool _hasInitialized = false;

  // Recommandations intelligentes
  List<SmartRecommendation> _smartRecommendations = [];
  List<QuickWin> _quickWins = [];

  AIAdvisorService(this._lighthouseService);

  // Getters
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  bool get isProcessing => _isProcessing;
  List<SmartRecommendation> get smartRecommendations =>
      List.unmodifiable(_smartRecommendations);
  List<QuickWin> get quickWins => List.unmodifiable(_quickWins);

  /// Analyse un résultat d'audit et génère des recommandations intelligentes
  Future<void> analyzeAuditResult(AuditResult result) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // Générer les quick wins
      _quickWins = _identifyQuickWins(result);

      // Générer les recommandations intelligentes
      _smartRecommendations = _generateSmartRecommendations(result);

      // Trier par priorité
      _smartRecommendations.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      
      // Initialiser le chat avec le rapport en contexte
      _hasInitialized = false;
      _chatHistory.clear();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  /// Initialise le chat avec le rapport d'analyse (appelé automatiquement lors de l'ouverture du chat)
  Future<void> initializeChat() async {
    if (_hasInitialized) return;
    
    final result = _lighthouseService.lastResult;
    if (result == null) return;
    
    _hasInitialized = true;
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Préparer le contexte du rapport
      final context = _buildAuditContext(result);
      
      // Envoyer le premier message de l'IA avec le contexte
      final response = await _aiService.chat(
        prompt: 'Analyse ce rapport Lighthouse et donne-moi un résumé des points clés et des recommandations prioritaires.',
        context: context,
        type: 'lighthouse_analysis',
      );
      
      if (response != null && response['response'] != null) {
        _chatHistory.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: ChatRole.assistant,
          content: response['response'] as String,
          timestamp: DateTime.now(),
        ));
      } else {
        // Fallback si l'IA ne répond pas
        _chatHistory.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: ChatRole.assistant,
          content: _generateInitialMessage(result),
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Erreur initialisation chat IA: $e');
      // Fallback avec message généré localement
      final result = _lighthouseService.lastResult;
      if (result != null) {
        _chatHistory.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: ChatRole.assistant,
          content: _generateInitialMessage(result),
          timestamp: DateTime.now(),
        ));
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  /// Construit le contexte du rapport pour l'IA
  Map<String, dynamic> _buildAuditContext(AuditResult result) {
    return {
      'overallScore': result.overallScore,
      'url': result.url,
      'categories': {
        'performance': result.categories[AuditCategory.performance]?.score,
        'accessibility': result.categories[AuditCategory.accessibility]?.score,
        'bestPractices': result.categories[AuditCategory.bestPractices]?.score,
        'seo': result.categories[AuditCategory.seo]?.score,
      },
      'webVitals': {
        'lcp': result.webVitals.lcp,
        'fid': result.webVitals.fid,
        'cls': result.webVitals.cls,
        'ttfb': result.webVitals.ttfb,
      },
      'issuesCount': result.issues.length,
      'issues': result.issues.take(20).map((issue) => {
        'title': issue.title,
        'description': issue.description,
        'category': issue.category.toString(),
        'severity': issue.severity.toString(),
      }).toList(),
      'quickWinsCount': _quickWins.length,
      'recommendationsCount': _smartRecommendations.length,
    };
  }
  
  /// Génère un message initial si l'IA ne répond pas
  String _generateInitialMessage(AuditResult result) {
    return 'Bonjour ! J\'ai analysé votre site et voici un résumé :\n\n'
        '📊 Score global : ${result.overallScore}/100\n\n'
        '🔍 Points clés :\n'
        '• ${result.issues.length} problème(s) détecté(s)\n'
        '• ${_quickWins.length} quick win(s) disponible(s)\n'
        '• ${_smartRecommendations.length} recommandation(s) intelligente(s)\n\n'
        'Posez-moi une question pour en savoir plus !';
  }

  /// Identifie les quick wins (corrections faciles avec grand impact)
  List<QuickWin> _identifyQuickWins(AuditResult result) {
    final quickWins = <QuickWin>[];

    // Quick wins basés sur les issues avec effort minimal
    for (final issue in result.issues) {
      if (issue.suggestedFixes?.any((f) => f.effort == EffortLevel.minimal) == true) {
        final fix = issue.suggestedFixes!.firstWhere(
          (f) => f.effort == EffortLevel.minimal,
        );

        // Calculer l'impact estimé
        final impact = _estimateImpact(issue);

        if (impact >= 5) {
          quickWins.add(QuickWin(
            id: 'qw_${issue.id}',
            title: issue.title,
            description: issue.description,
            fix: fix,
            estimatedScoreGain: impact,
            category: issue.category,
            issue: issue,
          ));
        }
      }
    }

    // Quick wins basés sur les Core Web Vitals
    if (result.webVitals.lcp != null && result.webVitals.lcp! > 2500) {
      quickWins.add(QuickWin(
        id: 'qw_lcp',
        title: 'Optimiser LCP (Largest Contentful Paint)',
        description:
            'Le LCP est de ${result.webVitals.lcp!.toStringAsFixed(0)}ms. Optimiser l\'image principale peut améliorer le score de 5-10 points.',
        fix: Fix(
          id: 'fix_lcp',
          title: 'Optimiser l\'image LCP',
          description:
              'Compresser et utiliser des formats modernes (WebP, AVIF) pour l\'image principale.',
          effort: EffortLevel.minimal,
        ),
        estimatedScoreGain: 8,
        category: AuditCategory.performance,
      ));
    }

    if (result.webVitals.cls != null && result.webVitals.cls! > 0.1) {
      quickWins.add(QuickWin(
        id: 'qw_cls',
        title: 'Réduire CLS (Cumulative Layout Shift)',
        description:
            'Le CLS est de ${result.webVitals.cls!.toStringAsFixed(3)}. Ajouter des dimensions aux images peut améliorer le score de 3-7 points.',
        fix: Fix(
          id: 'fix_cls',
          title: 'Ajouter dimensions aux images',
          description:
              'Spécifier width et height sur toutes les images pour éviter les décalages de layout.',
          effort: EffortLevel.minimal,
          code: '<img src="image.jpg" width="800" height="600" alt="Description">',
          canAutoFix: true,
        ),
        estimatedScoreGain: 5,
        category: AuditCategory.performance,
      ));
    }

    // Quick wins SEO
    final seoIssues = result.issues.where((i) => i.category == AuditCategory.seo);
    if (seoIssues.any((i) => i.title.toLowerCase().contains('meta'))) {
      quickWins.add(QuickWin(
        id: 'qw_seo_meta',
        title: 'Ajouter meta tags SEO',
        description:
            'Ajouter des meta tags (description, keywords) peut améliorer le référencement.',
        fix: Fix(
          id: 'fix_seo_meta',
          title: 'Ajouter meta tags',
          description: 'Ajouter <meta name="description" content="..."> dans le <head>.',
          effort: EffortLevel.minimal,
          code:
              '<meta name="description" content="Description de votre site">\n<meta name="keywords" content="mots, clés, pertinents">',
        ),
        estimatedScoreGain: 6,
        category: AuditCategory.seo,
      ));
    }

    return quickWins;
  }

  /// Génère des recommandations intelligentes priorisées
  List<SmartRecommendation> _generateSmartRecommendations(AuditResult result) {
    final recommendations = <SmartRecommendation>[];

    // Analyser le score global
    if (result.overallScore < 50) {
      recommendations.add(SmartRecommendation(
        id: 'sr_critical_score',
        title: 'Score critique - Action immédiate requise',
        description:
            'Le score global est de ${result.overallScore}/100. Des améliorations majeures sont nécessaires.',
        priority: RecommendationPriority.high,
        category: AuditCategory.performance,
        estimatedImpact: 20,
        effort: EffortLevel.significant,
        actionPlan: [
          'Identifier les problèmes critiques (${result.criticalIssueCount} détectés)',
          'Prioriser les quick wins disponibles',
          'Planifier les optimisations à long terme',
        ],
        reasoning:
            'Un score inférieur à 50 indique des problèmes fondamentaux qui affectent l\'expérience utilisateur.',
      ));
    }

    // Analyser les Core Web Vitals
    if (result.webVitals.lcp != null && result.webVitals.lcp! > 4000) {
      recommendations.add(SmartRecommendation(
        id: 'sr_lcp_critical',
        title: 'LCP critique - Optimisation urgente',
        description:
            'Le LCP de ${result.webVitals.lcp!.toStringAsFixed(0)}ms est dans la zone rouge (>4000ms).',
        priority: RecommendationPriority.high,
        category: AuditCategory.performance,
        estimatedImpact: 15,
        effort: EffortLevel.moderate,
        actionPlan: [
          'Optimiser l\'image principale (compression, format moderne)',
          'Améliorer le temps de réponse serveur (TTFB)',
          'Précharger les ressources critiques',
        ],
        reasoning:
            'Le LCP est le facteur le plus important pour l\'expérience utilisateur perçue.',
      ));
    }

    // Analyser les problèmes de sécurité
    final securityIssues = result.issues
        .where((i) => i.category == AuditCategory.security)
        .toList();
    if (securityIssues.isNotEmpty) {
      recommendations.add(SmartRecommendation(
        id: 'sr_security',
        title: 'Problèmes de sécurité détectés',
        description:
            '${securityIssues.length} problème(s) de sécurité nécessitent une attention immédiate.',
        priority: RecommendationPriority.high,
        category: AuditCategory.security,
        estimatedImpact: 25,
        effort: EffortLevel.moderate,
        actionPlan: securityIssues
            .take(5)
            .map((i) => 'Corriger: ${i.title}')
            .toList(),
        reasoning:
            'Les problèmes de sécurité peuvent exposer les utilisateurs et affecter la confiance.',
      ));
    }

    // Analyser les ressources
    if (result.resources.totalSize > 5 * 1024 * 1024) {
      recommendations.add(SmartRecommendation(
        id: 'sr_resources',
        title: 'Taille totale des ressources élevée',
        description:
            'La taille totale des ressources est de ${(result.resources.totalSize / (1024 * 1024)).toStringAsFixed(1)} MB.',
        priority: RecommendationPriority.medium,
        category: AuditCategory.performance,
        estimatedImpact: 10,
        effort: EffortLevel.moderate,
        actionPlan: [
          'Compresser les images',
          'Minifier CSS et JavaScript',
          'Utiliser la compression gzip/brotli',
          'Implémenter le lazy loading',
        ],
        reasoning:
            'Réduire la taille des ressources améliore les temps de chargement et l\'expérience utilisateur.',
      ));
    }

    // Analyser l'accessibilité
    final a11yIssues = result.issues
        .where((i) => i.category == AuditCategory.accessibility)
        .toList();
    if (a11yIssues.length > 5) {
      recommendations.add(SmartRecommendation(
        id: 'sr_accessibility',
        title: 'Améliorer l\'accessibilité',
        description:
            '${a11yIssues.length} problème(s) d\'accessibilité détectés.',
        priority: RecommendationPriority.medium,
        category: AuditCategory.accessibility,
        estimatedImpact: 8,
        effort: EffortLevel.moderate,
        actionPlan: [
          'Ajouter des attributs alt aux images',
          'Améliorer le contraste des couleurs',
          'Ajouter des labels aux formulaires',
          'Vérifier la navigation au clavier',
        ],
        reasoning:
            'L\'accessibilité améliore l\'expérience pour tous les utilisateurs et la conformité légale.',
      ));
    }

    return recommendations;
  }

  /// Estime l'impact d'une issue
  int _estimateImpact(Issue issue) {
    int impact = 0;

    // Basé sur la sévérité
    switch (issue.severity) {
      case IssueSeverity.critical:
        impact += 10;
        break;
      case IssueSeverity.high:
        impact += 7;
        break;
      case IssueSeverity.medium:
        impact += 4;
        break;
      case IssueSeverity.low:
        impact += 2;
        break;
      case IssueSeverity.warning:
        impact += 3;
        break;
      case IssueSeverity.info:
        impact += 1;
        break;
      case IssueSeverity.passed:
        impact += 0;
        break;
    }

    // Basé sur la catégorie
    switch (issue.category) {
      case AuditCategory.performance:
        impact += 3;
        break;
      case AuditCategory.security:
        impact += 5;
        break;
      case AuditCategory.accessibility:
        impact += 2;
        break;
      default:
        impact += 1;
    }

    return impact;
  }

  /// Envoie un message dans le chat
  Future<void> sendMessage(String message) async {
    // Initialiser le chat si ce n'est pas déjà fait
    if (!_hasInitialized) {
      await initializeChat();
    }
    
    // Ajouter le message utilisateur
    _chatHistory.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: message,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // Appeler l'IA avec le contexte du rapport
    _isProcessing = true;
    notifyListeners();

    try {
      final result = _lighthouseService.lastResult;
      Map<String, dynamic>? context;
      
      if (result != null) {
        context = _buildAuditContext(result);
      }
      
      final response = await _aiService.chat(
        prompt: message,
        context: context,
        type: 'lighthouse_analysis',
      );
      
      String aiResponse;
      if (response != null && response['response'] != null) {
        aiResponse = response['response'] as String;
      } else {
        // Fallback sur la génération locale
        aiResponse = _generateChatResponse(message);
      }
      
      _chatHistory.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.assistant,
        content: aiResponse,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Erreur chat IA: $e');
      // Fallback sur la génération locale
      final response = _generateChatResponse(message);
      _chatHistory.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: ChatRole.assistant,
        content: response,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Génère une réponse de chat basée sur le contexte
  String _generateChatResponse(String message) {
    final lowerMessage = message.toLowerCase();
    final result = _lighthouseService.lastResult;

    if (result == null) {
      return 'Je n\'ai pas encore analysé de site. Lancez un audit pour que je puisse vous aider !';
    }

    // Réponses contextuelles basées sur les mots-clés
    if (lowerMessage.contains('score') || lowerMessage.contains('performance')) {
      return 'Le score actuel est de ${result.overallScore}/100. '
          'Je recommande de commencer par les ${_quickWins.length} quick wins disponibles, '
          'qui peuvent améliorer le score de ${_quickWins.fold<int>(0, (sum, qw) => sum + qw.estimatedScoreGain)} points.';
    }

    if (lowerMessage.contains('lcp') || lowerMessage.contains('chargement')) {
      if (result.webVitals.lcp != null) {
        return 'Le LCP actuel est de ${result.webVitals.lcp!.toStringAsFixed(0)}ms. '
            'Pour l\'optimiser, je recommande de :\n'
            '1. Optimiser l\'image principale\n'
            '2. Améliorer le TTFB (actuellement ${result.webVitals.ttfb?.toStringAsFixed(0) ?? "?"}ms)\n'
            '3. Précharger les ressources critiques';
      }
    }

    if (lowerMessage.contains('sécurité') || lowerMessage.contains('security')) {
      final secIssues = result.issues
          .where((i) => i.category == AuditCategory.security)
          .length;
      if (secIssues > 0) {
        return 'J\'ai détecté $secIssues problème(s) de sécurité. '
            'Je recommande de les corriger en priorité, notamment :\n'
            '${result.issues.where((i) => i.category == AuditCategory.security).take(3).map((i) => "- ${i.title}").join("\n")}';
      } else {
        return 'Aucun problème de sécurité majeur détecté. Continuez à suivre les bonnes pratiques !';
      }
    }

    if (lowerMessage.contains('quick win') || lowerMessage.contains('rapide')) {
      if (_quickWins.isNotEmpty) {
        return 'Voici les ${_quickWins.length} quick wins disponibles :\n\n'
            '${_quickWins.take(5).map((qw) => "• ${qw.title} (+${qw.estimatedScoreGain} points)").join("\n")}\n\n'
            'Ces corrections sont faciles à implémenter et auront un impact immédiat sur votre score.';
      } else {
        return 'Aucun quick win disponible pour le moment. '
            'Les améliorations nécessiteront plus d\'effort mais auront un impact significatif.';
      }
    }

    // Réponse par défaut
    return 'Basé sur l\'audit actuel, je recommande de :\n'
        '1. Commencer par les quick wins (${_quickWins.length} disponibles)\n'
        '2. Suivre les recommandations prioritaires\n'
        '3. Surveiller les tendances dans l\'historique\n\n'
        'Posez-moi des questions spécifiques pour des conseils détaillés !';
  }

  /// Efface l'historique du chat
  void clearChat() {
    _chatHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Message de chat
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

/// Rôle dans le chat
enum ChatRole {
  user,
  assistant,
}

/// Quick Win (correction rapide avec grand impact)
class QuickWin {
  final String id;
  final String title;
  final String description;
  final Fix fix;
  final int estimatedScoreGain;
  final AuditCategory category;
  final Issue? issue;

  QuickWin({
    required this.id,
    required this.title,
    required this.description,
    required this.fix,
    required this.estimatedScoreGain,
    required this.category,
    this.issue,
  });
}

/// Recommandation intelligente
class SmartRecommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final AuditCategory category;
  final int estimatedImpact;
  final EffortLevel effort;
  final List<String> actionPlan;
  final String reasoning;

  SmartRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.estimatedImpact,
    required this.effort,
    required this.actionPlan,
    required this.reasoning,
  });

  /// Score de priorité (impact / effort)
  double get priorityScore {
    final effortMultiplier = effort == EffortLevel.minimal
        ? 3.0
        : effort == EffortLevel.moderate
            ? 2.0
            : 1.0;
    return estimatedImpact * effortMultiplier;
  }
}

