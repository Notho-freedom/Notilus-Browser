/// Registre centralisé des règles d'audit
/// Contient toutes les règles pour Performance, Accessibility, SEO, Security
library audit_rules_registry;

import '../../models/lighthouse/audit_models.dart';

/// Règle d'audit
class AuditRule {
  final String id;
  final String name;
  final String description;
  final AuditCategory category;
  final IssueSeverity severity;
  final String? wcagCriterion; // Pour les règles WCAG
  final String? seoGuideline; // Pour les règles SEO
  final String? securityStandard; // Pour les règles de sécurité

  AuditRule({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.severity,
    this.wcagCriterion,
    this.seoGuideline,
    this.securityStandard,
  });
}

/// Registre des règles d'audit
class AuditRulesRegistry {
  static final List<AuditRule> _allRules = [];

  /// Règles WCAG 2.1 (Accessibilité)
  static final List<AuditRule> wcagRules = [
    // WCAG 1.1.1 - Text Alternatives
    AuditRule(
      id: 'wcag_1_1_1',
      name: 'Images sans texte alternatif',
      description: 'Toutes les images doivent avoir un attribut alt',
      category: AuditCategory.accessibility,
      severity: IssueSeverity.critical,
      wcagCriterion: '1.1.1',
    ),
    // WCAG 1.3.1 - Info and Relationships
    AuditRule(
      id: 'wcag_1_3_1',
      name: 'Structure sémantique',
      description: 'Utiliser des éléments HTML sémantiques appropriés',
      category: AuditCategory.accessibility,
      severity: IssueSeverity.high,
      wcagCriterion: '1.3.1',
    ),
    // WCAG 1.4.3 - Contrast (Minimum)
    AuditRule(
      id: 'wcag_1_4_3',
      name: 'Contraste des couleurs',
      description: 'Ratio de contraste minimum 4.5:1 pour le texte normal',
      category: AuditCategory.accessibility,
      severity: IssueSeverity.high,
      wcagCriterion: '1.4.3',
    ),
    // WCAG 2.1.1 - Keyboard
    AuditRule(
      id: 'wcag_2_1_1',
      name: 'Navigation au clavier',
      description: 'Toutes les fonctionnalités doivent être accessibles au clavier',
      category: AuditCategory.accessibility,
      severity: IssueSeverity.critical,
      wcagCriterion: '2.1.1',
    ),
    // WCAG 2.4.1 - Bypass Blocks
    AuditRule(
      id: 'wcag_2_4_1',
      name: 'Liens de contournement',
      description: 'Fournir un moyen de contourner les blocs de contenu répétitifs',
      category: AuditCategory.accessibility,
      severity: IssueSeverity.medium,
      wcagCriterion: '2.4.1',
    ),
    // WCAG 2.4.2 - Page Titled
    AuditRule(
      id: 'wcag_2_4_2',
      name: 'Titre de page',
      description: 'Chaque page doit avoir un titre descriptif',
      category: AuditCategory.accessibility,
      severity: IssueSeverity.high,
      wcagCriterion: '2.4.2',
    ),
    // WCAG 3.1.1 - Language of Page
    AuditRule(
      id: 'wcag_3_1_1',
      name: 'Langue du document',
      description: 'La langue principale de la page doit être déclarée',
      category: AuditCategory.accessibility,
      severity: IssueSeverity.medium,
      wcagCriterion: '3.1.1',
    ),
    // WCAG 4.1.2 - Name, Role, Value
    AuditRule(
      id: 'wcag_4_1_2',
      name: 'Nom, rôle, valeur',
      description: 'Tous les composants UI doivent avoir un nom, rôle et valeur accessibles',
      category: AuditCategory.accessibility,
      severity: IssueSeverity.critical,
      wcagCriterion: '4.1.2',
    ),
  ];

