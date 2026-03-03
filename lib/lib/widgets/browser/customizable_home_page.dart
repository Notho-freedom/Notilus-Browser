/// Page d'accueil entièrement personnalisable façon dock
library customizable_home_page;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/home_widget_models.dart';
import '../../services/home_widget_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../core/services/wallpaper_manager.dart';
import '../common/wallpaper_background.dart';
import '../home_widgets/home_widget_base.dart';
import '../home_widgets/server_list_widget.dart';
import '../home_widgets/home_widget_draggable.dart';
import 'home_pages/widget_factory.dart';

class CustomizableHomePage extends StatefulWidget {
  final VoidCallback? onTerminalSelected;

  const CustomizableHomePage({
    super.key,
    this.onTerminalSelected,
  });

  @override
  State<CustomizableHomePage> createState() => _CustomizableHomePageState();
}

class _CustomizableHomePageState extends State<CustomizableHomePage> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<WallpaperManager>(
      builder: (context, wallpaperManager, _) {
        return Stack(
          children: [
            // Fond d'écran
            WallpaperBackground(
              child: Container(),
            ),
            
            // Contenu principal
            Scaffold(
              backgroundColor: Colors.transparent,
              body: Consumer<HomeWidgetService>(
                builder: (context, widgetService, _) {
                  return _buildContent(context, accentColor, widgetService);
                },
              ),
            ),

            // Bouton d'édition
            Positioned(
              top: 16,
              right: 16,
              child: _buildEditButton(context, accentColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, Color accentColor, HomeWidgetService widgetService) {
    final config = widgetService.config;
    final widgets = config.widgets;

    if (widgets.isEmpty) {
      return _buildEmptyState(context, accentColor);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildGrid(context, config, accentColor, widgetService),
    );
  }

  Widget _buildGrid(BuildContext context, HomePageConfig config, Color accentColor, HomeWidgetService widgetService) {
    // Calculer la taille de la grille basée sur les widgets
    final maxX = config.widgets.fold<double>(
      0,
      (max, widget) => (widget.position.dx + widget.size.width) > max
          ? (widget.position.dx + widget.size.width)
          : max,
    );
    final maxY = config.widgets.fold<double>(
      0,
      (max, widget) => (widget.position.dy + widget.size.height) > max
          ? (widget.position.dy + widget.size.height)
          : max,
    );

    final gridWidth = MediaQuery.of(context).size.width - 32;
    final gridHeight = (maxY + 2) * 120; // 120px par cellule

    return Container(
      width: gridWidth,
      height: gridHeight,
      child: Stack(
        children: config.widgets.map((widget) {
          return _buildWidget(context, widget, accentColor, widgetService);
        }).toList(),
      ),
    );
  }

  Widget _buildWidget(BuildContext context, HomeWidget widget, Color accentColor, HomeWidgetService widgetService) {
    final cellSize = 120.0;
    final spacing = widgetService.config.widgetSpacing;
    
    final left = widget.position.dx * (cellSize + spacing);
    final top = widget.position.dy * (cellSize + spacing);
    final width = widget.size.width * cellSize + (widget.size.width - 1) * spacing;
    final height = widget.size.height * cellSize + (widget.size.height - 1) * spacing;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: HomeWidgetDraggable(
        widget: widget,
        isEditMode: _isEditMode,
        onMinimize: () => widgetService.toggleMinimize(widget.id),
        onRemove: () => widgetService.removeWidget(widget.id),
        onSettings: () => _showWidgetSettings(context, widget),
      ),
    );
  }

  Widget _buildWidgetContent(BuildContext context, HomeWidget widget, HomeWidgetService widgetService) {
    return HomeWidgetFactory.buildWidget(
      widget: widget,
      onMinimize: () => widgetService.toggleMinimize(widget.id),
      onRemove: () => widgetService.removeWidget(widget.id),
      onSettings: () => _showWidgetSettings(context, widget),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.widgets_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Page d\'accueil personnalisable',
            style: NotilusFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cliquez sur le bouton + pour ajouter des widgets',
            style: NotilusFonts.rajdhani(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddWidgetDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un widget'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, Color accentColor) {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _isEditMode = !_isEditMode;
        });
      },
      backgroundColor: accentColor,
      child: Icon(_isEditMode ? Icons.check : Icons.edit),
    );
  }

  void _showAddWidgetDialog(BuildContext context) {
    final widgetService = Provider.of<HomeWidgetService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => _AddWidgetDialog(
        onWidgetSelected: (type) {
          final widget = HomeWidget(
            type: type,
            size: WidgetSize.medium,
            position: Offset(0, 0),
          );
          widgetService.addWidget(widget);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showWidgetSettings(BuildContext context, HomeWidget widget) {
    // TODO: Implémenter le dialogue de paramètres
  }
}

class _AddWidgetDialog extends StatelessWidget {
  final Function(HomeWidgetType) onWidgetSelected;

  const _AddWidgetDialog({required this.onWidgetSelected});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context, listen: false);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Dialog(
      backgroundColor: NotilusColors.chromeDark,
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajouter un widget',
              style: NotilusFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: HomeWidgetType.values.length,
                itemBuilder: (context, index) {
                  final type = HomeWidgetType.values[index];
                  return _WidgetTypeCard(
                    type: type,
                    accentColor: accentColor,
                    onTap: () => onWidgetSelected(type),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetTypeCard extends StatelessWidget {
  final HomeWidgetType type;
  final Color accentColor;
  final VoidCallback onTap;

  const _WidgetTypeCard({
    required this.type,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NotilusColors.chromeDark.withOpacity(0.6),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.icon,
              size: 32,
              color: accentColor,
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              style: NotilusFonts.rajdhani(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

