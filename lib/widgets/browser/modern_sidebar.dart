import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';

class ModernSidebar extends StatefulWidget {
  final VoidCallback? onClose;
  
  const ModernSidebar({
    super.key,
    this.onClose,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> {
  int _selectedIndex = 0;

  final List<SidebarItem> _items = [
    SidebarItem(
      icon: CupertinoIcons.home,
      label: 'Accueil',
      color: Color(0xFF007AFF),
    ),
    SidebarItem(
      icon: CupertinoIcons.bookmark,
      label: 'Favoris',
      color: Color(0xFFFF9500),
    ),
    SidebarItem(
      icon: CupertinoIcons.clock,
      label: 'Historique',
      color: Color(0xFF5856D6),
    ),
    SidebarItem(
      icon: CupertinoIcons.download_circle,
      label: 'Téléchargements',
      color: Color(0xFF34C759),
    ),
    SidebarItem(
      icon: CupertinoIcons.gear,
      label: 'Paramètres',
      color: Color(0xFF8E8E93),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: 280,
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      child: Column(
        children: [
          // En-tête avec profil
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF5856D6),
                        Color(0xFF007AFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notilus',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Navigateur Pro',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Section de recherche rapide
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recherche rapide',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isSelected = _selectedIndex == index;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        
                        if (index == 0) {
                          // Retour à l'accueil
                          final tabManager = Provider.of<TabManager>(context, listen: false);
                          tabManager.addTab(url: 'about:newtab');
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? item.color.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected
                                  ? item.color
                                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? item.color
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Section du bas
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Statistiques
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF5856D6).withOpacity(0.1),
                        Color(0xFF007AFF).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.shield_lefthalf_fill,
                            size: 16,
                            color: Color(0xFF5856D6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Protection activée',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '127 trackers bloqués',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;
  final Color color;

  SidebarItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
