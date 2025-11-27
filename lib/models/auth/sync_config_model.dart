/// Modèle de configuration synchronisée
library sync_config_model;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de configuration synchronisée
class SyncConfigModel {
  final DateTime lastSync;
  final bool success;
  final Map<String, dynamic> configs;

  SyncConfigModel({
    required this.lastSync,
    required this.success,
    required this.configs,
  });

  factory SyncConfigModel.fromJson(Map<String, dynamic> json) {
    return SyncConfigModel(
      lastSync: json['lastSync'] != null
          ? (json['lastSync'] is Timestamp
              ? (json['lastSync'] as Timestamp).toDate()
              : DateTime.parse(json['lastSync'] as String))
          : DateTime.now(),
      success: json['success'] as bool? ?? false,
      configs: json['configs'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastSync': lastSync.toIso8601String(),
      'success': success,
      'configs': configs,
    };
  }
}

