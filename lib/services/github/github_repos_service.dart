import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../auth/firebase_auth_service.dart';

/// Modèle pour un dépôt GitHub
class GitHubRepo {
  final String id;
  final String name;
  final String fullName;
  final String description;
  final String language;
  final int stars;
  final int forks;
  final bool isPrivate;
  final String? url;
  final DateTime updatedAt;
  final String owner;
  final String? avatarUrl;

  GitHubRepo({
    required this.id,
    required this.name,
    required this.fullName,
    required this.description,
    required this.language,
    required this.stars,
    required this.forks,
    required this.isPrivate,
    this.url,
    required this.updatedAt,
    required this.owner,
    this.avatarUrl,
  });

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    return GitHubRepo(
      id: json['id'].toString(),
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      description: json['description'] as String? ?? '',
      language: json['language'] as String? ?? '',
      stars: json['stargazers_count'] as int? ?? 0,
      forks: json['forks_count'] as int? ?? 0,
      isPrivate: json['private'] as bool? ?? false,
      url: json['html_url'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      owner: json['owner']?['login'] as String? ?? '',
      avatarUrl: json['owner']?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': fullName,
      'description': description,
      'language': language,
      'stargazers_count': stars,
      'forks_count': forks,
      'private': isPrivate,
      'html_url': url,
      'updated_at': updatedAt.toIso8601String(),
      'owner': {
        'login': owner,
        'avatar_url': avatarUrl,
      },
    };
  }
}

/// Service pour récupérer les dépôts GitHub
class GitHubReposService extends ChangeNotifier {
  final FirebaseAuthService _authService;
  List<GitHubRepo> _repos = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  GitHubReposService(this._authService) {
    // Écouter les changements d'authentification
    _authService.addListener(_onAuthChanged);
    _onAuthChanged(); // Vérifier l'état initial
  }

  List<GitHubRepo> get repos => _repos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasRepos => _repos.isNotEmpty;

  void _onAuthChanged() {
    if (_authService.isGitHubSignedIn) {
      // Charger les dépôts si l'utilisateur est connecté via GitHub
      loadRepos();
    } else {
      // Nettoyer les dépôts si l'utilisateur se déconnecte
      _repos = [];
      _error = null;
      _refreshTimer?.cancel();
      notifyListeners();
    }
  }

  /// Charge la liste des dépôts GitHub
  Future<void> loadRepos({bool forceRefresh = false}) async {
    if (!_authService.isGitHubSignedIn) {
      _error = 'Non connecté via GitHub';
      notifyListeners();
      return;
    }

    if (_isLoading && !forceRefresh) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final githubUser = _authService.githubUser;
      if (githubUser == null || githubUser.accessToken.isEmpty) {
        throw Exception('Token GitHub manquant');
      }

      // Récupérer tous les dépôts (publics et privés)
      final List<GitHubRepo> allRepos = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore && page <= 10) { // Limiter à 10 pages (300 repos max)
        final response = await http.get(
          Uri.parse('https://api.github.com/user/repos?per_page=30&page=$page&sort=updated'),
          headers: {
            'Authorization': 'Bearer ${githubUser.accessToken}',
            'Accept': 'application/vnd.github.v3+json',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          
          if (data.isEmpty) {
            hasMore = false;
          } else {
            allRepos.addAll(
              data.map((repo) => GitHubRepo.fromJson(repo as Map<String, dynamic>)),
            );
            page++;
          }
        } else if (response.statusCode == 401) {
          throw Exception('Token GitHub invalide ou expiré');
        } else {
          throw Exception('Erreur API GitHub: ${response.statusCode}');
        }
      }

      _repos = allRepos;
      _isLoading = false;
      _error = null;
      notifyListeners();

      debugPrint('✅ ${_repos.length} dépôts GitHub chargés');
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      debugPrint('❌ Erreur lors du chargement des dépôts GitHub: $e');
      notifyListeners();
    }
  }

  /// Démarre le rafraîchissement automatique des dépôts
  void startAutoRefresh({Duration interval = const Duration(minutes: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      if (_authService.isGitHubSignedIn) {
        loadRepos(forceRefresh: true);
      }
    });
  }

  /// Arrête le rafraîchissement automatique
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}

