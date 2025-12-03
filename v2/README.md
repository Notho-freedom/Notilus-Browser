# Notilus Browser v2 - Migration Tauri

## 🚀 Nouvelle Architecture

Cette version migre Notilus Browser de **Flutter Desktop** vers **Tauri + React/Svelte**.

### Stack Technique

- **Frontend**: React/TypeScript ou Svelte
- **Backend**: Rust (intégré dans Tauri)
- **Moteur Web**: WebView2 natif (via Tauri)
- **Storage**: SQLite + Keyring natif
- **State**: Zustand ou Svelte Stores

### Structure Projet

```
v2/
├── src/                    # Frontend React/Svelte
│   ├── components/         # Composants UI
│   ├── stores/            # State management
│   ├── hooks/              # Custom hooks
│   └── App.tsx
│
├── src-tauri/              # Backend Rust
│   ├── src/
│   │   ├── main.rs
│   │   ├── commands/       # Commandes IPC
│   │   ├── services/       # Services métier
│   │   └── db/             # SQLite
│   └── Cargo.toml
│
└── package.json
```

### Migration depuis v1

#### Fonctionnalités à Migrer

- [ ] Système de tabs multi-WebView
- [ ] Authentification GitHub/Firebase
- [ ] Ad Blocker
- [ ] DevTools Panel
- [ ] Mosaic System
- [ ] Studio avec previews temps réel
- [ ] Système de téléchargements
- [ ] Raccourcis clavier
- [ ] Thèmes et personnalisation
- [ ] Backend Lab
- [ ] Terminal intégré

#### Avantages de la Migration

1. **Performance**: Binaire ~10 MB vs ~150 MB
2. **Mémoire**: ~50-100 MB vs ~200-400 MB
3. **Backend intégré**: Pas de processus Python séparé
4. **WebView natif**: Meilleure intégration
5. **Sécurité**: Rust memory-safe
6. **IPC type-safe**: Communication frontend/backend sécurisée

### Démarrage

```bash
# Installer les dépendances
npm install

# Lancer en développement
npm run tauri dev

# Build production
npm run tauri build
```

### Documentation

- [Tauri Documentation](https://tauri.app/)
- [WebView2 API](https://learn.microsoft.com/en-us/microsoft-edge/webview2/)
- [Rust Book](https://doc.rust-lang.org/book/)

---

**Note**: Cette version est en développement actif. Consultez v1/ pour la version Flutter stable.

