import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../models/devtools_models.dart';
import '../../services/notilus_devtools_service.dart';

/// Onglet Storage pour l'inspection du stockage local
class DevToolsStorageTab extends StatefulWidget {
  const DevToolsStorageTab({super.key});

  @override
  State<DevToolsStorageTab> createState() => _DevToolsStorageTabState();
}

class _DevToolsStorageTabState extends State<DevToolsStorageTab> {
  String _searchQuery = '';
  StorageEntry? _selectedEntry;
  bool _isEditing = false;
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  String _selectedType = 'String';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotilusDevToolsService>().loadStorageEntries();
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.watch<ColorThemeManager>();
    final accentColor = colorTheme.nativeSecondaryColor;

    return Column(
      children: [
        // Toolbar
        _buildToolbar(accentColor),

        // Content
        Expanded(
          child: Row(
            children: [
              // Liste des entrées
              Expanded(
                flex: 2,
                child: Consumer<NotilusDevToolsService>(
                  builder: (context, devTools, _) {
                    final entries = _searchQuery.isEmpty
                        ? devTools.storageEntries
                        : devTools.storageEntries
                            .where((e) =>
                                e.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                e.value.toLowerCase().contains(_searchQuery.toLowerCase()))
                            .toList();

                    if (entries.isEmpty) {
                      return _buildEmptyState(accentColor);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(4),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isSelected = _selectedEntry?.key == entry.key;
                        return _StorageEntryWidget(
                          entry: entry,
                          isSelected: isSelected,
                          accentColor: accentColor,
                          onTap: () {
                            setState(() {
                              _selectedEntry = isSelected ? null : entry;
                              _isEditing = false;
                            });
                          },
                          onDelete: () async {
                            await devTools.deleteStorageEntry(entry.key);
                            if (_selectedEntry?.key == entry.key) {
                              setState(() {
                                _selectedEntry = null;
                              });
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Panneau de détails/édition
              if (_selectedEntry != null || _isEditing)
                Expanded(
                  flex: 3,
                  child: _buildDetailsPanel(accentColor),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(Color accentColor) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Refresh button
          GestureDetector(
            onTap: () {
              context.read<NotilusDevToolsService>().loadStorageEntries();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.arrow_clockwise,
                    size: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Add new entry
          GestureDetector(
            onTap: () {
              setState(() {
                _isEditing = true;
                _selectedEntry = null;
                _keyController.clear();
                _valueController.clear();
                _selectedType = 'String';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.plus,
                    size: 12,
                    color: accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Search
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'JetBrains Mono',
                  color: Colors.white70,
                ),
                decoration: InputDecoration(
                  hintText: 'Search keys...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  isDense: true,
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: 12,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 22,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Entry count
          Consumer<NotilusDevToolsService>(
            builder: (context, devTools, _) {
              return Text(
                '${devTools.storageEntries.length} entries',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontFamily: 'JetBrains Mono',
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          // Clear all
          GestureDetector(
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E2E),
                  title: const Text(
                    'Clear All Storage?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'This will delete all stored data. This action cannot be undone.',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Color(0xFFEF5350)),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await context.read<NotilusDevToolsService>().clearStorage();
                setState(() {
                  _selectedEntry = null;
                });
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                CupertinoIcons.trash,
                size: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.archivebox,
            size: 48,
            color: accentColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No storage entries',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add" to create a new entry',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(Color accentColor) {
    final isNewEntry = _isEditing && _selectedEntry == null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          left: BorderSide(
            color: accentColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(
                  color: accentColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isNewEntry ? CupertinoIcons.plus_circle : CupertinoIcons.pencil,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isNewEntry ? 'New Entry' : (_isEditing ? 'Edit Entry' : 'Entry Details'),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                const Spacer(),
                if (!_isEditing && _selectedEntry != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditing = true;
                        _keyController.text = _selectedEntry!.key;
                        _valueController.text = _selectedEntry!.value;
                        _selectedType = _selectedEntry!.type;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEntry = null;
                      _isEditing = false;
                    });
                  },
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key field
                  _buildLabel('Key'),
                  const SizedBox(height: 4),
                  if (_isEditing)
                    _buildTextField(_keyController, 'Enter key...', enabled: isNewEntry)
                  else
                    _buildValueDisplay(_selectedEntry?.key ?? ''),

                  const SizedBox(height: 16),

                  // Type selector (only for editing)
                  if (_isEditing) ...[
                    _buildLabel('Type'),
                    const SizedBox(height: 4),
                    _buildTypeSelector(accentColor),
                    const SizedBox(height: 16),
                  ],

                  // Value field
                  _buildLabel('Value'),
                  const SizedBox(height: 4),
                  if (_isEditing)
                    _buildTextField(_valueController, 'Enter value...', maxLines: 8)
                  else
                    _buildValueDisplay(_selectedEntry?.value ?? '', maxLines: 10),

                  // Metadata (only for viewing)
                  if (!_isEditing && _selectedEntry != null) ...[
                    const SizedBox(height: 16),
                    _buildLabel('Metadata'),
                    const SizedBox(height: 4),
                    _buildMetadataRow('Type', _selectedEntry!.type),
                    _buildMetadataRow('Size', _selectedEntry!.formattedSize),
                  ],

                  // Action buttons (only for editing)
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEditing = false;
                                if (_selectedEntry == null) {
                                  // Cancel new entry
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Cancel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final key = _keyController.text.trim();
                              final value = _valueController.text;

                              if (key.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Key cannot be empty')),
                                );
                                return;
                              }

                              await context.read<NotilusDevToolsService>().setStorageEntry(
                                    key,
                                    value,
                                    _selectedType,
                                  );

                              setState(() {
                                _isEditing = false;
                                _selectedEntry = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Save',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        fontFamily: 'JetBrains Mono',
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: TextStyle(
          color: Colors.white.withOpacity(enabled ? 0.9 : 0.5),
          fontSize: 11,
          fontFamily: 'JetBrains Mono',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  Widget _buildValueDisplay(String value, {int maxLines = 1}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: SelectableText(
        value,
        maxLines: maxLines,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 11,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }

  Widget _buildTypeSelector(Color accentColor) {
    const types = ['String', 'int', 'double', 'bool'];
    return Row(
      children: types.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? accentColor.withOpacity(0.5) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? accentColor : Colors.white.withOpacity(0.6),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une entrée de storage
class _StorageEntryWidget extends StatelessWidget {
  final StorageEntry entry;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StorageEntryWidget({
    required this.entry,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.15) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: isSelected ? accentColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getTypeColor(entry.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  _getTypeIcon(entry.type),
                  style: TextStyle(
                    color: _getTypeColor(entry.type),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Key and value preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.value.length > 50 ? '${entry.value.substring(0, 50)}...' : entry.value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),

            // Size
            Text(
              entry.formattedSize,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 9,
                fontFamily: 'JetBrains Mono',
              ),
            ),

            const SizedBox(width: 8),

            // Delete button
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  CupertinoIcons.trash,
                  size: 10,
                  color: Color(0xFFEF5350),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'String':
        return const Color(0xFF66BB6A);
      case 'int':
        return const Color(0xFF64B5F6);
      case 'double':
        return const Color(0xFFBA68C8);
      case 'bool':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case 'String':
        return 'S';
      case 'int':
        return '#';
      case 'double':
        return '.#';
      case 'bool':
        return '?';
      default:
        return '?';
    }
  }
}
