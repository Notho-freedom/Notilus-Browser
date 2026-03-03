import 'dart:io';
import 'package:flutter/cupertino.dart';

/// Type de terminal
enum TerminalType {
  native, // Terminal natif du système
  isolated, // Terminal isolé (Docker, WSL, etc.)
}

/// Plateforme supportée
enum TerminalPlatform {
  windows,
  macos,
  linux,
  all, // Toutes les plateformes
}

/// Modèle représentant un terminal
class TerminalModel {
  final String id;
  final String name;
  final String description;
  final TerminalType type;
  final List<TerminalPlatform> supportedPlatforms;
  final IconData icon;
  final String command; // Commande pour lancer le terminal
  final List<String>? args; // Arguments supplémentaires
  final bool isLocked; // Si le terminal est verrouillé (non supporté)

  TerminalModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.supportedPlatforms,
    required this.icon,
    required this.command,
    this.args,
    this.isLocked = false,
  });

  /// Vérifie si le terminal est supporté sur la plateforme actuelle
  bool isSupportedOnCurrentPlatform() {
    if (supportedPlatforms.contains(TerminalPlatform.all)) {
      return true;
    }

    if (Platform.isWindows) {
      return supportedPlatforms.contains(TerminalPlatform.windows);
    } else if (Platform.isMacOS) {
      return supportedPlatforms.contains(TerminalPlatform.macos);
    } else if (Platform.isLinux) {
      return supportedPlatforms.contains(TerminalPlatform.linux);
    }

    return false;
  }

  /// Crée une copie avec isLocked mis à jour
  TerminalModel copyWith({bool? isLocked}) {
    return TerminalModel(
      id: id,
      name: name,
      description: description,
      type: type,
      supportedPlatforms: supportedPlatforms,
      icon: icon,
      command: command,
      args: args,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

