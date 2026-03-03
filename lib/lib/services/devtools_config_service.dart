/// Service de configuration des DevTools Notilus
/// Gère les préférences utilisateur pour les DevTools
library devtools_config_service;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration des DevTools
class DevToolsConfigService extends ChangeNotifier {
  static const String _prefix = 'devtools_';
  
  SharedPreferences? _prefs;
  
  // === Position et taille ===
  String _position = 'bottom'; // bottom, right, detached
  double _height = 300;
  double _width = 400;
  bool _rememberSize = true;
  
  // === Comportement général ===
  bool _autoOpen = false;
  bool _preserveLog = false;
  bool _autoExpandErrors = true;
  bool _showTimestamps = true;
  bool _darkMode = true;
  
  // === Console ===
  bool _consoleShowInfo = true;
  bool _consoleShowWarn = true;
  bool _consoleShowError = true;
  bool _consoleShowDebug = false;
  bool _consoleGroupSimilar = true;
  int _consoleMaxEntries = 1000;
  bool _consoleAutoScroll = true;
  
  // === Network ===
  bool _networkPreserveLog = false;
  bool _networkDisableCache = false;
  bool _networkShowBlocked = true;
  bool _networkShowDetails = true;
  int _networkMaxEntries = 500;
  Set<String> _networkHiddenDomains = {};
  bool _networkCaptureBody = true;
  int _networkBodySizeLimit = 1024 * 100; // 100KB
  
  // === Elements ===
  bool _elementsShowRulers = true;
  bool _elementsShowAccessibility = false;
  bool _elementsHighlightOnHover = true;
  String _elementsPanelPosition = 'right'; // right, bottom
  bool _elementsShowUserAgent = false;
  bool _elementsShowComputedStyles = true;
  
  // === Inspection ===
  bool _inspectHighlightPadding = true;
  bool _inspectHighlightMargin = true;
  bool _inspectHighlightBorder = true;
  bool _inspectShowTooltip = true;
  bool _inspectShowDimensions = true;
  String _inspectHighlightColor = '#FF6B6B';
  double _inspectHighlightOpacity = 0.3;
  
  // === Performance ===
  bool _performanceAutoRecord = false;
  int _performanceRefreshRate = 2; // secondes
  bool _performanceShowFPS = true;
  bool _performanceShowMemory = true;
  bool _performanceShowNetwork = true;
  
  // === Application/Storage ===
  bool _storageAutoRefresh = false;
  int _storageRefreshRate = 5;
  bool _storageClearOnReload = false;
  
  // === Ressources ===
  bool _resourcesShowImages = true;
  bool _resourcesShowScripts = true;
  bool _resourcesShowStyles = true;
  bool _resourcesShowFonts = true;
  bool _resourcesShowMedia = true;
  bool _resourcesShowOther = true;
  bool _resourcesGroupByType = true;
  bool _resourcesShowSize = true;
  bool _resourcesShowTiming = true;
  
  // === Raccourcis clavier ===
  String _shortcutOpen = 'F12';
  String _shortcutConsole = 'Ctrl+Shift+J';
  String _shortcutElements = 'Ctrl+Shift+C';
  String _shortcutNetwork = 'Ctrl+Shift+E';
  String _shortcutClear = 'Ctrl+L';
  
  // === Thème ===
  String _theme = 'dark'; // dark, light, system
  double _fontSize = 12;
  String _fontFamily = 'JetBrains Mono';

  // Getters
  String get position => _position;
  double get height => _height;
  double get width => _width;
  bool get rememberSize => _rememberSize;
  bool get autoOpen => _autoOpen;
  bool get preserveLog => _preserveLog;
  bool get autoExpandErrors => _autoExpandErrors;
  bool get showTimestamps => _showTimestamps;
  bool get darkMode => _darkMode;
  
