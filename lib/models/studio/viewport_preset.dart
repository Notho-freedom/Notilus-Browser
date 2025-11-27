/// Modèle de preset viewport pour Notilus Studio
/// Définit les caractéristiques d'un appareil pour la simulation responsive
library viewport_preset;

import 'package:flutter/material.dart';

/// Catégorie d'appareil
enum DeviceCategory {
  phone,
  tablet,
  laptop,
  desktop,
  watch,
  custom,
}

extension DeviceCategoryExtension on DeviceCategory {
  String get displayName {
    switch (this) {
      case DeviceCategory.phone:
        return 'Téléphones';
      case DeviceCategory.tablet:
        return 'Tablettes';
      case DeviceCategory.laptop:
        return 'Ordinateurs portables';
      case DeviceCategory.desktop:
        return 'Écrans desktop';
      case DeviceCategory.watch:
        return 'Montres';
      case DeviceCategory.custom:
        return 'Personnalisé';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceCategory.phone:
        return Icons.smartphone;
      case DeviceCategory.tablet:
        return Icons.tablet_mac;
      case DeviceCategory.laptop:
        return Icons.laptop_mac;
      case DeviceCategory.desktop:
        return Icons.desktop_mac;
      case DeviceCategory.watch:
        return Icons.watch;
      case DeviceCategory.custom:
        return Icons.tune;
    }
  }
}

/// Orientation de l'appareil
enum DeviceOrientation {
  portrait,
  landscape,
}

/// Preset de viewport représentant un appareil
class ViewportPreset {
  final String id;
  final String name;
  final String? brand;
  final DeviceCategory category;
  final int width;
  final int height;
  final double devicePixelRatio;
  final String? userAgent;
  final bool isMobile;
  final bool hasTouch;
  final bool isDefault;
  final String? iconAsset;
  final Color? frameColor;

  const ViewportPreset({
    required this.id,
    required this.name,
    this.brand,
    required this.category,
    required this.width,
    required this.height,
    this.devicePixelRatio = 1.0,
    this.userAgent,
    this.isMobile = false,
    this.hasTouch = false,
    this.isDefault = false,
    this.iconAsset,
    this.frameColor,
  });

  /// Crée une copie avec orientation inversée
  ViewportPreset get rotated => ViewportPreset(
        id: id,
        name: name,
        brand: brand,
        category: category,
        width: height,
        height: width,
        devicePixelRatio: devicePixelRatio,
        userAgent: userAgent,
        isMobile: isMobile,
        hasTouch: hasTouch,
        isDefault: isDefault,
        iconAsset: iconAsset,
        frameColor: frameColor,
      );

  /// Orientation actuelle basée sur les dimensions
  DeviceOrientation get orientation =>
      width < height ? DeviceOrientation.portrait : DeviceOrientation.landscape;

  /// Ratio d'aspect
  double get aspectRatio => width / height;

  /// Dimensions formatées
  String get dimensionsText => '${width}×$height';

  /// Taille d'écran approximative en pouces (diagonal)
  double get screenSizeInches {
    final diagonal =
        (width * width + height * height).toDouble();
    return (diagonal / (devicePixelRatio * 160)).round() / 10;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewportPreset &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category.name,
        'width': width,
        'height': height,
        'devicePixelRatio': devicePixelRatio,
        'userAgent': userAgent,
        'isMobile': isMobile,
        'hasTouch': hasTouch,
        'isDefault': isDefault,
      };

  factory ViewportPreset.fromJson(Map<String, dynamic> json) {
    return ViewportPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: DeviceCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DeviceCategory.custom,
      ),
      width: json['width'] as int,
      height: json['height'] as int,
      devicePixelRatio: (json['devicePixelRatio'] as num?)?.toDouble() ?? 1.0,
      userAgent: json['userAgent'] as String?,
      isMobile: json['isMobile'] as bool? ?? false,
      hasTouch: json['hasTouch'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Crée un preset personnalisé
  factory ViewportPreset.custom({
    required String name,
    required int width,
    required int height,
    double devicePixelRatio = 1.0,
    bool isMobile = false,
    bool hasTouch = false,
  }) {
    return ViewportPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: DeviceCategory.custom,
      width: width,
      height: height,
      devicePixelRatio: devicePixelRatio,
      isMobile: isMobile,
      hasTouch: hasTouch,
    );
  }
}

