/// Panel de test pour les composants futuristes GX
library gx_test_panel;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../core/services/color_theme_manager.dart';
import '../../services/gx_notification_service.dart';
import 'gx_futuristic_components.dart';
import 'gx_futuristic_dialog.dart';

/// Panel de test des composants futuristes
class GxTestPanel extends StatefulWidget {
  const GxTestPanel({super.key});

  @override
  State<GxTestPanel> createState() => _GxTestPanelState();
}

class _GxTestPanelState extends State<GxTestPanel> {
  final TextEditingController _inputController = TextEditingController();
  bool _switchValue = false;
  double _progressValue = 0.65;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NotilusColors.getSecondaryColor(context);

    return Container(
      color: NotilusColors.getNativeBackgroundColor(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    border: Border.all(
                      color: accentColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.science_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel de Test GX',
                      style: NotilusFonts.orbitron(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Testez tous les composants futuristes',
                      style: NotilusFonts.rajdhani(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Cards
            _buildSection(
              context,
              'Cartes Futuristes',
              accentColor,
              [
                GxFuturisticCard(
                  title: 'Carte Simple',
                  titleIcon: Icons.card_giftcard_rounded,
                  accentColor: accentColor,
                  child: Text(
                    'Ceci est une carte futuriste avec contours géométriques.',
                    style: NotilusFonts.rajdhani(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GxFuturisticCard(
                  title: 'Carte Interactive',
                  titleIcon: Icons.touch_app_rounded,
                  accentColor: accentColor,
                  onTap: () {
                    GxNotificationService().showInfo(
                      title: 'Carte cliquée',
                      message: 'Vous avez cliqué sur la carte',
                      context: context,
                    );
                  },
                  child: Text(
                    'Cliquez sur cette carte pour voir une notification.',
                    style: NotilusFonts.rajdhani(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),

            // Inputs
            _buildSection(
              context,
              'Champs de Saisie',
              accentColor,
              [
                GxFuturisticInput(
                  controller: _inputController,
                  hint: 'Tapez quelque chose...',
                  label: 'Champ de texte',
                  prefixIcon: Icons.edit_rounded,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
                GxFuturisticInput(
                  hint: 'Email',
                  label: 'Email',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  accentColor: accentColor,
                ),
              ],
            ),

            // Badges
            _buildSection(
              context,
              'Badges',
              accentColor,
              [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    GxFuturisticBadge(
                      label: 'Succès',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF22C55E),
                      glow: true,
                    ),
                    GxFuturisticBadge(
                      label: 'Erreur',
                      icon: Icons.error_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                    GxFuturisticBadge(
                      label: 'Avertissement',
                      icon: Icons.warning_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    GxFuturisticBadge(
                      label: 'Info',
                      icon: Icons.info_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ],
            ),

            // Switch
            _buildSection(
              context,
              'Interrupteurs',
              accentColor,
              [
                GxFuturisticSwitch(
                  value: _switchValue,
                  onChanged: (value) => setState(() => _switchValue = value),
                  label: 'Activer la fonctionnalité',
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
                GxFuturisticSwitch(
                  value: !_switchValue,
                  onChanged: (value) => setState(() => _switchValue = !value),
                  label: 'Mode avancé',
                  accentColor: accentColor,
                ),
              ],
            ),

            // Progress
            _buildSection(
              context,
              'Barres de Progression',
              accentColor,
              [
                GxFuturisticProgress(
                  value: _progressValue,
                  label: 'Progression',
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
                GxFuturisticProgress(
                  value: 0.3,
                  label: 'Téléchargement',
                  accentColor: const Color(0xFF22C55E),
                ),
                const SizedBox(height: 16),
                GxFuturisticProgress(
                  value: 0.8,
                  label: 'Upload',
                  accentColor: const Color(0xFF3B82F6),
                ),
              ],
            ),

            // Divider
            _buildSection(
              context,
              'Séparateurs',
              accentColor,
              [
                GxFuturisticDivider(accentColor: accentColor),
                GxFuturisticDivider(
                  accentColor: accentColor,
                  height: 2,
                ),
              ],
            ),

            // Buttons
            _buildSection(
              context,
              'Boutons',
              accentColor,
              [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    GxFuturisticButton(
                      label: 'Succès',
                      icon: Icons.check_rounded,
                      variant: GxFuturisticButtonVariant.primary,
                      accentColor: const Color(0xFF22C55E),
                      onPressed: () {
                        GxNotificationService().showSuccess(
                          title: 'Succès !',
                          message: 'Opération réussie',
                          context: context,
                        );
                      },
                    ),
                    GxFuturisticButton(
                      label: 'Erreur',
                      icon: Icons.error_rounded,
                      variant: GxFuturisticButtonVariant.primary,
                      accentColor: const Color(0xFFEF4444),
                      onPressed: () {
                        GxNotificationService().showError(
                          title: 'Erreur',
                          message: 'Une erreur est survenue',
                          context: context,
                        );
                      },
                    ),
                    GxFuturisticButton(
                      label: 'Secondaire',
                      variant: GxFuturisticButtonVariant.secondary,
                      accentColor: accentColor,
                      onPressed: () {
                        GxNotificationService().showInfo(
                          title: 'Information',
                          message: 'Ceci est un bouton secondaire',
                          context: context,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Dialogs
            _buildSection(
              context,
              'Dialogs',
              accentColor,
              [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    GxFuturisticButton(
                      label: 'Ouvrir Dialog',
                      icon: Icons.open_in_new_rounded,
                      variant: GxFuturisticButtonVariant.primary,
                      accentColor: accentColor,
                      onPressed: () {
                        GxFuturisticDialog.show(
                          context: context,
                          title: 'Dialog de Test',
                          titleIcon: Icons.science_rounded,
                          accentColor: accentColor,
                          width: 500,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ceci est un dialog futuriste avec contours géométriques.',
                                style: NotilusFonts.rajdhani(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              GxFuturisticInput(
                                hint: 'Testez un input',
                                accentColor: accentColor,
                              ),
                            ],
                          ),
                          actions: [
                            GxFuturisticButton(
                              label: 'Annuler',
                              variant: GxFuturisticButtonVariant.secondary,
                              accentColor: accentColor,
                              onPressed: () => Navigator.pop(context),
                            ),
                            GxFuturisticButton(
                              label: 'Confirmer',
                              icon: Icons.check_rounded,
                              variant: GxFuturisticButtonVariant.primary,
                              accentColor: accentColor,
                              onPressed: () {
                                Navigator.pop(context);
                                GxNotificationService().showSuccess(
                                  title: 'Confirmé !',
                                  context: context,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Notifications
            _buildSection(
              context,
              'Notifications',
              accentColor,
              [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    GxFuturisticButton(
                      label: 'Notification Succès',
                      icon: Icons.check_circle_rounded,
                      variant: GxFuturisticButtonVariant.primary,
                      accentColor: const Color(0xFF22C55E),
                      onPressed: () {
                        GxNotificationService().showSuccess(
                          title: 'Opération réussie',
                          message: 'Les données ont été sauvegardées avec succès',
                          context: context,
                        );
                      },
                    ),
                    GxFuturisticButton(
                      label: 'Notification Erreur',
                      icon: Icons.error_rounded,
                      variant: GxFuturisticButtonVariant.primary,
                      accentColor: const Color(0xFFEF4444),
                      onPressed: () {
                        GxNotificationService().showError(
                          title: 'Erreur',
                          message: 'Impossible de se connecter au serveur',
                          context: context,
                        );
                      },
                    ),
                    GxFuturisticButton(
                      label: 'Notification Avertissement',
                      icon: Icons.warning_rounded,
                      variant: GxFuturisticButtonVariant.primary,
                      accentColor: const Color(0xFFF59E0B),
                      onPressed: () {
                        GxNotificationService().showWarning(
                          title: 'Attention',
                          message: 'Cette action est irréversible',
                          context: context,
                        );
                      },
                    ),
                    GxFuturisticButton(
                      label: 'Notification Info',
                      icon: Icons.info_rounded,
                      variant: GxFuturisticButtonVariant.primary,
                      accentColor: const Color(0xFF3B82F6),
                      onPressed: () {
                        GxNotificationService().showInfo(
                          title: 'Information',
                          message: 'Nouvelle mise à jour disponible',
                          context: context,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    Color accentColor,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: NotilusFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 32),
      ],
    );
  }
}

