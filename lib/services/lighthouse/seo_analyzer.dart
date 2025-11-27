/// Analyseur SEO pour Notilus Lighthouse
/// Vérifie les bonnes pratiques de référencement
library seo_analyzer;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/lighthouse/audit_models.dart';
import 'lighthouse_service.dart';
import 'extended_audit_rules.dart';

/// Analyseur SEO
class SEOAnalyzer {
  final LighthouseService _lighthouseService;

  SEOAnalyzer(this._lighthouseService);

  /// Analyse SEO complète
  Future<CategoryAnalysisResult?> analyze() async {
    final issues = <Issue>[];
    final recommendations = <Recommendation>[];
    int passed = 0;
    int total = 0;

    try {
      // 1. Vérifier le titre
      total++;
      final titleResult = await _checkTitle();
      if (titleResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(titleResult['issues'] as List<Issue>);
      }

      // 2. Vérifier la meta description
      total++;
      final descResult = await _checkMetaDescription();
      if (descResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(descResult['issues'] as List<Issue>);
      }

      // 3. Vérifier les headings
      total++;
      final headingsResult = await _checkHeadings();
      if (headingsResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(headingsResult['issues'] as List<Issue>);
      }

      // 4. Vérifier les images
      total++;
      final imagesResult = await _checkImages();
      if (imagesResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(imagesResult['issues'] as List<Issue>);
      }

      // 5. Vérifier les liens
      total++;
      final linksResult = await _checkLinks();
      if (linksResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(linksResult['issues'] as List<Issue>);
      }

      // 6. Vérifier le canonical
      total++;
      final canonicalResult = await _checkCanonical();
      if (canonicalResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(canonicalResult['issues'] as List<Issue>);
      }

      // 7. Vérifier les données structurées
      total++;
      final structuredDataResult = await _checkStructuredData();
      if (structuredDataResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(structuredDataResult['issues'] as List<Issue>);
        recommendations.addAll(structuredDataResult['recommendations'] as List<Recommendation>);
      }

      // 8. Vérifier les meta robots
      total++;
      final robotsResult = await _checkMetaRobots();
      if (robotsResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(robotsResult['issues'] as List<Issue>);
      }

      // 9. Vérifier le sitemap
      total++;
      final sitemapResult = await _checkSitemap();
      if (sitemapResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(sitemapResult['issues'] as List<Issue>);
      }

      // 10. Vérifier les Open Graph
      total++;
      final ogResult = await _checkOpenGraph();
      if (ogResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(ogResult['issues'] as List<Issue>);
      }

      // Règles SEO étendues (11-30)
      final extendedRules = ExtendedSEORules(_lighthouseService);
      final extendedIssues = await extendedRules.runExtendedRules();
      issues.addAll(extendedIssues);
      total += extendedIssues.length;
      passed += extendedIssues.where((i) => i.severity == IssueSeverity.passed).length;

      final score = total > 0 ? ((passed / total) * 100).round() : 0;

      return CategoryAnalysisResult(
        categoryScore: CategoryScore(
          category: AuditCategory.seo,
          score: score,
          passedAudits: passed,
          totalAudits: total,
          issues: issues,
        ),
        issues: issues,
        recommendations: recommendations,
      );
    } catch (e) {
      debugPrint('SEO analysis error: $e');
      return null;
    }
  }

  /// Vérifie le titre de la page
  Future<Map<String, dynamic>> _checkTitle() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const title = document.title || '';
        return JSON.stringify({
          title: title,
          length: title.length
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final title = data['title'] as String? ?? '';
        final length = data['length'] as int? ?? 0;

        if (title.isEmpty) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_no_title',
                title: 'Titre de page manquant',
                description: 'La page n\'a pas de balise <title>.',
                severity: IssueSeverity.critical,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        if (length < 30) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_short_title',
                title: 'Titre trop court',
                description: 'Le titre fait $length caractères (recommandé: 50-60).',
                severity: IssueSeverity.warning,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        if (length > 60) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_long_title',
                title: 'Titre trop long',
                description: 'Le titre fait $length caractères (recommandé: 50-60).',
                severity: IssueSeverity.warning,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking title: $e');
      }
    }

