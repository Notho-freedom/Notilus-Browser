# Notilus V2 - Interfaces et Vues Completes (Reference UI)

Version: `2.0.0`  
Date: `2026-03-03`  
Statut: `Reference officielle des vues V2`

---

## 1) Objectif du document

Ce document complete la charte graphique V2 et definit la structure des interfaces Notilus au niveau:

- Pages / ecrans
- Vues principales
- Panneaux lateraux
- Popups / modales / menus contextuels
- Etats d'affichage (loading, erreur, vide, actif)

Perimetre volontaire: **niveau vue** (et non inventaire exhaustif de tous les composants unitaires).

---

## 2) Principes de fidelite au design d'origine

La V2 doit rester alignee avec l'ADN visuel de Notilus:

1. **Ambiance dev-first futuriste**: interface sombre, accent neon controle.
2. **Transparence fonctionnelle**: blur + opacite pour separer les plans, pas pour decorer.
3. **Lisibilite prioritaire**: densite elevee mais hierarchie nette.
4. **Feedback immediat**: etats hover/focus/loading/erreur visibles partout.
5. **Cohesion cross-vues**: meme logique de card/panel/dialog dans toute l'app.

---

## 3) Carte globale des interfaces

## 3.1 Flux principal d'entree

1. `Splash Screen` (`NotilusSplashScreen`)
2. `HomeScreen` (container principal)
3. `ModernBrowserWindow` (shell applicatif)

## 3.2 Shell applicatif (ModernBrowserWindow)

Zones fixes:

- Sidebar gauche (navigation sections)
- Barre d'onglets (mode GX ou Grouped)
- Address bar (saisie + actions)
- Zone de contenu centrale (page active)
- Panel lateral droit optionnel (selon section)
- Couche DevTools dockee (bas)
- Couche Mini DevTools flottante

## 3.3 Modes de contenu central

La zone centrale affiche, selon contexte:

- Home page (style configurable)
- Web content tab standard (`WebContentView`)
- Mosaik view (`MosaicContainer`)
- Onglets 3D (`about:3dtabs` -> `Gx3DCoverFlowTabsView`)

---

## 4) Catalogue des pages et vues principales

| Vue | Type | Trigger | Role UX |
|---|---|---|---|
| Splash | Ecran de lancement | Demarrage app | Intro + progression + attente backend |
| Home Screen | Container | Fin splash | Affiche shell + warning backend si necessaire |
| Modern Browser Window | Shell principal | Toujours | Orchestration complete des vues |
| Home Page Styles | Vue centrale | Onglet vide / about:newtab / home | Dashboard de depart adapte au profil |
| Web Content View | Vue centrale | Onglet URL web | Navigation web + loading + erreurs + context menu |
| Mosaic View | Vue centrale | `Ctrl+Shift+M` / section Mosaic | Multi-vues simultanees |
| 3D Tabs View | Vue centrale | Onglet `about:3dtabs` | Navigation visuelle coverflow |

---

## 5) Home pages (styles disponibles)

## 5.1 Inventaire officiel

| Style ID | Intention | Signature visuelle |
|---|---|---|
| `modern` | Usage general | Speed dial + historique + widgets systeme |
| `notilus_dev` | Dev immersif | Command bar style IDE + categories dev |
| `frontend` | Dev front | Ambiance design/web + frameworks + tools UI |
| `backend` | Dev back | Ambiance terminal/serveur + status systeme |
| `devops` | Ops/infra | Dashboard monitoring + services + pipeline |
| `data_science` | Data/ML | Visualisation analytique + stack data |
| `minimal` | Focus absolu | Horloge + recherche + essentiels |
| `customizable` | Mode modulaire | Grille widgets dockables editable |

## 5.2 Detail des vues Home

### A) `modern`

- Recherche centrale (URL ou recherche web)
- Sites rapides (ajout via modale futuriste)
- Historique recent
- Widgets systeme / metriques
- Menus contextuels sur cards de raccourcis

### B) `notilus_dev`

- Header status technique + horloge
- Command bar (commandes speciales `:terminal`, `:devtools`, etc.)
- Categories CODE / DOCS / AI / TOOLS
- Sidebar d'activite recente
- Motifs visuels techniques (grille, scanlines, glow)