  /// Règles SEO
  static final List<AuditRule> seoRules = [
    AuditRule(
      id: 'seo_title',
      name: 'Titre optimisé',
      description: 'Le titre doit être présent, unique et entre 30-60 caractères',
      category: AuditCategory.seo,
      severity: IssueSeverity.high,
      seoGuideline: 'Title Tag Optimization',
    ),
    AuditRule(
      id: 'seo_meta_description',
      name: 'Meta description',
      description: 'Meta description présente et entre 120-160 caractères',
      category: AuditCategory.seo,
      severity: IssueSeverity.medium,
      seoGuideline: 'Meta Description',
    ),
    AuditRule(
      id: 'seo_heading_structure',
      name: 'Structure des headings',
      description: 'Utiliser une hiérarchie H1-H6 logique',
      category: AuditCategory.seo,
      severity: IssueSeverity.medium,
      seoGuideline: 'Heading Structure',
    ),
    AuditRule(
      id: 'seo_canonical',
      name: 'URL canonique',
      description: 'Définir une URL canonique pour éviter le contenu dupliqué',
      category: AuditCategory.seo,
      severity: IssueSeverity.medium,
      seoGuideline: 'Canonical URL',
    ),
    AuditRule(
      id: 'seo_structured_data',
      name: 'Données structurées',
      description: 'Utiliser Schema.org pour améliorer le référencement',
      category: AuditCategory.seo,
      severity: IssueSeverity.low,
      seoGuideline: 'Structured Data',
    ),
    AuditRule(
      id: 'seo_alt_text',
      name: 'Texte alternatif des images',
      description: 'Toutes les images doivent avoir un attribut alt descriptif',
      category: AuditCategory.seo,
      severity: IssueSeverity.medium,
      seoGuideline: 'Image Alt Text',
    ),
    AuditRule(
      id: 'seo_internal_links',
      name: 'Liens internes',
      description: 'Avoir suffisamment de liens internes pour la navigation',
      category: AuditCategory.seo,
      severity: IssueSeverity.low,
      seoGuideline: 'Internal Linking',
    ),
    AuditRule(
      id: 'seo_sitemap',
      name: 'Sitemap XML',
      description: 'Fournir un sitemap XML pour faciliter l\'indexation',
      category: AuditCategory.seo,
      severity: IssueSeverity.low,
      seoGuideline: 'XML Sitemap',
    ),
    AuditRule(
      id: 'seo_robots_txt',
      name: 'robots.txt',
      description: 'Fournir un fichier robots.txt',
      category: AuditCategory.seo,
      severity: IssueSeverity.low,
      seoGuideline: 'robots.txt',
    ),
    AuditRule(
      id: 'seo_open_graph',
      name: 'Meta tags Open Graph',
      description: 'Ajouter des meta tags Open Graph pour les réseaux sociaux',
      category: AuditCategory.seo,
      severity: IssueSeverity.low,
      seoGuideline: 'Open Graph',
    ),
  ];

