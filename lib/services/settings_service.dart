import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service centralisé pour toutes les préférences de l'application Notilus
/// Permet de gérer les paramètres de façon cohérente et persistante
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // ============================================
  // CLÉS DE PRÉFÉRENCES
  // ============================================
  
  // Apparence
  static const String _keyThemeMode = 'notilus_theme_mode';
  static const String _keyColorTheme = 'notilus_color_theme';
  static const String _keyNativeBgColor = 'notilus_native_background_color';
  static const String _keyNativeSecondaryColor = 'notilus_native_secondary_color';
  
  // Fonds d'écran
  static const String _keyWallpaperEnabled = 'notilus_wallpaper_enabled';
  static const String _keyWallpaperRotation = 'notilus_wallpaper_rotation';
  static const String _keyWallpaperInterval = 'notilus_wallpaper_interval'; // en minutes
  
  // Onglets
  static const String _keyRestoreTabs = 'notilus_restore_tabs';
  static const String _keyStartOnHome = 'notilus_start_on_home';
  static const String _keyNewTabBehavior = 'notilus_new_tab_behavior'; // 'home', 'blank', 'url'
  static const String _keyNewTabUrl = 'notilus_new_tab_url';
  
  // Téléchargements
  static const String _keyDownloadFolder = 'notilus_download_folder';
  static const String _keyAskDownloadLocation = 'notilus_ask_download_location';
  static const String _keyAutoOpenDownloads = 'notilus_auto_open_downloads';
  
  // Terminal
  static const String _keyPreferredTerminal = 'notilus_preferred_terminal';
  static const String _keyTerminalFontSize = 'notilus_terminal_font_size';
  
  // Page d'accueil
  static const String _keyLeftColumnExpanded = 'notilus_left_column_expanded';
  static const String _keyRightColumnExpanded = 'notilus_right_column_expanded';
  static const String _keyShowSystemWidgets = 'notilus_show_system_widgets';
  static const String _keyShowQuickAccess = 'notilus_show_quick_access';
  static const String _keyShowRecentHistory = 'notilus_show_recent_history';
  static const String _keyHomePageStyle = 'notilus_home_page_style'; // 'modern', 'notilus_dev'
  
  // Services Web Sidebar
  static const String _keyEnabledWebServices = 'notilus_enabled_web_services';
  
  // Confidentialité
  static const String _keySaveHistory = 'notilus_save_history';
  static const String _keySaveCookies = 'notilus_save_cookies';
  static const String _keyBlockTrackers = 'notilus_block_trackers';
  
  // AI Assistant
  static const String _keyAiContextual = 'notilus_ai_contextual';
  static const String _keyAiSummary = 'notilus_ai_summary';
  static const String _keyAiProtection = 'notilus_ai_protection';
  
  // DevTools
  static const String _keyDevToolsPosition = 'notilus_devtools_position'; // 'bottom', 'right', 'detached'
  static const String _keyDevToolsHeight = 'notilus_devtools_height';
  static const String _keyDevToolsShowTimestamps = 'notilus_devtools_show_timestamps';
  static const String _keyDevToolsGroupLogs = 'notilus_devtools_group_logs';
  static const String _keyDevToolsAutoScroll = 'notilus_devtools_auto_scroll';
  static const String _keyDevToolsPreserveLogs = 'notilus_devtools_preserve_logs';
  static const String _keyDevToolsCaptureBody = 'notilus_devtools_capture_body';
  static const String _keyDevToolsDisableCache = 'notilus_devtools_disable_cache';
  static const String _keyDevToolsShowBoxModel = 'notilus_devtools_show_box_model';
  static const String _keyDevToolsShowDimensions = 'notilus_devtools_show_dimensions';
  static const String _keyDevToolsShowGuides = 'notilus_devtools_show_guides';
  static const String _keyDevToolsHighlightColor = 'notilus_devtools_highlight_color';
  static const String _keyDevToolsRefreshRate = 'notilus_devtools_refresh_rate';
  static const String _keyDevToolsFontSize = 'notilus_devtools_font_size';
  
  // ============================================
  // INITIALISATION
  // ============================================
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    notifyListeners();
  }

  // ============================================
  // APPARENCE
  // ============================================
  
  ThemeMode get themeMode {
    final value = _prefs?.getString(_keyThemeMode) ?? 'system';
    switch (value) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs?.setString(_keyThemeMode, value);
    notifyListeners();
  }
  
  String get colorTheme => _prefs?.getString(_keyColorTheme) ?? 'red';
  
  Future<void> setColorTheme(String themeId) async {
    await _prefs?.setString(_keyColorTheme, themeId);
    notifyListeners();
  }
  
  Color? get nativeBackgroundColor {
    final value = _prefs?.getInt(_keyNativeBgColor);
    return value != null ? Color(value) : null;
  }
  
  Future<void> setNativeBackgroundColor(Color? color) async {
    if (color != null) {
      await _prefs?.setInt(_keyNativeBgColor, color.value);
    } else {
      await _prefs?.remove(_keyNativeBgColor);
    }
    notifyListeners();
  }
  
  Color? get nativeSecondaryColor {
    final value = _prefs?.getInt(_keyNativeSecondaryColor);
    return value != null ? Color(value) : null;
  }
  
  Future<void> setNativeSecondaryColor(Color? color) async {
    if (color != null) {
      await _prefs?.setInt(_keyNativeSecondaryColor, color.value);
    } else {
      await _prefs?.remove(_keyNativeSecondaryColor);
    }
    notifyListeners();
  }

  // ============================================
  // FONDS D'ÉCRAN
  // ============================================
  
  bool get wallpaperEnabled => _prefs?.getBool(_keyWallpaperEnabled) ?? true;
  
  Future<void> setWallpaperEnabled(bool enabled) async {
    await _prefs?.setBool(_keyWallpaperEnabled, enabled);
    notifyListeners();
  }
  
  bool get wallpaperRotationEnabled => _prefs?.getBool(_keyWallpaperRotation) ?? true;
  
  Future<void> setWallpaperRotationEnabled(bool enabled) async {
    await _prefs?.setBool(_keyWallpaperRotation, enabled);
    notifyListeners();
  }
  
  int get wallpaperIntervalMinutes => _prefs?.getInt(_keyWallpaperInterval) ?? 2;
  
  Future<void> setWallpaperIntervalMinutes(int minutes) async {
    await _prefs?.setInt(_keyWallpaperInterval, minutes);
    notifyListeners();
  }

  // ============================================
  // ONGLETS
  // ============================================
  
  bool get restoreTabsOnStartup => _prefs?.getBool(_keyRestoreTabs) ?? true;
  
  Future<void> setRestoreTabsOnStartup(bool value) async {
    await _prefs?.setBool(_keyRestoreTabs, value);
    notifyListeners();
  }
  
  bool get startOnHomePage => _prefs?.getBool(_keyStartOnHome) ?? true;
  
  Future<void> setStartOnHomePage(bool value) async {
    await _prefs?.setBool(_keyStartOnHome, value);
    notifyListeners();
  }
  
  String get newTabBehavior => _prefs?.getString(_keyNewTabBehavior) ?? 'home';
  
  Future<void> setNewTabBehavior(String behavior) async {
    await _prefs?.setString(_keyNewTabBehavior, behavior);
    notifyListeners();
  }
  
  String get newTabUrl => _prefs?.getString(_keyNewTabUrl) ?? '';
  
  Future<void> setNewTabUrl(String url) async {
    await _prefs?.setString(_keyNewTabUrl, url);
    notifyListeners();
  }

  // ============================================
  // TÉLÉCHARGEMENTS
  // ============================================
  
  String? get downloadFolder => _prefs?.getString(_keyDownloadFolder);
  
  Future<void> setDownloadFolder(String? path) async {
    if (path != null) {
      await _prefs?.setString(_keyDownloadFolder, path);
    } else {
      await _prefs?.remove(_keyDownloadFolder);
    }
    notifyListeners();
  }
  
  bool get askDownloadLocation => _prefs?.getBool(_keyAskDownloadLocation) ?? false;
  
  Future<void> setAskDownloadLocation(bool value) async {
    await _prefs?.setBool(_keyAskDownloadLocation, value);
    notifyListeners();
  }
  
  bool get autoOpenDownloads => _prefs?.getBool(_keyAutoOpenDownloads) ?? false;
  
  Future<void> setAutoOpenDownloads(bool value) async {
    await _prefs?.setBool(_keyAutoOpenDownloads, value);
    notifyListeners();
  }

  // ============================================
  // TERMINAL
  // ============================================
  
  String get preferredTerminal => _prefs?.getString(_keyPreferredTerminal) ?? 'powershell';
  
  Future<void> setPreferredTerminal(String terminalId) async {
    await _prefs?.setString(_keyPreferredTerminal, terminalId);
    notifyListeners();
  }
  
  double get terminalFontSize => _prefs?.getDouble(_keyTerminalFontSize) ?? 14.0;
  
  Future<void> setTerminalFontSize(double size) async {
    await _prefs?.setDouble(_keyTerminalFontSize, size);
    notifyListeners();
  }

  // ============================================
  // PAGE D'ACCUEIL
  // ============================================
  
  bool get leftColumnExpanded => _prefs?.getBool(_keyLeftColumnExpanded) ?? false;
  
  Future<void> setLeftColumnExpanded(bool expanded) async {
    await _prefs?.setBool(_keyLeftColumnExpanded, expanded);
    notifyListeners();
  }
  
  bool get rightColumnExpanded => _prefs?.getBool(_keyRightColumnExpanded) ?? false;
  
  Future<void> setRightColumnExpanded(bool expanded) async {
    await _prefs?.setBool(_keyRightColumnExpanded, expanded);
    notifyListeners();
  }
  
  bool get showSystemWidgets => _prefs?.getBool(_keyShowSystemWidgets) ?? true;
  
  Future<void> setShowSystemWidgets(bool show) async {
    await _prefs?.setBool(_keyShowSystemWidgets, show);
    notifyListeners();
  }
  
  bool get showQuickAccess => _prefs?.getBool(_keyShowQuickAccess) ?? true;
  
  Future<void> setShowQuickAccess(bool show) async {
    await _prefs?.setBool(_keyShowQuickAccess, show);
    notifyListeners();
  }
  
  bool get showRecentHistory => _prefs?.getBool(_keyShowRecentHistory) ?? true;
  
  Future<void> setShowRecentHistory(bool show) async {
    await _prefs?.setBool(_keyShowRecentHistory, show);
    notifyListeners();
  }
  
  /// Style de la page d'accueil: 'modern' (classique) ou 'notilus_dev' (développeur)
  String get homePageStyle => _prefs?.getString(_keyHomePageStyle) ?? 'modern';
  
  Future<void> setHomePageStyle(String style) async {
    await _prefs?.setString(_keyHomePageStyle, style);
    notifyListeners();
  }

  // ============================================
  // SERVICES WEB SIDEBAR
  // ============================================
  
  List<String> get enabledWebServices {
    final value = _prefs?.getStringList(_keyEnabledWebServices);
    // Par défaut, tous les services sont activés
    return value ?? ['youtubeMusic', 'youtube', 'chatgpt', 'deepseek', 'whatsapp', 'telegram'];
  }
  
  Future<void> setEnabledWebServices(List<String> services) async {
    await _prefs?.setStringList(_keyEnabledWebServices, services);
    notifyListeners();
  }
  
  bool isWebServiceEnabled(String serviceId) {
    return enabledWebServices.contains(serviceId);
  }
  
  Future<void> toggleWebService(String serviceId, bool enabled) async {
    final services = List<String>.from(enabledWebServices);
    if (enabled && !services.contains(serviceId)) {
      services.add(serviceId);
    } else if (!enabled && services.contains(serviceId)) {
      services.remove(serviceId);
    }
    await setEnabledWebServices(services);
  }

  // ============================================
  // CONFIDENTIALITÉ
  // ============================================
  
  bool get saveHistory => _prefs?.getBool(_keySaveHistory) ?? true;
  
  Future<void> setSaveHistory(bool value) async {
    await _prefs?.setBool(_keySaveHistory, value);
    notifyListeners();
  }
  
  bool get saveCookies => _prefs?.getBool(_keySaveCookies) ?? true;
  
  Future<void> setSaveCookies(bool value) async {
    await _prefs?.setBool(_keySaveCookies, value);
    notifyListeners();
  }
  
  bool get blockTrackers => _prefs?.getBool(_keyBlockTrackers) ?? false;
  
  Future<void> setBlockTrackers(bool value) async {
    await _prefs?.setBool(_keyBlockTrackers, value);
    notifyListeners();
  }

  // ============================================
  // AI ASSISTANT
  // ============================================
  
  bool get aiContextualEnabled => _prefs?.getBool(_keyAiContextual) ?? true;
  
  Future<void> setAiContextualEnabled(bool value) async {
    await _prefs?.setBool(_keyAiContextual, value);
    notifyListeners();
  }
  
  bool get aiSummaryEnabled => _prefs?.getBool(_keyAiSummary) ?? false;
  
  Future<void> setAiSummaryEnabled(bool value) async {
    await _prefs?.setBool(_keyAiSummary, value);
    notifyListeners();
  }
  
  bool get aiProtectionEnabled => _prefs?.getBool(_keyAiProtection) ?? true;
  
  Future<void> setAiProtectionEnabled(bool value) async {
    await _prefs?.setBool(_keyAiProtection, value);
    notifyListeners();
  }

  // ============================================
  // DEVTOOLS
  // ============================================
  
  String get devToolsPosition => _prefs?.getString(_keyDevToolsPosition) ?? 'bottom';
  Future<void> setDevToolsPosition(String position) async {
    await _prefs?.setString(_keyDevToolsPosition, position);
    notifyListeners();
  }
  
  double get devToolsHeight => _prefs?.getDouble(_keyDevToolsHeight) ?? 300.0;
  Future<void> setDevToolsHeight(double height) async {
    await _prefs?.setDouble(_keyDevToolsHeight, height);
    notifyListeners();
  }
  
  // Console
  bool get devToolsShowTimestamps => _prefs?.getBool(_keyDevToolsShowTimestamps) ?? true;
  Future<void> setDevToolsShowTimestamps(bool value) async {
    await _prefs?.setBool(_keyDevToolsShowTimestamps, value);
    notifyListeners();
  }
  
  bool get devToolsGroupLogs => _prefs?.getBool(_keyDevToolsGroupLogs) ?? true;
  Future<void> setDevToolsGroupLogs(bool value) async {
    await _prefs?.setBool(_keyDevToolsGroupLogs, value);
    notifyListeners();
  }
  
  bool get devToolsAutoScroll => _prefs?.getBool(_keyDevToolsAutoScroll) ?? true;
  Future<void> setDevToolsAutoScroll(bool value) async {
    await _prefs?.setBool(_keyDevToolsAutoScroll, value);
    notifyListeners();
  }
  
  bool get devToolsPreserveLogs => _prefs?.getBool(_keyDevToolsPreserveLogs) ?? false;
  Future<void> setDevToolsPreserveLogs(bool value) async {
    await _prefs?.setBool(_keyDevToolsPreserveLogs, value);
    notifyListeners();
  }
  
  // Network
  bool get devToolsCaptureBody => _prefs?.getBool(_keyDevToolsCaptureBody) ?? true;
  Future<void> setDevToolsCaptureBody(bool value) async {
    await _prefs?.setBool(_keyDevToolsCaptureBody, value);
    notifyListeners();
  }
  
  bool get devToolsDisableCache => _prefs?.getBool(_keyDevToolsDisableCache) ?? false;
  Future<void> setDevToolsDisableCache(bool value) async {
    await _prefs?.setBool(_keyDevToolsDisableCache, value);
    notifyListeners();
  }
  
  // Inspection
  bool get devToolsShowBoxModel => _prefs?.getBool(_keyDevToolsShowBoxModel) ?? true;
  Future<void> setDevToolsShowBoxModel(bool value) async {
    await _prefs?.setBool(_keyDevToolsShowBoxModel, value);
    notifyListeners();
  }
  
  bool get devToolsShowDimensions => _prefs?.getBool(_keyDevToolsShowDimensions) ?? true;
  Future<void> setDevToolsShowDimensions(bool value) async {
    await _prefs?.setBool(_keyDevToolsShowDimensions, value);
    notifyListeners();
  }
  
  bool get devToolsShowGuides => _prefs?.getBool(_keyDevToolsShowGuides) ?? true;
  Future<void> setDevToolsShowGuides(bool value) async {
    await _prefs?.setBool(_keyDevToolsShowGuides, value);
    notifyListeners();
  }
  
  String get devToolsHighlightColor => _prefs?.getString(_keyDevToolsHighlightColor) ?? '#FF6B6B';
  Future<void> setDevToolsHighlightColor(String value) async {
    await _prefs?.setString(_keyDevToolsHighlightColor, value);
    notifyListeners();
  }
  
  // Performance
  int get devToolsRefreshRate => _prefs?.getInt(_keyDevToolsRefreshRate) ?? 2;
  Future<void> setDevToolsRefreshRate(int value) async {
    await _prefs?.setInt(_keyDevToolsRefreshRate, value);
    notifyListeners();
  }
  
  // Apparence
  double get devToolsFontSize => _prefs?.getDouble(_keyDevToolsFontSize) ?? 12.0;
  Future<void> setDevToolsFontSize(double value) async {
    await _prefs?.setDouble(_keyDevToolsFontSize, value);
    notifyListeners();
  }
  
  // Reset
  Future<void> resetDevToolsSettings() async {
    await _prefs?.remove(_keyDevToolsPosition);
    await _prefs?.remove(_keyDevToolsHeight);
    await _prefs?.remove(_keyDevToolsShowTimestamps);
    await _prefs?.remove(_keyDevToolsGroupLogs);
    await _prefs?.remove(_keyDevToolsAutoScroll);
    await _prefs?.remove(_keyDevToolsPreserveLogs);
    await _prefs?.remove(_keyDevToolsCaptureBody);
    await _prefs?.remove(_keyDevToolsDisableCache);
    await _prefs?.remove(_keyDevToolsShowBoxModel);
    await _prefs?.remove(_keyDevToolsShowDimensions);
    await _prefs?.remove(_keyDevToolsShowGuides);
    await _prefs?.remove(_keyDevToolsHighlightColor);
    await _prefs?.remove(_keyDevToolsRefreshRate);
    await _prefs?.remove(_keyDevToolsFontSize);
    notifyListeners();
  }

  // ============================================
  // UTILITAIRES
  // ============================================
  
  /// Réinitialise toutes les préférences aux valeurs par défaut
  Future<void> resetAllSettings() async {
    await _prefs?.clear();
    notifyListeners();
  }
  
  /// Réinitialise uniquement les préférences d'apparence
  Future<void> resetAppearanceSettings() async {
    await _prefs?.remove(_keyThemeMode);
    await _prefs?.remove(_keyColorTheme);
    await _prefs?.remove(_keyNativeBgColor);
    await _prefs?.remove(_keyNativeSecondaryColor);
    notifyListeners();
  }
  
  /// Réinitialise uniquement les préférences de confidentialité
  Future<void> resetPrivacySettings() async {
    await _prefs?.remove(_keySaveHistory);
    await _prefs?.remove(_keySaveCookies);
    await _prefs?.remove(_keyBlockTrackers);
    notifyListeners();
  }
}
