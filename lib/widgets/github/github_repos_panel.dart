/// Panel GitHub Notilus GX - Style futuriste avec navigation dans les dépôts
library github_repos_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/github/github_repos_service.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/settings_service.dart';
import '../common/hack_loading_indicator.dart';

// Helper pour créer un TextStyle avec JetBrains Mono
TextStyle _jetbrainsMono({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: fontSize ?? 12,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing,
  );
}

/// Panneau GitHub avec style GX futuriste
class GitHubReposPanel extends StatefulWidget {
  const GitHubReposPanel({super.key});

  @override
  State<GitHubReposPanel> createState() => _GitHubReposPanelState();
}

class _GitHubReposPanelState extends State<GitHubReposPanel> {
  String _searchQuery = '';
  String _sortBy = 'updated';
  bool _showPrivateOnly = false;
  
  // Navigation
  GitHubRepo? _selectedRepo;
  List<String> _pathStack = []; // Chemin actuel dans le dépôt
  List<GitHubContentItem> _currentContents = [];
  bool _isLoadingContents = false;
  String? _contentsError;

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final accentColor = colorThemeManager.nativeSecondaryColor;
    final authService = Provider.of<FirebaseAuthService?>(context);
    final reposService = Provider.of<GitHubReposService?>(context);

    if (authService == null || !authService.isGitHubSignedIn) {
      return _buildNotConnectedState(accentColor);
    }

