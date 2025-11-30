import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../services/text_selection_service.dart';
import 'text_selection_menu.dart';

/// Wrapper pour détecter les sélections de texte et afficher le menu flottant
class TextSelectionWrapper extends StatefulWidget {
  final Widget child;

  const TextSelectionWrapper({
    super.key,
    required this.child,
  });

  @override
  State<TextSelectionWrapper> createState() => _TextSelectionWrapperState();
}

class _TextSelectionWrapperState extends State<TextSelectionWrapper> {
  final TextSelectionService _selectionService = TextSelectionService();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _selectionService.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    _selectionService.removeListener(_onSelectionChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onSelectionChanged() {
    debugPrint('🔄 _onSelectionChanged: visible=${_selectionService.isVisible}');
    if (_selectionService.isVisible) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    debugPrint('📌 _showOverlay appelé');
    _removeOverlay();
    final overlayState = Overlay.of(context);
    if (overlayState != null && mounted) {
      debugPrint('✅ OverlayState trouvé, insertion du menu');
      _overlayEntry = OverlayEntry(
        builder: (context) => TextSelectionMenu(),
      );
      overlayState.insert(_overlayEntry!);
      debugPrint('✅ Menu inséré dans l\'overlay');
    } else {
      debugPrint('⚠️ OverlayState null ou widget non monté');
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _selectionService,
      child: GestureDetector(
        onTapDown: (details) {
          // Ne pas cacher immédiatement, laisser le menu s'afficher d'abord
          // Le menu se cachera automatiquement si on clique sur le bouton fermer
        },
        child: widget.child,
      ),
    );
  }
}

/// Contrôles de sélection de texte personnalisés pour afficher le menu flottant
class CustomTextSelectionControls extends MaterialTextSelectionControls {
  final TextSelectionService _selectionService = TextSelectionService();

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    // Récupérer le texte sélectionné
    final text = delegate.textEditingValue.text;
    final selection = delegate.textEditingValue.selection;
    
    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      
      // Calculer la position du menu
      final screenSize = MediaQuery.of(context).size;
      final position = Offset(
        selectionMidpoint.dx.clamp(0.0, screenSize.width - 200),
        (globalEditableRegion.top + selectionMidpoint.dy - 50).clamp(0.0, screenSize.height - 100),
      );
      
      // Afficher le menu via le service
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectionService.showMenu(selectedText, position);
      });
    }
    
    // Retourner un widget vide car on utilise notre propre menu
    return const SizedBox.shrink();
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) => true;

  @override
  bool canCopy(TextSelectionDelegate delegate) => true;

  @override
  bool canCut(TextSelectionDelegate delegate) => true;

  @override
  bool canPaste(TextSelectionDelegate delegate) => true;

  @override
  void handleCopy(TextSelectionDelegate delegate) {
    final text = delegate.textEditingValue.text;
    final selection = delegate.textEditingValue.selection;
    if (selection.isValid && !selection.isCollapsed) {
      Clipboard.setData(ClipboardData(
        text: text.substring(selection.start, selection.end),
      ));
    }
  }

  @override
  void handleCut(TextSelectionDelegate delegate) {
    handleCopy(delegate);
    final text = delegate.textEditingValue.text;
    final selection = delegate.textEditingValue.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final newText = text.replaceRange(selection.start, selection.end, '');
      delegate.userUpdateTextEditingValue(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start),
        ),
        SelectionChangedCause.keyboard,
      );
    }
  }

  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      final text = delegate.textEditingValue.text;
      final selection = delegate.textEditingValue.selection;
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        clipboardData.text!,
      );
      delegate.userUpdateTextEditingValue(
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.start + clipboardData.text!.length,
          ),
        ),
        SelectionChangedCause.keyboard,
      );
    }
  }

  @override
  void handleSelectAll(TextSelectionDelegate delegate) {
    final text = delegate.textEditingValue.text;
    delegate.userUpdateTextEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        ),
      ),
      SelectionChangedCause.keyboard,
    );
  }
}

/// Widget wrapper pour SelectableText qui affiche le menu flottant
class SelectableTextWithMenu extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextSelectionControls? selectionControls;

  const SelectableTextWithMenu({
    super.key,
    required this.data,
    this.style,
    this.textAlign,
    this.maxLines,
    this.selectionControls,
  });

  @override
  Widget build(BuildContext context) {
    final selectionService = Provider.of<TextSelectionService>(context, listen: false);
    final customControls = selectionControls ?? CustomTextSelectionControls();
    
    return SelectableText(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      selectionControls: customControls,
      onSelectionChanged: (selection, cause) {
        if (selection.isValid && !selection.isCollapsed) {
          final selectedText = data.substring(selection.start, selection.end);
          // Calculer la position approximative
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final position = renderBox.localToGlobal(Offset.zero);
            selectionService.showMenu(selectedText, position);
          }
        } else {
          selectionService.hideMenu();
        }
      },
    );
  }
}