/// Bibliothèque des presets d'appareils populaires
class DevicePresets {
  DevicePresets._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PHONES - iPhone
  // ═══════════════════════════════════════════════════════════════════════════

  static const iPhone15ProMax = ViewportPreset(
    id: 'iphone_15_pro_max',
    name: 'iPhone 15 Pro Max',
    brand: 'Apple',
    category: DeviceCategory.phone,
    width: 430,
    height: 932,
    devicePixelRatio: 3.0,
    isMobile: true,
    hasTouch: true,
    isDefault: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
  );

  static const iPhone15Pro = ViewportPreset(
    id: 'iphone_15_pro',
    name: 'iPhone 15 Pro',
    brand: 'Apple',
    category: DeviceCategory.phone,
    width: 393,
    height: 852,
    devicePixelRatio: 3.0,
    isMobile: true,
    hasTouch: true,
    isDefault: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
  );

  static const iPhone14 = ViewportPreset(
    id: 'iphone_14',
    name: 'iPhone 14',
    brand: 'Apple',
    category: DeviceCategory.phone,
    width: 390,
    height: 844,
    devicePixelRatio: 3.0,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
  );

  static const iPhoneSE = ViewportPreset(
    id: 'iphone_se',
    name: 'iPhone SE',
    brand: 'Apple',
    category: DeviceCategory.phone,
    width: 375,
    height: 667,
    devicePixelRatio: 2.0,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
  );

