/// Panneau Interaction Recorder pour Notilus Studio
/// Enregistre les interactions et génère du code de test
library interaction_recorder_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/studio/studio_service.dart';
import '../../services/studio/interaction_recorder_service.dart';
import '../../models/studio/studio_models.dart';
import '../../core/services/color_theme_manager.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/gx_notification_service.dart';

/// Panneau Interaction Recorder
class InteractionRecorderPanel extends StatefulWidget {
  const InteractionRecorderPanel({super.key});

  @override
  State<InteractionRecorderPanel> createState() => _InteractionRecorderPanelState();
}

class _InteractionRecorderPanelState extends State<InteractionRecorderPanel> {
  String _selectedExport = 'playwright';

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<StudioService>(
      builder: (context, studioService, _) {
        final recorder = studioService.interactionRecorder;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 1000;
            final isVeryCompact = constraints.maxWidth < 600;
            
            if (isVeryCompact) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      child: _buildControlsPanel(recorder, accentColor),
                    ),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      child: _buildTimelinePanel(recorder, accentColor),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: _buildExportPanel(recorder, accentColor),
                    ),
                  ],
                ),
              );
            }
            
            if (isCompact) {
              return Row(
                children: [
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    child: _buildControlsPanel(recorder, accentColor),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildTimelinePanel(recorder, accentColor),
                        ),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                          ),
                          child: _buildExportPanel(recorder, accentColor),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            
            return Row(
              children: [
                // Controls panel
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: _buildControlsPanel(recorder, accentColor),
                ),
                // Timeline
                Expanded(
                  child: _buildTimelinePanel(recorder, accentColor),
                ),
                // Export panel
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: _buildExportPanel(recorder, accentColor),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlsPanel(InteractionRecorderService recorder, Color accentColor) {
    return Column(
      children: [
        // Recording status
        _buildRecordingStatus(recorder, accentColor),
        const SizedBox(height: 16),
        // Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildMainButton(recorder, accentColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      icon: CupertinoIcons.pause,
                      label: 'Pause',
                      onPressed: recorder.isRecording ? recorder.pauseRecording : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SecondaryButton(
                      icon: CupertinoIcons.trash,
                      label: 'Effacer',
                      onPressed: recorder.currentSession != null ? recorder.clearRecording : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Options
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildOptions(recorder, accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingStatus(InteractionRecorderService recorder, Color accentColor) {
    final isRecording = recorder.isRecording;
    final duration = recorder.recordingDuration;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isRecording
            ? LinearGradient(
                colors: [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.05)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        border: Border(
          bottom: BorderSide(
            color: isRecording ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          // Recording indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecording ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isRecording ? Colors.red : Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Center(
              child: isRecording
                  ? _PulsingDot(color: Colors.red)
                  : Icon(
                      CupertinoIcons.circle_fill,
                      size: 32,
                      color: Colors.white.withOpacity(0.3),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Duration
          Text(
            _formatDuration(duration),
            style: TextStyle(
              color: isRecording ? Colors.red : Colors.white.withOpacity(0.5),
              fontSize: 32,
              fontWeight: FontWeight.w300,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 8),
          // Status text
          Text(
            isRecording
                ? '${recorder.eventCount} événements enregistrés'
                : recorder.currentSession != null
                    ? 'Enregistrement en pause'
                    : 'Prêt à enregistrer',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(InteractionRecorderService recorder, Color accentColor) {
    final isRecording = recorder.isRecording;
    final hasSession = recorder.currentSession != null;

    if (isRecording) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: recorder.stopRecording,
          icon: const Icon(CupertinoIcons.stop_fill, size: 18),
          label: const Text('Arrêter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    if (hasSession && !isRecording) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: recorder.resumeRecording,
          icon: const Icon(CupertinoIcons.play_fill, size: 18),
          label: const Text('Reprendre'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: recorder.startRecording,
        icon: const Icon(CupertinoIcons.circle_fill, size: 14, color: Colors.red),
        label: const Text('Démarrer l\'enregistrement'),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildOptions(InteractionRecorderService recorder, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPTIONS D\'ENREGISTREMENT',
          style: TextStyle(
            color: accentColor.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _OptionToggle(
          label: 'Enregistrer les clics',
          value: recorder.recordClicks,
          onChanged: recorder.setRecordClicks,
          accentColor: accentColor,
        ),
        _OptionToggle(
          label: 'Enregistrer la saisie',
          value: recorder.recordTyping,
          onChanged: recorder.setRecordTyping,
          accentColor: accentColor,
        ),
        _OptionToggle(
          label: 'Enregistrer le scroll',
          value: recorder.recordScrolls,
          onChanged: recorder.setRecordScrolls,
          accentColor: accentColor,
        ),
        _OptionToggle(
          label: 'Enregistrer le hover',
          value: recorder.recordHovers,
          onChanged: recorder.setRecordHovers,
          accentColor: accentColor,
        ),
        _OptionToggle(
          label: 'Enregistrer la navigation',
          value: recorder.recordNavigation,
          onChanged: recorder.setRecordNavigation,
          accentColor: accentColor,
        ),
        const Divider(height: 24),
        _OptionToggle(
          label: 'Masquer les mots de passe',
          value: recorder.maskPasswords,
          onChanged: recorder.setMaskPasswords,
          accentColor: accentColor,
        ),
        const SizedBox(height: 24),
        Text(
          'ACTIONS MANUELLES',
          style: TextStyle(
            color: accentColor.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: CupertinoIcons.checkmark_shield,
          label: 'Ajouter une assertion',
          onPressed: recorder.isRecording
              ? () => _showAssertionDialog(context, recorder, accentColor)
              : null,
        ),
        _ActionButton(
          icon: CupertinoIcons.camera,
          label: 'Ajouter une capture',
          onPressed: recorder.isRecording ? recorder.addScreenshot : null,
        ),
        _ActionButton(
          icon: CupertinoIcons.timer,
          label: 'Ajouter une attente',
          onPressed: recorder.isRecording
              ? () => _showWaitDialog(context, recorder, accentColor)
              : null,
        ),
      ],
    );
  }

  Widget _buildTimelinePanel(InteractionRecorderService recorder, Color accentColor) {
    final interactions = recorder.interactions;

    if (interactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.time,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Timeline vide',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Démarrez un enregistrement pour\ncapturer vos interactions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.list_bullet, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Timeline (${interactions.length} événements)',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Events list
        Expanded(
          child: ListView.builder(
            itemCount: interactions.length,
            itemBuilder: (context, index) {
              final interaction = interactions[index];
              return _EventRow(
                interaction: interaction,
                accentColor: accentColor,
                onDelete: () => recorder.removeInteraction(interaction.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExportPanel(InteractionRecorderService recorder, Color accentColor) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.arrow_up_doc, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Export',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Format selector
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FORMAT',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ExportFormatChip(
                    label: 'Playwright',
                    isSelected: _selectedExport == 'playwright',
                    accentColor: accentColor,
                    onTap: () => setState(() => _selectedExport = 'playwright'),
                  ),
                  _ExportFormatChip(
                    label: 'Cypress',
                    isSelected: _selectedExport == 'cypress',
                    accentColor: accentColor,
                    onTap: () => setState(() => _selectedExport = 'cypress'),
                  ),
                  _ExportFormatChip(
                    label: 'Puppeteer',
                    isSelected: _selectedExport == 'puppeteer',
                    accentColor: accentColor,
                    onTap: () => setState(() => _selectedExport = 'puppeteer'),
                  ),
                  _ExportFormatChip(
                    label: 'Selenium',
                    isSelected: _selectedExport == 'selenium',
                    accentColor: accentColor,
                    onTap: () => setState(() => _selectedExport = 'selenium'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Code preview
        Expanded(
          child: _buildCodePreview(recorder, accentColor),
        ),
        // Export button
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: recorder.currentSession != null
                  ? () => _copyCode(recorder, accentColor)
                  : null,
              icon: const Icon(CupertinoIcons.doc_on_doc, size: 14),
              label: const Text('Copier le code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodePreview(InteractionRecorderService recorder, Color accentColor) {
    String code = '';

    if (recorder.currentSession != null) {
      switch (_selectedExport) {
        case 'playwright':
          code = recorder.exportPlaywright();
          break;
        case 'cypress':
          code = recorder.exportCypress();
          break;
        case 'puppeteer':
          code = recorder.exportPuppeteer();
          break;
        case 'selenium':
          code = recorder.exportSelenium();
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: code.isEmpty
          ? Center(
              child: Text(
                'Aucun code à exporter',
                style: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(
                code,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _copyCode(InteractionRecorderService recorder, Color accentColor) {
    String code = '';

    switch (_selectedExport) {
      case 'playwright':
        code = recorder.exportPlaywright();
        break;
      case 'cypress':
        code = recorder.exportCypress();
        break;
      case 'puppeteer':
        code = recorder.exportPuppeteer();
        break;
      case 'selenium':
        code = recorder.exportSelenium();
        break;
    }

    Clipboard.setData(ClipboardData(text: code));
    GxNotificationService().showSuccess(
      title: 'Copié',
      message: 'Code ${_selectedExport.toUpperCase()} copié',
      context: context,
    );
  }

  void _showAssertionDialog(
    BuildContext context,
    InteractionRecorderService recorder,
    Color accentColor,
  ) {
    final selectorController = TextEditingController();
    final textController = TextEditingController();

    GxFuturisticDialog.show(
      context: context,
      title: 'Ajouter une assertion',
      titleIcon: CupertinoIcons.checkmark_circle_fill,
      accentColor: accentColor,
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GxFuturisticInput(
            controller: selectorController,
            label: 'Sélecteur CSS',
            hint: '#my-element',
            prefixIcon: Icons.code,
            accentColor: accentColor,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          GxFuturisticInput(
            controller: textController,
            label: 'Texte attendu (optionnel)',
            hint: 'Texte à vérifier',
            prefixIcon: CupertinoIcons.textformat,
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
          label: 'Ajouter',
          icon: CupertinoIcons.check_mark,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: accentColor,
          onPressed: () {
            recorder.addAssertion(
              selectorController.text,
              expectedText: textController.text.isNotEmpty ? textController.text : null,
            );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showWaitDialog(
    BuildContext context,
    InteractionRecorderService recorder,
    Color accentColor,
  ) {
    int seconds = 1;

    GxFuturisticDialog.show(
      context: context,
      title: 'Ajouter une attente',
      titleIcon: CupertinoIcons.time,
      accentColor: accentColor,
      width: 450,
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$seconds seconde(s)',
              style: NotilusFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            GxFuturisticSlider(
              value: seconds.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              accentColor: accentColor,
              onChanged: (v) => setState(() => seconds = v.round()),
            ),
          ],
        ),
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: accentColor,
          onPressed: () => Navigator.pop(context),
        ),
        GxFuturisticButton(
          label: 'Ajouter',
          icon: CupertinoIcons.check_mark,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: accentColor,
          onPressed: () {
            recorder.addWait(Duration(seconds: seconds));
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 16 + (_controller.value * 8),
          height: 16 + (_controller.value * 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.8 - (_controller.value * 0.3)),
          ),
        );
      },
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.7),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

class _OptionToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;

  const _OptionToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withOpacity(onPressed != null ? 0.7 : 0.3),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final RecordedInteraction interaction;
  final Color accentColor;
  final VoidCallback? onDelete;

  const _EventRow({
    required this.interaction,
    required this.accentColor,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.03)),
        ),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 50,
            child: Text(
              interaction.formattedTime,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          // Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(interaction.type.icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 12),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interaction.type.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (interaction.selector != null || interaction.value != null)
                  Text(
                    interaction.selector ?? interaction.value ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Delete
          IconButton(
            icon: Icon(CupertinoIcons.trash, size: 14, color: Colors.white.withOpacity(0.3)),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}

class _ExportFormatChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ExportFormatChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? accentColor : Colors.white.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

