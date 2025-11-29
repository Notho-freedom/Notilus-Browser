/// Panneau Application du DevTools natif Notilus - Storage & Cookies
/// Utilise la couleur secondaire du thème
library devtools_application_panel;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/devtools_models.dart';
import '../../services/devtools_service.dart';
import '../../core/services/color_theme_manager.dart';

class DevToolsApplicationPanel extends StatefulWidget {
  const DevToolsApplicationPanel({super.key});

  @override
  State<DevToolsApplicationPanel> createState() =>
      _DevToolsApplicationPanelState();
}

class _DevToolsApplicationPanelState extends State<DevToolsApplicationPanel> {
  StorageType _selectedType = StorageType.localStorage;
  StorageItem? _selectedItem;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  Future<void> _loadStorage() async {
    setState(() => _isLoading = true);
    final devTools = context.read<DevToolsService>();
    await devTools.fetchStorage();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Provider.of<ColorThemeManager>(context);
    final accentColor = colorTheme.nativeSecondaryColor;

    return Consumer<DevToolsService>(
      builder: (context, devTools, _) {
        final storage = devTools.storage;
        final items = storage[_selectedType] ?? [];

        return Container(
          color: const Color(0xFF0D0D12),
          child: Row(
            children: [
              // Sidebar - Types de storage
              _buildSidebar(storage, accentColor),

              // Contenu principal
              Expanded(
                child: Column(
                  children: [
                    _buildToolbar(items, accentColor),
                    Expanded(
                      child: _isLoading
                          ? _buildLoadingState(accentColor)
                          : items.isEmpty
                              ? _buildEmptyState()
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: _selectedItem != null ? 1 : 2,
                                      child: _buildItemsList(items, accentColor),
                                    ),
                                    if (_selectedItem != null) ...[
                                      Container(width: 1, color: accentColor.withOpacity(0.2)),
                                      Expanded(
                                        flex: 1,
                                        child: _buildItemDetails(_selectedItem!, accentColor),
                                      ),
                                    ],
                                  ],
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(Map<StorageType, List<StorageItem>> storage, Color accentColor) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(right: BorderSide(color: accentColor.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text('Storage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 14),
                  color: Colors.white.withOpacity(0.5),
                  onPressed: _loadStorage,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: StorageType.values.map((type) {
                final count = storage[type]?.length ?? 0;
                return _StorageTypeItem(
                  type: type,
                  count: count,
                  isSelected: _selectedType == type,
                  accentColor: accentColor,
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      _selectedItem = null;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(List<StorageItem> items, Color accentColor) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Icon(_selectedType.icon, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Text(_selectedType.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${items.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor)),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)),
          const SizedBox(height: 12),
          Text('Chargement du storage...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_selectedType.icon, size: 48, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text('Aucune donnée dans ${_selectedType.displayName}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<StorageItem> items, Color accentColor) {
    return Column(
      children: [
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131318),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: const Row(
            children: [
              Expanded(flex: 1, child: Text('Clé', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white54))),
              Expanded(flex: 2, child: Text('Valeur', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white54))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = _selectedItem?.key == item.key;

              return Material(
                color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedItem = isSelected ? null : item),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(item.key, style: const TextStyle(fontSize: 11, color: Color(0xFF9CDCFE), fontFamily: 'JetBrains Mono'), overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(item.value, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontFamily: 'JetBrains Mono'), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemDetails(StorageItem item, Color accentColor) {
    String formattedValue = item.value;
    bool isJson = false;

    try {
      if (item.value.startsWith('{') || item.value.startsWith('[')) {
        isJson = true;
      }
    } catch (_) {}

    return Container(
      color: const Color(0xFF0D0D12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131318),
              border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Text('Détails', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  color: Colors.white.withOpacity(0.5),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '${item.key}: ${item.value}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Copié dans le presse-papiers'), backgroundColor: accentColor.withOpacity(0.9), duration: const Duration(seconds: 1)),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'Copier',
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  color: Colors.white.withOpacity(0.5),
                  onPressed: () => setState(() => _selectedItem = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailField(label: 'Clé', value: item.key),
                  const SizedBox(height: 16),
                  _DetailField(label: 'Type', value: _selectedType.displayName),
                  const SizedBox(height: 16),
                  Text('Valeur', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5), letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: SelectableText(
                      formattedValue,
                      style: TextStyle(
                        fontSize: 11,
                        color: isJson ? const Color(0xFFCE9178) : Colors.white.withOpacity(0.8),
                        fontFamily: 'JetBrains Mono',
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailField(label: 'Taille', value: '${item.value.length} caractères'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageTypeItem extends StatelessWidget {
  final StorageType type;
  final int count;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _StorageTypeItem({
    required this.type,
    required this.count,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: isSelected ? accentColor : Colors.transparent, width: 2)),
          ),
          child: Row(
            children: [
              Icon(type.icon, size: 16, color: isSelected ? accentColor : Colors.white.withOpacity(0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? accentColor : Colors.white.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accentColor : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5), letterSpacing: 1)),
        const SizedBox(height: 4),
        SelectableText(value, style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'JetBrains Mono')),
      ],
    );
  }
}
