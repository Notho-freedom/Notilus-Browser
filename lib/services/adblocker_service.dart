import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de blocage de publicités pour Notilus
/// Implémente un système de filtrage basé sur EasyList et des patterns personnalisés
class AdBlockerService extends ChangeNotifier {
  static const String _prefsKey = 'adblocker_enabled';
  static const String _prefsBlockedCount = 'adblocker_blocked_count';
  
  bool _isEnabled = true;
  int _blockedCount = 0;
  
  // Listes de domaines et patterns à bloquer
  final Set<String> _blockedDomains = {};
  final List<RegExp> _blockedPatterns = [];
  
  // Patterns de base (domaines publicitaires connus)
  static const List<String> _baseBlockedDomains = [
    'doubleclick.net',
    'googleadservices.com',
    'googlesyndication.com',
    'google-analytics.com',
    'facebook.com/tr',
    'facebook.net',
    'amazon-adsystem.com',
    'advertising.com',
    'adnxs.com',
    'adsrvr.org',
    'adtechus.com',
    'criteo.com',
    'outbrain.com',
    'taboola.com',
    'scorecardresearch.com',
    'quantserve.com',
    'moatads.com',
    'adsafeprotected.com',
    'advertising.com',
    'adform.net',
    'adition.com',
    'adriver.ru',
    'adroll.com',
    'adsystem.com',
    'advertising.com',
  ];
  
  // Patterns regex pour bloquer les URLs
  static const List<String> _baseBlockedPatterns = [
    r'/ads?/',
    r'/advertising/',
    r'/banner',
    r'/popup',
    r'/tracking',
    r'/analytics',
    r'/pixel',
    r'/beacon',
    r'\.ads\.',
    r'\.ad\.',
    r'/adserver',
    r'/advert',
    r'/promo',
    r'/sponsor',
  ];

  AdBlockerService() {
    _loadSettings();
    _initializeBlockLists();
  }

  bool get isEnabled => _isEnabled;
  int get blockedCount => _blockedCount;
  
