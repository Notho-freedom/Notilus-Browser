/// Service de gestion de la documentation
library documentation_service;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:markdown/markdown.dart' as md;

/// Service de documentation
class DocumentationService extends ChangeNotifier {
  final Map<String, String> _cachedDocs = {};
  final List<DocumentationItem> _items = [];
  bool _isInitialized = false;

  List<DocumentationItem> get items => List.unmodifiable(_items);
  bool get isInitialized => _isInitialized;

  /// Initialise le service et charge la documentation
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Utiliser le chemin relatif depuis le répertoire de l'application
      final appDir = Directory.current;
      final docsDir = Directory(path.join(appDir.path, 'docs'));
      if (!await docsDir.exists()) {
        debugPrint('Dossier docs/ non trouvé');
        _isInitialized = true;
        notifyListeners();
        return;
      }

      await _loadDocumentation(docsDir);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement de la documentation: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadDocumentation(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final content = await entity.readAsString();
          final relativePath = path.relative(entity.path, from: dir.path);
          final item = DocumentationItem(
            id: relativePath,
            title: _extractTitle(content) ?? path.basenameWithoutExtension(relativePath),
            content: content,
            path: relativePath,
            category: _getCategory(relativePath),
          );
          _items.add(item);
          _cachedDocs[relativePath] = content;
        } catch (e) {
          debugPrint('Erreur lors du chargement de ${entity.path}: $e');
        }
      }
    }
  }

  String? _extractTitle(String markdown) {
    final lines = markdown.split('\n');
    for (final line in lines) {
      if (line.startsWith('# ')) {
        return line.substring(2).trim();
      }
    }
    return null;
  }

  DocumentationCategory _getCategory(String filePath) {
    if (filePath.startsWith('features/')) {
      return DocumentationCategory.features;
    } else if (filePath.startsWith('guides/')) {
      return DocumentationCategory.guides;
    } else if (filePath.startsWith('api/')) {
      return DocumentationCategory.api;
    }
    return DocumentationCategory.general;
  }

  /// Recherche dans la documentation
  List<DocumentationItem> search(String query) {
    if (query.isEmpty) return _items;

    final lowerQuery = query.toLowerCase();
    return _items.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          item.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Obtient un document par son ID
  DocumentationItem? getDocument(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtient les documents d'une catégorie
  List<DocumentationItem> getDocumentsByCategory(DocumentationCategory category) {
    return _items.where((item) => item.category == category).toList();
  }
}

enum DocumentationCategory {
  general,
  features,
  guides,
  api,
}

class DocumentationItem {
  final String id;
  final String title;
  final String content;
  final String path;
  final DocumentationCategory category;

  DocumentationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.path,
    required this.category,
  });
}

