import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service de gestion des mises à jour de Notilus Browser
class UpdateService extends ChangeNotifier {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String currentVersion = '1.0.0';
  static const String _githubRepo = 'notilus/notilus-browser'; // À remplacer par le vrai repo
  
  String? _latestVersion;
  String? _changelog;
  DateTime? _lastCheck;
  bool _isChecking = false;
  bool _updateAvailable = false;
  String? _downloadUrl;
  List<UpdateInfo> _recentUpdates = [];

  // Getters
  String get version => currentVersion;
  String? get latestVersion => _latestVersion;
  String? get changelog => _changelog;
  DateTime? get lastCheck => _lastCheck;
  bool get isChecking => _isChecking;
  bool get updateAvailable => _updateAvailable;
  String? get downloadUrl => _downloadUrl;
  List<UpdateInfo> get recentUpdates => _recentUpdates;

  /// Vérifie les mises à jour depuis GitHub Releases
  Future<void> checkForUpdates() async {
    if (_isChecking) return;
    
    _isChecking = true;
    notifyListeners();

    try {
      // Simuler une vérification (à remplacer par une vraie API GitHub)
      await Future.delayed(const Duration(seconds: 2));
      
      // Pour la démo, on simule qu'il n'y a pas de mise à jour
      _latestVersion = currentVersion;
      _updateAvailable = false;
      _lastCheck = DateTime.now();
      
      // Charger le changelog local
      _loadLocalChangelog();
      
    } catch (e) {
      debugPrint('Erreur lors de la vérification des mises à jour: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Charge le changelog depuis GitHub API (simulé)
  Future<void> _fetchGitHubReleases() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_githubRepo/releases'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> releases = jsonDecode(response.body);
        if (releases.isNotEmpty) {
          final latest = releases.first;
          _latestVersion = (latest['tag_name'] as String).replaceFirst('v', '');
          _changelog = latest['body'] as String?;
          _downloadUrl = latest['html_url'] as String?;
          _updateAvailable = _compareVersions(_latestVersion!, currentVersion) > 0;
        }
      }
    } catch (e) {
      debugPrint('Erreur GitHub API: $e');
    }
  }

  /// Compare deux versions (retourne 1 si v1 > v2, -1 si v1 < v2, 0 si égales)
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// Charge les mises à jour locales depuis les fonctionnalités implémentées
  void _loadLocalChangelog() {
    _recentUpdates = [
      UpdateInfo(
        title: 'Système de Mosaïque',
        description: 'Workspace dynamique avec 9 layouts prédéfinis et tiles personnalisables',
        date: DateTime.now().subtract(const Duration(days: 1)),
        isNew: true,
        category: UpdateCategory.feature,
      ),
      UpdateInfo(
        title: 'DevTools Natifs',
        description: 'Console, Network, Elements, Performance, Application, Resources',
        date: DateTime.now().subtract(const Duration(days: 2)),
        isNew: true,
        category: UpdateCategory.feature,
      ),
      UpdateInfo(
        title: 'Terminal Intégré',
        description: 'Terminal PowerShell/CMD natif avec coloration syntaxique',
        date: DateTime.now().subtract(const Duration(days: 3)),
        isNew: false,
        category: UpdateCategory.feature,
      ),
      UpdateInfo(
        title: 'Optimisation Performance',
        description: 'RepaintBoundary, Selector, et lazy loading pour une meilleure fluidité',
        date: DateTime.now().subtract(const Duration(days: 4)),
        isNew: false,
        category: UpdateCategory.improvement,
      ),
      UpdateInfo(
        title: 'Responsive Design',
        description: 'Adaptation automatique à toutes les tailles d\'écran',
        date: DateTime.now().subtract(const Duration(days: 5)),
        isNew: false,
        category: UpdateCategory.improvement,
      ),
      UpdateInfo(
        title: 'Services Web Sidebar',
        description: 'YouTube Music, ChatGPT, DeepSeek, WhatsApp, Telegram intégrés',
        date: DateTime.now().subtract(const Duration(days: 7)),
        isNew: false,
        category: UpdateCategory.feature,
      ),
    ];
    notifyListeners();
  }

  /// Formate la date relative
  String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    }
  }
}

/// Information sur une mise à jour
class UpdateInfo {
  final String title;
  final String description;
  final DateTime date;
  final bool isNew;
  final UpdateCategory category;

  const UpdateInfo({
    required this.title,
    required this.description,
    required this.date,
    this.isNew = false,
    this.category = UpdateCategory.feature,
  });
}

/// Catégorie de mise à jour
enum UpdateCategory {
  feature,
  improvement,
  bugfix,
  security,
}

extension UpdateCategoryExtension on UpdateCategory {
  String get label {
    switch (this) {
      case UpdateCategory.feature:
        return 'Nouvelle fonctionnalité';
      case UpdateCategory.improvement:
        return 'Amélioration';
      case UpdateCategory.bugfix:
        return 'Correction';
      case UpdateCategory.security:
        return 'Sécurité';
    }
  }

  String get icon {
    switch (this) {
      case UpdateCategory.feature:
        return '✨';
      case UpdateCategory.improvement:
        return '⚡';
      case UpdateCategory.bugfix:
        return '🐛';
      case UpdateCategory.security:
        return '🔒';
    }
  }
}