  /// Active ou désactive le bloqueur
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _saveSettings();
    notifyListeners();
  }

  /// Vérifie si une URL doit être bloquée
  bool shouldBlockUrl(String url) {
    if (!_isEnabled) return false;
    
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();
      
      // Vérifier les domaines bloqués
      for (final domain in _blockedDomains) {
        if (host.contains(domain.toLowerCase())) {
          _incrementBlockedCount();
          return true;
        }
      }
      
      // Vérifier les patterns
      for (final pattern in _blockedPatterns) {
        if (pattern.hasMatch(url) || pattern.hasMatch(path)) {
          _incrementBlockedCount();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'URL: $e');
      return false;
    }
  }

  /// Initialise les listes de blocage
  void _initializeBlockLists() {
    _blockedDomains.addAll(_baseBlockedDomains);
    
    for (final pattern in _baseBlockedPatterns) {
      try {
        _blockedPatterns.add(RegExp(pattern, caseSensitive: false));
      } catch (e) {
        debugPrint('Pattern invalide: $pattern');
      }
    }
  }

  /// Charge les paramètres depuis SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefsKey) ?? true;
      _blockedCount = prefs.getInt(_prefsBlockedCount) ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres: $e');
    }
  }

  /// Sauvegarde les paramètres
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isEnabled);
      await prefs.setInt(_prefsBlockedCount, _blockedCount);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des paramètres: $e');
    }
  }

  /// Incrémente le compteur de requêtes bloquées
  void _incrementBlockedCount() {
    _blockedCount++;
    _saveSettings();
    notifyListeners();
  }

  /// Met à jour le compteur depuis une valeur externe (ex: JavaScript)
  void updateBlockedCount(int newCount) {
    if (newCount > _blockedCount) {
      _blockedCount = newCount;
      _saveSettings();
      notifyListeners();
    }
  }

  /// Ajoute un nombre de blocages au compteur
  void addBlockedCount(int count) {
    if (count > 0) {
      _blockedCount += count;
      _saveSettings();
      notifyListeners();
    }
  }

  /// Réinitialise le compteur
  Future<void> resetBlockedCount() async {
    _blockedCount = 0;
    await _saveSettings();
    notifyListeners();
  }

  /// Génère le script JavaScript pour bloquer les pubs côté client
  String generateBlockingScript() {
    if (!_isEnabled) return '';
    
    final domainsList = _blockedDomains.map((d) => '"$d"').join(',');
    
    return '''
(function() {
  if (window._notilusAdBlockerInstalled) return;
  window._notilusAdBlockerInstalled = true;
  
  const blockedDomains = [$domainsList];
  let blockedCount = 0;
  
  // Fonction pour notifier le blocage (sera appelée par Flutter)
  window._notilusAdBlocked = function(url) {
    blockedCount++;
    window._notilusAdBlockerPageCount = blockedCount;
    console.log('%c[Notilus AdBlocker] 🛡️ Bloqué #' + blockedCount + ':', 'color: #FF0040; font-weight: bold;', url);
    // Stocker le compteur pour récupération par Flutter
    if (document.body) {
      document.body.setAttribute('data-adblock-count', blockedCount.toString());
    }
  };
  
  // Bloquer les requêtes fetch
  const originalFetch = window.fetch;
  window.fetch = function(...args) {
    const url = args[0];
    if (typeof url === 'string' && shouldBlock(url)) {
      window._notilusAdBlocked(url);
      return Promise.reject(new Error('Blocked by Notilus AdBlocker'));
    }
    return originalFetch.apply(this, args);
  };
  
  // Bloquer les requêtes XMLHttpRequest
  const originalOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url, ...rest) {
    if (shouldBlock(url)) {
      window._notilusAdBlocked(url);
      return;
    }
    return originalOpen.apply(this, [method, url, ...rest]);
  };
  
  // Bloquer les images publicitaires
  const originalImage = Image;
  window.Image = function(...args) {
    const img = new originalImage(...args);
    const originalSrcSetter = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, 'src').set;
    Object.defineProperty(img, 'src', {
      set: function(value) {
        if (shouldBlock(value)) {
          window._notilusAdBlocked(value);
          return;
        }
        originalSrcSetter.call(this, value);
      },
      get: function() {
        return this.getAttribute('src') || '';
      }
    });
    return img;
  };
  
  // Fonction de vérification
  function shouldBlock(url) {
    if (!url || typeof url !== 'string') return false;
    const lowerUrl = url.toLowerCase();
    
    // Vérifier les domaines bloqués
    for (const domain of blockedDomains) {
      if (lowerUrl.includes(domain.toLowerCase())) {
        return true;
      }
    }
    
    // Vérifier les patterns
    const patterns = [
      /\\/ads?\\//i,
      /\\/advertising\\//i,
      /\\/banner/i,
      /\\.ads\\./i,
      /\\.ad\\./i,
      /\\/adserver/i,
      /\\/advert/i,
      /\\/promo/i,
      /\\/sponsor/i,
      /doubleclick/i,
      /googlesyndication/i,
      /googleadservices/i,
    ];
    
    for (const pattern of patterns) {
      if (pattern.test(lowerUrl)) {
        return true;
      }
    }
    
    return false;
  }
  
  // Nettoyer le DOM des éléments publicitaires
  function cleanDOM() {
    const adSelectors = [
      '[id*="ad"]',
      '[class*="ad"]',
      '[id*="advertisement"]',
      '[class*="advertisement"]',
      '[id*="banner"]',
      '[class*="banner"]',
      'iframe[src*="ads"]',
      'iframe[src*="advertising"]',
      'iframe[src*="doubleclick"]',
      'iframe[src*="googlesyndication"]',
      '[data-ad]',
      '[data-ad-unit]',
      '[data-ad-slot]',
    ];
    
    let removedCount = 0;
    adSelectors.forEach(selector => {
      try {
        document.querySelectorAll(selector).forEach(el => {
          const src = el.src || el.href || el.getAttribute('data-src') || '';
          if (shouldBlock(src) || selector.includes('iframe')) {
            el.remove();
            removedCount++;
            window._notilusAdBlocked(src || selector);
          }
        });
      } catch(e) {}
    });
    
    if (removedCount > 0) {
      console.log('%c[Notilus AdBlocker] 🧹 Nettoyé ' + removedCount + ' élément(s) publicitaire(s)', 'color: #00FF88; font-weight: bold;');
    }
  }
  
  // Observer les mutations pour nettoyer les nouveaux éléments
  const observer = new MutationObserver(() => {
    cleanDOM();
  });
  
  observer.observe(document.body || document.documentElement, {
    childList: true,
    subtree: true
  });
  
  // Nettoyer immédiatement
  if (document.body) {
    cleanDOM();
  } else {
    document.addEventListener('DOMContentLoaded', cleanDOM);
  }
  
  // Nettoyer périodiquement (pour les pubs chargées dynamiquement)
  setInterval(cleanDOM, 2000);
  
  console.log('%c[Notilus AdBlocker] 🛡️ Activé - Protection active', 'color: #00FF88; font-weight: bold; font-size: 14px;');
})();
''';
  }
}

