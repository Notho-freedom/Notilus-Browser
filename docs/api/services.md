# API Services

Documentation des services principaux de Notilus.

## SettingsService

Gestion centralisée des paramètres de l'application.

### Méthodes principales

```dart
// Thème
await settingsService.setThemeMode(ThemeMode.dark);
ThemeMode mode = settingsService.themeMode;

// Transparence
await settingsService.setWidgetTransparency(0.2);
double transparency = settingsService.widgetTransparency;

// Terminal
await settingsService.setTerminalInterfaceType('xterm');
String type = settingsService.terminalInterfaceType;
```

## DevToolsService

Service pour les DevTools intégrés.

### Méthodes principales

```dart
// Attacher/détacher
devToolsService.attachEngine(engine);
devToolsService.detachEngine();

// Console
List<ConsoleEntry> logs = devToolsService.consoleLogs;

// Network
List<NetworkRequest> requests = devToolsService.networkRequests;
```

## StudioService

Service principal pour Notilus Studio.

### Méthodes principales

```dart
// Attacher/détacher
studioService.attachEngine(engine);
studioService.detachEngine();

// Responsive Tester
studioService.responsiveTester.addViewport(preset);
studioService.responsiveTester.removeViewport(presetId);
```

## LighthouseService

Service principal pour Notilus Lighthouse.

### Méthodes principales

```dart
// Audit
await lighthouseService.runFullAudit();
AuditResult result = lighthouseService.lastResult;

// Historique
List<AuditHistoryEntry> history = lighthouseService.historyService.history;
```

## FirebaseAuthService

Service d'authentification Firebase.

### Méthodes principales

```dart
// Connexion
UserCredential? result = await authService.signInWithGoogle();

// Déconnexion
await authService.signOut();

// État
bool isSignedIn = authService.isSignedIn;
User? user = authService.currentUser;
```

## ConfigSyncService

Service de synchronisation des configurations.

### Méthodes principales

```dart
// Export
bool success = await syncService.exportConfigs();

// Restore
bool success = await syncService.restoreConfigs();

// État
bool isSyncing = syncService.isSyncing;
DateTime? lastSync = syncService.lastSyncTime;
```

