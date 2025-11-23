class UrlValidator {
  /// Valide et formate une URL
  static String? validateAndFormat(String input) {
    if (input.isEmpty) return null;

    // Nettoyer l'input
    final cleaned = input.trim();

    // Si c'est déjà une URL complète
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      try {
        Uri.parse(cleaned);
        return cleaned;
      } catch (e) {
        return null;
      }
    }

    // Si ça ressemble à une URL (contient un point et pas d'espaces)
    if (cleaned.contains('.') && !cleaned.contains(' ')) {
      // Vérifier si c'est un domaine valide
      final parts = cleaned.split('.');
      if (parts.length >= 2) {
        final lastPart = parts.last.toLowerCase();
        final validTlds = [
          'com', 'org', 'net', 'edu', 'gov', 'io', 'co', 'dev',
          'fr', 'uk', 'de', 'jp', 'cn', 'au', 'ca', 'br',
          'tech', 'ai', 'app', 'site', 'online', 'xyz'
        ];
        
        if (validTlds.contains(lastPart) || lastPart.length >= 2) {
          return 'https://$cleaned';
        }
      }
    }

    // Sinon, c'est probablement une recherche
    return null;
  }

  /// Détermine si l'input est une URL ou une recherche
  static bool isUrl(String input) {
    final formatted = validateAndFormat(input);
    return formatted != null && formatted.startsWith('http');
  }

  /// Crée une URL de recherche Google
  static String createSearchUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://www.google.com/search?q=$encoded';
  }

  /// Extrait le domaine d'une URL
  static String? extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si une URL est sécurisée (HTTPS)
  static bool isSecure(String url) {
    return url.startsWith('https://');
  }
}

