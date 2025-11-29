# Démarrage rapide

Guide de démarrage rapide pour Notilus Browser.

## Installation

### Prérequis

- Windows 10/11 (ou macOS/Linux pour les versions futures)
- WebView2 Runtime (inclus avec Windows 11, téléchargeable pour Windows 10)
- Flutter SDK 3.0.0 ou supérieur (pour le développement)

### Installation depuis le code source

```bash
git clone https://github.com/votre-repo/notilus-browser.git
cd notilus-browser
flutter pub get
flutter run -d windows
```

## Première utilisation

### Configuration initiale

1. **Thème et apparence** : Accédez aux paramètres (`Ctrl+,`) pour personnaliser l'apparence
2. **Page d'accueil** : Choisissez votre style de page d'accueil préféré
3. **Terminal** : Sélectionnez votre interface terminal (Native ou XTerm)
4. **Transparence** : Ajustez la transparence des widgets selon vos préférences

### Authentification Firebase (optionnel)

Pour activer la synchronisation cloud :

1. Configurez Firebase dans votre projet
2. Générez `firebase_options.dart` avec `flutterfire configure`
3. Connectez-vous via les paramètres > Compte

## Navigation de base

- **Onglets** : Créez des onglets avec `Ctrl+T`
- **Recherche** : Utilisez la barre d'adresse pour naviguer
- **Sidebar** : Accédez aux fonctionnalités via la sidebar gauche
- **DevTools** : Appuyez sur `F12` pour ouvrir les DevTools

## Prochaines étapes

- Consultez les [fonctionnalités](features/) pour découvrir toutes les capacités
- Lisez les [guides pratiques](guides/) pour des cas d'usage spécifiques
- Explorez l'[API](api/) pour l'intégration personnalisée

