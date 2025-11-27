import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/terminal_model.dart';

/// Service pour gérer les terminaux disponibles
class TerminalService extends ChangeNotifier {
  static final TerminalService _instance = TerminalService._internal();
  factory TerminalService() => _instance;
  TerminalService._internal();

  List<TerminalModel> _availableTerminals = [];
  TerminalModel? _selectedTerminal;
  String? _activeTerminalId;

  List<TerminalModel> get availableTerminals => _availableTerminals;
  TerminalModel? get selectedTerminal => _selectedTerminal;
  String? get activeTerminalId => _activeTerminalId;

  /// Initialise la liste des terminaux disponibles
  void initialize() {
    _availableTerminals = _getAvailableTerminals();
    _updateLockedStatus();
    
    // Sélectionner un terminal par défaut si aucun n'est sélectionné
    if (_selectedTerminal == null && _availableTerminals.isNotEmpty) {
      // Sur Windows, préférer PowerShell, sinon prendre le premier disponible
      final defaultTerminal = _availableTerminals.firstWhere(
        (t) => !t.isLocked && (Platform.isWindows ? t.id == 'powershell' : true),
        orElse: () => _availableTerminals.firstWhere((t) => !t.isLocked, orElse: () => _availableTerminals.first),
      );
      _selectedTerminal = defaultTerminal;
      _activeTerminalId = defaultTerminal.id;
    }
    
    notifyListeners();
  }