  bool get consoleShowInfo => _consoleShowInfo;
  bool get consoleShowWarn => _consoleShowWarn;
  bool get consoleShowError => _consoleShowError;
  bool get consoleShowDebug => _consoleShowDebug;
  bool get consoleGroupSimilar => _consoleGroupSimilar;
  int get consoleMaxEntries => _consoleMaxEntries;
  bool get consoleAutoScroll => _consoleAutoScroll;
  
  bool get networkPreserveLog => _networkPreserveLog;
  bool get networkDisableCache => _networkDisableCache;
  bool get networkShowBlocked => _networkShowBlocked;
  bool get networkShowDetails => _networkShowDetails;
  int get networkMaxEntries => _networkMaxEntries;
  Set<String> get networkHiddenDomains => _networkHiddenDomains;
  bool get networkCaptureBody => _networkCaptureBody;
  int get networkBodySizeLimit => _networkBodySizeLimit;
  
  bool get elementsShowRulers => _elementsShowRulers;
  bool get elementsShowAccessibility => _elementsShowAccessibility;
  bool get elementsHighlightOnHover => _elementsHighlightOnHover;
  String get elementsPanelPosition => _elementsPanelPosition;
  bool get elementsShowComputedStyles => _elementsShowComputedStyles;
  
  bool get inspectHighlightPadding => _inspectHighlightPadding;
  bool get inspectHighlightMargin => _inspectHighlightMargin;
  bool get inspectHighlightBorder => _inspectHighlightBorder;
  bool get inspectShowTooltip => _inspectShowTooltip;
  bool get inspectShowDimensions => _inspectShowDimensions;
  String get inspectHighlightColor => _inspectHighlightColor;
  double get inspectHighlightOpacity => _inspectHighlightOpacity;
  
  bool get performanceAutoRecord => _performanceAutoRecord;
  int get performanceRefreshRate => _performanceRefreshRate;
  bool get performanceShowFPS => _performanceShowFPS;
  bool get performanceShowMemory => _performanceShowMemory;
  bool get performanceShowNetwork => _performanceShowNetwork;
  
  bool get storageAutoRefresh => _storageAutoRefresh;
  int get storageRefreshRate => _storageRefreshRate;
  bool get storageClearOnReload => _storageClearOnReload;
  
  bool get resourcesShowImages => _resourcesShowImages;
  bool get resourcesShowScripts => _resourcesShowScripts;
  bool get resourcesShowStyles => _resourcesShowStyles;
  bool get resourcesShowFonts => _resourcesShowFonts;
  bool get resourcesShowMedia => _resourcesShowMedia;
  bool get resourcesShowOther => _resourcesShowOther;
  bool get resourcesGroupByType => _resourcesGroupByType;
  bool get resourcesShowSize => _resourcesShowSize;
  bool get resourcesShowTiming => _resourcesShowTiming;
  
  String get shortcutOpen => _shortcutOpen;
  String get shortcutConsole => _shortcutConsole;
  String get shortcutElements => _shortcutElements;
  String get shortcutNetwork => _shortcutNetwork;
  String get shortcutClear => _shortcutClear;
  
  String get theme => _theme;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;

