import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/github/github_repos_service.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../core/services/color_theme_manager.dart';
// import 'package:url_launcher/url_launcher.dart'; // Plus utilisé - tout est géré dans Notilus
import '../../services/tab_manager.dart';

/// Panneau pour afficher les dépôts GitHub
class GitHubReposPanel extends StatefulWidget {
  const GitHubReposPanel({super.key});

  @override
  State<GitHubReposPanel> createState() => _GitHubReposPanelState();
}

class _GitHubReposPanelState extends State<GitHubReposPanel> {
  String _searchQuery = '';
  String _sortBy = 'updated'; // updated, stars, name
  bool _showPrivateOnly = false;

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final accentColor = colorThemeManager.nativeSecondaryColor;
    final authService = Provider.of<FirebaseAuthService?>(context);
    final reposService = Provider.of<GitHubReposService?>(context);

    // Vérifier si l'utilisateur est connecté via GitHub
    if (authService == null || !authService.isGitHubSignedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 64,
              color: accentColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Connectez-vous avec GitHub pour voir vos dépôts',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (reposService == null) {
      return Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    // Charger les dépôts au premier affichage
    if (!reposService.hasRepos && !reposService.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reposService.loadRepos();
      });
    }

    return Container(
      color: const Color(0xFF0D0D10),
      child: Column(
        children: [
          _buildHeader(accentColor, reposService),
          _buildFilters(accentColor),
          Expanded(
            child: _buildReposList(accentColor, reposService),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accentColor, GitHubReposService reposService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: accentColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.code, color: accentColor, size: 24),
          const SizedBox(width: 12),
          Text(
            'Mes Dépôts GitHub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (reposService.isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
              ),
            )
          else
            IconButton(
              icon: Icon(CupertinoIcons.arrow_clockwise, color: accentColor),
              onPressed: () => reposService.loadRepos(forceRefresh: true),
              tooltip: 'Actualiser',
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(color: accentColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher un dépôt...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(CupertinoIcons.search, color: accentColor.withOpacity(0.7)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: Icon(CupertinoIcons.sort_down, color: accentColor),
            tooltip: 'Trier',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'updated',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.clock, size: 16, color: _sortBy == 'updated' ? accentColor : Colors.white70),
                    const SizedBox(width: 8),
                    const Text('Dernière mise à jour'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stars',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.star, size: 16, color: _sortBy == 'stars' ? accentColor : Colors.white70),
                    const SizedBox(width: 8),
                    const Text('Étoiles'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.textformat, size: 16, color: _sortBy == 'name' ? accentColor : Colors.white70),
                    const SizedBox(width: 8),
                    const Text('Nom'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _showPrivateOnly ? CupertinoIcons.lock_fill : CupertinoIcons.lock_open,
              color: _showPrivateOnly ? accentColor : accentColor.withOpacity(0.5),
            ),
            onPressed: () {
              setState(() {
                _showPrivateOnly = !_showPrivateOnly;
              });
            },
            tooltip: _showPrivateOnly ? 'Afficher tous' : 'Privés uniquement',
          ),
        ],
      ),
    );
  }

  Widget _buildReposList(Color accentColor, GitHubReposService reposService) {
    if (reposService.isLoading && reposService.repos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentColor),
            const SizedBox(height: 16),
            Text(
              'Chargement des dépôts...',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      );
    }

    if (reposService.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur: ${reposService.error}',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => reposService.loadRepos(forceRefresh: true),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Filtrer et trier les dépôts
    var filteredRepos = reposService.repos.where((repo) {
      if (_showPrivateOnly && !repo.isPrivate) return false;
      if (_searchQuery.isNotEmpty) {
        return repo.name.toLowerCase().contains(_searchQuery) ||
               repo.description.toLowerCase().contains(_searchQuery) ||
               repo.language.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    // Trier
    filteredRepos.sort((a, b) {
      switch (_sortBy) {
        case 'stars':
          return b.stars.compareTo(a.stars);
        case 'name':
          return a.name.compareTo(b.name);
        case 'updated':
        default:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    if (filteredRepos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.folder, size: 64, color: accentColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucun dépôt ne correspond à votre recherche'
                  : 'Aucun dépôt trouvé',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRepos.length,
      itemBuilder: (context, index) {
        return _RepoCard(
          repo: filteredRepos[index],
          accentColor: accentColor,
        );
      },
    );
  }
}

class _RepoCard extends StatelessWidget {
  final GitHubRepo repo;
  final Color accentColor;

  const _RepoCard({
    required this.repo,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: repo.url != null
              ? () {
                  // Ouvrir dans un nouvel onglet Notilus au lieu d'un navigateur externe
                  final tabManager = Provider.of<TabManager>(context, listen: false);
                  tabManager.addTab(url: repo.url!);
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (repo.isPrivate)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          CupertinoIcons.lock_fill,
                          size: 16,
                          color: accentColor,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        repo.fullName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (repo.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    repo.description,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (repo.language.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          repo.language,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(CupertinoIcons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      repo.stars.toString(),
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(CupertinoIcons.arrow_branch, size: 14, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      repo.forks.toString(),
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(repo.updatedAt),
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      return 'Il y a ${(difference.inDays / 7).floor()} semaines';
    } else if (difference.inDays < 365) {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    } else {
      return 'Il y a ${(difference.inDays / 365).floor()} ans';
    }
  }
}

