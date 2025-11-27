/// Dialog d'authentification pour Notilus
library auth_dialog;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../services/auth/firebase_auth_service.dart';
import '../../services/auth/local_oauth_service.dart';
import '../../core/services/color_theme_manager.dart';

/// Dialog d'authentification
class AuthDialog extends StatelessWidget {
  final FirebaseAuthService authService;

  const AuthDialog({
    super.key,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final gxRed = Provider.of<ColorThemeManager>(context).nativeSecondaryColor;

    return Dialog(
      backgroundColor: const Color(0xFF15151A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connexion à Notilus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous pour synchroniser vos configurations',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connexion annulée ou échouée'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (e is GoogleDeviceFlowException && context.mounted) {
                      _showGoogleDeviceFlowDialog(context, authService, e.deviceFlow);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
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
                try {
                  final result = await authService.signInWithGitHub();
                  if (result != null && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  if (e is GitHubOAuthUrlException && context.mounted) {
                    _showGitHubOAuthDialog(context, authService, e.authUrl, e.state);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().contains('Backend')
                              ? 'Backend OAuth local non disponible. Démarrez-le avec: cd backend && python main.py'
                              : 'Erreur: ${e.toString()}'
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEmailAuthDialog(BuildContext context, FirebaseAuthService authService) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSignUp = false;
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF15151A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isSignUp ? 'Créer un compte' : 'Se connecter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Utilisez votre email et mot de passe',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
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
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Provider.of<ColorThemeManager>(context).nativeSecondaryColor),
                      ),
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
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Provider.of<ColorThemeManager>(context).nativeSecondaryColor),
                      ),
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
                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        
                        final result = isSignUp
                            ? await authService.createUserWithEmailAndPassword(
                                emailController.text.trim(),
                                passwordController.text,
                              )
                            : await authService.signInWithEmailAndPassword(
                                emailController.text.trim(),
                                passwordController.text,
                              );
                        
                        setState(() => isLoading = false);
                        
                        if (result != null && context.mounted) {
                          Navigator.of(context).pop(); // Fermer le dialog email
                          Navigator.of(context).pop(true); // Fermer le dialog principal
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSignUp
                                  ? 'Erreur lors de la création du compte'
                                  : 'Email ou mot de passe incorrect'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Provider.of<ColorThemeManager>(context).nativeSecondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isSignUp ? 'Créer un compte' : 'Se connecter'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => isSignUp = !isSignUp),
                    child: Text(
                      isSignUp
                          ? 'Déjà un compte ? Se connecter'
                          : 'Pas de compte ? Créer un compte',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ],
              ),
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
      barrierDismissible: false,
      builder: (context) => _GitHubOAuthDialog(
        authService: authService,
        authUrl: authUrl,
        state: state,
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
  State<_GoogleDeviceFlowDialog> createState() => _GoogleDeviceFlowDialogState();
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
  
  void _openVerificationUrl() async {
    final uri = Uri.parse(widget.deviceFlow.verificationUriComplete);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
            if (_isPolling)
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _pollTimer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
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
  
  const _GitHubOAuthDialog({
    required this.authService,
    required this.authUrl,
    required this.state,
  });
  
  @override
  State<_GitHubOAuthDialog> createState() => _GitHubOAuthDialogState();
}

class _GitHubOAuthDialogState extends State<_GitHubOAuthDialog> {
  Timer? _pollTimer;
  bool _isPolling = false;
  
  @override
  void initState() {
    super.initState();
    _openAuthUrl();
    _startPolling();
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
  
  void _openAuthUrl() async {
    final uri = Uri.parse(widget.authUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  void _startPolling() {
    setState(() => _isPolling = true);
    
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        final result = await widget.authService.getGitHubTokenAfterAuth(
          widget.state,
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
              'Une fenêtre de votre navigateur va s\'ouvrir.\n'
              'Connectez-vous avec GitHub et autorisez l\'application.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_isPolling)
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _pollTimer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
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