### C) `frontend`

- Hero section orientee web UI
- Barre de recherche elegante
- Frameworks rapides (React/Vue/Angular...)
- Categories Design / CSS Tools / Assets
- Fond anime (mesh/gradient + elements flottants)

### D) `backend`

- Header style terminal
- Command section orientee shell/ops
- Panel systeme lateral (etat machine)
- Grilles langages/outils backend
- Insertion de vues backend lab selon contexte

### E) `devops`

- Header monitoring
- Panel services (running/warning)
- Outils cloud/orchestration/CI/CD/observabilite
- Detection d'hotes serveurs depuis historique
- Animation radar + flux de donnees

### F) `data_science`

- Hero analytique
- Librairies data/ML
- Categories notebooks/ML/visualisation/warehouses
- Fond neural + wave + particules

### G) `minimal`

- Horloge/date grandes tailles
- Search bar centrale unique
- Raccourcis essentiels reduits
- Fond sobre + legere respiration visuelle

### H) `customizable`

- Grille dynamique de widgets
- Mode edition on/off
- Drag, resize, remove, minimize widgets
- Dialog "Ajouter un widget"

---

## 6) Sidebar et panneaux lateraux

## 6.1 Sections sidebar

Sections detectees:

- `home`
- `favorites`
- `history`
- `downloads`
- `widgets`
- `ai`
- `settings`
- `updates`
- `terminal`
- `nativeDevtools`
- `mosaic`
- `studio`
- `lighthouse`
- `github`
- `docs`
- `testPanel` (archive)
- services web: `youtubeMusic`, `youtube`, `chatgpt`, `deepseek`, `whatsapp`, `telegram`

## 6.2 Mapping section -> panneau

| Section | Panneau / vue | Notes |
|---|---|---|
| favorites | `GxFuturisticBookmarksPanel` | Recherche, filtre domaine, ajout/suppression |
| history | `GxFuturisticHistoryPanel` | Recherche, filtres periode/domaine, clear |
| downloads | `GxFuturisticDownloadsPanel` | Recherche, statut, periode, actions download |
| widgets | `GxFuturisticWidgetsPanel` | Cards metriques live |
| ai | `GxFuturisticAiPanel` | Modes CONSOLE/CHAT + actions rapides |
| settings | `ModernSettingsPanel` | Parametrage complet multi-sections |
| updates | `GxFuturisticUpdatesPanel` | Feed updates avec filtres |
| terminal | `TerminalPanel` | Native terminal ou XTerm |
| studio | `StudioPanel` | Suite front-end test/design |
| lighthouse | `LighthousePanel` | Audit qualite/score/recommandations |
| github | `GitHubReposPanel` | Repos + navigation contenus |
| docs | `DocumentationPanel` | Navigation + lecture markdown |
| youtube/chat services | `WebViewServicePanel` | Service web embarque persistant |
| home/nativeDevtools/mosaic | `null` | Ces sections pilotent la vue centrale ou un overlay |

---

## 7) Detail des panneaux metier

## 7.1 Favoris

- Header panel + recherche
- Filtrage par domaine
- Groupement d'affichage
- Modale "Ajouter aux favoris"
- Modale de confirmation suppression

## 7.2 Historique

- Recherche plein texte
- Filtres periode + domaine
- Groupement temporel
- Clear history avec confirmation

## 7.3 Telechargements

- Recherche
- Filtres periode + statut (en cours, termines, erreurs)
- Groupement par periode
- Actions item (ouvrir, annuler, etc. selon statut)

## 7.4 Widgets systeme

- Liste cards metriques live:
  - CPU
  - RAM
  - GPU
  - Reseau
  - Onglets
  - Session
  - Pages
  - Donnees

## 7.5 Hyper Assistant

- 2 modes principaux:
  - `CONSOLE`
  - `CHAT`
- Actions rapides:
  - Resumer
  - Traduire
  - Expliquer
  - Simplifier
- Zone conversation + reponses structurees

## 7.6 Mises a jour

- Feed recent updates
- Recherche multi-champs
- Filtres:
  - Periode
  - Categorie
- Action "Verifier" avec etat loading
- Etat vide "a jour"

## 7.7 Parametres (ModernSettingsPanel)

Sections principales:

