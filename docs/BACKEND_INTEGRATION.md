# Intégration du Backend Python dans Flutter

Ce document explique comment le backend Python Notilus est intégré dans l'application Flutter et lancé automatiquement au démarrage.

## Architecture

Le backend Python est intégré comme un binaire natif qui est :
1. **Construit** avec PyInstaller (Python 3.11) dans `backend/dist/`
2. **Copié** automatiquement dans le build Flutter lors de la compilation
3. **Lancé** automatiquement au démarrage de l'application Flutter
4. **Géré** par le service `BackendService` qui surveille son état de santé

## Fichiers clés

### Service Flutter
- `lib/services/backend_service.dart` : Service qui gère le cycle de vie du backend
  - Trouve/copie l'exécutable backend
  - Lance le processus en arrière-plan
  - Vérifie périodiquement la santé du backend (health check)
  - Redémarre automatiquement en cas de problème

### Intégration
- `lib/main.dart` : Initialise le backend au démarrage de l'application
- `windows/CMakeLists.txt` : Copie automatiquement l'exécutable backend dans le build Windows

## Workflow de build

### 1. Construire le backend

```bash
cd backend
build_backend.bat  # Windows
# ou
./build_backend.sh  # Linux/macOS
```

L'exécutable sera généré dans `backend/dist/notilus-backend.exe` (Windows) ou `backend/dist/notilus-backend` (Linux/macOS).

### 2. Construire l'application Flutter

```bash
flutter build windows
```

Le CMakeLists.txt copiera automatiquement l'exécutable backend dans le dossier de build Flutter.

### 3. Exécution

Lorsque vous lancez l'application Flutter :
1. Le `BackendService` cherche l'exécutable backend
2. Si trouvé, il le lance automatiquement en arrière-plan
3. Le backend démarre sur `http://127.0.0.1:8000`
4. Un health check périodique vérifie que le backend répond

## Emplacements de l'exécutable

Le service cherche l'exécutable dans cet ordre :

1. **Dossier de l'application** (build Flutter) : `notilus.exe` → `notilus-backend.exe`
2. **Dossier backend/dist** (développement) : `backend/dist/notilus-backend.exe`
   - Si trouvé, il sera copié vers le dossier de l'application

## Gestion des erreurs

- Si l'exécutable n'est pas trouvé : L'application démarre normalement, mais le backend ne sera pas disponible
- Si le backend ne démarre pas : Un message d'erreur est loggé, l'application continue
- Si le backend s'arrête : Le service tente de le redémarrer automatiquement

## Vérification du statut

Le `BackendService` expose :
- `isRunning` : Indique si le backend est en cours d'exécution
- `isInitialized` : Indique si le service a été initialisé
- `baseUrl` : URL de base du backend (`http://127.0.0.1:8000`)
- `lastError` : Dernière erreur rencontrée

## Utilisation dans le code

```dart
// Accéder au service
final backendService = Provider.of<BackendService>(context);

// Vérifier le statut
if (backendService.isRunning) {
  print('Backend disponible sur ${backendService.baseUrl}');
}

// Utiliser l'URL de base pour les appels API
final response = await http.get(
  Uri.parse('${backendService.baseUrl}/api/health'),
);
```

## Notes importantes

- Le backend s'exécute **sans console ni fenêtre** (mode `--noconsole`)
- Le backend utilise le port **8000** par défaut
- Le health check s'exécute toutes les **10 secondes**
- Le backend est arrêté automatiquement lorsque l'application Flutter se ferme

## Dépannage

### Le backend ne démarre pas

1. Vérifier que l'exécutable existe : `backend/dist/notilus-backend.exe`
2. Vérifier les logs dans la console Flutter (debugPrint)
3. Vérifier que le port 8000 n'est pas déjà utilisé
4. Tester l'exécutable manuellement : `backend/dist/notilus-backend.exe`

### Le backend ne répond pas

1. Vérifier que le processus est en cours d'exécution (Gestionnaire des tâches)
2. Tester l'endpoint de santé : `http://127.0.0.1:8000/api/health`
3. Vérifier les logs du backend (si disponibles)

### L'exécutable n'est pas copié dans le build

1. Vérifier que le backend a été construit : `backend/dist/notilus-backend.exe`
2. Vérifier que le chemin dans `CMakeLists.txt` est correct
3. Reconstruire l'application Flutter : `flutter clean && flutter build windows`

