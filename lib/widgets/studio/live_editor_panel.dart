/// Panneau Live Editor pour Notilus Studio
/// Édition en temps réel du HTML/CSS
library live_editor_panel;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/studio/studio_service.dart';
import '../../services/studio/live_editor_service.dart';
import '../../models/studio/studio_models.dart';
import '../../core/services/color_theme_manager.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/gx_futuristic_components.dart';
import '../../services/gx_notification_service.dart';

/// Panneau Live Editor
class LiveEditorPanel extends StatefulWidget {
  const LiveEditorPanel({super.key});

  @override
  State<LiveEditorPanel> createState() => _LiveEditorPanelState();
}

class _LiveEditorPanelState extends State<LiveEditorPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cssController = TextEditingController();
  final TextEditingController _htmlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cssController.dispose();
    _htmlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<StudioService>(
      builder: (context, studioService, _) {
        final editor = studioService.liveEditor;
        
        // Écouter les changements du service liveEditor en temps réel
        return ListenableBuilder(
          listenable: editor,
          builder: (context, _) {
            // Vérifier que le moteur est attaché
            if (studioService.engine == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 48,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune page chargée',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ouvrez une page web pour utiliser l\'éditeur live',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 800;
            final isVeryCompact = constraints.maxWidth < 500;
            
            if (isVeryCompact) {
              return Column(
                children: [
                  Expanded(
                    child: _buildInspectorPanel(editor, accentColor),
                  ),
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.05),
                  ),
                  Expanded(
                    child: _buildEditorPanel(editor, accentColor),
                  ),
                ],
              );
            } else if (isCompact) {
              return Row(
                children: [
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    child: _buildInspectorPanel(editor, accentColor),
                  ),
                  Expanded(
                    child: _buildEditorPanel(editor, accentColor),
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  // Element Inspector
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    child: _buildInspectorPanel(editor, accentColor),
                  ),
                  // Editor Panel
                  Expanded(
                    child: _buildEditorPanel(editor, accentColor),
                  ),
                  // History Panel
                  Container(
                    width: 250,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    child: _buildHistoryPanel(editor, accentColor),
                  ),
                ],
              );
            }
          },
        );
            },
          );
      },
    );
  }

  Widget _buildInspectorPanel(LiveEditorService editor, Color accentColor) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.eye, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Inspecteur',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _InspectToggle(
                isActive: editor.isInspecting,
                accentColor: accentColor,
                onToggle: editor.toggleInspection,
              ),
            ],
          ),
        ),
        // Selected element info
        Expanded(
          child: editor.selectedSelector == null
              ? _buildNoSelection(accentColor)
              : _buildElementInfo(editor, accentColor),
        ),
      ],
    );
  }

  Widget _buildNoSelection(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.cursor_rays,
            size: 32,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun élément sélectionné',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activez le mode inspection ou\nentrez un sélecteur CSS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementInfo(LiveEditorService editor, Color accentColor) {
    final info = editor.selectedElementInfo;
    if (info == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.tag, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    editor.selectedSelector ?? '',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.doc_on_doc, size: 14, color: accentColor),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: editor.selectedSelector ?? ''));
                    GxNotificationService().showSuccess(
                      title: 'Copié',
                      message: 'Sélecteur copié',
                      context: context,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tag info
          _InfoSection(
            title: 'Élément',
            accentColor: accentColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Tag', value: info['tagName'] ?? '-'),
                if (info['id'] != null) _InfoRow(label: 'ID', value: '#${info['id']}'),
                if (info['className'] != null)
                  _InfoRow(label: 'Classes', value: '.${info['className']?.toString().replaceAll(' ', ' .')}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Computed styles
          _InfoSection(
            title: 'Styles calculés',
            accentColor: accentColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info['computedStyles'] != null) ...[
                  for (final entry in (info['computedStyles'] as Map<String, dynamic>).entries.take(10))
                    _StyleRow(
                      property: entry.key,
                      value: entry.value.toString(),
                      accentColor: accentColor,
                      onEdit: (newValue) => editor.editStyle(entry.key, newValue),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Suggestions
          if (editor.suggestions.isNotEmpty) ...[
            _InfoSection(
              title: 'Suggestions',
              accentColor: accentColor,
              child: Column(
                children: editor.suggestions.map((s) => _SuggestionRow(
                  suggestion: s,
                  accentColor: accentColor,
                  onApply: s.suggestedValue != null && s.property != null
                      ? () => editor.editStyle(s.property!, s.suggestedValue!)
                      : null,
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorPanel(LiveEditorService editor, Color accentColor) {
    return Column(
      children: [
        // Tabs
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF131318),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'CSS'),
              Tab(text: 'HTML'),
              Tab(text: 'Attributs'),
            ],
            labelColor: accentColor,
            unselectedLabelColor: Colors.white.withOpacity(0.5),
            indicatorColor: accentColor,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            dividerColor: Colors.transparent,
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCSSEditor(editor, accentColor),
              _buildHTMLEditor(editor, accentColor),
              _buildAttributesEditor(editor, accentColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCSSEditor(LiveEditorService editor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Injecter du CSS personnalisé',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _cssController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: '/* Votre CSS ici */\n\nbody {\n  background: #f0f0f0;\n}',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _cssController.clear(),
                child: Text('Effacer', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final studioService = Provider.of<StudioService>(context, listen: false);
                  if (studioService.engine == null) {
                    GxNotificationService().showError(
                      title: 'Erreur',
                      message: 'Aucune page chargée. Ouvrez une page web d\'abord.',
                      context: context,
                    );
                    return;
                  }
                  await editor.injectCSS(_cssController.text);
                  if (context.mounted) {
                    GxNotificationService().showSuccess(
                      title: 'Injecté',
                      message: 'CSS injecté',
                      context: context,
                    );
                  }
                },
                icon: const Icon(CupertinoIcons.play, size: 14),
                label: const Text('Appliquer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHTMLEditor(LiveEditorService editor, Color accentColor) {
    final html = editor.selectedElementInfo?['outerHTML'] as String? ?? '';
    _htmlController.text = html;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (editor.selectedSelector == null)
            Expanded(
              child: Center(
                child: Text(
                  'Sélectionnez un élément pour éditer son HTML',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
                ),
              ),
            )
          else ...[
            Text(
              'HTML de l\'élément sélectionné',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _htmlController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    editor.editHTML(_htmlController.text);
                    GxNotificationService().showSuccess(
                      title: 'Mis à jour',
                      message: 'HTML mis à jour',
                      context: context,
                    );
                  },
                  icon: const Icon(CupertinoIcons.checkmark, size: 14),
                  label: const Text('Appliquer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttributesEditor(LiveEditorService editor, Color accentColor) {
    final attrs = editor.selectedElementInfo?['attributes'] as Map<String, dynamic>? ?? {};

    if (editor.selectedSelector == null) {
      return Center(
        child: Text(
          'Sélectionnez un élément pour voir ses attributs',
          style: TextStyle(color: Colors.white.withOpacity(0.4)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: attrs.entries.map((attr) => _AttributeRow(
          name: attr.key,
          value: attr.value.toString(),
          accentColor: accentColor,
          onEdit: (newValue) => editor.editAttribute(attr.key, newValue),
        )).toList(),
      ),
    );
  }

  Widget _buildHistoryPanel(LiveEditorService editor, Color accentColor) {
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
              Icon(CupertinoIcons.clock, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Historique (${editor.activeChangeCount})',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  final css = editor.exportCSS();
                  Clipboard.setData(ClipboardData(text: css));
                  GxNotificationService().showSuccess(
                    title: 'Exporté',
                    message: 'CSS exporté',
                    context: context,
                  );
                },
                icon: Icon(CupertinoIcons.arrow_up_doc, size: 12, color: accentColor),
                label: Text('Export', style: TextStyle(fontSize: 11, color: accentColor)),
              ),
            ],
          ),
        ),
        // Changes list
        Expanded(
          child: editor.changes.isEmpty
              ? Center(
                  child: Text(
                    'Aucune modification',
                    style: TextStyle(color: Colors.white.withOpacity(0.3)),
                  ),
                )
              : ListView.builder(
                  itemCount: editor.changes.length,
                  itemBuilder: (context, index) {
                    final change = editor.changes[editor.changes.length - 1 - index];
                    return _ChangeRow(
                      change: change,
                      accentColor: accentColor,
                      onUndo: () => editor.undoChange(change.id),
                      onRedo: () => editor.redoChange(change.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _InspectToggle extends StatelessWidget {
  final bool isActive;
  final Color accentColor;
  final VoidCallback? onToggle;

  const _InspectToggle({
    required this.isActive,
    required this.accentColor,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.cursor_rays,
              size: 12,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              isActive ? 'Actif' : 'Inspecter',
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;

  const _InfoSection({
    required this.title,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: accentColor.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  final String property;
  final String value;
  final Color accentColor;
  final Function(String) onEdit;

  const _StyleRow({
    required this.property,
    required this.value,
    required this.accentColor,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              property,
              style: TextStyle(
                color: accentColor.withOpacity(0.8),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onDoubleTap: () => _showEditDialog(context),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'JetBrains Mono',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: value);
    final accentColor = Provider.of<ColorThemeManager>(context, listen: false).nativeSecondaryColor;
    
    GxFuturisticDialog.show(
      context: context,
      title: 'Éditer $property',
      titleIcon: CupertinoIcons.pencil,
      accentColor: accentColor,
      width: 450,
      child: GxFuturisticInput(
        controller: controller,
        hint: 'Valeur',
        prefixIcon: CupertinoIcons.textformat,
        accentColor: accentColor,
        autofocus: true,
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: accentColor,
          onPressed: () => Navigator.pop(context),
        ),
        GxFuturisticButton(
          label: 'Appliquer',
          icon: CupertinoIcons.check_mark,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: accentColor,
          onPressed: () {
            onEdit(controller.text);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final EditorSuggestion suggestion;
  final Color accentColor;
  final VoidCallback? onApply;

  const _SuggestionRow({
    required this.suggestion,
    required this.accentColor,
    this.onApply,
  });

  IconData get _icon {
    switch (suggestion.type) {
      case SuggestionType.warning:
        return CupertinoIcons.exclamationmark_triangle;
      case SuggestionType.error:
        return CupertinoIcons.xmark_circle;
      case SuggestionType.accessibility:
        return CupertinoIcons.person_2;
      case SuggestionType.performance:
        return CupertinoIcons.speedometer;
      default:
        return CupertinoIcons.info;
    }
  }

  Color get _color {
    switch (suggestion.type) {
      case SuggestionType.warning:
        return Colors.orange;
      case SuggestionType.error:
        return Colors.red;
      default:
        return accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              suggestion.message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ),
          if (onApply != null)
            TextButton(
              onPressed: onApply,
              child: Text('Fix', style: TextStyle(fontSize: 10, color: _color)),
            ),
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final String name;
  final String value;
  final Color accentColor;
  final Function(String) onEdit;

  const _AttributeRow({
    required this.name,
    required this.value,
    required this.accentColor,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            name,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(width: 8),
          const Text('=', style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onDoubleTap: () => _showEditDialog(context),
              child: Text(
                '"$value"',
                style: TextStyle(
                  color: Colors.green.shade300,
                  fontSize: 11,
                  fontFamily: 'JetBrains Mono',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: Icon(CupertinoIcons.pencil, size: 12, color: Colors.white.withOpacity(0.3)),
            onPressed: () => _showEditDialog(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: value);
    final accentColor = Provider.of<ColorThemeManager>(context, listen: false).nativeSecondaryColor;
    
    GxFuturisticDialog.show(
      context: context,
      title: 'Éditer $name',
      titleIcon: CupertinoIcons.pencil,
      accentColor: accentColor,
      width: 450,
      child: GxFuturisticInput(
        controller: controller,
        hint: 'Valeur',
        prefixIcon: CupertinoIcons.textformat,
        accentColor: accentColor,
        autofocus: true,
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: accentColor,
          onPressed: () => Navigator.pop(context),
        ),
        GxFuturisticButton(
          label: 'Appliquer',
          icon: CupertinoIcons.check_mark,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: accentColor,
          onPressed: () {
            onEdit(controller.text);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final EditChange change;
  final Color accentColor;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const _ChangeRow({
    required this.change,
    required this.accentColor,
    this.onUndo,
    this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: change.isReverted ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.03)),
            left: BorderSide(color: change.type.color, width: 3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    change.displayText,
                    style: TextStyle(
                      color: change.isReverted ? Colors.white38 : Colors.white,
                      fontSize: 11,
                      fontFamily: 'JetBrains Mono',
                      decoration: change.isReverted ? TextDecoration.lineThrough : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    change.selector,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                change.isReverted ? CupertinoIcons.arrow_clockwise : CupertinoIcons.arrow_uturn_left,
                size: 12,
                color: Colors.white.withOpacity(0.4),
              ),
              onPressed: change.isReverted ? onRedo : onUndo,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
      ),
    );
  }
}

