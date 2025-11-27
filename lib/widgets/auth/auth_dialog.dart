/// Dialog d'authentification pour Notilus
library auth_dialog;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_fonts.dart';
import '../common/gx_futuristic_dialog.dart';

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
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Authentification GitHub en cours... Vérifiez votre navigateur'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().contains('configuration')
                            ? 'GitHub OAuth nécessite une configuration dans Firebase Console'
                            : 'Erreur lors de la connexion GitHub: ${e.toString()}'
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  void _showEmailAuthDialog(BuildContext context, FirebaseAuthService authService) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSignUp = false;
    bool isLoading = false;
    final accentColor = Provider.of<ColorThemeManager>(context, listen: false).nativeSecondaryColor;
    
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
                      borderSide: BorderSide(color: accentColor),
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
                      borderSide: BorderSide(color: accentColor),
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
                GxFuturisticButton(
                  label: isLoading ? '...' : (isSignUp ? 'Créer un compte' : 'Se connecter'),
                  icon: isLoading ? null : Icons.login_rounded,
                  variant: GxFuturisticButtonVariant.primary,
                  accentColor: accentColor,
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

