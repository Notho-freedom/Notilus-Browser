# 📚 Notilus Browser - Documentation Développeur

> **Version 3.0.0** | Navigateur conçu par et pour les développeurs
> 
> Dernière mise à jour : Novembre 2025

---

## 📋 Table des matières

1. [Introduction](#-introduction)
2. [Installation & Lancement](#-installation--lancement)
3. [Interface Utilisateur](#-interface-utilisateur)
4. [DevTools Notilus](#-devtools-notilus)
5. [Commandes Console REPL](#-commandes-console-repl)
6. [Raccourcis Clavier](#-raccourcis-clavier)
7. [Architecture Technique](#-architecture-technique)
8. [API & Services](#-api--services)
9. [Configuration](#-configuration)
10. [Changelog](#-changelog)

---

## 🚀 Introduction

**Notilus Browser** est un navigateur web moderne construit avec Flutter, spécialement conçu pour les développeurs. Il intègre des outils de développement avancés directement dans l'interface, sans avoir besoin d'extensions externes.

### Caractéristiques principales

- 🔧 **DevTools intégrés** - Console, Network, Performance, Security Audit
- 📊 **Métriques temps réel** - FPS, mémoire, CPU, widgets Flutter
- 🔒 **Audit de sécurité automatique** - Détection des vulnérabilités
- 📹 **Session Recording** - Enregistrez et rejouez vos sessions
- 🌳 **Widget Inspector** - Inspectez l'arbre Flutter en temps réel
- 🖥️ **Terminal intégré** - PowerShell/Bash directement dans le navigateur
- 🎨 **Thèmes personnalisables** - Couleurs d'accent configurables

---

## 💻 Installation & Lancement

### Prérequis

```bash
# Flutter SDK 3.x+
flutter --version

# Windows: Visual Studio 2022 avec C++ workload
# WebView2 Runtime (inclus dans Windows 11)
```

### Lancement

```bash
# Mode développement
flutter run -d windows --hot

# Build release
flutter build windows --release
```

---

## 🎨 Interface Utilisateur

### Sidebar (Barre latérale)

| Icône | Section | Description |
|-------|---------|-------------|
| 🏠 | Accueil | Page d'accueil avec raccourcis |
| 🔖 | Favoris | Gestionnaire de bookmarks |
| 🕐 | Historique | Historique de navigation |
| ⬇️ | Téléchargements | Gestionnaire de downloads |
| 📦 | Widgets | Widgets système dynamiques |
| ✨ | AI | Assistant Hyper AI |
| ⚙️ | Paramètres | Configuration rapide |
| 📟 | Terminal | Terminal intégré |
| 🔧 | DevTools | Outils de développement |
| 🐜 | DevTools Natif | Chrome DevTools (F12) |
| 📖 | Documentation | Cette documentation |

### Barre d'onglets

- **Glisser-déposer** pour réorganiser
- **Clic molette** pour fermer
- **Double-clic** pour renommer
- **Groupes d'onglets** avec couleurs

### Barre d'adresse

- **Autocomplétion** intelligente
- **Suggestions** de recherche
- **Indicateurs** de sécurité (HTTPS, certificat)
- **Actions rapides** (reload, favoris, partage)

---

## 🔧 DevTools Notilus

Les DevTools Notilus sont des outils de développement **natifs Flutter**, pas un wrapper des DevTools Chrome. Ils offrent des insights uniques sur votre application.

### Console (Onglet 1)

```
📋 Fonctionnalités:
- Logs Flutter (debugPrint, print)
- Logs WebView (console.log, console.error)
- Filtres par niveau: INFO, WARN, ERROR, DEBUG, SUCCESS, SYSTEM
- Recherche textuelle
- Export des logs
- REPL interactif
```

**Niveaux de log:**
| Niveau | Couleur | Usage |
|--------|---------|-------|
| INFO | 🔵 Bleu | Information générale |
| WARN | 🟠 Orange | Avertissements |
| ERROR | 🔴 Rouge | Erreurs |
| DEBUG | 🟢 Vert | Debug uniquement |
| SUCCESS | 🟢 Vert vif | Opérations réussies |
| SYSTEM | 🟣 Violet | Messages système |

### Network (Onglet 2)

```
🌐 Fonctionnalités:
- Interception requêtes Flutter (http package)
- Interception requêtes WebView (fetch, XMLHttpRequest)
- Headers request/response
- Body request/response
- Timing détaillé
- Filtres par méthode, status, URL
- Audit de sécurité automatique
```

**Indicateurs de status:**
| Code | Couleur | Signification |
|------|---------|---------------|
| 2xx | 🟢 Vert | Succès |
| 3xx | 🔵 Bleu | Redirection |
| 4xx | 🟠 Orange | Erreur client |
| 5xx | 🔴 Rouge | Erreur serveur |

### Performance (Onglet 3)

```
📊 Métriques temps réel:
- FPS (frames par seconde) - via SchedulerBinding
- Mémoire utilisée (MB) - via ProcessInfo.currentRss
- CPU estimé (%) - basé sur frame time
- Render time (ms) - temps de rendu par frame
- Widgets actifs - comptage arbre Flutter
- GC count - détection garbage collection
```

**Graphiques:**
- Timeline FPS (60 dernières secondes)
- Timeline Mémoire
- Indicateur 60 FPS target

### Alerts (Onglet 4) 🆕

```
🔔 Smart Monitoring:
- Alerte chute FPS (< 30 FPS par défaut)
- Alerte mémoire élevée (> 500 MB)
- Alerte requêtes lentes (> 3000 ms)
- Alerte rafale d'erreurs (5+ en 60s)
- Suggestions de correction
- Configuration des seuils
```

**Sévérités:**
| Niveau | Icône | Action |
|--------|-------|--------|
| INFO | ℹ️ | Information |
| WARNING | ⚠️ | Attention requise |
| CRITICAL | 🚨 | Action immédiate |

### Security (Onglet 5) 🆕

```
🔒 Audit automatique:
- Détection connexions HTTP (non HTTPS)
- Clés API exposées dans URLs
- Données sensibles dans réponses
- Score de sécurité 0-100
- Recommandations de correction
```

**Types de problèmes:**
| Type | Sévérité | Description |
|------|----------|-------------|
| NO_HTTPS | Warning | Connexion non chiffrée |
| EXPOSED_API_KEY | Critical | Token visible dans URL |
| SENSITIVE_DATA | Warning | Données sensibles exposées |
| MIXED_CONTENT | Warning | HTTP dans page HTTPS |

### Widgets (Onglet 6) 🆕

```
🌳 Widget Tree Inspector:
- Capture arbre Flutter complet
- Hiérarchie navigable
- Propriétés des widgets
- Bounds de rendu (x, y, width, height)
- Couleurs par type de widget
- Comptage enfants
```

**Navigation:**
- Clic pour sélectionner
- Chevron pour expand/collapse
- Panneau propriétés à droite

### Analytics (Onglet 7) 🆕

```
📈 Statistiques avancées:
- Stats par onglet (requêtes, données, erreurs)
- Session Recording (enregistrer/rejouer)
- Bookmarks annotés
- Export rapport JSON complet
- Durée de session
- Taux de succès global
```

**Session Recording:**
```
record start [name]  - Démarrer l'enregistrement
record stop          - Arrêter l'enregistrement
sessions             - Lister les sessions
```

### Storage (Onglet 8)

```
💾 Gestion SharedPreferences:
- Liste des clés/valeurs
- Types: String, int, double, bool, List<String>
- Modification en place
- Suppression
- Export
```

---

## 💻 Commandes Console REPL

Le REPL (Read-Eval-Print Loop) permet d'exécuter des commandes directement dans la console DevTools.

### Commandes de base

```bash
help              # Affiche l'aide complète
clear             # Vide la console
logs              # Nombre de logs
echo <message>    # Affiche un message
version           # Version DevTools
```

### Commandes réseau

```bash
requests          # Nombre de requêtes
fetch <url>       # Effectue une requête GET
```

### Commandes performance

```bash
perf              # Métriques actuelles
widgets           # Capture l'arbre des widgets
```

### Commandes analytics 🆕

```bash
analytics         # Statistiques globales
alerts            # Liste des alertes actives
security          # Problèmes de sécurité
```

### Commandes session 🆕

```bash
record            # Toggle enregistrement
record start      # Démarrer avec nom auto
record start Test # Démarrer avec nom "Test"
record stop       # Arrêter l'enregistrement
sessions          # Lister les sessions
```

### Commandes storage

```bash
storage           # Nombre d'entrées
get <key>         # Lire une valeur
set <key> <value> # Définir une valeur (String)
del <key>         # Supprimer une clé
```

### Commandes utilitaires

```bash
bookmark <titre>  # Ajouter un bookmark
export            # Générer rapport JSON
monitor on        # Activer Smart Monitor
monitor off       # Désactiver Smart Monitor
env               # Informations environnement
time              # Heure actuelle ISO
json <string>     # Formater du JSON
```

---

## ⌨️ Raccourcis Clavier

### Navigation

| Raccourci | Action |
|-----------|--------|
| `Ctrl+T` | Nouvel onglet |
| `Ctrl+W` | Fermer l'onglet actif |
| `Ctrl+Tab` | Onglet suivant |
| `Ctrl+Shift+Tab` | Onglet précédent |
| `Ctrl+1-9` | Aller à l'onglet N |
| `Alt+←` | Page précédente |
| `Alt+→` | Page suivante |
| `Ctrl+R` ou `F5` | Recharger |
| `Ctrl+Shift+R` | Recharger (ignorer cache) |

### DevTools

| Raccourci | Action |
|-----------|--------|
| `F12` | Toggle DevTools Notilus |
| `Ctrl+Shift+I` | Toggle DevTools Notilus |
| `Ctrl+Shift+C` | Inspecter élément |
| `Ctrl+Shift+J` | Ouvrir Console |

### Édition

| Raccourci | Action |
|-----------|--------|
| `Ctrl+L` | Focus barre d'adresse |
| `Ctrl+K` | Recherche rapide |
| `Ctrl+D` | Ajouter aux favoris |
| `Ctrl+Shift+B` | Toggle barre favoris |

### Système

| Raccourci | Action |
|-----------|--------|
| `F11` | Plein écran |
| `Ctrl+Shift+Delete` | Effacer données navigation |
| `Ctrl+H` | Historique |
| `Ctrl+J` | Téléchargements |

---

## 🏗️ Architecture Technique

### Stack technologique

```
┌─────────────────────────────────────────┐
│              Notilus Browser            │
├─────────────────────────────────────────┤
│  UI Layer (Flutter Widgets)             │
│  - GXSidebar, GXTabBar, GXAddressBar   │
│  - DevTools Panels                      │
├─────────────────────────────────────────┤
│  Service Layer                          │
│  - TabManager, TabWebViewManager       │
│  - NotilusDevToolsService              │
│  - DownloadService, TerminalService    │
├─────────────────────────────────────────┤
│  Engine Layer                           │
│  - WebView2BrowserEngine (Windows)     │
│  - JavaScript Bridge                    │
├─────────────────────────────────────────┤
│  Platform Layer                         │
│  - webview_windows (WebView2)          │
│  - window_manager                       │
│  - shared_preferences                   │
└─────────────────────────────────────────┘
```

### Structure des fichiers

```
lib/
├── core/
│   ├── constants/      # Couleurs, dimensions
│   ├── services/       # ColorThemeManager, WallpaperManager
│   ├── theme/          # ModernTheme, DarkTheme
│   └── utils/          # Extensions, helpers
├── models/
│   ├── tab_model.dart
│   └── devtools_models.dart
├── services/
│   ├── tab_manager.dart
│   ├── tab_webview_manager.dart
│   ├── notilus_devtools_service.dart
│   ├── browser_engine.dart
│   └── webview2_browser_engine.dart
├── widgets/
│   ├── browser/        # UI principale
│   ├── dev_tools/      # Onglets DevTools
│   ├── terminal/       # Terminal intégré
│   └── common/         # Composants réutilisables
└── main.dart
```

### Services principaux

#### TabManager
Gestion des onglets (création, fermeture, réorganisation).

#### TabWebViewManager
Association onglets ↔ moteurs WebView avec cache intelligent.

#### NotilusDevToolsService
Service singleton pour tous les DevTools:
- Logging (console)
- Network interception
- Performance monitoring
- Smart alerts
- Security audit
- Session recording
- Analytics

#### BrowserEngine
Interface abstraite pour le moteur de rendu, implémentée par:
- `WebView2BrowserEngine` (Windows - production)
- `PlaceholderBrowserEngine` (fallback)

---

## 🔌 API & Services

### Injection WebView

Le DevTools injecte automatiquement du JavaScript dans chaque WebView pour capturer:

```javascript
// Console interception
console.log/warn/error/info/debug → DevTools Console

// Network interception
fetch() → DevTools Network
XMLHttpRequest → DevTools Network
```

### Provider Pattern

```dart
// Accès aux services via Provider
final tabManager = context.read<TabManager>();
final devTools = context.read<NotilusDevToolsService>();
```

### Événements DevTools

```dart
// Logger un message
devTools.logInfo('Message', source: 'MyComponent');
devTools.logError('Error', stackTrace: stackTrace);

// Ajouter une requête
devTools.addRequest(NetworkRequest(...));
devTools.updateRequest(id, statusCode: 200, ...);

// Créer une alerte
devTools._createAlert(
  severity: AlertSeverity.warning,
  title: 'Titre',
  message: 'Message',
  category: 'performance',
);

// Bookmark
devTools.addBookmark(title: 'Checkpoint', category: 'debug');
```

---

## ⚙️ Configuration

### SmartMonitorConfig

```dart
SmartMonitorConfig(
  fpsDropAlert: true,           // Alerte chute FPS
  fpsThreshold: 30,             // Seuil FPS
  memorySpikAlert: true,        // Alerte mémoire
  memoryThresholdMB: 500,       // Seuil mémoire (MB)
  slowRequestAlert: true,       // Alerte requêtes lentes
  slowRequestThresholdMs: 3000, // Seuil requête (ms)
  errorBurstAlert: true,        // Alerte rafale erreurs
  errorBurstThreshold: 5,       // Nombre erreurs
  errorBurstWindowSeconds: 60,  // Fenêtre temporelle
  securityScanEnabled: true,    // Scan sécurité auto
)
```

### Thèmes

Le thème est géré par `ColorThemeManager`:
- Couleur d'accent personnalisable
- Mode sombre natif
- Wallpapers dynamiques

---

## 📝 Changelog

### v3.0.0 (Novembre 2025) - Advanced DevTools Edition

**Nouveautés:**
- ✨ Onglet Alerts - Smart Monitoring avec alertes intelligentes
- ✨ Onglet Security - Audit de sécurité automatique
- ✨ Onglet Widgets - Widget Tree Inspector Flutter
- ✨ Onglet Analytics - Stats, sessions, export
- ✨ Session Recording - Enregistrer/rejouer
- ✨ Bookmarks DevTools - Annoter les moments importants
- ✨ Export JSON - Rapports complets
- ✨ Documentation intégrée

**Améliorations:**
- 🔧 Métriques performance réelles (ProcessInfo)
- 🔧 Capture console WebView (injection JS)
- 🔧 Capture réseau WebView (fetch, XHR)
- 🔧 Nouvelles commandes REPL

### v2.0.0 - Native DevTools

- DevTools Console, Network, Performance, Storage
- Terminal intégré
- Split screen

### v1.0.0 - Initial Release

- Navigation web basique
- Gestion onglets
- Favoris, historique

---

## 🤝 Contribution

Ce projet est développé avec ❤️ pour la communauté des développeurs.

```
Notilus Browser
├── Fait avec Flutter 💙
├── Moteur: WebView2 (Chromium)
└── Pour les développeurs, par les développeurs
```

---

*Documentation générée automatiquement - Notilus Browser v3.0.0*