- Apparence
- Fonds d'ecran
- Onglets
- Telechargements
- Panels lateraux
- Terminal
- Page d'accueil
- Services web
- Confidentialite
- Compte
- Assistant IA
- DevTools
- Composants GX
- Notifications
- Synthese vocale
- A propos

Caracteristiques UX:

- Recherche transversale de settings
- Index interne avec mots-cles
- Dialogs de confirmation pour actions destructives
- Entrypoints auth/sync/cloud/AI/TTS

## 7.8 Terminal

- `TerminalPanel` route vers:
  - `NativeTerminalPanel` (UI Flutter custom)
  - `GXTerminalView` (xterm)
- Choix pilote par parametre `terminalInterfaceType`

## 7.9 Documentation

- Sidebar navigation docs
- Recherche
- Historique navigation interne
- Rendu markdown

## 7.10 GitHub

- Etat connecte/deconnecte selon auth GitHub
- Recherche repos
- Tri (updated/stars/name)
- Filtrage (incl. private)
- Navigation contenus repo (dossiers/fichiers)

---

## 8) Vues Studio (tests front-end)

`StudioPanel` expose 5 modules:

1. `Responsive`
2. `Screenshot`
3. `Live Edit`
4. `Recorder`
5. `Mockup`

## 8.1 Responsive

- Multi-viewports (limite de previews actives)
- Presets devices
- Rotation viewport
- Suppression viewport

## 8.2 Screenshot

- Capture viewport ou full-page selon options
- Historique captures
- Suppression/export/copie selon actions dispo

## 8.3 Live Edit

- Onglets CSS / HTML
- Injection CSS en live
- Edition HTML element selectionne
- Export CSS

## 8.4 Recorder

- Start / pause / stop / resume
- Timeline d'interactions enregistrees
- Actions additionnelles:
  - Assertion
  - Wait
  - Screenshot
- Export code vers:
  - Playwright
  - Cypress
  - Puppeteer
  - Selenium

## 8.5 Mockup Comparator

- Import mockup
- Modes comparaison:
  - Overlay (opacite ajustable)
  - Diff
- Liste differences detectees
- Severite + suggestion de correction

---

## 9) Vues Lighthouse

`LighthousePanel` est organise en tabs:

1. Overview
2. Issues
3. Recommendations
4. History
5. AI Advisor

## 9.1 Overview

- Scores: Performance, Accessibility, SEO, Security
- Scorecards visuelles + couleurs de seuil

## 9.2 Issues

- Liste des problemes detectes
- Priorisation par gravite/impact

## 9.3 Recommendations

- Liste des optimisations proposees
- Orientation corrective actionnable

## 9.4 History

- `HistoryTrendsPanel`
- Liste URLs auditees
- Graph tendances (Score/LCP/CLS/Issues)
- Tableau historique + clear history

## 9.5 AI Advisor

Tabs internes:

- Quick Wins
- Recommendations
- Chat

Export rapport Lighthouse disponible en:

- HTML
- JSON
- CSV
- Markdown

---

## 10) DevTools et couches techniques

## 10.1 DevTools docke (bas)

`NotilusDevTools` tabs:

- Elements
- Console
- Network
- Resources
- Performance
- Application

Ouverture rapide:

- `F12`
- `Ctrl+Shift+I`

## 10.2 Mini DevTools flottant

`NotilusMiniDevToolsPanel`:

- Draggable
- Collapse / expand
- Tabs Console / Network
- Switch vers DevTools docke

## 10.3 Overlay DevTools WebView

`NotilusDevToolsOverlay` present mais actuellement en mode placeholder (integration websocket prevue).

---

## 11) Popups, modales et menus contextuels

## 11.1 Systeme modal principal

- `GxFuturisticDialog.show(...)`
- Signature visuelle commune:
  - blur fond
  - bordures geometriques
  - accent neon
  - animations ouverture/fermeture

## 11.2 Popups/modales cles par zone

