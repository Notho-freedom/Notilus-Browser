/// Vue 3D Cover Flow pour afficher les onglets en perspective
/// Style collection de voitures de jeux avec effet 3D prononcé
library gx_3d_coverflow_tabs_view;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/tabs_preview_service.dart';
import '../../models/tab_model.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_colors.dart';
import '../../core/constants/notilus_fonts.dart';
import '../common/gx_futuristic_components.dart';
import '../common/gx_futuristic_dialog.dart';
import '../common/notilus_tooltip.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Vue 3D Cover Flow pour les onglets
class Gx3DCoverFlowTabsView extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onTabSelected;

  const Gx3DCoverFlowTabsView({
    super.key,
    this.onClose,
    this.onTabSelected,
  });

  @override
  State<Gx3DCoverFlowTabsView> createState() => _Gx3DCoverFlowTabsViewState();
}

class _Gx3DCoverFlowTabsViewState extends State<Gx3DCoverFlowTabsView> {
  late PageController _pageController;
  int _currentIndex = 0;
  double _currentPage = 0.0;
  TabsPreviewService? _previewService;

  @override
  void initState() {
    super.initState();
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final tabs = tabManager.tabs;
    final activeTab = tabManager.activeTab;
    
    _previewService = Provider.of<TabsPreviewService>(context, listen: false);
    
    if (activeTab != null) {
      final activeIndex = tabs.indexWhere((tab) => tab.id == activeTab.id);
      _currentIndex = activeIndex >= 0 ? activeIndex : 0;
      _currentPage = _currentIndex.toDouble();
    }
    
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.3, // Permet de voir 3-4 cartes en même temps
    );
    
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        final newPage = _pageController.page ?? _currentPage;
        if ((newPage - _currentPage).abs() > 0.01) {
          setState(() {
            _currentPage = newPage;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _previewService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: true);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final bgColor = colorThemeManager.nativeBackgroundColor;
    final tabManager = Provider.of<TabManager>(context, listen: true);
    final tabs = tabManager.tabs;

    if (tabs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.car_detailed,
              size: 64,
              color: gxRed.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun onglet ouvert',
              style: NotilusFonts.rajdhani(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgColor,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header avec titre style jeu de voitures
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gxRed.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: gxRed.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.car_detailed,
                  color: gxRed,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'COLLECTION D\'ONGlets',
                  style: NotilusFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gxRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: gxRed,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${tabs.length}',
                    style: NotilusFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: gxRed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                NotilusTooltip(
                  message: 'Retour au garage',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 40,
                    onPressed: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gxRed.withOpacity(0.3),
                            gxRed.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: gxRed,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gxRed.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Zone principale avec le carrousel 3D style collection voitures
          Expanded(
            child: Stack(
              children: [
                // Fond avec effet de piste
                _buildRacetrackBackground(gxRed),
                
                // Carrousel 3D style collection
                Center(
                  child: Consumer<TabsPreviewService>(
                    builder: (context, previewService, _) {
                      return PageView.builder(
                        controller: _pageController,
                        itemCount: tabs.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                            _currentPage = index.toDouble();
                          });
                        },
                        itemBuilder: (context, index) {
                          return _buildCarCollectionCard(
                            tabs[index],
                            index,
                            _currentPage,
                            gxRed,
                            bgColor,
                            tabManager,
                          );
                        },
                      );
                    },
                  ),
                ),

                // Indicateurs de performance en bas (style jeu de voitures)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: _buildPerformanceIndicators(gxRed, tabs.length),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRacetrackBackground(Color gxRed) {
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    gxRed.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Ligne d'arrivée stylisée
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 100),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  gxRed,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicators(Color gxRed, int totalTabs) {
    return Column(
      children: [
        // Barre de progression style compteur de vitesse
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Expanded(
                flex: _currentIndex + 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gxRed, gxRed.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                flex: totalTabs - _currentIndex - 1,
                child: const SizedBox(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Indicateurs de position
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chevron_left,
              color: gxRed,
              size: 16,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: gxRed,
                  width: 1,
                ),
              ),
              child: Text(
                '${_currentIndex + 1} / $totalTabs',
                style: NotilusFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              color: gxRed,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarCollectionCard(
    TabModel tab,
    int index,
    double currentIndex,
    Color gxRed,
    Color bgColor,
    TabManager tabManager,
  ) {
    final distance = (index - currentIndex).abs();
    final isActive = (index - currentIndex).abs() < 0.5;
    
    // Effets 3D plus prononcés pour l'effet collection de voitures
    final angleY = (index - currentIndex) * 0.4; // Rotation Y plus importante
    final scale = math.max(0.7, 1.0 - (distance * 0.15)); // Différence d'échelle plus marquée
    final opacity = math.max(0.4, 1.0 - (distance * 0.3)); // Opacité réduite pour les cartes éloignées
    
    // Translation X pour alignement horizontal centré
    final xTranslation = (index - currentIndex) * 220.0; // Espacement plus large
    
    // Translation Z pour effet de profondeur (les voitures éloignées sont plus petites et plus basses)
    final zTranslation = -distance * 50.0;
    
    // Translation Y pour effet d'alignement sur le sol (les voitures éloignées sont plus basses)
    final yTranslation = distance * 20.0;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
          );
        } else {
          tabManager.selectTab(tab.id);
          widget.onTabSelected?.call();
        }
      },
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective plus prononcée
          ..translate(xTranslation, yTranslation, zTranslation)
          ..rotateY(angleY)
          ..scale(scale),
        child: Opacity(
          opacity: opacity,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Stack(
                children: [
                  // Ombre portée au sol
                  if (isActive)
                    Positioned(
                      bottom: -30,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: gxRed.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Carte principale
                  GxFuturisticCard(
                    accentColor: isActive ? gxRed : Colors.white.withOpacity(0.2),
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: isActive ? 320 : 280,
                      height: isActive ? 200 : 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isActive
                              ? [
                                  gxRed.withOpacity(0.1),
                                  Colors.black.withOpacity(0.8),
                                ]
                              : [
                                  Colors.white.withOpacity(0.05),
                                  Colors.black.withOpacity(0.9),
                                ],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Preview de la page (style pare-brise)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildCarPreviewContent(tab, gxRed),
                          ),
                          
                          // Overlay de style tableau de bord
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive ? gxRed : Colors.white.withOpacity(0.1),
                                width: isActive ? 3 : 1,
                              ),
                            ),
                          ),
                          
                          // Informations style plaque d'immatriculation
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.95),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Titre style plaque
                                    Text(
                                      tab.title ?? 'VOITURE SANS NOM',
                                      style: NotilusFonts.orbitron(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // URL style numéro de série
                                    if (tab.url != null && tab.url!.isNotEmpty)
                                      Text(
                                        tab.url!,
                                        style: NotilusFonts.rajdhani(
                                          fontSize: 9,
                                          color: gxRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Badge "SÉLECTIONNÉ" style autocollant tuning
                          if (isActive)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Transform.rotate(
                                angle: -0.1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        gxRed,
                                        gxRed.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gxRed.withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'SÉLECTIONNÉ',
                                    style: NotilusFonts.orbitron(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Boutons d'action style commandes de tableau de bord
                          if (isActive)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Row(
                                children: [
                                  _buildDashboardButton(
                                    'PILOTER',
                                    CupertinoIcons.play_fill,
                                    gxRed,
                                    () {
                                      tabManager.selectTab(tab.id);
                                      widget.onTabSelected?.call();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildDashboardButton(
                                    'GARER',
                                    CupertinoIcons.xmark,
                                    Colors.red,
                                    () {
                                      final tabWebViewManager = Provider.of<TabWebViewManager>(
                                        context,
                                        listen: false,
                                      );
                                      tabWebViewManager.removeEngineForTab(tab.id);
                                      tabManager.closeTab(tab.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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

  Widget _buildDashboardButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return NotilusTooltip(
      message: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 36,
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCarPreviewContent(TabModel tab, Color gxRed) {
    final preview = _previewService?.getPreview(tab.id);
    
    if (preview?.imageBytes != null && preview!.imageBytes!.isNotEmpty) {
      try {
        final bytes = preview.imageBytes!;
        final isValidImage = bytes.length > 8 && (
          (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) ||
          (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) ||
          (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38)
        );
        
        if (isValidImage) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCarFallbackContent(tab, gxRed),
          );
        }
      } catch (e) {
        debugPrint('Erreur validation image preview: $e');
      }
    }
    
    return _buildCarFallbackContent(tab, gxRed);
  }

  Widget _buildCarFallbackContent(TabModel tab, Color gxRed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gxRed.withOpacity(0.3),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: tab.favicon != null && 
             tab.favicon!.isNotEmpty &&
             tab.url != null &&
             !tab.url!.startsWith('about:')
          ? Center(
              child: Image.network(
                tab.favicon!,
                width: 40,
                height: 40,
                errorBuilder: (_, __, ___) => _buildCarDefaultContent(gxRed),
              ),
            )
          : _buildCarDefaultContent(gxRed),
    );
  }

  Widget _buildCarDefaultContent(Color gxRed) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.car_detailed,
            size: 50,
            color: gxRed.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'NOTILUS\nRACING',
            style: NotilusFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: gxRed.withOpacity(0.8),
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}