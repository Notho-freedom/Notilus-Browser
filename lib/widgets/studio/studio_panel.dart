/// Panneau principal de Notilus Studio
/// Interface unifiée pour tous les outils de test front-end
library studio_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/studio/studio_service.dart';
import '../../core/services/color_theme_manager.dart';
import 'responsive_tester_panel.dart';
import 'screenshot_panel.dart';
import 'live_editor_panel.dart';
import 'interaction_recorder_panel.dart';

/// Panneau principal de Studio
class StudioPanel extends StatefulWidget {
  final VoidCallback? onClose;

  const StudioPanel({super.key, this.onClose});

  @override
  State<StudioPanel> createState() => _StudioPanelState();
}

class _StudioPanelState extends State<StudioPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_StudioTab> _tabs = [
    _StudioTab(
      module: StudioModule.responsive,
      icon: CupertinoIcons.device_phone_portrait,
      label: 'Responsive',
    ),
    _StudioTab(
      module: StudioModule.screenshot,
      icon: CupertinoIcons.camera,
      label: 'Screenshot',
    ),
    _StudioTab(
      module: StudioModule.liveEditor,
      icon: CupertinoIcons.pencil,
      label: 'Live Edit',
    ),
    _StudioTab(
      module: StudioModule.interactionRecorder,
      icon: CupertinoIcons.circle_fill,
      label: 'Recorder',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        border: Border(
          top: BorderSide(color: accentColor.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(accentColor),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                ResponsiveTesterPanel(),
                ScreenshotPanel(),
                LiveEditorPanel(),
                InteractionRecorderPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(
          bottom: BorderSide(color: accentColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.paintbrush, size: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Notilus Studio',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 24, color: Colors.white.withOpacity(0.1)),

          // Tabs
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: accentColor, width: 2),
                ),
              ),
              labelColor: accentColor,
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              dividerColor: Colors.transparent,
              tabs: _tabs.map((tab) => Tab(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 14),
                    const SizedBox(width: 6),
                    Text(tab.label),
                  ],
                ),
              )).toList(),
            ),
          ),

          // Actions
          _ActionButton(
            icon: CupertinoIcons.question_circle,
            tooltip: 'Aide',
            accentColor: accentColor,
            onPressed: () {},
          ),
          _ActionButton(
            icon: CupertinoIcons.xmark,
            tooltip: 'Fermer',
            accentColor: accentColor,
            onPressed: widget.onClose,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _StudioTab {
  final StudioModule module;
  final IconData icon;
  final String label;

  const _StudioTab({
    required this.module,
    required this.icon,
    required this.label,
  });
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.accentColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
        ),
      ),
    );
  }
}