  /// Initialise le service avec les préférences sauvegardées
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefs == null) return;
    
    _position = _prefs!.getString('${_prefix}position') ?? 'bottom';
    _height = _prefs!.getDouble('${_prefix}height') ?? 300;
    _width = _prefs!.getDouble('${_prefix}width') ?? 400;
    _rememberSize = _prefs!.getBool('${_prefix}rememberSize') ?? true;
    _autoOpen = _prefs!.getBool('${_prefix}autoOpen') ?? false;
    _preserveLog = _prefs!.getBool('${_prefix}preserveLog') ?? false;
    _autoExpandErrors = _prefs!.getBool('${_prefix}autoExpandErrors') ?? true;
    _showTimestamps = _prefs!.getBool('${_prefix}showTimestamps') ?? true;
    _darkMode = _prefs!.getBool('${_prefix}darkMode') ?? true;
    
    _consoleShowInfo = _prefs!.getBool('${_prefix}consoleShowInfo') ?? true;
    _consoleShowWarn = _prefs!.getBool('${_prefix}consoleShowWarn') ?? true;
    _consoleShowError = _prefs!.getBool('${_prefix}consoleShowError') ?? true;
    _consoleShowDebug = _prefs!.getBool('${_prefix}consoleShowDebug') ?? false;
    _consoleGroupSimilar = _prefs!.getBool('${_prefix}consoleGroupSimilar') ?? true;
    _consoleMaxEntries = _prefs!.getInt('${_prefix}consoleMaxEntries') ?? 1000;
    _consoleAutoScroll = _prefs!.getBool('${_prefix}consoleAutoScroll') ?? true;
    
    _networkPreserveLog = _prefs!.getBool('${_prefix}networkPreserveLog') ?? false;
    _networkDisableCache = _prefs!.getBool('${_prefix}networkDisableCache') ?? false;
    _networkCaptureBody = _prefs!.getBool('${_prefix}networkCaptureBody') ?? true;
    _networkBodySizeLimit = _prefs!.getInt('${_prefix}networkBodySizeLimit') ?? 102400;
    
    _elementsShowRulers = _prefs!.getBool('${_prefix}elementsShowRulers') ?? true;
    _elementsHighlightOnHover = _prefs!.getBool('${_prefix}elementsHighlightOnHover') ?? true;
    _elementsShowComputedStyles = _prefs!.getBool('${_prefix}elementsShowComputedStyles') ?? true;
    
    _inspectHighlightPadding = _prefs!.getBool('${_prefix}inspectHighlightPadding') ?? true;
    _inspectHighlightMargin = _prefs!.getBool('${_prefix}inspectHighlightMargin') ?? true;
    _inspectHighlightBorder = _prefs!.getBool('${_prefix}inspectHighlightBorder') ?? true;
    _inspectShowTooltip = _prefs!.getBool('${_prefix}inspectShowTooltip') ?? true;
    _inspectShowDimensions = _prefs!.getBool('${_prefix}inspectShowDimensions') ?? true;
    _inspectHighlightColor = _prefs!.getString('${_prefix}inspectHighlightColor') ?? '#FF6B6B';
    _inspectHighlightOpacity = _prefs!.getDouble('${_prefix}inspectHighlightOpacity') ?? 0.3;
    
    _performanceRefreshRate = _prefs!.getInt('${_prefix}performanceRefreshRate') ?? 2;
    _performanceShowFPS = _prefs!.getBool('${_prefix}performanceShowFPS') ?? true;
    _performanceShowMemory = _prefs!.getBool('${_prefix}performanceShowMemory') ?? true;
    
    _resourcesGroupByType = _prefs!.getBool('${_prefix}resourcesGroupByType') ?? true;
    _resourcesShowSize = _prefs!.getBool('${_prefix}resourcesShowSize') ?? true;
    _resourcesShowTiming = _prefs!.getBool('${_prefix}resourcesShowTiming') ?? true;
    
    _fontSize = _prefs!.getDouble('${_prefix}fontSize') ?? 12;
    _fontFamily = _prefs!.getString('${_prefix}fontFamily') ?? 'JetBrains Mono';
    
    notifyListeners();
  }

  Future<void> _save(String key, dynamic value) async {
    if (_prefs == null) return;
    
    if (value is String) {
      await _prefs!.setString('$_prefix$key', value);
    } else if (value is int) {
      await _prefs!.setInt('$_prefix$key', value);
    } else if (value is double) {
      await _prefs!.setDouble('$_prefix$key', value);
    } else if (value is bool) {
      await _prefs!.setBool('$_prefix$key', value);
    }
  }

  // === Setters ===
  
  Future<void> setPosition(String value) async {
    _position = value;
    await _save('position', value);
    notifyListeners();
  }

  Future<void> setHeight(double value) async {
    _height = value;
    if (_rememberSize) await _save('height', value);
    notifyListeners();
  }

  Future<void> setWidth(double value) async {
    _width = value;
    if (_rememberSize) await _save('width', value);
    notifyListeners();
  }

  Future<void> setRememberSize(bool value) async {
    _rememberSize = value;
    await _save('rememberSize', value);
    notifyListeners();
  }

  Future<void> setAutoOpen(bool value) async {
    _autoOpen = value;
    await _save('autoOpen', value);
    notifyListeners();
  }

  Future<void> setPreserveLog(bool value) async {
    _preserveLog = value;
    await _save('preserveLog', value);
    notifyListeners();
  }

  Future<void> setAutoExpandErrors(bool value) async {
    _autoExpandErrors = value;
    await _save('autoExpandErrors', value);
    notifyListeners();
  }

  Future<void> setShowTimestamps(bool value) async {
    _showTimestamps = value;
    await _save('showTimestamps', value);
    notifyListeners();
  }

  Future<void> setConsoleShowInfo(bool value) async {
    _consoleShowInfo = value;
    await _save('consoleShowInfo', value);
    notifyListeners();
  }

  Future<void> setConsoleShowWarn(bool value) async {
    _consoleShowWarn = value;
    await _save('consoleShowWarn', value);
    notifyListeners();
  }

  Future<void> setConsoleShowError(bool value) async {
    _consoleShowError = value;
    await _save('consoleShowError', value);
    notifyListeners();
  }

  Future<void> setConsoleShowDebug(bool value) async {
    _consoleShowDebug = value;
    await _save('consoleShowDebug', value);
    notifyListeners();
  }

  Future<void> setConsoleGroupSimilar(bool value) async {
    _consoleGroupSimilar = value;
    await _save('consoleGroupSimilar', value);
    notifyListeners();
  }

  Future<void> setConsoleMaxEntries(int value) async {
    _consoleMaxEntries = value;
    await _save('consoleMaxEntries', value);
    notifyListeners();
  }

  Future<void> setConsoleAutoScroll(bool value) async {
    _consoleAutoScroll = value;
    await _save('consoleAutoScroll', value);
    notifyListeners();
  }

  Future<void> setNetworkPreserveLog(bool value) async {
    _networkPreserveLog = value;
    await _save('networkPreserveLog', value);
    notifyListeners();
  }

  Future<void> setNetworkDisableCache(bool value) async {
    _networkDisableCache = value;
    await _save('networkDisableCache', value);
    notifyListeners();
  }

  Future<void> setNetworkCaptureBody(bool value) async {
    _networkCaptureBody = value;
    await _save('networkCaptureBody', value);
    notifyListeners();
  }

  Future<void> setNetworkBodySizeLimit(int value) async {
    _networkBodySizeLimit = value;
    await _save('networkBodySizeLimit', value);
    notifyListeners();
  }

  Future<void> setElementsShowRulers(bool value) async {
    _elementsShowRulers = value;
    await _save('elementsShowRulers', value);
    notifyListeners();
  }

  Future<void> setElementsHighlightOnHover(bool value) async {
    _elementsHighlightOnHover = value;
    await _save('elementsHighlightOnHover', value);
    notifyListeners();
  }

  Future<void> setElementsShowComputedStyles(bool value) async {
    _elementsShowComputedStyles = value;
    await _save('elementsShowComputedStyles', value);
    notifyListeners();
  }

  Future<void> setInspectHighlightPadding(bool value) async {
    _inspectHighlightPadding = value;
    await _save('inspectHighlightPadding', value);
    notifyListeners();
  }

  Future<void> setInspectHighlightMargin(bool value) async {
    _inspectHighlightMargin = value;
    await _save('inspectHighlightMargin', value);
    notifyListeners();
  }

  Future<void> setInspectHighlightBorder(bool value) async {
    _inspectHighlightBorder = value;
    await _save('inspectHighlightBorder', value);
    notifyListeners();
  }

  Future<void> setInspectShowTooltip(bool value) async {
    _inspectShowTooltip = value;
    await _save('inspectShowTooltip', value);
    notifyListeners();
  }

  Future<void> setInspectShowDimensions(bool value) async {
    _inspectShowDimensions = value;
    await _save('inspectShowDimensions', value);
    notifyListeners();
  }

  Future<void> setInspectHighlightColor(String value) async {
    _inspectHighlightColor = value;
    await _save('inspectHighlightColor', value);
    notifyListeners();
  }

  Future<void> setInspectHighlightOpacity(double value) async {
    _inspectHighlightOpacity = value;
    await _save('inspectHighlightOpacity', value);
    notifyListeners();
  }

  Future<void> setPerformanceRefreshRate(int value) async {
    _performanceRefreshRate = value;
    await _save('performanceRefreshRate', value);
    notifyListeners();
  }

  Future<void> setPerformanceShowFPS(bool value) async {
    _performanceShowFPS = value;
    await _save('performanceShowFPS', value);
    notifyListeners();
  }

  Future<void> setPerformanceShowMemory(bool value) async {
    _performanceShowMemory = value;
    await _save('performanceShowMemory', value);
    notifyListeners();
  }

  Future<void> setResourcesGroupByType(bool value) async {
    _resourcesGroupByType = value;
    await _save('resourcesGroupByType', value);
    notifyListeners();
  }

  Future<void> setResourcesShowSize(bool value) async {
    _resourcesShowSize = value;
    await _save('resourcesShowSize', value);
    notifyListeners();
  }

  Future<void> setResourcesShowTiming(bool value) async {
    _resourcesShowTiming = value;
    await _save('resourcesShowTiming', value);
    notifyListeners();
  }

  Future<void> setFontSize(double value) async {
    _fontSize = value;
    await _save('fontSize', value);
    notifyListeners();
  }

  Future<void> setFontFamily(String value) async {
    _fontFamily = value;
    await _save('fontFamily', value);
    notifyListeners();
  }

  /// Réinitialise tous les paramètres aux valeurs par défaut
  Future<void> resetToDefaults() async {
    if (_prefs == null) return;
    
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await _prefs!.remove(key);
    }
    
    _loadSettings();
  }

  /// Exporte les paramètres en JSON
  Map<String, dynamic> exportSettings() {
    return {
      'position': _position,
      'height': _height,
      'width': _width,
      'rememberSize': _rememberSize,
      'autoOpen': _autoOpen,
      'preserveLog': _preserveLog,
      'autoExpandErrors': _autoExpandErrors,
      'showTimestamps': _showTimestamps,
      'darkMode': _darkMode,
      'console': {
        'showInfo': _consoleShowInfo,
        'showWarn': _consoleShowWarn,
        'showError': _consoleShowError,
        'showDebug': _consoleShowDebug,
        'groupSimilar': _consoleGroupSimilar,
        'maxEntries': _consoleMaxEntries,
        'autoScroll': _consoleAutoScroll,
      },
      'network': {
        'preserveLog': _networkPreserveLog,
        'disableCache': _networkDisableCache,
        'captureBody': _networkCaptureBody,
        'bodySizeLimit': _networkBodySizeLimit,
      },
      'elements': {
        'showRulers': _elementsShowRulers,
        'highlightOnHover': _elementsHighlightOnHover,
        'showComputedStyles': _elementsShowComputedStyles,
      },
      'inspect': {
        'highlightPadding': _inspectHighlightPadding,
        'highlightMargin': _inspectHighlightMargin,
        'highlightBorder': _inspectHighlightBorder,
        'showTooltip': _inspectShowTooltip,
        'showDimensions': _inspectShowDimensions,
        'highlightColor': _inspectHighlightColor,
        'highlightOpacity': _inspectHighlightOpacity,
      },
      'performance': {
        'refreshRate': _performanceRefreshRate,
        'showFPS': _performanceShowFPS,
        'showMemory': _performanceShowMemory,
      },
      'resources': {
        'groupByType': _resourcesGroupByType,
        'showSize': _resourcesShowSize,
        'showTiming': _resourcesShowTiming,
      },
      'theme': {
        'name': _theme,
        'fontSize': _fontSize,
        'fontFamily': _fontFamily,
      },
    };
  }
}