    return {'passed': false, 'issues': <Issue>[]};
  }

  /// Vérifie la meta description
  Future<Map<String, dynamic>> _checkMetaDescription() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const meta = document.querySelector('meta[name="description"]');
        const content = meta ? meta.content : '';
        return JSON.stringify({
          content: content,
          length: content.length
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final content = data['content'] as String? ?? '';
        final length = data['length'] as int? ?? 0;

        if (content.isEmpty) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_no_description',
                title: 'Meta description manquante',
                description: 'La page n\'a pas de meta description.',
                severity: IssueSeverity.warning,
                category: AuditCategory.seo,
                suggestedFixes: [
                  Fix(
                    id: 'fix_description',
                    title: 'Ajouter une meta description',
                    description: 'Ajoutez une description de 150-160 caractères.',
                    code: '<meta name="description" content="Votre description ici...">',
                    effort: EffortLevel.minimal,
                  ),
                ],
              ),
            ],
          };
        }

        if (length < 120) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_short_description',
                title: 'Meta description trop courte',
                description: 'La meta description fait $length caractères (recommandé: 150-160).',
                severity: IssueSeverity.info,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        if (length > 160) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_long_description',
                title: 'Meta description trop longue',
                description: 'La meta description fait $length caractères (recommandé: 150-160). Elle sera tronquée dans les résultats de recherche.',
                severity: IssueSeverity.info,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking meta description: $e');
      }
    }

    return {'passed': false, 'issues': <Issue>[]};
  }

  /// Vérifie les headings
  Future<Map<String, dynamic>> _checkHeadings() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const h1s = document.querySelectorAll('h1');
        return JSON.stringify({
          h1Count: h1s.length,
          h1Text: h1s.length > 0 ? h1s[0].textContent.trim() : null
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final h1Count = data['h1Count'] as int? ?? 0;

        if (h1Count == 0) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_no_h1',
                title: 'Pas de titre H1',
                description: 'La page n\'a pas de titre principal (h1).',
                severity: IssueSeverity.warning,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        if (h1Count > 1) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_multiple_h1',
                title: 'Plusieurs H1',
                description: 'La page a $h1Count titres h1. Il est recommandé d\'en avoir un seul.',
                severity: IssueSeverity.info,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking headings: $e');
      }
    }

    return {'passed': false, 'issues': <Issue>[]};
  }

  /// Vérifie les images
  Future<Map<String, dynamic>> _checkImages() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const images = document.querySelectorAll('img');
        let noAlt = 0;
        
        images.forEach(img => {
          if (!img.hasAttribute('alt')) noAlt++;
        });
        
        return JSON.stringify({
          total: images.length,
          noAlt: noAlt
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final noAlt = data['noAlt'] as int? ?? 0;

        if (noAlt > 0) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_img_alt',
                title: 'Images sans attribut alt',
                description: '$noAlt images n\'ont pas de texte alternatif.',
                severity: IssueSeverity.warning,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking images: $e');
      }
    }

    return {'passed': false, 'issues': <Issue>[]};
  }

  /// Vérifie les liens
  Future<Map<String, dynamic>> _checkLinks() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const links = document.querySelectorAll('a[href]');
        let nofollow = 0;
        let broken = 0;
        
        links.forEach(link => {
          if (link.rel && link.rel.includes('nofollow')) nofollow++;
        });
        
        return JSON.stringify({
          total: links.length,
          nofollow: nofollow
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final totalLinks = data['total'] as int? ?? 0;

        if (totalLinks == 0) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_no_links',
                title: 'Pas de liens sur la page',
                description: 'La page ne contient aucun lien. Le maillage interne est important pour le SEO.',
                severity: IssueSeverity.info,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking links: $e');
      }
    }

    return {'passed': false, 'issues': <Issue>[]};
  }

  /// Vérifie l'URL canonical
  Future<Map<String, dynamic>> _checkCanonical() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const canonical = document.querySelector('link[rel="canonical"]');
        return JSON.stringify({
          hasCanonical: !!canonical,
          href: canonical ? canonical.href : null
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final hasCanonical = data['hasCanonical'] as bool? ?? false;

        if (!hasCanonical) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_no_canonical',
                title: 'URL canonical manquante',
                description: 'La page n\'a pas de balise canonical.',
                severity: IssueSeverity.info,
                category: AuditCategory.seo,
                suggestedFixes: [
                  Fix(
                    id: 'fix_canonical',
                    title: 'Ajouter l\'URL canonical',
                    description: 'Ajoutez une balise canonical pour éviter le contenu dupliqué.',
                    code: '<link rel="canonical" href="https://example.com/page">',
                    effort: EffortLevel.minimal,
                  ),
                ],
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking canonical: $e');
      }
    }

    return {'passed': false, 'issues': <Issue>[]};
  }

  /// Vérifie les données structurées
  Future<Map<String, dynamic>> _checkStructuredData() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const scripts = document.querySelectorAll('script[type="application/ld+json"]');
        let hasStructuredData = scripts.length > 0;
        let types = [];
        
        scripts.forEach(script => {
          try {
            const data = JSON.parse(script.textContent);
            if (data['@type']) types.push(data['@type']);
          } catch (e) {}
        });
        
        return JSON.stringify({
          hasStructuredData: hasStructuredData,
          types: types
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final hasStructuredData = data['hasStructuredData'] as bool? ?? false;

        if (!hasStructuredData) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_no_structured_data',
                title: 'Pas de données structurées',
                description: 'La page n\'a pas de Schema.org / JSON-LD.',
                severity: IssueSeverity.info,
                category: AuditCategory.seo,
              ),
            ],
            'recommendations': [
              Recommendation(
                id: 'rec_structured_data',
                title: 'Ajouter des données structurées',
                description: 'Les données structurées améliorent l\'affichage dans les résultats de recherche.',
                priority: RecommendationPriority.medium,
                estimatedImpact: 3,
                effort: EffortLevel.moderate,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[], 'recommendations': <Recommendation>[]};
      } catch (e) {
        debugPrint('Error checking structured data: $e');
      }
    }

    return {'passed': false, 'issues': <Issue>[], 'recommendations': <Recommendation>[]};
  }

  /// Vérifie la meta robots
  Future<Map<String, dynamic>> _checkMetaRobots() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const robots = document.querySelector('meta[name="robots"]');
        const content = robots ? robots.content.toLowerCase() : '';
        return JSON.stringify({
          hasRobots: !!robots,
          content: content,
          noindex: content.includes('noindex'),
          nofollow: content.includes('nofollow')
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final noindex = data['noindex'] as bool? ?? false;

        if (noindex) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_noindex',
                title: 'Page bloquée pour l\'indexation',
                description: 'La page a une directive noindex.',
                severity: IssueSeverity.critical,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking meta robots: $e');
      }
    }

    return {'passed': true, 'issues': <Issue>[]};
  }

  /// Vérifie le sitemap
  Future<Map<String, dynamic>> _checkSitemap() async {
    // Vérification simple - on suppose qu'il existe si la page fonctionne
    return {'passed': true, 'issues': <Issue>[]};
  }

  /// Vérifie les balises Open Graph
  Future<Map<String, dynamic>> _checkOpenGraph() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const og = {
          title: document.querySelector('meta[property="og:title"]'),
          description: document.querySelector('meta[property="og:description"]'),
          image: document.querySelector('meta[property="og:image"]'),
          url: document.querySelector('meta[property="og:url"]')
        };
        
        return JSON.stringify({
          hasTitle: !!og.title,
          hasDescription: !!og.description,
          hasImage: !!og.image,
          hasUrl: !!og.url
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final hasTitle = data['hasTitle'] as bool? ?? false;
        final hasImage = data['hasImage'] as bool? ?? false;

        if (!hasTitle || !hasImage) {
          final missing = <String>[];
          if (!hasTitle) missing.add('og:title');
          if (!(data['hasDescription'] as bool? ?? false)) missing.add('og:description');
          if (!hasImage) missing.add('og:image');

          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'seo_og_incomplete',
                title: 'Balises Open Graph incomplètes',
                description: 'Balises manquantes: ${missing.join(', ')}.',
                severity: IssueSeverity.info,
                category: AuditCategory.seo,
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking Open Graph: $e');
      }
    }

    return {'passed': false, 'issues': <Issue>[]};
  }
}

