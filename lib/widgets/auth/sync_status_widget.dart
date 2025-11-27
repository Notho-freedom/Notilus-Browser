/// Widget d'état de synchronisation
library sync_status_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/auth/config_sync_service.dart';

/// Widget d'état de synchronisation
class SyncStatusWidget extends StatelessWidget {
  final ConfigSyncService syncService;

  const SyncStatusWidget({
    super.key,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: syncService,
      builder: (context, _) {
        if (syncService.isSyncing) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Synchronisation...',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          );
        }

        if (syncService.lastSyncSuccess && syncService.lastSyncTime != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Colors.green,
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                'Synchronisé',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              color: Colors.orange,
              size: 12,
            ),
            const SizedBox(width: 6),
            Text(
              'Non synchronisé',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        );
      },
    );
  }
}