  /// Récupère tous les terminaux disponibles
  List<TerminalModel> _getAvailableTerminals() {
    final terminals = <TerminalModel>[];

    // === TERMINAUX NATIFS ===
    
    // Windows
    if (Platform.isWindows) {
      // PowerShell
      terminals.add(TerminalModel(
        id: 'powershell',
        name: 'PowerShell',
        description: 'Terminal PowerShell natif Windows',
        type: TerminalType.native,
        supportedPlatforms: [TerminalPlatform.windows],
        icon: CupertinoIcons.square_list,
        command: 'powershell.exe',
        args: ['-NoExit', '-Command'],
      ));

      // CMD
      terminals.add(TerminalModel(
        id: 'cmd',
        name: 'Command Prompt',
        description: 'Invite de commande Windows (CMD)',
        type: TerminalType.native,
        supportedPlatforms: [TerminalPlatform.windows],
        icon: CupertinoIcons.square_list,
        command: 'cmd.exe',
        args: ['/k'],
      ));

      // Windows Terminal (si disponible)
      terminals.add(TerminalModel(
        id: 'wt',
        name: 'Windows Terminal',
        description: 'Terminal Windows moderne',
        type: TerminalType.native,
        supportedPlatforms: [TerminalPlatform.windows],
        icon: CupertinoIcons.square_list,
        command: 'wt.exe',
      ));
    }

    // macOS
    if (Platform.isMacOS) {
      // Terminal.app
      terminals.add(TerminalModel(
        id: 'terminal',
        name: 'Terminal',
        description: 'Terminal natif macOS',
        type: TerminalType.native,
        supportedPlatforms: [TerminalPlatform.macos],
        icon: CupertinoIcons.square_list,
        command: 'open',
        args: ['-a', 'Terminal'],
      ));

      // iTerm2 (si disponible)
      terminals.add(TerminalModel(
        id: 'iterm2',
        name: 'iTerm2',
        description: 'Terminal iTerm2 pour macOS',
        type: TerminalType.native,
        supportedPlatforms: [TerminalPlatform.macos],
        icon: CupertinoIcons.square_list,
        command: 'open',
        args: ['-a', 'iTerm'],
      ));
    }

    // Linux
    if (Platform.isLinux) {
      // GNOME Terminal
      terminals.add(TerminalModel(
        id: 'gnome-terminal',
        name: 'GNOME Terminal',
        description: 'Terminal GNOME',
        type: TerminalType.native,
        supportedPlatforms: [TerminalPlatform.linux],
        icon: CupertinoIcons.square_list,
        command: 'gnome-terminal',
      ));

      // Konsole
      terminals.add(TerminalModel(
        id: 'konsole',
        name: 'Konsole',
        description: 'Terminal KDE',
        type: TerminalType.native,
        supportedPlatforms: [TerminalPlatform.linux],
        icon: CupertinoIcons.square_list,
        command: 'konsole',
      ));

      // xterm
      terminals.add(TerminalModel(
        id: 'xterm',
        name: 'XTerm',
        description: 'Terminal X11',
        type: TerminalType.native,
        supportedPlatforms: [TerminalPlatform.linux],
        icon: CupertinoIcons.square_list,
        command: 'xterm',
      ));
    }

    // === TERMINAUX ISOLÉS ===

    // WSL (Windows Subsystem for Linux) - Windows uniquement
    terminals.add(TerminalModel(
      id: 'wsl',
      name: 'WSL',
      description: 'Windows Subsystem for Linux',
      type: TerminalType.isolated,
      supportedPlatforms: [TerminalPlatform.windows],
      icon: CupertinoIcons.square_list,
      command: 'wsl.exe',
    ));

    // Ubuntu (via WSL ou Docker)
    terminals.add(TerminalModel(
      id: 'ubuntu',
      name: 'Ubuntu',
      description: 'Terminal Ubuntu isolé',
      type: TerminalType.isolated,
      supportedPlatforms: [TerminalPlatform.all],
      icon: CupertinoIcons.square_list,
      command: Platform.isWindows ? 'wsl.exe' : 'docker',
      args: Platform.isWindows ? ['-d', 'Ubuntu'] : ['run', '-it', 'ubuntu'],
    ));

    // Debian
    terminals.add(TerminalModel(
      id: 'debian',
      name: 'Debian',
      description: 'Terminal Debian isolé',
      type: TerminalType.isolated,
      supportedPlatforms: [TerminalPlatform.all],
      icon: CupertinoIcons.square_list,
      command: Platform.isWindows ? 'wsl.exe' : 'docker',
      args: Platform.isWindows ? ['-d', 'Debian'] : ['run', '-it', 'debian'],
    ));

    // Alpine Linux
    terminals.add(TerminalModel(
      id: 'alpine',
      name: 'Alpine Linux',
      description: 'Terminal Alpine Linux isolé',
      type: TerminalType.isolated,
      supportedPlatforms: [TerminalPlatform.all],
      icon: CupertinoIcons.square_list,
      command: 'docker',
      args: ['run', '-it', 'alpine'],
    ));

    // Fedora
    terminals.add(TerminalModel(
      id: 'fedora',
      name: 'Fedora',
      description: 'Terminal Fedora isolé',
      type: TerminalType.isolated,
      supportedPlatforms: [TerminalPlatform.all],
      icon: CupertinoIcons.square_list,
      command: 'docker',
      args: ['run', '-it', 'fedora'],
    ));

    return terminals;
  }

  /// Met à jour le statut verrouillé des terminaux
  void _updateLockedStatus() {
    _availableTerminals = _availableTerminals.map((terminal) {
      return terminal.copyWith(
        isLocked: !terminal.isSupportedOnCurrentPlatform(),
      );
    }).toList();
  }

  /// Sélectionne un terminal
  void selectTerminal(String terminalId) {
    final terminal = _availableTerminals.firstWhere(
      (t) => t.id == terminalId,
      orElse: () => _availableTerminals.first,
    );

    if (terminal.isLocked) {
      debugPrint('⚠️ Terminal $terminalId est verrouillé');
      return;
    }

    _selectedTerminal = terminal;
    _activeTerminalId = terminalId;
    notifyListeners();
  }

  /// Obtient les terminaux par type
  List<TerminalModel> getTerminalsByType(TerminalType type) {
    return _availableTerminals.where((t) => t.type == type).toList();
  }

  /// Obtient les terminaux natifs
  List<TerminalModel> get nativeTerminals => getTerminalsByType(TerminalType.native);

  /// Obtient les terminaux isolés
  List<TerminalModel> get isolatedTerminals => getTerminalsByType(TerminalType.isolated);

  /// Ferme le terminal actif
  void closeActiveTerminal() {
    _activeTerminalId = null;
    _selectedTerminal = null;
    notifyListeners();
  }
}

