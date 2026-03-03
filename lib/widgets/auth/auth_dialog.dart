/// Dialog d'authentification pour Notilus
library auth_dialog;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart'; // Plus utilisé, on ouvre tout dans Notilus
import 'dart:async';
import '../../services/auth/firebase_auth_service.dart';
import '../../services/auth/local_oauth_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/tab_manager.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../core/utils/result.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';
import '../../services/gx_notification_service.dart';

/// Dialog d'authentification
class AuthDialog extends StatelessWidget {
  final FirebaseAuthService authService;
  final VoidCallback? onAuthStarted; // Callback appelé quand l'auth démarre

  const AuthDialog({
    super.key,
    required this.authService,
    this.onAuthStarted,
  });

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context).nativeSecondaryColor;

    return GxFuturisticDialog(
      title: 'Connexion à Notilus',
      titleIcon: Icons.lock_rounded,
      accentColor: gxRed,
      width: 420,
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: gxRed,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Connectez-vous pour synchroniser vos configurations',
            style: NotilusFonts.rajdhani(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          if (authService.isGoogleSignInAvailable)
            _AuthButton(
              icon: Icons.g_mobiledata,
              label: 'Continuer avec Google',
              color: Colors.blue,
              onPressed: () async {
                try {
                  final result = await authService.signInWithGoogle();
                  if (result != null && context.mounted) {
                    Navigator.of(context).pop(true);
                  } else if (context.mounted) {
                    GxNotificationService().showError(
                      title: 'Erreur',
                      message: 'Connexion annulée ou échouée',
                      context: context,
                    );
                  }
                } catch (e) {
                  if (e is GoogleDeviceFlowException && context.mounted) {
                    _showGoogleDeviceFlowDialog(
                        context, authService, e.deviceFlow);
                  } else if (context.mounted) {
                    GxNotificationService().showError(
                      title: 'Erreur',
                      message: 'Erreur: ${e.toString()}',
                      context: context,
                    );
                  }
                }
              },
            )
          else
            _AuthButton(
              icon: Icons.email,
              label: 'Continuer avec Email',
              color: Colors.blue,
              onPressed: () => _showEmailAuthDialog(context, authService),
            ),
          const SizedBox(height: 12),
          _AuthButton(
            icon: Icons.code,
            label: 'Continuer avec GitHub',
            color: Colors.white,
            onPressed: () async {
              final result = await authService.signInWithGitHubV2();
              if (!context.mounted) {
                return;
              }

              result.fold(
                onSuccess: (oauthData) {
                  _showGitHubOAuthDialog(
                    context,
                    authService,
                    oauthData.authUrl,
                    oauthData.state,
                  );
                },
                onFailure: (error) {
                  GxNotificationService().showError(
                    title: 'Erreur',
                    message: error.message,
                    context: context,
                    duration: const Duration(seconds: 5),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEmailAuthDialog(
      BuildContext context, FirebaseAuthService authService) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSignUp = false;
    bool isLoading = false;
    final accentColor = Provider.of<ColorThemeManager>(context, listen: false)
        .nativeSecondaryColor;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => GxFuturisticDialog(
          title: isSignUp ? 'Créer un compte' : 'Se connecter',
          titleIcon: Icons.email_rounded,
          accentColor: accentColor,
          width: 420,
          actions: [
            GxFuturisticButton(
              label: 'Annuler',
              variant: GxFuturisticButtonVariant.secondary,
              accentColor: accentColor,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Utilisez votre email et mot de passe',
                  style: NotilusFonts.rajdhani(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                GxFuturisticButton(
                  label: isLoading
                      ? '...'
                      : (isSignUp ? 'Créer un compte' : 'Se connecter'),
                  icon: isLoading ? null : Icons.login_rounded,
                  variant: GxFuturisticButtonVariant.primary,
                  accentColor: accentColor,
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isLoading = true);

                            final result = isSignUp
                                ? await authService
                                    .createUserWithEmailAndPassword(
                                    emailController.text.trim(),
                                    passwordController.text,
                                  )
                                : await authService.signInWithEmailAndPassword(
                                    emailController.text.trim(),
                                    passwordController.text,
                                  );

                            setState(() => isLoading = false);

                            if (result != null && context.mounted) {
                              Navigator.of(context)
                                  .pop(); // Fermer le dialog email
                              Navigator.of(context)
                                  .pop(true); // Fermer le dialog principal
                            } else if (context.mounted) {
                              GxNotificationService().showError(
                                title: 'Erreur',
                                message: isSignUp
                                    ? 'Erreur lors de la création du compte'
                                    : 'Email ou mot de passe incorrect',
                                context: context,
                              );
                            }
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => isSignUp = !isSignUp),
                  child: Text(
                    isSignUp
                        ? 'Déjà un compte ? Se connecter'
                        : 'Pas de compte ? Créer un compte',
                    style: NotilusFonts.rajdhani(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGoogleDeviceFlowDialog(
    BuildContext context,
    FirebaseAuthService authService,
    GoogleDeviceFlow deviceFlow,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GoogleDeviceFlowDialog(
        authService: authService,
        deviceFlow: deviceFlow,
      ),
    );
  }

  void _showGitHubOAuthDialog(
    BuildContext context,
    FirebaseAuthService authService,
    String authUrl,
    String state,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Ne pas permettre de fermer pendant l'auth
      builder: (dialogContext) => _GitHubOAuthDialog(
        authService: authService,
        authUrl: authUrl,
        state: state,
        onTabOpened: () {
          // Appeler le callback pour fermer le panel de paramètres
          onAuthStarted?.call();
          // NE PAS fermer le dialog ici - il se fermera automatiquement quand l'auth réussit
        },
        onAuthSuccess: () {
          // Fermer les dialogs seulement quand l'auth réussit
          Navigator.of(dialogContext).pop(); // Fermer le dialog GitHub
          Navigator.of(dialogContext).pop(true); // Fermer le dialog principal
        },
      ),
    );
  }
}

class _GoogleDeviceFlowDialog extends StatefulWidget {
  final FirebaseAuthService authService;
  final GoogleDeviceFlow deviceFlow;

  const _GoogleDeviceFlowDialog({
    required this.authService,
    required this.deviceFlow,
  });

  @override
  State<_GoogleDeviceFlowDialog> createState() =>
      _GoogleDeviceFlowDialogState();
}

class _GoogleDeviceFlowDialogState extends State<_GoogleDeviceFlowDialog> {
  Timer? _pollTimer;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _openVerificationUrl();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _openVerificationUrl() {
    // Ouvrir l'URL dans un nouvel onglet Notilus au lieu d'un navigateur externe
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: widget.deviceFlow.verificationUriComplete);
  }

  void _startPolling() {
    setState(() => _isPolling = true);

    _pollTimer = Timer.periodic(
      Duration(seconds: widget.deviceFlow.interval),
      (timer) async {
        final result = await widget.authService.pollGoogleTokenDeviceFlow(
          widget.deviceFlow.deviceCode,
        );

        if (result != null && mounted) {
          timer.cancel();
          Navigator.of(context).pop(); // Fermer ce dialog
          Navigator.of(context).pop(true); // Fermer le dialog principal
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context).nativeSecondaryColor;

    return Dialog(
      backgroundColor: const Color(0xFF15151A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Authentification Google',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text(
                    'Code de vérification:',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.deviceFlow.userCode,
                    style: TextStyle(
                      color: gxRed,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Ouvrez le lien dans votre navigateur\n'
              '2. Entrez le code ci-dessus\n'
              '3. Autorisez l\'application',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_isPolling) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _pollTimer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GitHubOAuthDialog extends StatefulWidget {
  final FirebaseAuthService authService;
  final String authUrl;
  final String state;
  final VoidCallback? onTabOpened;
  final VoidCallback? onAuthSuccess;

  const _GitHubOAuthDialog({
    required this.authService,
    required this.authUrl,
    required this.state,
    this.onTabOpened,
    this.onAuthSuccess,
  });

  @override
  State<_GitHubOAuthDialog> createState() => _GitHubOAuthDialogState();
}

class _GitHubOAuthDialogState extends State<_GitHubOAuthDialog> {
  bool _tabOpened = false;
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour éviter setState pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openAuthUrl();
      // Le polling est maintenant géré par FirebaseAuthService
      // On écoute juste les changements d'état
      _listenToAuthChanges();
    });
  }

  void _listenToAuthChanges() {
    _authListener = () {
      if (!mounted) return;
      if (widget.authService.isAnySignedIn) {
        widget.onAuthSuccess?.call();
      }
    };
    widget.authService.addListener(_authListener!);
  }

  @override
  void dispose() {
    if (_authListener != null) {
      widget.authService.removeListener(_authListener!);
      _authListener = null;
    }
    widget.authService.stopGitHubPolling(widget.state);
    // Le polling est géré par le service, pas besoin d'annuler ici
    super.dispose();
  }

  void _openAuthUrl() {
    if (_tabOpened) return;
    _tabOpened = true;

    // Ouvrir dans un nouvel onglet Notilus au lieu du navigateur externe
    final tabManager = Provider.of<TabManager>(context, listen: false);
    tabManager.addTab(url: widget.authUrl);

    // Fermer les dialogs et le panel de paramètres après un court délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onTabOpened?.call();
      }
    });
  }

  // Le polling est maintenant géré par FirebaseAuthService
  // Cette méthode n'est plus nécessaire

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF15151A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Authentification GitHub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Un nouvel onglet Notilus va s\'ouvrir.\n'
              'Connectez-vous avec GitHub et autorisez l\'application.\n'
              'Le dialog se fermera automatiquement une fois l\'authentification réussie.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Arrêter le polling dans le service
                    widget.authService.stopGitHubPolling(widget.state);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annuler',
                      style: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }
}
