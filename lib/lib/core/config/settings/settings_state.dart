/// Settings State - État des paramètres organisé en catégories
/// Utilise des classes simples en attendant la génération Freezed
library settings_state;

import 'package:flutter/material.dart';

/// État complet des settings
class SettingsState {
  final AppearanceSettings appearance;
  final TabsSettings tabs;
  final PrivacySettings privacy;
  final DevToolsSettings devtools;
  final AdvancedSettings advanced;
  
  const SettingsState({
    this.appearance = const AppearanceSettings(),
    this.tabs = const TabsSettings(),
    this.privacy = const PrivacySettings(),
    this.devtools = const DevToolsSettings(),
    this.advanced = const AdvancedSettings(),
  });
  
  SettingsState copyWith({
    AppearanceSettings? appearance,
    TabsSettings? tabs,
    PrivacySettings? privacy,
    DevToolsSettings? devtools,
    AdvancedSettings? advanced,
  }) {
    return SettingsState(
      appearance: appearance ?? this.appearance,
      tabs: tabs ?? this.tabs,
      privacy: privacy ?? this.privacy,
      devtools: devtools ?? this.devtools,
      advanced: advanced ?? this.advanced,
    );
  }
}

/// Settings d'apparence
class AppearanceSettings {
  final ThemeMode themeMode;
  final String colorTheme;
  final Color nativeBackgroundColor;
  final Color nativeSecondaryColor;
  final bool wallpaperEnabled;
  final bool wallpaperRotation;
  final int wallpaperInterval;
  final double widgetTransparency;
  final double panelTransparency;
  final double glassBlurIntensity;
  
  const AppearanceSettings({
    this.themeMode = ThemeMode.dark,
    this.colorTheme = 'default',
    this.nativeBackgroundColor = const Color(0xFF1A1A2E),
    this.nativeSecondaryColor = const Color(0xFFE94560),
    this.wallpaperEnabled = true,
    this.wallpaperRotation = false,
    this.wallpaperInterval = 30,
    this.widgetTransparency = 0.8,
    this.panelTransparency = 0.9,
    this.glassBlurIntensity = 10.0,
  });
  
  AppearanceSettings copyWith({
    ThemeMode? themeMode,
    String? colorTheme,
    Color? nativeBackgroundColor,
    Color? nativeSecondaryColor,
    bool? wallpaperEnabled,
    bool? wallpaperRotation,
    int? wallpaperInterval,
    double? widgetTransparency,
    double? panelTransparency,
    double? glassBlurIntensity,
  }) {
    return AppearanceSettings(
      themeMode: themeMode ?? this.themeMode,
      colorTheme: colorTheme ?? this.colorTheme,
      nativeBackgroundColor: nativeBackgroundColor ?? this.nativeBackgroundColor,
      nativeSecondaryColor: nativeSecondaryColor ?? this.nativeSecondaryColor,
      wallpaperEnabled: wallpaperEnabled ?? this.wallpaperEnabled,
      wallpaperRotation: wallpaperRotation ?? this.wallpaperRotation,
      wallpaperInterval: wallpaperInterval ?? this.wallpaperInterval,
      widgetTransparency: widgetTransparency ?? this.widgetTransparency,
      panelTransparency: panelTransparency ?? this.panelTransparency,
      glassBlurIntensity: glassBlurIntensity ?? this.glassBlurIntensity,
    );
  }
}

/// Settings des onglets
class TabsSettings {
  final bool restoreTabs;
  final bool startOnHome;
  final String newTabBehavior; // 'home', 'blank', 'url'
  final String? newTabUrl;
  final String tabMode; // 'classic', 'native'
  final bool tabGroupingEnabled;
  final bool tabPreviewEnabled;
  
  const TabsSettings({
    this.restoreTabs = true,
    this.startOnHome = true,
    this.newTabBehavior = 'home',
    this.newTabUrl,
    this.tabMode = 'native',
    this.tabGroupingEnabled = true,
    this.tabPreviewEnabled = true,
  });
  
