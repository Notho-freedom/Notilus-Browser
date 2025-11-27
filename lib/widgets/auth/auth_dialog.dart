/// Dialog d'authentification pour Notilus
library auth_dialog;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/auth/firebase_auth_service.dart';
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
            _AuthButton(
              icon: CupertinoIcons.logo_google,
              label: 'Continuer avec Google',
              color: Colors.blue,
              onPressed: () async {
                final result = await authService.signInWithGoogle();
                if (result != null && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            const SizedBox(height: 12),
            _AuthButton(
              icon: CupertinoIcons.logo_github,
              label: 'Continuer avec GitHub',
              color: Colors.white,
              onPressed: () async {
                final result = await authService.signInWithGitHub();
                if (result != null && context.mounted) {
                  Navigator.of(context).pop(true);
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

