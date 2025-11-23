import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/utils/url_validator.dart';

class FaviconService {
  static const String _defaultFaviconPath = 'assets/icons/default_favicon.png';
  
  /// Récupère le favicon d'une URL
  /// Essaie plusieurs méthodes : Google Favicon Service, favicon.ico, ou meta tags
  static Future<String?> getFaviconUrl(String url) async {
    try {
      final domain = UrlValidator.extractDomain(url);
      if (domain == null) return null;

      // Méthode 1: Google Favicon Service (le plus fiable)
      final googleFaviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
      
      // Vérifier si le favicon existe
      final response = await http.head(Uri.parse(googleFaviconUrl));
      if (response.statusCode == 200) {
        return googleFaviconUrl;
      }

      // Méthode 2: Essayer favicon.ico à la racine
      final faviconIcoUrl = 'https://$domain/favicon.ico';
      final icoResponse = await http.head(Uri.parse(faviconIcoUrl));
      if (icoResponse.statusCode == 200) {
        return faviconIcoUrl;
      }

      // Méthode 3: Essayer /favicon.png
      final faviconPngUrl = 'https://$domain/favicon.png';
      final pngResponse = await http.head(Uri.parse(faviconPngUrl));
      if (pngResponse.statusCode == 200) {
        return faviconPngUrl;
      }

      // Retourner le Google Favicon Service par défaut (fonctionne même si pas vérifié)
      return googleFaviconUrl;
    } catch (e) {
      debugPrint('Error fetching favicon: $e');
      return null;
    }
  }

  /// Récupère le favicon depuis les meta tags HTML
  /// Nécessite de parser le HTML (sera implémenté avec CEF)
  static Future<String?> getFaviconFromHtml(String html, String baseUrl) async {
    // TODO: Parser HTML pour trouver <link rel="icon"> ou <link rel="shortcut icon">
    // Pour l'instant, retourner null
    return null;
  }

  /// Cache le favicon localement
  static Future<String?> cacheFavicon(String url, String faviconUrl) async {
    try {
      final response = await http.get(Uri.parse(faviconUrl));
      if (response.statusCode == 200) {
        // TODO: Sauvegarder le favicon dans le cache local
        // Pour l'instant, retourner l'URL
        return faviconUrl;
      }
    } catch (e) {
      debugPrint('Error caching favicon: $e');
    }
    return null;
  }

  /// Récupère le favicon avec cache
  static Future<String?> getFaviconWithCache(String url) async {
    // TODO: Vérifier le cache local d'abord
    // Si pas dans le cache, récupérer et mettre en cache
    return await getFaviconUrl(url);
  }
}