| Zone | UI ephemere |
|---|---|
| Address bar | Suggestions URL (`OverlayEntry`) |
| Address bar | Menu "Plus d'outils" (`GXFuturisticMoreMenu`) |
| Address bar / compte | Dialog compte + `AuthDialog` |
| Barre onglets | Dialog recherche d'onglets |
| Onglets / home | Menus contextuels (ouvrir, dupliquer, fermer, etc.) |
| Home modern | Dialog "Ajouter un site rapide" |
| Downloads action | Popup telechargements rapide (`DownloadsPopupMenu`) |
| Settings | Multiples dialogs confirmation/reset/clear |
| Auth | Dialogs Email, Google Device Flow, GitHub OAuth |
| Studio Recorder | Dialog Assertion + Dialog Wait |
| Web content | Context menu image/lien/texte (download/copy/new tab/cloudinary) |

## 11.3 Menus contextuels

Deux implementations presentes:

- `GxContextMenu` (style moderne)
- `ContextMenu` (legacy encore utilise sur certaines vues)

---

## 12) Grammaire visuelle des vues (niveau cards/panels)

Cette section est la traduction "layout concret" de la charte, appliquee aux vues.

## 12.1 Panel standard

- Fond sombre avec opacite controlee
- Bordure fine claire/accent
- Header avec titre + icone + action close
- Contenu scrollable
- Drag handle si panel redimensionnable

## 12.2 Card standard futuriste

- Fond surface semi-transparent
- Radius moyen (8-12)
- Bordure subtile + glow limite
- Etat hover: elevation legere + contraste augmente
- Etat actif: accent plus franc + contour visible

## 12.3 Overlay/popup/modal

- Backdrop blur coherent avec reglage global
- Barrier opacity configurable
- Animation courte informative (pas decorative)
- Boutons actions primaires/secondaires differencies

## 12.4 Etats UX obligatoires par vue

- Loading
- Vide
- Erreur
- Succes (si action utilisateur)
- Desactive (si non disponible)

---

## 13) Raccourcis clavier impactant les vues

| Raccourci | Effet |
|---|---|
| `F12` | Toggle DevTools docke |
| `Ctrl+Shift+I` | Toggle DevTools docke |
| `Ctrl+Shift+M` | Toggle vue Mosaik |
| `Ctrl+Shift+L` | Ouvre panneau Lighthouse |
| `Ctrl+Shift+S` | Ouvre panneau Studio |
| `Ctrl+Shift+R` | Lance audit Lighthouse (si panneau Lighthouse actif) |
| `Ctrl+Shift+N` | Ouvre un onglet prive |

---

## 14) Etats de robustesse et fallback

## 14.1 Backend indisponible

- Banner warning dans `HomeScreen`
- Actions manuelles proposees:
  - Lancement manuel
  - Relancer backend
  - Copier diagnostic

## 14.2 Web content

- Etats init webview: notInitialized / initializing / ready / error
- Overlay loading pendant navigation
- Ecran erreur avec retry

## 14.3 Donnees vides

Chaque panel critique dispose d'un empty state explicite (downloads, updates, docs, github, etc.).

---

## 15) Checklist QA Interfaces V2

## 15.1 Couverture des vues

- [ ] Toutes les sections sidebar ouvrent la bonne vue/panel
- [ ] Les vues centrales switchent correctement (Home/Web/Mosaic/3D Tabs)
- [ ] Les raccourcis clavier ouvrent la bonne couche

## 15.2 Cohesion visuelle

- [ ] Meme logique header/panel/card sur toutes les vues
- [ ] Transparence/blur homogenes
- [ ] Accent actif coherent avec theme choisi

## 15.3 UX transversale

- [ ] Etats loading/erreur/empty/systematiquement visibles
- [ ] Menus contextuels coherents selon cible (image/lien/texte)
- [ ] Dialogs de confirmation sur actions destructives

## 15.4 Responsive et densite

- [ ] Sidebar/panel exploitables sur resolutions compactes
- [ ] Dialogs non coupes en petites fenetres
- [ ] Scroll interne propre dans tous les panneaux longs

---

## 16) Convention de migration V2 web

Pour la migration stack web, conserver en priorite:

1. La **cartographie des vues** de ce document.
2. La **grammaire visuelle** de la charte graphique.
3. Les **etats UX** (loading/error/empty/success) pour chaque interface.
4. Les **raccourcis et comportements** qui structurent le workflow dev.

Decision: ce document est la base "structure ecran" officielle de Notilus V2, complementaire a la charte graphique.