  /// Règles de sécurité
  static final List<AuditRule> securityRules = [
    AuditRule(
      id: 'sec_https',
      name: 'HTTPS obligatoire',
      description: 'Le site doit utiliser HTTPS',
      category: AuditCategory.security,
      severity: IssueSeverity.critical,
      securityStandard: 'OWASP A02:2021',
    ),
    AuditRule(
      id: 'sec_csp',
      name: 'Content Security Policy',
      description: 'Implémenter une CSP pour prévenir XSS',
      category: AuditCategory.security,
      severity: IssueSeverity.high,
      securityStandard: 'OWASP A03:2021',
    ),
    AuditRule(
      id: 'sec_hsts',
      name: 'HTTP Strict Transport Security',
      description: 'Utiliser HSTS pour forcer HTTPS',
      category: AuditCategory.security,
      severity: IssueSeverity.high,
      securityStandard: 'OWASP A02:2021',
    ),
    AuditRule(
      id: 'sec_x_frame_options',
      name: 'X-Frame-Options',
      description: 'Protéger contre le clickjacking',
      category: AuditCategory.security,
      severity: IssueSeverity.medium,
      securityStandard: 'OWASP A05:2021',
    ),
    AuditRule(
      id: 'sec_x_content_type',
      name: 'X-Content-Type-Options',
      description: 'Empêcher le MIME sniffing',
      category: AuditCategory.security,
      severity: IssueSeverity.medium,
      securityStandard: 'OWASP A05:2021',
    ),
    AuditRule(
      id: 'sec_mixed_content',
      name: 'Contenu mixte',
      description: 'Éviter les ressources HTTP sur une page HTTPS',
      category: AuditCategory.security,
      severity: IssueSeverity.high,
      securityStandard: 'OWASP A02:2021',
    ),
    AuditRule(
      id: 'sec_inline_scripts',
      name: 'Scripts inline',
      description: 'Éviter les scripts inline non sécurisés',
      category: AuditCategory.security,
      severity: IssueSeverity.medium,
      securityStandard: 'OWASP A03:2021',
    ),
    AuditRule(
      id: 'sec_cookies',
      name: 'Cookies sécurisés',
      description: 'Utiliser Secure et HttpOnly pour les cookies sensibles',
      category: AuditCategory.security,
      severity: IssueSeverity.high,
      securityStandard: 'OWASP A02:2021',
    ),
  ];

  /// Règles de performance
  static final List<AuditRule> performanceRules = [
    AuditRule(
      id: 'perf_lcp',
      name: 'Largest Contentful Paint',
      description: 'LCP doit être < 2.5s',
      category: AuditCategory.performance,
      severity: IssueSeverity.high,
    ),
    AuditRule(
      id: 'perf_fid',
      name: 'First Input Delay',
      description: 'FID doit être < 100ms',
      category: AuditCategory.performance,
      severity: IssueSeverity.high,
    ),
    AuditRule(
      id: 'perf_cls',
      name: 'Cumulative Layout Shift',
      description: 'CLS doit être < 0.1',
      category: AuditCategory.performance,
      severity: IssueSeverity.high,
    ),
    AuditRule(
      id: 'perf_image_optimization',
      name: 'Optimisation des images',
      description: 'Compresser et utiliser des formats modernes',
      category: AuditCategory.performance,
      severity: IssueSeverity.medium,
    ),
    AuditRule(
      id: 'perf_lazy_loading',
      name: 'Lazy loading',
      description: 'Utiliser le lazy loading pour les images',
      category: AuditCategory.performance,
      severity: IssueSeverity.medium,
    ),
    AuditRule(
      id: 'perf_minify',
      name: 'Minification',
      description: 'Minifier CSS et JavaScript',
      category: AuditCategory.performance,
      severity: IssueSeverity.medium,
    ),
    AuditRule(
      id: 'perf_caching',
      name: 'Cache',
      description: 'Configurer correctement les headers de cache',
      category: AuditCategory.performance,
      severity: IssueSeverity.low,
    ),
    AuditRule(
      id: 'perf_cdn',
      name: 'CDN',
      description: 'Utiliser un CDN pour les ressources statiques',
      category: AuditCategory.performance,
      severity: IssueSeverity.low,
    ),
  ];

  /// Obtenir toutes les règles
  static List<AuditRule> getAllRules() {
    if (_allRules.isEmpty) {
      _allRules.addAll(wcagRules);
      _allRules.addAll(seoRules);
      _allRules.addAll(securityRules);
      _allRules.addAll(performanceRules);
    }
    return List.unmodifiable(_allRules);
  }

  /// Obtenir les règles par catégorie
  static List<AuditRule> getRulesByCategory(AuditCategory category) {
    return getAllRules().where((r) => r.category == category).toList();
  }

  /// Obtenir une règle par ID
  static AuditRule? getRuleById(String id) {
    return getAllRules().firstWhere(
      (r) => r.id == id,
      orElse: () => throw StateError('Rule not found: $id'),
    );
  }

  /// Compter le total de règles
  static int getTotalRuleCount() {
    return getAllRules().length;
  }
}

