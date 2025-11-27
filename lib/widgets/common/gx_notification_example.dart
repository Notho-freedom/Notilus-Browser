/// Exemple d'utilisation du système de notifications GX
/// 
/// Usage:
/// ```dart
/// // Notification de succès
/// GxNotificationService().showSuccess(
///   title: 'Opération réussie',
///   message: 'Les données ont été sauvegardées',
///   context: context,
/// );
/// 
/// // Notification d'erreur
/// GxNotificationService().showError(
///   title: 'Erreur',
///   message: 'Impossible de se connecter au serveur',
///   context: context,
/// );
/// 
/// // Notification personnalisée
/// GxNotificationService().show(
///   title: 'Nouveau message',
///   message: 'Vous avez reçu un nouveau message',
///   type: GxNotificationType.info,
///   icon: Icons.message_rounded,
///   duration: Duration(seconds: 5),
///   onTap: () => print('Notification cliquée'),
///   context: context,
/// );
/// ```

