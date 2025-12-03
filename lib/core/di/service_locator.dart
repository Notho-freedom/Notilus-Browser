import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

// Services Core
import '../services/secure_storage_service.dart';
import '../services/logger_service.dart';
import '../services/wallpaper_manager.dart';
import '../services/color_theme_manager.dart';
import '../services/theme_mode_notifier.dart';
import '../services/background_music_service.dart';

// Services App
import '../../services/settings_service.dart';
import '../../services/tab_manager.dart';
import '../../services/tab_webview_manager.dart';
import '../../services/download_service.dart';
import '../../services/devtools_service.dart';
import '../../services/mosaic_service.dart';
import '../../services/home_widget_service.dart';
import '../../services/adblocker_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/tabs_preview_service.dart';
import '../../services/backend_process_service.dart';
import '../../services/documentation_service.dart';
import '../../services/text_selection_service.dart';
import '../../services/sound_effects_service.dart';

// Services Auth
import '../../services/auth/firebase_auth_service.dart';
import '../../services/auth/config_sync_service.dart';

// Services Spécialisés
import '../../services/studio/studio_service.dart';
import '../../services/lighthouse/lighthouse_service.dart';
import '../../services/backend_lab/backend_lab_service.dart';
import '../../services/github/github_repos_service.dart';

/// Service Locator global pour l'application Notilus
/// Utilise GetIt pour l'injection de dépendances
final GetIt sl = GetIt.instance;

/// Types d'enregistrement de service
enum ServiceScope {
  /// Singleton: Une seule instance partagée
  singleton,
  /// Lazy Singleton: Créé à la première utilisation
  lazySingleton,
  /// Factory: Nouvelle instance à chaque appel
  factory,
}

/// Configuration du Service Locator
class ServiceLocator {
  static bool _isInitialized = false;
  
  /// Initialise tous les services de l'application
  /// Doit être appelé au démarrage de l'application
  static Future<void> init() async {
    if (_isInitialized) {
      debugPrint('⚠️ ServiceLocator déjà initialisé');
      return;
    }
    
    debugPrint('🚀 Initialisation du ServiceLocator...');
    
    // =========================================
    // Services Core (Singletons immédiats)
    // =========================================
    
    // Logger - Premier à être initialisé
    sl.registerSingleton<LoggerService>(LoggerService());
    await sl<LoggerService>().initialize(enableFileLogging: kDebugMode);
    
    // Stockage sécurisé
    sl.registerSingleton<SecureStorageService>(SecureStorageService());
    
    // Settings - Singleton avec initialisation
    sl.registerSingletonAsync<SettingsService>(() async {
      final service = SettingsService();
      await service.initialize();
      return service;
    });
    
    // =========================================
    // Services UI (Lazy Singletons)
    // =========================================
    
    sl.registerLazySingleton<ThemeModeNotifier>(() => ThemeModeNotifier());
    sl.registerLazySingleton<ColorThemeManager>(() => ColorThemeManager());
    sl.registerLazySingleton<WallpaperManager>(() => WallpaperManager());
    sl.registerLazySingleton<BackgroundMusicService>(() => BackgroundMusicService());
    sl.registerLazySingleton<SoundEffectsService>(() => SoundEffectsService());
    
    // =========================================
    // Services Navigateur (Lazy Singletons)
    // =========================================
    
    sl.registerLazySingleton<TabManager>(() => TabManager());
    sl.registerLazySingleton<TabWebViewManager>(() => TabWebViewManager());
    sl.registerLazySingleton<DownloadService>(() => DownloadService());
    sl.registerLazySingleton<DevToolsService>(() => DevToolsService());
    sl.registerLazySingleton<AdBlockerService>(() => AdBlockerService());
    sl.registerLazySingleton<TabsPreviewService>(() => TabsPreviewService());
    sl.registerLazySingleton<TextSelectionService>(() => TextSelectionService());
    
    // =========================================
    // Services Optionnels (Lazy Singletons)
    // =========================================
    
    sl.registerLazySingleton<NotilusMosaicService>(() => NotilusMosaicService());
    sl.registerLazySingleton<HomeWidgetService>(() => HomeWidgetService()..initialize());
    sl.registerLazySingleton<CloudinaryService>(() => CloudinaryService());
    sl.registerLazySingleton<StudioService>(() => StudioService());
    sl.registerLazySingleton<LighthouseService>(() => LighthouseService());
    sl.registerLazySingleton<DocumentationService>(() => DocumentationService()..initialize());
    
    // =========================================
    // Services Backend (Lazy Singletons)
    // =========================================
    
    sl.registerLazySingleton<BackendProcessService>(() => BackendProcessService());
    sl.registerLazySingleton<BackendLabService>(() => BackendLabService()..checkConnection());
    
    // =========================================
    // Services Auth (Lazy Singletons avec dépendances)
    // =========================================
    
    sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
    
    // ConfigSyncService dépend de FirebaseAuthService et SettingsService
    sl.registerLazySingletonAsync<ConfigSyncService>(() async {
      await sl.isReady<SettingsService>();
      return ConfigSyncService(sl<FirebaseAuthService>(), sl<SettingsService>());
    });
    
    // GitHubReposService dépend de FirebaseAuthService
    sl.registerLazySingleton<GitHubReposService>(
      () => GitHubReposService(sl<FirebaseAuthService>()),
    );
    
    // Attendre que les services async soient prêts
    await sl.allReady();
    
    _isInitialized = true;
    debugPrint('✅ ServiceLocator initialisé avec succès');
  }
  
  /// Réinitialise le Service Locator (utile pour les tests)
  static Future<void> reset() async {
    await sl.reset();
    _isInitialized = false;
    debugPrint('🔄 ServiceLocator réinitialisé');
  }
  
  /// Vérifie si le Service Locator est initialisé
  static bool get isInitialized => _isInitialized;
  
  /// Enregistre un service manuellement
  static void registerService<T extends Object>(
    T instance, {
    ServiceScope scope = ServiceScope.singleton,
  }) {
    if (sl.isRegistered<T>()) {
      debugPrint('⚠️ Service ${T.toString()} déjà enregistré');
      return;
    }
    
    switch (scope) {
      case ServiceScope.singleton:
        sl.registerSingleton<T>(instance);
        break;
      case ServiceScope.lazySingleton:
        sl.registerLazySingleton<T>(() => instance);
        break;
      case ServiceScope.factory:
        sl.registerFactory<T>(() => instance);
        break;
    }
  }
  
  /// Obtient un service enregistré
  static T get<T extends Object>() => sl<T>();
  
  /// Vérifie si un service est enregistré
  static bool isRegistered<T extends Object>() => sl.isRegistered<T>();
}

/// Extensions pour un accès plus facile aux services
extension ServiceLocatorExtension on GetIt {
  /// Obtient le LoggerService
  LoggerService get logger => get<LoggerService>();
  
  /// Obtient le SettingsService
  SettingsService get settings => get<SettingsService>();
  
  /// Obtient le SecureStorageService
  SecureStorageService get secureStorage => get<SecureStorageService>();
  
  /// Obtient le TabManager
  TabManager get tabManager => get<TabManager>();
  
  /// Obtient le TabWebViewManager
  TabWebViewManager get webViewManager => get<TabWebViewManager>();
}

