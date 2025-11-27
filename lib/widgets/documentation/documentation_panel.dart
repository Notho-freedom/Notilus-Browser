/// Panneau de documentation Notilus
/// Système structuré et évolutif pour afficher la documentation Markdown
library documentation_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/animations/notilus_animations.dart';
import '../../services/documentation_service.dart';
import '../../core/constants/notilus_colors.dart';
import '../common/gx_futuristic_widgets.dart';

class DocumentationPanel extends StatefulWidget {
  const DocumentationPanel({super.key});

  @override
  State<DocumentationPanel> createState() => _DocumentationPanelState();
}

class _DocumentationPanelState extends State<DocumentationPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DocumentationItem? _selectedDocument;
  final List<String> _navigationHistory = [];
  DocumentationCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Initialiser le service si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docService = Provider.of<DocumentationService>(context, listen: false);
      if (!docService.isInitialized) {
        docService.initialize();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDocument(DocumentationItem document) {
    setState(() {
      if (_selectedDocument != null) {
        _navigationHistory.add(_selectedDocument!.id);
      }
      _selectedDocument = document;
    });
  }

  void _goBack() {
    if (_navigationHistory.isNotEmpty) {
      final previousId = _navigationHistory.removeLast();
      final docService = Provider.of<DocumentationService>(context, listen: false);
      final doc = docService.getDocument(previousId);
      setState(() {
        _selectedDocument = doc;
      });
    } else {
      setState(() {
        _selectedDocument = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final accentColor = colorThemeManager.nativeSecondaryColor;

    return Consumer<DocumentationService>(
      builder: (context, docService, _) {
        // Si un document est sélectionné, afficher la vue Markdown
        if (_selectedDocument != null) {
          return _buildMarkdownView(_selectedDocument!, accentColor);
        }

        // Sinon, afficher la navigation
        return _buildNavigationView(docService, accentColor);
      },
    );
  }

  Widget _buildNavigationView(DocumentationService docService, Color accentColor) {
    // Filtrer les documents selon la recherche
    List<DocumentationItem> documents = _searchQuery.isEmpty
        ? docService.items
        : docService.search(_searchQuery);

    // Grouper par catégorie
    final Map<DocumentationCategory, List<DocumentationItem>> groupedDocs = {};
    for (final doc in documents) {
      groupedDocs.putIfAbsent(doc.category, () => []).add(doc);
    }

    return Container(
      color: const Color(0xFF0D0D10),
      child: Column(
        children: [
          _buildHeader(accentColor),
          Expanded(
            child: Row(
              children: [
                // Sidebar de navigation
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: accentColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildNavigationSidebar(docService, groupedDocs, accentColor),
                ),
                // Contenu principal
                Expanded(
                  child: _buildContentArea(docService, groupedDocs, accentColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.book, color: accentColor, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Documentation Notilus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Barre de recherche
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _searchQuery.isNotEmpty
                    ? accentColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher dans la documentation...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: Colors.white.withOpacity(0.5),
                  size: 18,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: Colors.white.withOpacity(0.5),
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildNavigationSidebar(
    DocumentationService docService,
    Map<DocumentationCategory, List<DocumentationItem>> groupedDocs,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catégories
          _buildCategorySection(
            'Général',
            CupertinoIcons.doc_text,
            groupedDocs[DocumentationCategory.general] ?? [],
            accentColor,
          ),
          const SizedBox(height: 20),
          _buildCategorySection(
            'Fonctionnalités',
            CupertinoIcons.star_fill,
            groupedDocs[DocumentationCategory.features] ?? [],
            accentColor,
          ),
          const SizedBox(height: 20),
          _buildCategorySection(
            'Guides',
            CupertinoIcons.book_fill,
            groupedDocs[DocumentationCategory.guides] ?? [],
            accentColor,
          ),
          const SizedBox(height: 20),
          _buildCategorySection(
            'API',
            CupertinoIcons.doc_on_doc,
            groupedDocs[DocumentationCategory.api] ?? [],
            accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    String title,
    IconData icon,
    List<DocumentationItem> items,
    Color accentColor,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((doc) => _buildDocumentationItem(doc, accentColor)),
      ],
    );
  }

  Widget _buildDocumentationItem(DocumentationItem doc, Color accentColor) {
    final isSelected = _selectedDocument?.id == doc.id;

    return InkWell(
      onTap: () => _navigateToDocument(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: accentColor.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              _getIconForCategory(doc.category),
              size: 14,
              color: isSelected
                  ? accentColor
                  : Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                doc.title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(DocumentationCategory category) {
    switch (category) {
      case DocumentationCategory.general:
        return CupertinoIcons.doc_text;
      case DocumentationCategory.features:
        return CupertinoIcons.star;
      case DocumentationCategory.guides:
        return CupertinoIcons.book;
      case DocumentationCategory.api:
        return CupertinoIcons.doc_on_doc;
    }
  }

  Widget _buildContentArea(
    DocumentationService docService,
    Map<DocumentationCategory, List<DocumentationItem>> groupedDocs,
    Color accentColor,
  ) {
    if (_searchQuery.isNotEmpty) {
      // Afficher les résultats de recherche
      final results = docService.search(_searchQuery);
      if (results.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.search,
                size: 48,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun résultat trouvé',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez avec d\'autres mots-clés',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.search, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Résultats de recherche (${results.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...results.map((doc) => _buildSearchResultCard(doc, accentColor)),
          ],
        ),
      );
    }

    // Afficher la vue d'ensemble par catégorie
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Général
          if (groupedDocs.containsKey(DocumentationCategory.general))
            _buildCategoryOverview(
              'Général',
              CupertinoIcons.doc_text,
              groupedDocs[DocumentationCategory.general]!,
              accentColor,
            ),
          // Fonctionnalités
          if (groupedDocs.containsKey(DocumentationCategory.features)) ...[
            const SizedBox(height: 32),
            _buildCategoryOverview(
              'Fonctionnalités',
              CupertinoIcons.star_fill,
              groupedDocs[DocumentationCategory.features]!,
              accentColor,
            ),
          ],
          // Guides
          if (groupedDocs.containsKey(DocumentationCategory.guides)) ...[
            const SizedBox(height: 32),
            _buildCategoryOverview(
              'Guides',
              CupertinoIcons.book_fill,
              groupedDocs[DocumentationCategory.guides]!,
              accentColor,
            ),
          ],
          // API
          if (groupedDocs.containsKey(DocumentationCategory.api)) ...[
            const SizedBox(height: 32),
            _buildCategoryOverview(
              'API',
              CupertinoIcons.doc_on_doc,
              groupedDocs[DocumentationCategory.api]!,
              accentColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryOverview(
    String title,
    IconData icon,
    List<DocumentationItem> items,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((doc) => _buildDocumentCard(doc, accentColor)).toList(),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(DocumentationItem doc, Color accentColor) {
    return InkWell(
      onTap: () => _navigateToDocument(doc),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForCategory(doc.category),
                  color: accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doc.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              doc.path,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Lire →',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(DocumentationItem doc, Color accentColor) {
    return InkWell(
      onTap: () => _navigateToDocument(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIconForCategory(doc.category),
              color: accentColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc.path,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: accentColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownView(DocumentationItem document, Color accentColor) {
    return Container(
      color: const Color(0xFF0D0D10),
      child: Column(
        children: [
          // Header avec navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.15),
                  accentColor.withOpacity(0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(CupertinoIcons.chevron_left, color: accentColor),
                  onPressed: _goBack,
                  tooltip: 'Retour',
                ),
                const SizedBox(width: 12),
                Icon(
                  _getIconForCategory(document.category),
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        document.path,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                IconButton(
                  icon: Icon(CupertinoIcons.share, color: accentColor),
                  onPressed: () {
                    // TODO: Implémenter le partage
                  },
                  tooltip: 'Partager',
                ),
              ],
            ),
          ),
          // Contenu Markdown
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: MarkdownBody(
                data: document.content,
                styleSheet: _buildMarkdownStyleSheet(accentColor),
                onTapLink: (text, href, title) {
                  // Gérer les liens internes
                  if (href != null && href.startsWith('#')) {
                    // Scroll vers l'ancre
                  } else if (href != null && !href.startsWith('http')) {
                    // Lien relatif - charger le document
                    final docService = Provider.of<DocumentationService>(context, listen: false);
                    final linkedDoc = docService.getDocument(href);
                    if (linkedDoc != null) {
                      _navigateToDocument(linkedDoc);
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(Color accentColor) {
    return MarkdownStyleSheet(
      h1: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      h2: TextStyle(
        color: accentColor,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      h3: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      h4: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      p: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 14,
        height: 1.6,
      ),
      a: TextStyle(
        color: accentColor,
        decoration: TextDecoration.underline,
      ),
      code: TextStyle(
        color: accentColor,
        backgroundColor: Colors.white.withOpacity(0.05),
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
        ),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquote: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: 4,
          ),
        ),
      ),
      listBullet: TextStyle(
        color: accentColor,
      ),
      tableHead: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      tableBody: TextStyle(
        color: Colors.white.withOpacity(0.9),
      ),
      tableHeadAlign: TextAlign.center,
      tableBorder: TableBorder(
        top: BorderSide(color: accentColor.withOpacity(0.3)),
        bottom: BorderSide(color: accentColor.withOpacity(0.3)),
        left: BorderSide(color: accentColor.withOpacity(0.3)),
        right: BorderSide(color: accentColor.withOpacity(0.3)),
        horizontalInside: BorderSide(color: accentColor.withOpacity(0.2)),
        verticalInside: BorderSide(color: accentColor.withOpacity(0.2)),
      ),
    );
  }
}
