# Guide de Test - Architecture Quantum-Bridge CEF

## 🧪 Tests à Effectuer

### 1. Test de Base - Lancement de l'Application

```bash
# Lancer l'application en mode Release
flutter run -d windows --release

# OU directement depuis le build
.\build\windows\x64\runner\Release\notilus.exe
```

### 2. Test via l'Écran de Test

L'écran de test a été créé dans `lib/screens/cef_test_screen.dart`.

Pour l'utiliser, ajoutez une route dans votre application :

```dart
// Dans lib/main.dart ou votre router
routes: {
  '/cef-test': (context) => const CefTestScreen(),
}
```

Puis naviguez vers `/cef-test` depuis votre application.

### 3. Test Direct du Widget QuantumBrowser

```dart
import 'package:notilus_cef/widgets/quantum_browser.dart';

// Dans votre widget
QuantumBrowser(
  initialUrl: 'https://flutter.dev',
  enableEffects: true,
)
```

### 4. Vérifications à Effectuer

#### ✅ Vérification du Processus Worker

1. **Lancer l'application**
2. **Ouvrir le Gestionnaire des tâches Windows**
3. **Vérifier la présence de `cef_worker.exe`** dans les processus
   - Le processus doit apparaître quand le widget CEF est initialisé
   - Le processus doit disparaître quand le widget est détruit

#### ✅ Vérification de la Communication IPC

1. **Shared Memory** : Vérifier que les pixels sont transférés
   - Le rendu de la page web doit apparaître dans Flutter
   - Pas de crash ou d'erreur de mémoire

2. **Named Pipes** : Vérifier que les commandes sont envoyées
   - Navigation (charger une URL)
   - Événements souris (clic, mouvement)
   - Événements clavier (saisie de texte)

#### ✅ Test de Navigation

1. Charger différentes URLs :
   - `https://flutter.dev`
   - `https://google.com`
   - `https://github.com`
   - `file:///C:/path/to/local/file.html` (si applicable)

2. Vérifier que :
   - La page se charge correctement
   - Les images s'affichent
   - Le JavaScript fonctionne
   - Les liens sont cliquables

#### ✅ Test des Interactions

1. **Souris** :
   - Clic gauche (navigation)
   - Clic droit (menu contextuel si implémenté)
   - Mouvement de la souris (hover effects)

2. **Clavier** :
   - Saisie de texte dans les champs
   - Raccourcis clavier (Ctrl+C, Ctrl+V, etc.)

#### ✅ Test de Performance

1. **FPS** : Vérifier que le rendu est fluide (60+ FPS)
2. **Mémoire** : Surveiller l'utilisation mémoire
3. **CPU** : Vérifier que l'utilisation CPU est raisonnable

### 5. Tests de Debug

#### Vérifier les Logs

Les logs peuvent être trouvés dans :
- Console de l'application Flutter
- Fichiers de log CEF (si configurés)

#### Vérifier les Erreurs

1. **Erreurs de plugin** : Vérifier la console Flutter
2. **Erreurs CEF** : Vérifier les logs du worker
3. **Erreurs IPC** : Vérifier les erreurs de Shared Memory ou Named Pipes

### 6. Test de Stabilité

1. **Chargement répété** : Charger/décharger le widget plusieurs fois
2. **Navigation rapide** : Naviguer rapidement entre plusieurs pages
3. **Fermeture propre** : Vérifier que tous les processus se terminent correctement

### 7. Test d'Intégration avec l'Application

1. Intégrer le widget dans votre interface existante
2. Tester avec d'autres widgets Flutter
3. Vérifier que les performances globales sont acceptables

## 🔍 Commandes Utiles

```bash
# Vérifier que cef_worker.exe existe
Test-Path "build\windows\x64\plugins\notilus_cef\Release\cef_worker.exe"

# Lister les processus CEF
Get-Process | Where-Object {$_.ProcessName -like "*cef*"}

# Vérifier les fichiers CEF copiés
Get-ChildItem "build\windows\x64\plugins\notilus_cef\Release" -Recurse | Select-Object Name
```

## ⚠️ Problèmes Potentiels

### Le widget ne s'affiche pas
- Vérifier que `cef_worker.exe` est présent dans le répertoire de build
- Vérifier que les DLLs CEF sont copiées
- Vérifier les logs d'erreur

### Le processus worker ne démarre pas
- Vérifier les permissions d'exécution
- Vérifier que le chemin vers `cef_worker.exe` est correct
- Vérifier les arguments passés au processus

### Pas de rendu / Écran noir
- Vérifier que Shared Memory est créée correctement
- Vérifier que les dimensions sont correctes
- Vérifier que le texture ID est valide

### Erreurs de communication
- Vérifier que Named Pipe est créé
- Vérifier les permissions de communication IPC
- Vérifier le format des commandes