  TabsSettings copyWith({
    bool? restoreTabs,
    bool? startOnHome,
    String? newTabBehavior,
    String? newTabUrl,
    String? tabMode,
    bool? tabGroupingEnabled,
    bool? tabPreviewEnabled,
  }) {
    return TabsSettings(
      restoreTabs: restoreTabs ?? this.restoreTabs,
      startOnHome: startOnHome ?? this.startOnHome,
      newTabBehavior: newTabBehavior ?? this.newTabBehavior,
      newTabUrl: newTabUrl ?? this.newTabUrl,
      tabMode: tabMode ?? this.tabMode,
      tabGroupingEnabled: tabGroupingEnabled ?? this.tabGroupingEnabled,
      tabPreviewEnabled: tabPreviewEnabled ?? this.tabPreviewEnabled,
    );
  }
}

/// Settings de confidentialité
class PrivacySettings {
  final bool saveHistory;
  final bool saveCookies;
  final bool blockTrackers;
  final bool adBlockerEnabled;
  final bool doNotTrack;
  
  const PrivacySettings({
    this.saveHistory = true,
    this.saveCookies = true,
    this.blockTrackers = true,
    this.adBlockerEnabled = true,
    this.doNotTrack = true,
  });
  
  PrivacySettings copyWith({
    bool? saveHistory,
    bool? saveCookies,
    bool? blockTrackers,
    bool? adBlockerEnabled,
    bool? doNotTrack,
  }) {
    return PrivacySettings(
      saveHistory: saveHistory ?? this.saveHistory,
      saveCookies: saveCookies ?? this.saveCookies,
      blockTrackers: blockTrackers ?? this.blockTrackers,
      adBlockerEnabled: adBlockerEnabled ?? this.adBlockerEnabled,
      doNotTrack: doNotTrack ?? this.doNotTrack,
    );
  }
}

/// Settings des DevTools
class DevToolsSettings {
  final String position; // 'bottom', 'right', 'detached'
  final double height;
  final bool showTimestamps;
  final bool groupLogs;
  final bool autoScroll;
  final bool preserveLogs;
  final double fontSize;
  
  const DevToolsSettings({
    this.position = 'bottom',
    this.height = 300.0,
    this.showTimestamps = true,
    this.groupLogs = true,
    this.autoScroll = true,
    this.preserveLogs = false,
    this.fontSize = 12.0,
  });
  
  DevToolsSettings copyWith({
    String? position,
    double? height,
    bool? showTimestamps,
    bool? groupLogs,
    bool? autoScroll,
    bool? preserveLogs,
    double? fontSize,
  }) {
    return DevToolsSettings(
      position: position ?? this.position,
      height: height ?? this.height,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      groupLogs: groupLogs ?? this.groupLogs,
      autoScroll: autoScroll ?? this.autoScroll,
      preserveLogs: preserveLogs ?? this.preserveLogs,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

/// Settings avancés
class AdvancedSettings {
  final bool showAnimations;
  final String animationSpeed; // 'slow', 'normal', 'fast'
  final String downloadFolder;
  final bool askDownloadLocation;
  final String preferredTerminal;
  final double terminalFontSize;
  final bool soundEffectsEnabled;
  final double soundEffectsVolume;
  
  const AdvancedSettings({
    this.showAnimations = true,
    this.animationSpeed = 'normal',
    this.downloadFolder = '',
    this.askDownloadLocation = true,
    this.preferredTerminal = 'cmd',
    this.terminalFontSize = 14.0,
    this.soundEffectsEnabled = true,
    this.soundEffectsVolume = 0.5,
  });
  
  AdvancedSettings copyWith({
    bool? showAnimations,
    String? animationSpeed,
    String? downloadFolder,
    bool? askDownloadLocation,
    String? preferredTerminal,
    double? terminalFontSize,
    bool? soundEffectsEnabled,
    double? soundEffectsVolume,
  }) {
    return AdvancedSettings(
      showAnimations: showAnimations ?? this.showAnimations,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      downloadFolder: downloadFolder ?? this.downloadFolder,
      askDownloadLocation: askDownloadLocation ?? this.askDownloadLocation,
      preferredTerminal: preferredTerminal ?? this.preferredTerminal,
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      soundEffectsVolume: soundEffectsVolume ?? this.soundEffectsVolume,
    );
  }
}

