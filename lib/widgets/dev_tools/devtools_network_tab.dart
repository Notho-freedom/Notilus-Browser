import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/services/color_theme_manager.dart';
import '../../models/devtools_models.dart';
import '../../services/notilus_devtools_service.dart';

/// Onglet Network pour l'inspection des requêtes HTTP
class DevToolsNetworkTab extends StatefulWidget {
  const DevToolsNetworkTab({super.key});

  @override
  State<DevToolsNetworkTab> createState() => _DevToolsNetworkTabState();
}

class _DevToolsNetworkTabState extends State<DevToolsNetworkTab> {
  HttpMethod? _filterMethod;
  RequestStatus? _filterStatus;
  String _searchQuery = '';
  NetworkRequest? _selectedRequest;

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
              // Liste des requêtes
              Expanded(
                flex: 2,
                child: Consumer<NotilusDevToolsService>(
                  builder: (context, devTools, _) {
                    final requests = _filterMethod != null ||
                            _filterStatus != null ||
                            _searchQuery.isNotEmpty
                        ? devTools.filterRequests(
                            method: _filterMethod,
                            status: _filterStatus,
                            search: _searchQuery,
                          )
                        : devTools.requests;

                    if (requests.isEmpty) {
                      return _buildEmptyState(accentColor, devTools);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(4),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[requests.length - 1 - index];
                        final isSelected = _selectedRequest?.id == request.id;
                        return _RequestListItem(
                          request: request,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedRequest =
                                  isSelected ? null : request;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Détails de la requête sélectionnée
              if (_selectedRequest != null)
                Expanded(
                  flex: 3,
                  child: _RequestDetailsPanel(
                    request: _selectedRequest!,
                    accentColor: accentColor,
                    onClose: () {
                      setState(() {
                        _selectedRequest = null;
                      });
                    },
                  ),
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
          // Recording toggle
          Consumer<NotilusDevToolsService>(
            builder: (context, devTools, _) {
              return GestureDetector(
                onTap: devTools.toggleNetworkRecording,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: devTools.isNetworkRecording
                        ? Colors.red.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: devTools.isNetworkRecording
                              ? Colors.red
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        devTools.isNetworkRecording ? 'Recording' : 'Paused',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          // Filtres par méthode
          _MethodFilter(
            label: 'GET',
            isSelected: _filterMethod == HttpMethod.get,
            color: const Color(0xFF66BB6A),
            onTap: () => setState(() {
              _filterMethod =
                  _filterMethod == HttpMethod.get ? null : HttpMethod.get;
            }),
          ),
          _MethodFilter(
            label: 'POST',
            isSelected: _filterMethod == HttpMethod.post,
            color: const Color(0xFFFFB74D),
            onTap: () => setState(() {
              _filterMethod =
                  _filterMethod == HttpMethod.post ? null : HttpMethod.post;
            }),
          ),
          _MethodFilter(
            label: 'ERR',
            isSelected: _filterStatus == RequestStatus.error,
            color: const Color(0xFFEF5350),
            onTap: () => setState(() {
              _filterStatus =
                  _filterStatus == RequestStatus.error ? null : RequestStatus.error;
            }),
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
                  hintText: 'Filtrer URL...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

          // Clear button
          GestureDetector(
            onTap: () {
              context.read<NotilusDevToolsService>().clearRequests();
              setState(() {
                _selectedRequest = null;
              });
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

  Widget _buildEmptyState(Color accentColor, NotilusDevToolsService devTools) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.globe,
            size: 48,
            color: accentColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            devTools.isNetworkRecording
                ? 'En attente de requêtes...'
                : 'Enregistrement en pause',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les requêtes HTTP apparaîtront ici',
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
}

/// Item de la liste des requêtes
class _RequestListItem extends StatelessWidget {
  final NetworkRequest request;
  final bool isSelected;
  final VoidCallback onTap;

  const _RequestListItem({
    required this.request,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? request.statusColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? request.statusColor
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Status
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: request.statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),

            // Method
            Container(
              width: 45,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _getMethodColor(request.method).withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                request.methodLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getMethodColor(request.method),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Status code
            SizedBox(
              width: 35,
              child: Text(
                request.statusCode?.toString() ?? '---',
                style: TextStyle(
                  color: request.statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),

            // URL
            Expanded(
              child: Text(
                request.path.isEmpty ? request.host : request.path,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),

            // Duration
            SizedBox(
              width: 60,
              child: Text(
                request.formattedDuration,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),

            // Size
            SizedBox(
              width: 50,
              child: Text(
                request.formattedSize,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return const Color(0xFF66BB6A);
      case HttpMethod.post:
        return const Color(0xFFFFB74D);
      case HttpMethod.put:
        return const Color(0xFF64B5F6);
      case HttpMethod.delete:
        return const Color(0xFFEF5350);
      case HttpMethod.patch:
        return const Color(0xFFBA68C8);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Filtre par méthode
class _MethodFilter extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _MethodFilter({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }
}

/// Panneau de détails de la requête
class _RequestDetailsPanel extends StatefulWidget {
  final NetworkRequest request;
  final Color accentColor;
  final VoidCallback onClose;

  const _RequestDetailsPanel({
    required this.request,
    required this.accentColor,
    required this.onClose,
  });

  @override
  State<_RequestDetailsPanel> createState() => _RequestDetailsPanelState();
}

class _RequestDetailsPanelState extends State<_RequestDetailsPanel> {
  String _activeSection = 'headers';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          left: BorderSide(
            color: widget.accentColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(
                  color: widget.accentColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.request.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.request.methodLabel} ${widget.request.statusCode ?? '...'}',
                  style: TextStyle(
                    color: widget.request.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // URL
          Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            color: Colors.black.withOpacity(0.2),
            child: SelectableText(
              widget.request.url,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),

          // Section tabs
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _buildSectionTab('Headers', 'headers'),
                _buildSectionTab('Request', 'request'),
                _buildSectionTab('Response', 'response'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: _buildSectionContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTab(String label, String section) {
    final isActive = _activeSection == section;
    return GestureDetector(
      onTap: () => setState(() => _activeSection = section),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? widget.accentColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? widget.accentColor
                : Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case 'headers':
        return _buildHeadersSection();
      case 'request':
        return _buildRequestSection();
      case 'response':
        return _buildResponseSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeadersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Request Headers'),
        ...widget.request.requestHeaders.entries.map(
          (e) => _buildHeaderRow(e.key, e.value),
        ),
        const SizedBox(height: 16),
        if (widget.request.responseHeaders != null) ...[
          _buildSubHeader('Response Headers'),
          ...widget.request.responseHeaders!.entries.map(
            (e) => _buildHeaderRow(e.key, e.value),
          ),
        ],
      ],
    );
  }

  Widget _buildRequestSection() {
    if (widget.request.requestBody == null ||
        widget.request.requestBody!.isEmpty) {
      return Center(
        child: Text(
          'No request body',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      );
    }
    return SelectableText(
      widget.request.requestBody!,
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 10,
        fontFamily: 'JetBrains Mono',
        height: 1.4,
      ),
    );
  }

  Widget _buildResponseSection() {
    if (widget.request.error != null) {
      return Text(
        'Error: ${widget.request.error}',
        style: const TextStyle(
          color: Color(0xFFEF5350),
          fontSize: 11,
          fontFamily: 'JetBrains Mono',
        ),
      );
    }
    if (widget.request.responseBody == null ||
        widget.request.responseBody!.isEmpty) {
      return Center(
        child: Text(
          widget.request.status == RequestStatus.pending
              ? 'Pending...'
              : 'No response body',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      );
    }
    return SelectableText(
      widget.request.responseBody!,
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 10,
        fontFamily: 'JetBrains Mono',
        height: 1.4,
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: widget.accentColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }

  Widget _buildHeaderRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              key,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