    if (reposService == null) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    // Charger les dépôts au premier affichage
    if (!reposService.hasRepos && !reposService.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reposService.loadRepos();
      });
    }

    return Container(
      color: const Color(0xFF0B0B0E),
      child: Column(
        children: [
          _buildHeader(accentColor, reposService),
          _buildFilters(accentColor),
          if (_selectedRepo != null) _buildBreadcrumb(accentColor),
          Expanded(
            child: _selectedRepo == null
                ? _buildReposList(accentColor, reposService)
                : _buildContentsList(accentColor, reposService),
          ),
        ],
      ),
    );
  }

  Widget _buildNotConnectedState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chevron_left_slash_chevron_right,
            size: 64,
            color: accentColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Connectez-vous avec GitHub',
            style: NotilusFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accentColor, GitHubReposService reposService) {
    final settings = SettingsService();
    final transparency = settings.panelTransparency;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - transparency * 0.5).clamp(0.0, 1.0)),
        border: Border(
          bottom: BorderSide(color: accentColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              border: Border.all(color: accentColor.withOpacity(0.4), width: 1),
            ),
            child: Icon(
              CupertinoIcons.chevron_left_slash_chevron_right,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _selectedRepo == null ? 'GITHUB REPOSITORIES' : _selectedRepo!.name.toUpperCase(),
            style: _jetbrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 2,
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
              onPressed: () {
                if (_selectedRepo == null) {
                  reposService.loadRepos(forceRefresh: true);
                } else {
                  _loadContents();
                }
              },
              tooltip: 'Actualiser',
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(Color accentColor) {
    final settings = SettingsService();
    final transparency = settings.panelTransparency;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - transparency * 0.3).clamp(0.0, 1.0)),
        border: Border(
          bottom: BorderSide(color: accentColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: _jetbrainsMono(
                  color: Colors.white,
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: _jetbrainsMono(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(CupertinoIcons.search, color: accentColor.withOpacity(0.7), size: 16),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  fillColor: Colors.transparent,
                  filled: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: Icon(CupertinoIcons.sort_down, color: accentColor, size: 18),
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
                    Icon(CupertinoIcons.clock, size: 14, color: _sortBy == 'updated' ? accentColor : Colors.white70),
                    const SizedBox(width: 8),
                    const Text('Dernière mise à jour', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'stars',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.star, size: 14, color: _sortBy == 'stars' ? accentColor : Colors.white70),
                    const SizedBox(width: 8),
                    const Text('Étoiles', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.textformat, size: 14, color: _sortBy == 'name' ? accentColor : Colors.white70),
                    const SizedBox(width: 8),
                    const Text('Nom', style: TextStyle(fontSize: 12)),
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
              size: 18,
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

  Widget _buildBreadcrumb(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(color: accentColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(CupertinoIcons.chevron_left, color: accentColor, size: 18),
            onPressed: () {
              if (_pathStack.isEmpty) {
                setState(() {
                  _selectedRepo = null;
                  _currentContents = [];
                });
              } else {
                _pathStack.removeLast();
                _loadContents();
              }
            },
            tooltip: 'Retour',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRepo = null;
                        _pathStack = [];
                        _currentContents = [];
                      });
                    },
                    child: Text(
                      _selectedRepo!.name,
                      style: _jetbrainsMono(
                        fontSize: 11,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_pathStack.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(CupertinoIcons.chevron_right, size: 12, color: accentColor.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text(
                      _pathStack.join(' / '),
                      style: _jetbrainsMono(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReposList(Color accentColor, GitHubReposService reposService) {
    if (reposService.isLoading && reposService.repos.isEmpty) {
      return Center(
        child: HackLoadingIndicator(
          accentColor: accentColor,
          message: 'Chargement des dépôts...',
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
              style: NotilusFonts.rajdhani(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
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
          index: index,
          onTap: () {
            setState(() {
              _selectedRepo = filteredRepos[index];
              _pathStack = [];
              _currentContents = [];
            });
            _loadContents();
          },
        );
      },
    );
  }

  Widget _buildContentsList(Color accentColor, GitHubReposService reposService) {
    if (_isLoadingContents) {
      return Center(
        child: HackLoadingIndicator(
          accentColor: accentColor,
          message: 'Chargement du contenu...',
        ),
      );
    }

    if (_contentsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur: $_contentsError',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadContents(),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_currentContents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.folder, size: 64, color: accentColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Dossier vide',
              style: NotilusFonts.rajdhani(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Séparer les dossiers et les fichiers
    final directories = _currentContents.where((item) => item.isDirectory).toList();
    final files = _currentContents.where((item) => item.isFile).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: directories.length + files.length,
      itemBuilder: (context, index) {
        if (index < directories.length) {
          return _ContentItemCard(
            item: directories[index],
            accentColor: accentColor,
            onTap: () {
              _pathStack.add(directories[index].name);
              _loadContents();
            },
          );
        } else {
          final fileIndex = index - directories.length;
          return _ContentItemCard(
            item: files[fileIndex],
            accentColor: accentColor,
            onTap: () {
              // TODO: Gérer les actions sur les fichiers
            },
          );
        }
      },
    );
  }

  Future<void> _loadContents() async {
    if (_selectedRepo == null) return;

    setState(() {
      _isLoadingContents = true;
      _contentsError = null;
    });

    try {
      final reposService = Provider.of<GitHubReposService>(context, listen: false);
      final path = _pathStack.isEmpty ? null : _pathStack.join('/');
      final contents = await reposService.getRepositoryContents(
        _selectedRepo!.owner,
        _selectedRepo!.name,
        path: path,
      );

      setState(() {
        _currentContents = contents;
        _isLoadingContents = false;
      });
    } catch (e) {
      setState(() {
        _contentsError = e.toString();
        _isLoadingContents = false;
      });
    }
  }
}

class _RepoCard extends StatelessWidget {
  final GitHubRepo repo;
  final Color accentColor;
  final int index;
  final VoidCallback onTap;

  const _RepoCard({
    required this.repo,
    required this.accentColor,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    final transparency = settings.panelTransparency;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - transparency * 0.5).clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
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
                          size: 14,
                          color: accentColor,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        repo.fullName,
                        style: _jetbrainsMono(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: accentColor.withOpacity(0.5),
                    ),
                  ],
                ),
                if (repo.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    repo.description,
                    style: NotilusFonts.rajdhani(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (repo.language.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: accentColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          repo.language,
                          style: _jetbrainsMono(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          repo.stars.toString(),
                          style: _jetbrainsMono(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.arrow_branch, size: 12, color: Colors.white.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          repo.forks.toString(),
                          style: _jetbrainsMono(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms);
  }
}

class _ContentItemCard extends StatelessWidget {
  final GitHubContentItem item;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ContentItemCard({
    required this.item,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    final transparency = settings.panelTransparency;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity((1 - transparency * 0.5).clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withOpacity(0.15), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  item.isDirectory ? CupertinoIcons.folder_fill : CupertinoIcons.doc_text,
                  size: 18,
                  color: item.isDirectory ? accentColor : Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: _jetbrainsMono(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.size != null && item.size! > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatSize(item.size!),
                    style: _jetbrainsMono(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
                if (item.isDirectory) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: accentColor.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
