# 📚 Notilus Browser - Documentation Développeur

> **Version 3.1.0** | Navigateur conçu par et pour les développeurs
> 
> Dernière mise à jour : Novembre 2025

---

## 📋 Table des matières

1. [Introduction](#-introduction)
2. [Installation & Lancement](#-installation--lancement)
3. [Interface Utilisateur](#-interface-utilisateur)
4. [DevTools Notilus](#-devtools-notilus)
5. [Terminal Intégré](#-terminal-intégré)
6. [Raccourcis Clavier](#-raccourcis-clavier)
7. [Architecture Technique](#-architecture-technique)
8. [Services Web Intégrés](#-services-web-intégrés)
9. [Configuration](#-configuration)
10. [Changelog](#-changelog)

---

## 🚀 Introduction

**Notilus Browser** est un navigateur web moderne construit avec Flutter, spécialement conçu pour les développeurs. Il intègre des outils de développement avancés directement dans l'interface, sans avoir besoin d'extensions externes.

### Caractéristiques principales

- 🐜 **DevTools intégrés** - Console, Network, Elements, Performance, Application
- 🌐 **Moteur Chromium** - WebView2 pour Windows (même moteur que Edge)
- 🖥️ **Terminal intégré** - PowerShell directement dans le navigateur
- 🎨 **Thèmes personnalisables** - Couleurs d'accent configurables
- 📱 **Services web intégrés** - YouTube, ChatGPT, WhatsApp, etc.
- ⚡ **Performance native** - Flutter pour une UI fluide et réactive

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
# Cloner le repo
git clone https://github.com/Notho-freedom/Notilus-Browser.git
cd Notilus-Browser

# Mode développement
flutter run -d windows

# Build release
flutter build windows --release
```

### Structure du projet

```
Notilus-Browser/
├── lib/
│   ├── core/           # Constants, Theme, Utils
│   ├── models/         # Modèles de données
│   ├── services/       # Logique métier
│   ├── widgets/        # Composants UI
│   └── main.dart       # Point d'entrée
├── windows/            # Code natif Windows
├── build/              # Fichiers générés
└── DOCS.md             # Cette documentation
```

---

## 🎨 Interface Utilisateur

### Sidebar (Barre latérale)

| Icône | Section | Description |
|-------|---------|-------------|
| 🏠 | Accueil | Page d'accueil avec speed dial |
| 🔖 | Favoris | Gestionnaire de bookmarks |
| 🕐 | Historique | Historique de navigation |
| ⬇️ | Téléchargements | Gestionnaire de downloads |
| 📦 | Widgets | Widgets système dynamiques |
| ✨ | AI | Assistant Hyper AI |
| ⚙️ | Paramètres | Configuration rapide |
| 📟 | Terminal | Terminal PowerShell intégré |
| 🐜 | DevTools (F12) | Outils de développement |
| 📖 | Documentation | Cette documentation |

### Services Web (en bas de sidebar)

| Icône | Service | URL |
|-------|---------|-----|
| 🎵 | YouTube Music | music.youtube.com |
| ▶️ | YouTube | youtube.com |
| 💬 | ChatGPT | chatgpt.com |
| 🔮 | DeepSeek | chat.deepseek.com |
| 📱 | WhatsApp | web.whatsapp.com |
| ✈️ | Telegram | web.telegram.org |

### Barre d'onglets

- **Glisser-déposer** pour réorganiser les onglets
- **Clic molette** pour fermer un onglet
- **Double-clic** pour renommer
- **Indicateur de couleur** pour l'onglet actif
- **Favicon dynamique** pour chaque site

### Barre d'adresse

- **Autocomplétion** intelligente
- **Suggestions** de recherche
- **Indicateurs** de sécurité (HTTPS)
- **Actions rapides** (reload, favoris, partage)

---

## 🐜 DevTools Notilus

Les DevTools s'ouvrent en **bas de l'écran** (comme les DevTools Chrome) via:
- **Bouton Fourmi** 🐜 dans la sidebar
- **F12** - Raccourci clavier
- **Ctrl+Shift+I** - Raccourci alternatif

### Panel redimensionnable

Le panel DevTools peut être redimensionné en glissant la bordure supérieure. Hauteur min: 150px, max: 600px.

### Onglet Console

```
📋 Fonctionnalités:
- Logs WebView (console.log, console.warn, console.error)
- Filtres par niveau: log, info, warn, error, debug, table
- Recherche textuelle dans les logs
- Compteur d'erreurs/warnings
- Bouton "Clear" pour effacer
```

**Niveaux de log:**
| Niveau | Couleur | Icône |
|--------|---------|-------|
| log | ⚪ Gris | ○ |
| info | 🔵 Bleu | ℹ |
| warn | 🟠 Orange | ⚠ |
| error | 🔴 Rouge | ✕ |
| debug | 🟢 Vert | 🐛 |
| table | 🟣 Violet | 📊 |

### Onglet Network

```
🌐 Fonctionnalités:
- Capture requêtes HTTP/HTTPS (fetch, XMLHttpRequest)
- Headers request/response
- Body request/response (JSON, HTML, etc.)
- Timing détaillé (durée, taille)
- Filtres par méthode (GET, POST, etc.)
- Filtres par status (2xx, 4xx, 5xx)
- Recherche par URL
```

**Indicateurs de status:**
| Code | Couleur | Signification |
|------|---------|---------------|
| 2xx | 🟢 Vert | Succès |
| 3xx | 🔵 Bleu | Redirection |
| 4xx | 🟠 Orange | Erreur client |
| 5xx | 🔴 Rouge | Erreur serveur |

### Onglet Elements

```
🏗️ Fonctionnalités:
- Arbre DOM de la page web
- Inspection des éléments HTML
- Propriétés CSS
- Box model (margin, padding, border)
- Navigation dans la hiérarchie
```

### Onglet Performance

```
📊 Métriques temps réel:
- Timeline d'activité
- Métriques de rendu
- Profiling JavaScript
- Détection des bottlenecks
```

### Onglet Application

```
💾 Stockage et ressources:
- LocalStorage - Stockage local persistant
- SessionStorage - Stockage de session
- Cookies - Gestion des cookies
- Cache - Cache du navigateur
- Service Workers - Workers enregistrés
```

### Barre d'outils DevTools

| Bouton | Action |
|--------|--------|
| 🧹 | Effacer tous les logs/requêtes |
| 📌 | Docker/Détacher le panel |
| ✕ | Fermer les DevTools |

---

## 🖥️ Terminal Intégré

Le terminal intégré permet d'exécuter des commandes shell directement dans le navigateur.

### Accès

- Icône **Terminal** 📟 dans la sidebar
- Ouvre un panel latéral avec PowerShell

### Fonctionnalités

- **Shell PowerShell** natif Windows
- **Historique** des commandes
- **Coloration syntaxique** de l'output
- **Redimensionnable** (glisser la bordure)
- **Copier/Coller** supporté

### Commandes utiles

```powershell
# Navigation
cd <path>          # Changer de répertoire
ls / dir           # Lister les fichiers
pwd                # Répertoire actuel

# Flutter
flutter doctor     # Vérifier l'installation
flutter run        # Lancer l'app
flutter build      # Compiler

# Git
git status         # État du repo
git pull           # Récupérer les changements
git push           # Pousser les changements
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
| `Ctrl+R` / `F5` | Recharger |
| `Ctrl+Shift+R` | Recharger (ignorer cache) |

### DevTools

| Raccourci | Action |
|-----------|--------|
| `F12` | Toggle DevTools |
| `Ctrl+Shift+I` | Toggle DevTools |
| `Echap` | Fermer DevTools |

### Édition

| Raccourci | Action |
|-----------|--------|
| `Ctrl+L` | Focus barre d'adresse |
| `Ctrl+K` | Recherche rapide |
| `Ctrl+D` | Ajouter aux favoris |
| `Ctrl+C` | Copier |
| `Ctrl+V` | Coller |
| `Ctrl+A` | Tout sélectionner |

### Système

| Raccourci | Action |
|-----------|--------|
| `F11` | Plein écran |
| `Ctrl+H` | Historique |
| `Ctrl+J` | Téléchargements |
| `Ctrl+Shift+Delete` | Effacer données navigation |

---

## 🏗️ Architecture Technique

### Stack technologique

```
┌─────────────────────────────────────────┐
│              Notilus Browser            │
├─────────────────────────────────────────┤
│  UI Layer (Flutter Widgets)             │
│  - GXSidebar, GXTabBar, GXAddressBar   │
│  - NotilusDevTools                      │
│  - DocumentationPanel                   │
├─────────────────────────────────────────┤
│  Service Layer                          │
│  - TabManager, TabWebViewManager        │
│  - DevToolsService                      │
│  - DownloadService, TerminalService     │
├─────────────────────────────────────────┤
│  Engine Layer                           │
│  - WebView2BrowserEngine (Windows)      │
│  - JavaScript Bridge                    │
├─────────────────────────────────────────┤
│  Platform Layer                         │
│  - webview_windows (WebView2)           │
│  - window_manager                       │
│  - shared_preferences                   │
└─────────────────────────────────────────┘
```

### Services principaux

#### TabManager
Gestion des onglets (création, fermeture, réorganisation, activation).

#### TabWebViewManager
Association onglets ↔ moteurs WebView avec cache intelligent pour éviter les rechargements.

#### DevToolsService
Service pour les DevTools intégrés:
- Capture des logs console WebView
- Interception des requêtes réseau
- Métriques de performance
- Inspection DOM

#### BrowserEngine
Interface abstraite pour le moteur de rendu, implémentée par:
- `WebView2BrowserEngine` (Windows - production)

### Provider Pattern

```dart
// Accès aux services via Provider
final tabManager = context.read<TabManager>();
final devTools = context.read<DevToolsService>();
final tabWebViewManager = context.read<TabWebViewManager>();
```

---

## 🌐 Services Web Intégrés

Les services web s'ouvrent dans des panels latéraux dédiés, permettant d'avoir YouTube, ChatGPT, etc. à portée de main sans quitter votre navigation.

### YouTube Music
- Écouter de la musique en arrière-plan
- Contrôles intégrés
- Ne se ferme pas en changeant d'onglet

### YouTube
- Regarder des vidéos dans un panel
- Mode mini-player possible

### ChatGPT / DeepSeek
- Assistant IA toujours accessible
- Poser des questions sur votre code

### WhatsApp / Telegram
- Messageries intégrées
- Notifications dans le panel

---

## ⚙️ Configuration

### Thèmes

Le thème est géré par `ColorThemeManager`:
- Couleur d'accent personnalisable
- Mode sombre natif
- Wallpapers dynamiques via `WallpaperManager`

### Stockage

Les préférences utilisateur sont stockées via `SharedPreferences`:
- Historique de navigation
- Favoris
- Paramètres d'affichage
- État des panels

---

## 📝 Changelog

### v3.1.0 (Novembre 2025) - DevTools Unifiés

**Changements majeurs:**
- 🐜 **Nouveau système DevTools** - Récupéré de la branche f509
- 🔧 **DevTools en bas** - Panel qui s'ouvre en bas de l'écran (comme Chrome)
- 🎯 **Bouton unique** - Un seul bouton "DevTools (F12)" avec icône fourmi
- ⚡ **DevToolsService** - Nouveau service unifié

**Onglets DevTools:**
- Console - Logs avec filtres par niveau
- Network - Capture des requêtes HTTP
- Elements - Inspection DOM
- Performance - Métriques
- Application - Storage, cookies, cache

### v3.0.0 - Advanced DevTools Edition

**Nouveautés:**
- ✨ DevTools intégrés natifs Flutter
- ✨ Terminal PowerShell intégré
- ✨ Documentation interactive
- ✨ Services web dans la sidebar

**Améliorations:**
- 🔧 Animations fluides
- 🔧 Thèmes personnalisables
- 🔧 Split-screen

### v2.0.0 - Modern UI

- Interface GX moderne
- Sidebar redessinée
- Gestion avancée des onglets

### v1.0.0 - Initial Release

- Navigation web basique
- Gestion onglets
- Favoris, historique

---

## 🤝 Contribution

Ce projet est développé avec ❤️ pour la communauté des développeurs.

### Comment contribuer

1. Fork le repo
2. Créer une branche feature (`git checkout -b feature/amazing`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push la branche (`git push origin feature/amazing`)
5. Ouvrir une Pull Request

### Liens utiles

- **GitHub**: [github.com/Notho-freedom/Notilus-Browser](https://github.com/Notho-freedom/Notilus-Browser)
- **Issues**: Pour signaler des bugs ou demander des fonctionnalités

---

```
Notilus Browser v3.1.0
├── Fait avec Flutter 💙
├── Moteur: WebView2 (Chromium)
└── Pour les développeurs, par les développeurs
```

---

*Documentation générée - Notilus Browser v3.1.0*
