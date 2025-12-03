# 🚀 Plan de Migration Notilus Browser

## Vue d'Ensemble

Migration de **v1 (Flutter)** vers **v2 (Tauri + React/Svelte)**.

## Structure des Versions

```
Notilus-Browser/
├── v1/              # Version Flutter (archivée, stable)
│   └── ...          # Code Flutter/Dart + Backend Python
│
├── v2/              # Version Tauri (en développement)
│   └── ...          # Code React/Svelte + Backend Rust
│
└── MIGRATION.md     # Ce fichier
```

## Objectifs de la Migration

### Performance
- ✅ Réduire la taille du binaire: 150 MB → 10-15 MB
- ✅ Réduire l'utilisation mémoire: 200-400 MB → 50-100 MB
- ✅ Améliorer le temps de démarrage

### Architecture
- ✅ Backend intégré (Rust) au lieu de processus Python séparé
- ✅ WebView2 natif via Tauri (pas de plugin tiers)
- ✅ IPC type-safe entre frontend et backend
- ✅ Meilleure gestion des erreurs avec Rust

### Développement
- ✅ Écosystème React/Svelte plus riche
- ✅ Hot reload plus rapide
- ✅ Meilleure intégration avec les outils web

## Plan de Migration

### Phase 1: Setup (Jour 1-2)
- [x] Créer structure v1/v2
- [ ] Initialiser projet Tauri
- [ ] Configurer WebView2 multi-instance
- [ ] Setup SQLite

### Phase 2: Backend Rust (Jour 3-4)
- [ ] Migrer endpoints Python → Rust Axum
- [ ] Implémenter OAuth GitHub
- [ ] Créer commandes IPC pour tabs
- [ ] Système de storage SQLite

### Phase 3: Frontend Core (Jour 5-7)
- [ ] Convertir widgets Flutter → React components
- [ ] Implémenter TabBar
- [ ] Implémenter AddressBar
- [ ] Système de thèmes

### Phase 4: Features Avancées (Jour 8-10)
- [ ] DevTools Panel
- [ ] Mosaic System
- [ ] Studio avec previews temps réel
- [ ] Ad Blocker

### Phase 5: Finalisation (Jour 11-15)
- [ ] Tests E2E
- [ ] Optimisations performance
- [ ] Installer Windows
- [ ] Documentation

## Checklist de Migration

### Fonctionnalités Critiques
- [ ] Multi-tabs avec WebView2
- [ ] Navigation (back/forward/reload)
- [ ] Authentification GitHub
- [ ] Ad Blocker
- [ ] Téléchargements
- [ ] Raccourcis clavier

### Fonctionnalités Avancées
- [ ] DevTools Panel
- [ ] Mosaic System
- [ ] Studio
- [ ] Backend Lab
- [ ] Terminal intégré
- [ ] Thèmes personnalisés

### Infrastructure
- [ ] Auto-updater
- [ ] Logging système
- [ ] Gestion d'erreurs
- [ ] Tests unitaires
- [ ] Tests d'intégration

## Ressources

- [Tauri Documentation](https://tauri.app/)
- [WebView2 API](https://learn.microsoft.com/en-us/microsoft-edge/webview2/)
- [Rust Book](https://doc.rust-lang.org/book/)
- [React Documentation](https://react.dev/)

## Notes

- v1 reste disponible pour référence
- Les deux versions peuvent coexister
- Migration progressive possible (feature par feature)

---

**Dernière mise à jour**: 2025-12-03

