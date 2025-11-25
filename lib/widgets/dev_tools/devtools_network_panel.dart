/// Panneau Network du DevTools natif Notilus
library devtools_network_panel;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/devtools_models.dart';
import '../../services/devtools_service.dart';
import '../../core/constants/notilus_colors.dart';

class DevToolsNetworkPanel extends StatefulWidget {
  const DevToolsNetworkPanel({super.key});

  @override
  State<DevToolsNetworkPanel> createState() => _DevToolsNetworkPanelState();
}

class _DevToolsNetworkPanelState extends State<DevToolsNetworkPanel> {
  NetworkRequest? _selectedRequest;
  int _selectedDetailTab = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<DevToolsService>(
      builder: (context, devTools, _) {
        final requests = devTools.networkRequests;

        return Container(
          color: const Color(0xFF0D0D12),
          child: Column(
            children: [
              // Toolbar
              _buildToolbar(devTools),

              // Contenu principal
              Expanded(
                child: requests.isEmpty
                    ? _buildEmptyState()
                    : Row(
                        children: [
                          // Liste des requêtes
                          Expanded(
                            flex: _selectedRequest != null ? 1 : 2,
                            child: _buildRequestsList(requests),
                          ),

                          // Détails de la requête sélectionnée
                          if (_selectedRequest != null) ...[
                            Container(
                              width: 1,
                              color: NotilusColors.neonRed.withOpacity(0.2),
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildRequestDetails(_selectedRequest!),
                            ),
                          ],
                        ],
                      ),
              ),

              // Barre de statistiques
              _buildStatsBar(devTools),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(DevToolsService devTools) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(
          bottom: BorderSide(
            color: NotilusColors.neonRed.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Bouton effacer
          _ToolbarButton(
            icon: Icons.block_outlined,
            tooltip: 'Effacer les requêtes',
            onPressed: devTools.clearNetwork,
          ),
          const SizedBox(width: 4),

          // Enregistrement
          _ToolbarButton(
            icon: Icons.fiber_manual_record,
            tooltip: devTools.isEnabled
                ? 'Enregistrement actif'
                : 'Enregistrement arrêté',
            isActive: devTools.isEnabled,
            activeColor: Colors.red,
            onPressed: () {
              if (devTools.isEnabled) {
                devTools.disable();
              } else {
                devTools.enable();
              }
            },
          ),

          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white.withOpacity(0.1),
          ),

          // Filtres méthodes HTTP
          ...RequestMethod.values.take(5).map((method) {
            final isEnabled = devTools.enabledMethods.contains(method);
            final count = devTools.networkRequests
                .where((r) => r.method == method)
                .length;

            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: _FilterChip(
                label: '${method.name}${count > 0 ? ' ($count)' : ''}',
                color: method.color,
                isSelected: isEnabled,
                onTap: () => devTools.toggleRequestMethod(method),
              ),
            );
          }),

          const Spacer(),

          // Filtre texte
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: TextField(
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontFamily: 'JetBrains Mono',
              ),
              decoration: InputDecoration(
                hintText: 'Filtrer URL...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                isDense: true,
                prefixIcon: Icon(
                  Icons.search,
                  size: 14,
                  color: Colors.white.withOpacity(0.3),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 24,
                ),
              ),
              onChanged: devTools.setNetworkFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune requête réseau',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Les requêtes HTTP apparaîtront ici',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<NetworkRequest> requests) {
    return Column(
      children: [
        // En-tête du tableau
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131318),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              _TableHeader('Status', width: 60),
              _TableHeader('Méthode', width: 60),
              _TableHeader('URL', flex: 2),
              _TableHeader('Type', width: 80),
              _TableHeader('Taille', width: 70),
              _TableHeader('Temps', width: 70),
            ],
          ),
        ),

        // Liste
        Expanded(
          child: ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[requests.length - 1 - index];
              final isSelected = _selectedRequest?.id == request.id;

              return _RequestRow(
                request: request,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedRequest = isSelected ? null : request;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestDetails(NetworkRequest request) {
    return Column(
      children: [
        // Onglets
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF131318),
            border: Border(
              bottom: BorderSide(
                color: NotilusColors.neonRed.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              _DetailTab(
                label: 'Headers',
                isActive: _selectedDetailTab == 0,
                onTap: () => setState(() => _selectedDetailTab = 0),
              ),
              _DetailTab(
                label: 'Request',
                isActive: _selectedDetailTab == 1,
                onTap: () => setState(() => _selectedDetailTab = 1),
              ),
              _DetailTab(
                label: 'Response',
                isActive: _selectedDetailTab == 2,
                onTap: () => setState(() => _selectedDetailTab = 2),
              ),
              _DetailTab(
                label: 'Timing',
                isActive: _selectedDetailTab == 3,
                onTap: () => setState(() => _selectedDetailTab = 3),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: Colors.white.withOpacity(0.5),
                onPressed: () => setState(() => _selectedRequest = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),

        // Contenu
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildDetailContent(request),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailContent(NetworkRequest request) {
    switch (_selectedDetailTab) {
      case 0:
        return _buildHeadersTab(request);
      case 1:
        return _buildRequestBodyTab(request);
      case 2:
        return _buildResponseTab(request);
      case 3:
        return _buildTimingTab(request);
      default:
        return const SizedBox();
    }
  }

  Widget _buildHeadersTab(NetworkRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informations générales
        _DetailSection(
          title: 'Général',
          children: [
            _DetailRow('URL', request.url),
            _DetailRow('Méthode', request.method.name),
            _DetailRow('Status', '${request.statusCode ?? 'En cours'} ${request.statusText ?? ''}'),
            _DetailRow('Type', request.mimeType ?? '-'),
          ],
        ),

        const SizedBox(height: 16),

        // Request Headers
        if (request.requestHeaders?.isNotEmpty == true)
          _DetailSection(
            title: 'Request Headers',
            children: request.requestHeaders!.entries
                .map((e) => _DetailRow(e.key, e.value))
                .toList(),
          ),

        const SizedBox(height: 16),

        // Response Headers
        if (request.responseHeaders?.isNotEmpty == true)
          _DetailSection(
            title: 'Response Headers',
            children: request.responseHeaders!.entries
                .map((e) => _DetailRow(e.key, e.value))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildRequestBodyTab(NetworkRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (request.requestBody != null && request.requestBody!.isNotEmpty)
          _CodeBlock(
            title: 'Request Body',
            content: request.requestBody!,
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Pas de body dans la requête',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResponseTab(NetworkRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (request.responseBody != null && request.responseBody!.isNotEmpty)
          _CodeBlock(
            title: 'Response Body',
            content: request.responseBody!,
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                request.status == NetworkRequestStatus.pending
                    ? 'En attente de la réponse...'
                    : 'Pas de body dans la réponse',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimingTab(NetworkRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailSection(
          title: 'Timing',
          children: [
            _DetailRow('Durée totale', request.formattedDuration),
            _DetailRow('Début', request.startTime.toIso8601String()),
            if (request.endTime != null)
              _DetailRow('Fin', request.endTime!.toIso8601String()),
          ],
        ),

        const SizedBox(height: 16),

        // Barre de timing visuelle
        if (request.duration != null)
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                // Barre de progression
                FractionallySizedBox(
                  widthFactor: (request.duration! / 5000).clamp(0.05, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          request.statusColor.withOpacity(0.7),
                          request.statusColor.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Label
                Center(
                  child: Text(
                    request.formattedDuration,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsBar(DevToolsService devTools) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131318),
        border: Border(
          top: BorderSide(
            color: NotilusColors.neonRed.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${devTools.totalRequests} requêtes',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          if (devTools.failedRequests > 0) ...[
            const SizedBox(width: 12),
            Text(
              '${devTools.failedRequests} échouées',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.red,
              ),
            ),
          ],
          const Spacer(),
          Text(
            devTools.isEnabled ? '● Enregistrement' : '○ Arrêté',
            style: TextStyle(
              fontSize: 10,
              color: devTools.isEnabled
                  ? Colors.green
                  : Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? NotilusColors.neonRed;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: isActive ? color : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : Colors.white.withOpacity(0.4),
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final double? width;
  final int? flex;

  const _TableHeader(this.label, {this.width, this.flex});

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.5),
      ),
    );

    if (flex != null) {
      return Expanded(flex: flex!, child: child);
    }
    return SizedBox(width: width, child: child);
  }
}

class _RequestRow extends StatelessWidget {
  final NetworkRequest request;
  final bool isSelected;
  final VoidCallback onTap;

  const _RequestRow({
    required this.request,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? NotilusColors.neonRed.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          child: Row(
            children: [
              // Status
              SizedBox(
                width: 60,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: request.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      request.statusCode?.toString() ?? '...',
                      style: TextStyle(
                        fontSize: 11,
                        color: request.statusColor,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ),

              // Méthode
              SizedBox(
                width: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: request.method.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    request.method.name,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: request.method.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // URL
              Expanded(
                flex: 2,
                child: Tooltip(
                  message: request.url,
                  child: Text(
                    request.shortUrl,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'JetBrains Mono',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Type
              SizedBox(
                width: 80,
                child: Text(
                  _formatMimeType(request.mimeType),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Taille
              SizedBox(
                width: 70,
                child: Text(
                  request.formattedSize,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),

              // Temps
              SizedBox(
                width: 70,
                child: Text(
                  request.formattedDuration,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getDurationColor(request.duration),
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMimeType(String? mimeType) {
    if (mimeType == null) return '-';
    if (mimeType.contains('javascript')) return 'JS';
    if (mimeType.contains('json')) return 'JSON';
    if (mimeType.contains('html')) return 'HTML';
    if (mimeType.contains('css')) return 'CSS';
    if (mimeType.contains('image')) return 'Image';
    if (mimeType.contains('font')) return 'Font';
    return mimeType.split('/').last.substring(0, 8);
  }

  Color _getDurationColor(double? duration) {
    if (duration == null) return Colors.white.withOpacity(0.5);
    if (duration < 100) return const Color(0xFF4CAF50);
    if (duration < 500) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }
}

class _DetailTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DetailTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? NotilusColors.neonRed : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive
                  ? NotilusColors.neonRed
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: NotilusColors.neonRed,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String title;
  final String content;

  const _CodeBlock({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NotilusColors.neonRed,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 14),
              color: Colors.white.withOpacity(0.5),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copié dans le presse-papiers'),
                    backgroundColor: NotilusColors.neonRed.withOpacity(0.9),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: SelectableText(
            content,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontFamily: 'JetBrains Mono',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
