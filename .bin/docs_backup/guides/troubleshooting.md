# Dépannage

Guide de résolution des problèmes courants.

## Problèmes de compilation

### Erreur WebView2Loader.dll
- Fermez toutes les instances de Notilus
- Relancez `flutter run`

### Erreurs de dépendances
```bash
flutter clean
flutter pub get
flutter run
```

## Problèmes de performance

### L'application est lente
- Réduisez le nombre de viewports actifs dans Studio
- Désactivez les animations dans les paramètres
- Fermez les onglets inutilisés

### Les DevTools sont lents
- Réduisez le taux de rafraîchissement
- Désactivez la capture du body des requêtes
- Limitez le nombre de logs conservés

## Problèmes de synchronisation

### Firebase ne se connecte pas
- Vérifiez que `firebase_options.dart` est correctement configuré
- Exécutez `flutterfire configure`
- Vérifiez vos credentials Firebase

### Les configurations ne se synchronisent pas
- Vérifiez votre connexion internet
- Vérifiez que vous êtes connecté à Firebase
- Essayez d'exporter manuellement depuis les paramètres

## Problèmes de terminal

### Le terminal ne s'ouvre pas
- Vérifiez que le terminal préféré est correctement configuré
- Essayez de changer l'interface (Native/XTerm)
- Redémarrez l'application

## Support

Si le problème persiste :
1. Consultez les logs dans la console
2. Ouvrez une issue sur GitHub avec les détails
3. Incluez les logs d'erreur si disponibles

