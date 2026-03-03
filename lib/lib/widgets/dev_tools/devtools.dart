/// Notilus DevTools - Module d'outils de développement natif
/// 
/// Ce module fournit un ensemble complet d'outils de débogage pour le navigateur Notilus,
/// inspiré des DevTools de Chrome mais entièrement personnalisé et natif à Flutter.
/// 
/// ## Fonctionnalités
/// 
/// - **Console** : Capture des logs JavaScript (log, info, warn, error, debug)
///   avec exécution de code en temps réel
/// 
/// - **Network** : Surveillance des requêtes HTTP (XHR et Fetch) avec détails
///   des headers, body, timing et statut
/// 
/// - **Elements** : Inspection du DOM avec vue arborescente, attributs et
///   styles calculés
/// 
/// - **Performance** : Métriques Web Vitals (FCP, LCP, TTI), timing de page
///   et utilisation mémoire JavaScript
/// 
/// - **Application** : Gestion du storage (localStorage, sessionStorage, cookies)
/// 
/// ## Utilisation
/// 
/// ```dart
/// // Ajouter le provider dans votre app
/// ChangeNotifierProvider(create: (_) => DevToolsService()),
/// 
/// // Utiliser le widget DevTools
/// NotilusDevTools(
///   engine: browserEngine,
///   onClose: () => setState(() => _isDevToolsVisible = false),
/// )
/// ```
/// 
/// ## Raccourcis clavier
/// 
/// - F12 : Ouvrir/fermer DevTools
/// - Ctrl+Shift+J : Console
/// - Ctrl+Shift+E : Network
/// - Ctrl+Shift+C : Elements
/// - Ctrl+Shift+I : DevTools (alternative)
/// - Escape : Fermer DevTools
library devtools;

// Export principal
export 'notilus_devtools.dart';

// Panneaux individuels
export 'devtools_console_panel.dart';
export 'devtools_network_panel.dart';
export 'devtools_elements_panel.dart';
export 'devtools_performance_panel.dart';
export 'devtools_application_panel.dart';
