# Composants Futuristes Notilus GX

Collection de composants réutilisables avec le style OS Science-Fiction.

## Composants Disponibles

### 1. GxFuturisticCard
Carte avec contours géométriques et transparence.

```dart
GxFuturisticCard(
  title: 'Ma Carte',
  titleIcon: Icons.star_rounded,
  accentColor: Colors.blue,
  child: Text('Contenu de la carte'),
)
```

### 2. GxFuturisticInput
Champ de saisie avec style futuriste.

```dart
GxFuturisticInput(
  controller: myController,
  hint: 'Entrez votre texte',
  label: 'Nom',
  prefixIcon: Icons.person_rounded,
  accentColor: Colors.blue,
)
```

### 3. GxFuturisticBadge
Badge avec effet glow optionnel.

```dart
GxFuturisticBadge(
  label: 'Nouveau',
  icon: Icons.star_rounded,
  color: Colors.green,
  glow: true,
)
```

### 4. GxFuturisticSwitch
Interrupteur avec animation fluide.

```dart
GxFuturisticSwitch(
  value: isEnabled,
  onChanged: (value) => setState(() => isEnabled = value),
  label: 'Activer la fonctionnalité',
)
```

### 5. GxFuturisticProgress
Barre de progression avec gradient.

```dart
GxFuturisticProgress(
  value: 0.75, // 75%
  label: 'Progression',
  accentColor: Colors.blue,
)
```

### 6. GxFuturisticDivider
Séparateur avec gradient.

```dart
GxFuturisticDivider(
  accentColor: Colors.blue,
  height: 2,
)
```

## Système de Notifications

### Utilisation de base

```dart
// Notification de succès
GxNotificationService().showSuccess(
  title: 'Opération réussie',
  message: 'Les données ont été sauvegardées',
  context: context,
);

// Notification d'erreur
GxNotificationService().showError(
  title: 'Erreur',
  message: 'Impossible de se connecter',
  context: context,
);

// Notification d'avertissement
GxNotificationService().showWarning(
  title: 'Attention',
  message: 'Cette action est irréversible',
  context: context,
);

// Notification d'information
GxNotificationService().showInfo(
  title: 'Information',
  message: 'Nouvelle mise à jour disponible',
  context: context,
);
```

### Notification personnalisée

```dart
GxNotificationService().show(
  title: 'Nouveau message',
  message: 'Vous avez reçu un message',
  type: GxNotificationType.info,
  icon: Icons.message_rounded,
  duration: Duration(seconds: 5),
  onTap: () {
    // Action au clic
  },
  context: context,
);
```

### Fermer une notification

```dart
// Fermer toutes les notifications
GxNotificationService().dismissAll();

// Fermer une notification spécifique (nécessite l'ID)
// Les notifications se ferment automatiquement après leur durée
```

## Caractéristiques

- **Transparence** : S'adapte automatiquement aux paramètres de transparence de l'application
- **Contours géométriques** : Style OS Science-Fiction avec angles et lignes
- **Animations fluides** : Animations d'entrée/sortie avec courbes personnalisées
- **Thème adaptatif** : Utilise automatiquement les couleurs du thème Notilus
- **Backdrop blur** : Effet de flou d'arrière-plan pour la profondeur