  static const iPhone12Mini = ViewportPreset(
    id: 'iphone_12_mini',
    name: 'iPhone 12 Mini',
    brand: 'Apple',
    category: DeviceCategory.phone,
    width: 360,
    height: 780,
    devicePixelRatio: 3.0,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15',
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // PHONES - Android
  // ═══════════════════════════════════════════════════════════════════════════

  static const pixel8Pro = ViewportPreset(
    id: 'pixel_8_pro',
    name: 'Pixel 8 Pro',
    brand: 'Google',
    category: DeviceCategory.phone,
    width: 448,
    height: 998,
    devicePixelRatio: 3.0,
    isMobile: true,
    hasTouch: true,
    isDefault: true,
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36',
  );

  static const pixel7 = ViewportPreset(
    id: 'pixel_7',
    name: 'Pixel 7',
    brand: 'Google',
    category: DeviceCategory.phone,
    width: 412,
    height: 915,
    devicePixelRatio: 2.625,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36',
  );

  static const samsungS24Ultra = ViewportPreset(
    id: 'samsung_s24_ultra',
    name: 'Samsung Galaxy S24 Ultra',
    brand: 'Samsung',
    category: DeviceCategory.phone,
    width: 480,
    height: 1040,
    devicePixelRatio: 3.0,
    isMobile: true,
    hasTouch: true,
    isDefault: true,
    userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36',
  );

  static const samsungS23 = ViewportPreset(
    id: 'samsung_s23',
    name: 'Samsung Galaxy S23',
    brand: 'Samsung',
    category: DeviceCategory.phone,
    width: 360,
    height: 780,
    devicePixelRatio: 3.0,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (Linux; Android 13; SM-S911B) AppleWebKit/537.36',
  );

  static const samsungA54 = ViewportPreset(
    id: 'samsung_a54',
    name: 'Samsung Galaxy A54',
    brand: 'Samsung',
    category: DeviceCategory.phone,
    width: 412,
    height: 915,
    devicePixelRatio: 2.625,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (Linux; Android 13; SM-A546B) AppleWebKit/537.36',
  );

  static const onePlus12 = ViewportPreset(
    id: 'oneplus_12',
    name: 'OnePlus 12',
    brand: 'OnePlus',
    category: DeviceCategory.phone,
    width: 412,
    height: 919,
    devicePixelRatio: 3.0,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (Linux; Android 14; CPH2573) AppleWebKit/537.36',
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TABLETS
  // ═══════════════════════════════════════════════════════════════════════════

  static const iPadPro129 = ViewportPreset(
    id: 'ipad_pro_12_9',
    name: 'iPad Pro 12.9"',
    brand: 'Apple',
    category: DeviceCategory.tablet,
    width: 1024,
    height: 1366,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: true,
    isDefault: true,
    userAgent: 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
  );

  static const iPadPro11 = ViewportPreset(
    id: 'ipad_pro_11',
    name: 'iPad Pro 11"',
    brand: 'Apple',
    category: DeviceCategory.tablet,
    width: 834,
    height: 1194,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
  );

  static const iPadAir = ViewportPreset(
    id: 'ipad_air',
    name: 'iPad Air',
    brand: 'Apple',
    category: DeviceCategory.tablet,
    width: 820,
    height: 1180,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
  );

  static const iPadMini = ViewportPreset(
    id: 'ipad_mini',
    name: 'iPad Mini',
    brand: 'Apple',
    category: DeviceCategory.tablet,
    width: 744,
    height: 1133,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
  );

  static const samsungTabS9Ultra = ViewportPreset(
    id: 'samsung_tab_s9_ultra',
    name: 'Samsung Galaxy Tab S9 Ultra',
    brand: 'Samsung',
    category: DeviceCategory.tablet,
    width: 1848,
    height: 2960,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-X916B) AppleWebKit/537.36',
  );

  static const surfacePro9 = ViewportPreset(
    id: 'surface_pro_9',
    name: 'Surface Pro 9',
    brand: 'Microsoft',
    category: DeviceCategory.tablet,
    width: 1920,
    height: 1280,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LAPTOPS
  // ═══════════════════════════════════════════════════════════════════════════

  static const macBookAir13 = ViewportPreset(
    id: 'macbook_air_13',
    name: 'MacBook Air 13"',
    brand: 'Apple',
    category: DeviceCategory.laptop,
    width: 1440,
    height: 900,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: false,
    isDefault: true,
  );

  static const macBookPro14 = ViewportPreset(
    id: 'macbook_pro_14',
    name: 'MacBook Pro 14"',
    brand: 'Apple',
    category: DeviceCategory.laptop,
    width: 1512,
    height: 982,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: false,
  );

  static const macBookPro16 = ViewportPreset(
    id: 'macbook_pro_16',
    name: 'MacBook Pro 16"',
    brand: 'Apple',
    category: DeviceCategory.laptop,
    width: 1728,
    height: 1117,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: false,
  );

  static const laptop13HD = ViewportPreset(
    id: 'laptop_13_hd',
    name: 'Laptop 13" HD',
    category: DeviceCategory.laptop,
    width: 1366,
    height: 768,
    devicePixelRatio: 1.0,
    isMobile: false,
    hasTouch: false,
  );

  static const laptop15FHD = ViewportPreset(
    id: 'laptop_15_fhd',
    name: 'Laptop 15" FHD',
    category: DeviceCategory.laptop,
    width: 1920,
    height: 1080,
    devicePixelRatio: 1.0,
    isMobile: false,
    hasTouch: false,
    isDefault: true,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOPS
  // ═══════════════════════════════════════════════════════════════════════════

  static const desktop1080p = ViewportPreset(
    id: 'desktop_1080p',
    name: 'Desktop FHD (1080p)',
    category: DeviceCategory.desktop,
    width: 1920,
    height: 1080,
    devicePixelRatio: 1.0,
    isMobile: false,
    hasTouch: false,
    isDefault: true,
  );

  static const desktop1440p = ViewportPreset(
    id: 'desktop_1440p',
    name: 'Desktop QHD (1440p)',
    category: DeviceCategory.desktop,
    width: 2560,
    height: 1440,
    devicePixelRatio: 1.0,
    isMobile: false,
    hasTouch: false,
  );

  static const desktop4K = ViewportPreset(
    id: 'desktop_4k',
    name: 'Desktop 4K UHD',
    category: DeviceCategory.desktop,
    width: 3840,
    height: 2160,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: false,
  );

  static const ultrawide = ViewportPreset(
    id: 'ultrawide',
    name: 'Ultrawide 21:9',
    category: DeviceCategory.desktop,
    width: 2560,
    height: 1080,
    devicePixelRatio: 1.0,
    isMobile: false,
    hasTouch: false,
  );

  static const iMac24 = ViewportPreset(
    id: 'imac_24',
    name: 'iMac 24"',
    brand: 'Apple',
    category: DeviceCategory.desktop,
    width: 2240,
    height: 1260,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: false,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // WATCHES
  // ═══════════════════════════════════════════════════════════════════════════

  static const appleWatchUltra = ViewportPreset(
    id: 'apple_watch_ultra',
    name: 'Apple Watch Ultra',
    brand: 'Apple',
    category: DeviceCategory.watch,
    width: 410,
    height: 502,
    devicePixelRatio: 2.0,
    isMobile: true,
    hasTouch: true,
  );

  static const appleWatch45 = ViewportPreset(
    id: 'apple_watch_45',
    name: 'Apple Watch 45mm',
    brand: 'Apple',
    category: DeviceCategory.watch,
    width: 396,
    height: 484,
    devicePixelRatio: 2.0,
    isMobile: true,
    hasTouch: true,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON BREAKPOINTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const mobileS = ViewportPreset(
    id: 'mobile_s',
    name: 'Mobile S (320px)',
    category: DeviceCategory.phone,
    width: 320,
    height: 568,
    devicePixelRatio: 2.0,
    isMobile: true,
    hasTouch: true,
  );

  static const mobileM = ViewportPreset(
    id: 'mobile_m',
    name: 'Mobile M (375px)',
    category: DeviceCategory.phone,
    width: 375,
    height: 667,
    devicePixelRatio: 2.0,
    isMobile: true,
    hasTouch: true,
  );

  static const mobileL = ViewportPreset(
    id: 'mobile_l',
    name: 'Mobile L (425px)',
    category: DeviceCategory.phone,
    width: 425,
    height: 812,
    devicePixelRatio: 2.0,
    isMobile: true,
    hasTouch: true,
  );

  static const tablet = ViewportPreset(
    id: 'tablet_768',
    name: 'Tablet (768px)',
    category: DeviceCategory.tablet,
    width: 768,
    height: 1024,
    devicePixelRatio: 2.0,
    isMobile: false,
    hasTouch: true,
  );

  static const laptopSmall = ViewportPreset(
    id: 'laptop_1024',
    name: 'Laptop (1024px)',
    category: DeviceCategory.laptop,
    width: 1024,
    height: 768,
    devicePixelRatio: 1.0,
    isMobile: false,
    hasTouch: false,
  );

  static const laptopLarge = ViewportPreset(
    id: 'laptop_1440',
    name: 'Laptop L (1440px)',
    category: DeviceCategory.laptop,
    width: 1440,
    height: 900,
    devicePixelRatio: 1.0,
    isMobile: false,
    hasTouch: false,
  );

  /// Tous les presets disponibles
  static List<ViewportPreset> get all => [
        // Phones - iPhone
        iPhone15ProMax,
        iPhone15Pro,
        iPhone14,
        iPhoneSE,
        iPhone12Mini,
        // Phones - Android
        pixel8Pro,
        pixel7,
        samsungS24Ultra,
        samsungS23,
        samsungA54,
        onePlus12,
        // Tablets
        iPadPro129,
        iPadPro11,
        iPadAir,
        iPadMini,
        samsungTabS9Ultra,
        surfacePro9,
        // Laptops
        macBookAir13,
        macBookPro14,
        macBookPro16,
        laptop13HD,
        laptop15FHD,
        // Desktops
        desktop1080p,
        desktop1440p,
        desktop4K,
        ultrawide,
        iMac24,
        // Watches
        appleWatchUltra,
        appleWatch45,
        // Breakpoints
        mobileS,
        mobileM,
        mobileL,
        tablet,
        laptopSmall,
        laptopLarge,
      ];

  /// Presets par défaut (affichés en premier)
  static List<ViewportPreset> get defaults =>
      all.where((p) => p.isDefault).toList();

  /// Presets par catégorie
  static List<ViewportPreset> byCategory(DeviceCategory category) =>
      all.where((p) => p.category == category).toList();

  /// Presets par marque
  static List<ViewportPreset> byBrand(String brand) =>
      all.where((p) => p.brand?.toLowerCase() == brand.toLowerCase()).toList();

  /// Recherche de preset
  static List<ViewportPreset> search(String query) {
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.brand?.toLowerCase().contains(q) ?? false))
        .toList();
  }
}

