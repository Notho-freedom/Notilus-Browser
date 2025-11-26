/// Analyseur de performance pour Notilus Lighthouse
/// Collecte et analyse les Core Web Vitals et métriques de performance
library performance_analyzer;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/lighthouse/audit_models.dart';
import 'lighthouse_service.dart';

/// Analyseur de performance
class PerformanceAnalyzer {
  final LighthouseService _lighthouseService;

  PerformanceAnalyzer(this._lighthouseService);

  /// Analyse complète des performances
  Future<CategoryAnalysisResult?> analyze() async {
    final issues = <Issue>[];
    final recommendations = <Recommendation>[];
    int passed = 0;
    int total = 0;

    try {
      // 1. Core Web Vitals
      final webVitals = await getCoreWebVitals();
      if (webVitals != null) {
        // Vérifier LCP
        total++;
        if (webVitals.lcpStatus == IssueSeverity.passed) {
          passed++;
        } else {
          issues.add(_createLCPIssue(webVitals));
          recommendations.add(_createLCPRecommendation(webVitals));
        }

        // Vérifier FID
        total++;
        if (webVitals.fidStatus == IssueSeverity.passed) {
          passed++;
        } else if (webVitals.fid != null) {
          issues.add(_createFIDIssue(webVitals));
        }

        // Vérifier CLS
        total++;
        if (webVitals.clsStatus == IssueSeverity.passed) {
          passed++;
        } else if (webVitals.cls != null) {
          issues.add(_createCLSIssue(webVitals));
          recommendations.add(_createCLSRecommendation(webVitals));
        }

        // Vérifier TTFB
        total++;
        if (webVitals.ttfbStatus == IssueSeverity.passed) {
          passed++;
        } else if (webVitals.ttfb != null) {
          issues.add(_createTTFBIssue(webVitals));
        }
      }

      // 2. Analyse des ressources bloquantes
      final blockingResult = await _analyzeRenderBlockingResources();
      if (blockingResult != null) {
        total += blockingResult['total'] as int;
        passed += blockingResult['passed'] as int;
        issues.addAll(blockingResult['issues'] as List<Issue>);
        recommendations.addAll(blockingResult['recommendations'] as List<Recommendation>);
      }

      // 3. Analyse des images
      final imageResult = await _analyzeImages();
      if (imageResult != null) {
        total += imageResult['total'] as int;
        passed += imageResult['passed'] as int;
        issues.addAll(imageResult['issues'] as List<Issue>);
        recommendations.addAll(imageResult['recommendations'] as List<Recommendation>);
      }

      // 4. Analyse du JavaScript
      final jsResult = await _analyzeJavaScript();
      if (jsResult != null) {
        total += jsResult['total'] as int;
        passed += jsResult['passed'] as int;
        issues.addAll(jsResult['issues'] as List<Issue>);
        recommendations.addAll(jsResult['recommendations'] as List<Recommendation>);
      }

      // 5. Analyse du CSS
      final cssResult = await _analyzeCSS();
      if (cssResult != null) {
        total += cssResult['total'] as int;
        passed += cssResult['passed'] as int;
        issues.addAll(cssResult['issues'] as List<Issue>);
      }

      // 6. Analyse du cache
      final cacheResult = await _analyzeCache();
      if (cacheResult != null) {
        total += cacheResult['total'] as int;
        passed += cacheResult['passed'] as int;
        issues.addAll(cacheResult['issues'] as List<Issue>);
      }

      final score = total > 0 ? ((passed / total) * 100).round() : 0;

      return CategoryAnalysisResult(
        categoryScore: CategoryScore(
          category: AuditCategory.performance,
          score: score,
          passedAudits: passed,
          totalAudits: total,
          issues: issues,
        ),
        issues: issues,
        recommendations: recommendations,
      );
    } catch (e) {
      debugPrint('Performance analysis error: $e');
      return null;
    }
  }

  /// Récupère les Core Web Vitals
  Future<CoreWebVitals?> getCoreWebVitals() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const perf = window.performance;
        const timing = perf.timing;
        const navigation = perf.getEntriesByType('navigation')[0] || {};
        const paint = perf.getEntriesByType('paint');
        const memory = perf.memory || {};
        
        // First Paint & First Contentful Paint
        const fp = paint.find(p => p.name === 'first-paint');
        const fcp = paint.find(p => p.name === 'first-contentful-paint');
        
        // LCP via PerformanceObserver (si disponible dans le buffer)
        let lcp = null;
        const lcpEntries = perf.getEntriesByType('largest-contentful-paint');
        if (lcpEntries.length > 0) {
          lcp = lcpEntries[lcpEntries.length - 1].startTime;
        }
        
        // TTFB
        const ttfb = navigation.responseStart ? navigation.responseStart - navigation.requestStart : null;
        
        // TTI approximatif
        const tti = timing.domInteractive ? timing.domInteractive - timing.navigationStart : null;
        
        // TBT approximatif (somme des long tasks)
        let tbt = 0;
        const longTasks = perf.getEntriesByType('longtask') || [];
        longTasks.forEach(task => {
          const blockingTime = task.duration - 50;
          if (blockingTime > 0) tbt += blockingTime;
        });
        
        // CLS approximatif
        let cls = 0;
        const layoutShifts = perf.getEntriesByType('layout-shift') || [];
        layoutShifts.forEach(shift => {
          if (!shift.hadRecentInput) {
            cls += shift.value;
          }
        });
        
        // FID (First Input Delay) - nécessite une interaction
        let fid = null;
        const fidEntries = perf.getEntriesByType('first-input');
        if (fidEntries.length > 0) {
          fid = fidEntries[0].processingStart - fidEntries[0].startTime;
        }
        
        // Speed Index approximatif
        const speedIndex = fcp ? fcp.startTime * 0.85 + (lcp || fcp.startTime) * 0.15 : null;
        
        return JSON.stringify({
          lcp: lcp,
          fid: fid,
          cls: cls,
          ttfb: ttfb,
          tti: tti,
          tbt: tbt,
          fcp: fcp ? fcp.startTime : null,
          speedIndex: speedIndex
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        return CoreWebVitals.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing Core Web Vitals: $e');
      }
    }

    return null;
  }

  /// Récupère l'analyse des ressources
  Future<ResourceAnalysis?> getResourceAnalysis() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const resources = performance.getEntriesByType('resource');
        const origin = window.location.origin;
        
        let totalSize = 0;
        let htmlSize = 0;
        let cssSize = 0;
        let jsSize = 0;
        let imageSize = 0;
        let fontsize = 0;
        let otherSize = 0;
        let thirdPartyRequests = 0;
        let thirdPartySize = 0;
        
        const largestResources = [];
        
        resources.forEach(r => {
          const size = r.transferSize || 0;
          totalSize += size;
          
          // Classifier par type
          if (r.initiatorType === 'script' || r.name.endsWith('.js')) {
            jsSize += size;
          } else if (r.initiatorType === 'link' || r.name.endsWith('.css')) {
            cssSize += size;
          } else if (r.initiatorType === 'img' || /\\.(png|jpg|jpeg|gif|webp|svg|ico)/.test(r.name)) {
            imageSize += size;
          } else if (/\\.(woff|woff2|ttf|otf|eot)/.test(r.name)) {
            fontsize += size;
          } else {
            otherSize += size;
          }
          
          // Vérifier si third-party
          if (!r.name.startsWith(origin)) {
            thirdPartyRequests++;
            thirdPartySize += size;
          }
          
          // Garder les plus grandes ressources
          largestResources.push({
            url: r.name,
            type: r.initiatorType,
            size: size,
            loadTime: r.duration,
            isThirdParty: !r.name.startsWith(origin)
          });
        });
        
        // Trier par taille
        largestResources.sort((a, b) => b.size - a.size);
        
        // Taille du document HTML
        htmlSize = document.documentElement.outerHTML.length;
        
        return JSON.stringify({
          totalRequests: resources.length,
          totalSize: totalSize + htmlSize,
          htmlSize: htmlSize,
          cssSize: cssSize,
          jsSize: jsSize,
          imageSize: imageSize,
          fontsize: fontsize,
          otherSize: otherSize,
          thirdPartyRequests: thirdPartyRequests,
          thirdPartySize: thirdPartySize,
          largestResources: largestResources.slice(0, 10)
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        return ResourceAnalysis.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing resource analysis: $e');
      }
    }

    return null;
  }

  /// Analyse des ressources bloquantes
  Future<Map<String, dynamic>?> _analyzeRenderBlockingResources() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const blocking = [];
        
        // Scripts sans defer/async
        document.querySelectorAll('head script[src]:not([async]):not([defer])').forEach(s => {
          blocking.push({
            type: 'script',
            url: s.src,
            size: null
          });
        });
        
        // CSS non-critique
        document.querySelectorAll('link[rel="stylesheet"]:not([media="print"]):not([media="(prefers-reduced-motion)"])').forEach(l => {
          blocking.push({
            type: 'stylesheet',
            url: l.href,
            size: null
          });
        });
        
        return JSON.stringify({
          blockingResources: blocking,
          count: blocking.length
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final blockingCount = data['count'] as int? ?? 0;
        final issues = <Issue>[];
        final recommendations = <Recommendation>[];

        if (blockingCount > 0) {
          final blockingResources = data['blockingResources'] as List<dynamic>;

          issues.add(Issue(
            id: 'perf_render_blocking',
            title: 'Ressources bloquant le rendu',
            description: '$blockingCount ressources bloquent le premier rendu de la page.',
            severity: blockingCount > 3 ? IssueSeverity.critical : IssueSeverity.warning,
            category: AuditCategory.performance,
            rootCause: 'Des scripts et feuilles de style dans le <head> bloquent le parsing HTML.',
            impact: ImpactEstimate(
              metric: 'LCP',
              currentValue: '${blockingCount} ressources',
              estimatedImprovement: '-${blockingCount * 200}ms',
              scoreImpact: blockingCount * 3,
            ),
            suggestedFixes: [
              Fix(
                id: 'fix_defer',
                title: 'Ajouter defer aux scripts',
                description: 'Ajoutez l\'attribut defer aux scripts non-critiques.',
                code: '<script src="script.js" defer></script>',
                effort: EffortLevel.minimal,
                canAutoFix: true,
              ),
              Fix(
                id: 'fix_preload',
                title: 'Précharger les ressources critiques',
                description: 'Utilisez <link rel="preload"> pour les ressources critiques.',
                effort: EffortLevel.moderate,
              ),
            ],
          ));

          recommendations.add(Recommendation(
            id: 'rec_render_blocking',
            title: 'Éliminer les ressources bloquantes',
            description: 'Différez le chargement des ressources non-critiques pour améliorer le LCP.',
            priority: RecommendationPriority.high,
            estimatedImpact: blockingCount * 3,
            effort: EffortLevel.moderate,
            category: AuditCategory.performance,
            actionSteps: [
              ActionStep(order: 1, description: 'Identifier les scripts non-critiques'),
              ActionStep(order: 2, description: 'Ajouter defer ou async à ces scripts'),
              ActionStep(order: 3, description: 'Inliner le CSS critique'),
              ActionStep(order: 4, description: 'Charger le reste du CSS de manière asynchrone'),
            ],
          ));
        }

        return {
          'total': 1,
          'passed': blockingCount == 0 ? 1 : 0,
          'issues': issues,
          'recommendations': recommendations,
        };
      } catch (e) {
        debugPrint('Error analyzing render blocking: $e');
      }
    }

    return null;
  }

  /// Analyse des images
  Future<Map<String, dynamic>?> _analyzeImages() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const issues = [];
        const images = document.querySelectorAll('img');
        
        images.forEach((img, i) => {
          // Vérifier les dimensions manquantes
          if (!img.hasAttribute('width') || !img.hasAttribute('height')) {
            issues.push({
              type: 'no_dimensions',
              src: img.src,
              natural: { w: img.naturalWidth, h: img.naturalHeight }
            });
          }
          
          // Vérifier le lazy loading
          if (!img.loading && img.getBoundingClientRect().top > window.innerHeight) {
            issues.push({
              type: 'no_lazy',
              src: img.src
            });
          }
          
          // Vérifier le format (non-optimisé)
          if (img.src && (img.src.endsWith('.png') || img.src.endsWith('.jpg') || img.src.endsWith('.jpeg'))) {
            issues.push({
              type: 'not_webp',
              src: img.src
            });
          }
          
          // Vérifier les images surdimensionnées
          if (img.naturalWidth > img.offsetWidth * 2) {
            issues.push({
              type: 'oversized',
              src: img.src,
              displayed: { w: img.offsetWidth, h: img.offsetHeight },
              natural: { w: img.naturalWidth, h: img.naturalHeight }
            });
          }
        });
        
        return JSON.stringify({
          totalImages: images.length,
          issues: issues
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final imageIssues = data['issues'] as List<dynamic>;
        final issues = <Issue>[];
        final recommendations = <Recommendation>[];

        // Grouper les problèmes par type
        final noDimensionsCount = imageIssues.where((i) => i['type'] == 'no_dimensions').length;
        final noLazyCount = imageIssues.where((i) => i['type'] == 'no_lazy').length;
        final notWebpCount = imageIssues.where((i) => i['type'] == 'not_webp').length;
        final oversizedCount = imageIssues.where((i) => i['type'] == 'oversized').length;

        int total = 4;
        int passed = 0;

        if (noDimensionsCount == 0) {
          passed++;
        } else {
          issues.add(Issue(
            id: 'perf_img_dimensions',
            title: 'Images sans dimensions explicites',
            description: '$noDimensionsCount images n\'ont pas de dimensions width/height.',
            severity: IssueSeverity.warning,
            category: AuditCategory.performance,
            rootCause: 'Les dimensions manquantes causent des décalages de layout (CLS).',
            impact: ImpactEstimate(
              metric: 'CLS',
              currentValue: '$noDimensionsCount images',
              scoreImpact: noDimensionsCount,
            ),
          ));
        }

        if (noLazyCount == 0) {
          passed++;
        } else {
          issues.add(Issue(
            id: 'perf_img_lazy',
            title: 'Images hors écran sans lazy loading',
            description: '$noLazyCount images hors de l\'écran pourraient utiliser loading="lazy".',
            severity: IssueSeverity.info,
            category: AuditCategory.performance,
          ));
        }

        if (notWebpCount == 0) {
          passed++;
        } else {
          issues.add(Issue(
            id: 'perf_img_format',
            title: 'Images dans des formats non-optimisés',
            description: '$notWebpCount images pourraient utiliser WebP ou AVIF.',
            severity: IssueSeverity.warning,
            category: AuditCategory.performance,
          ));

          recommendations.add(Recommendation(
            id: 'rec_img_webp',
            title: 'Convertir les images en WebP',
            description: 'WebP offre une compression 25-35% meilleure que PNG/JPEG.',
            priority: RecommendationPriority.medium,
            estimatedImpact: 5,
            effort: EffortLevel.moderate,
            category: AuditCategory.performance,
          ));
        }

        if (oversizedCount == 0) {
          passed++;
        } else {
          issues.add(Issue(
            id: 'perf_img_oversized',
            title: 'Images surdimensionnées',
            description: '$oversizedCount images sont plus grandes que leur taille d\'affichage.',
            severity: IssueSeverity.warning,
            category: AuditCategory.performance,
          ));
        }

        return {
          'total': total,
          'passed': passed,
          'issues': issues,
          'recommendations': recommendations,
        };
      } catch (e) {
        debugPrint('Error analyzing images: $e');
      }
    }

    return null;
  }

  /// Analyse du JavaScript
  Future<Map<String, dynamic>?> _analyzeJavaScript() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const scripts = performance.getEntriesByType('resource').filter(r => 
          r.initiatorType === 'script' || r.name.endsWith('.js')
        );
        
        let totalSize = 0;
        let thirdPartySize = 0;
        const origin = window.location.origin;
        
        scripts.forEach(s => {
          totalSize += s.transferSize || 0;
          if (!s.name.startsWith(origin)) {
            thirdPartySize += s.transferSize || 0;
          }
        });
        
        return JSON.stringify({
          count: scripts.length,
          totalSize: totalSize,
          thirdPartySize: thirdPartySize
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final totalSize = data['totalSize'] as int? ?? 0;
        final issues = <Issue>[];
        final recommendations = <Recommendation>[];

        int total = 2;
        int passed = 0;

        // Vérifier la taille totale du JS (seuil: 500KB)
        if (totalSize < 500000) {
          passed++;
        } else {
          issues.add(Issue(
            id: 'perf_js_size',
            title: 'Bundle JavaScript trop volumineux',
            description: 'Le JavaScript total fait ${(totalSize / 1024).round()} KB (seuil: 500 KB).',
            severity: totalSize > 1000000 ? IssueSeverity.critical : IssueSeverity.warning,
            category: AuditCategory.performance,
            rootCause: 'Un bundle JS volumineux ralentit le parsing et l\'exécution.',
            impact: ImpactEstimate(
              metric: 'TTI',
              currentValue: '${(totalSize / 1024).round()} KB',
              estimatedImprovement: 'Réduire de ${((totalSize - 500000) / 1024).round()} KB',
            ),
          ));

          recommendations.add(Recommendation(
            id: 'rec_js_split',
            title: 'Diviser le bundle JavaScript',
            description: 'Utilisez le code-splitting pour réduire le JS initial.',
            priority: RecommendationPriority.high,
            estimatedImpact: 8,
            effort: EffortLevel.significant,
            category: AuditCategory.performance,
          ));
        }

        // Vérifier le JS tiers
        final thirdPartySize = data['thirdPartySize'] as int? ?? 0;
        if (thirdPartySize < 200000) {
          passed++;
        } else {
          issues.add(Issue(
            id: 'perf_js_thirdparty',
            title: 'Scripts tiers volumineux',
            description: 'Les scripts tiers totalisent ${(thirdPartySize / 1024).round()} KB.',
            severity: IssueSeverity.warning,
            category: AuditCategory.performance,
          ));
        }

        return {
          'total': total,
          'passed': passed,
          'issues': issues,
          'recommendations': recommendations,
        };
      } catch (e) {
        debugPrint('Error analyzing JS: $e');
      }
    }

    return null;
  }

  /// Analyse du CSS
  Future<Map<String, dynamic>?> _analyzeCSS() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const stylesheets = document.querySelectorAll('link[rel="stylesheet"]');
        const inlineStyles = document.querySelectorAll('style');
        
        let totalCSS = 0;
        stylesheets.forEach(s => {
          const resource = performance.getEntriesByName(s.href)[0];
          if (resource) totalCSS += resource.transferSize || 0;
        });
        
        inlineStyles.forEach(s => {
          totalCSS += s.textContent.length;
        });
        
        return JSON.stringify({
          externalCount: stylesheets.length,
          inlineCount: inlineStyles.length,
          totalSize: totalCSS
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final totalSize = data['totalSize'] as int? ?? 0;
        final issues = <Issue>[];

        int total = 1;
        int passed = 0;

        if (totalSize < 200000) {
          passed++;
        } else {
          issues.add(Issue(
            id: 'perf_css_size',
            title: 'CSS trop volumineux',
            description: 'Le CSS total fait ${(totalSize / 1024).round()} KB.',
            severity: IssueSeverity.warning,
            category: AuditCategory.performance,
          ));
        }

        return {
          'total': total,
          'passed': passed,
          'issues': issues,
          'recommendations': <Recommendation>[],
        };
      } catch (e) {
        debugPrint('Error analyzing CSS: $e');
      }
    }

    return null;
  }

  /// Analyse du cache
  Future<Map<String, dynamic>?> _analyzeCache() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const resources = performance.getEntriesByType('resource');
        let uncachedCount = 0;
        
        resources.forEach(r => {
          if (r.transferSize === r.encodedBodySize) {
            // Ressource non mise en cache
            uncachedCount++;
          }
        });
        
        return JSON.stringify({
          total: resources.length,
          uncached: uncachedCount
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final totalResources = data['total'] as int? ?? 0;
        final uncachedCount = data['uncached'] as int? ?? 0;
        final issues = <Issue>[];

        int total = 1;
        int passed = 0;

        final cacheRate = totalResources > 0 ? (totalResources - uncachedCount) / totalResources : 1.0;

        if (cacheRate > 0.7) {
          passed++;
        } else {
          issues.add(Issue(
            id: 'perf_cache',
            title: 'Mise en cache insuffisante',
            description: '${(cacheRate * 100).round()}% des ressources sont en cache.',
            severity: IssueSeverity.warning,
            category: AuditCategory.performance,
          ));
        }

        return {
          'total': total,
          'passed': passed,
          'issues': issues,
          'recommendations': <Recommendation>[],
        };
      } catch (e) {
        debugPrint('Error analyzing cache: $e');
      }
    }

    return null;
  }

  // Créateurs d'issues
  Issue _createLCPIssue(CoreWebVitals webVitals) {
    return Issue(
      id: 'perf_lcp',
      title: 'Largest Contentful Paint trop lent',
      description: 'Le LCP est de ${webVitals.formatMs(webVitals.lcp)} (cible: < 2.5s).',
      severity: webVitals.lcpStatus,
      category: AuditCategory.performance,
      rootCause: 'Le plus grand élément visible met trop de temps à s\'afficher.',
      impact: ImpactEstimate(
        metric: 'LCP',
        currentValue: webVitals.formatMs(webVitals.lcp),
        estimatedImprovement: 'Réduire à < 2.5s',
        scoreImpact: 10,
      ),
    );
  }

  Issue _createFIDIssue(CoreWebVitals webVitals) {
    return Issue(
      id: 'perf_fid',
      title: 'First Input Delay élevé',
      description: 'Le FID est de ${webVitals.formatMs(webVitals.fid)} (cible: < 100ms).',
      severity: webVitals.fidStatus,
      category: AuditCategory.performance,
      rootCause: 'Le thread principal est bloqué lors de la première interaction.',
    );
  }

  Issue _createCLSIssue(CoreWebVitals webVitals) {
    return Issue(
      id: 'perf_cls',
      title: 'Cumulative Layout Shift élevé',
      description: 'Le CLS est de ${webVitals.formatCls(webVitals.cls)} (cible: < 0.1).',
      severity: webVitals.clsStatus,
      category: AuditCategory.performance,
      rootCause: 'Des éléments se déplacent après le chargement initial.',
    );
  }

  Issue _createTTFBIssue(CoreWebVitals webVitals) {
    return Issue(
      id: 'perf_ttfb',
      title: 'Time to First Byte lent',
      description: 'Le TTFB est de ${webVitals.formatMs(webVitals.ttfb)} (cible: < 800ms).',
      severity: webVitals.ttfbStatus,
      category: AuditCategory.performance,
      rootCause: 'Le serveur met trop de temps à répondre.',
    );
  }

  Recommendation _createLCPRecommendation(CoreWebVitals webVitals) {
    return Recommendation(
      id: 'rec_lcp',
      title: 'Optimiser le Largest Contentful Paint',
      description: 'Plusieurs techniques peuvent améliorer le LCP.',
      priority: RecommendationPriority.high,
      estimatedImpact: 10,
      effort: EffortLevel.moderate,
      category: AuditCategory.performance,
      actionSteps: [
        ActionStep(order: 1, description: 'Précharger l\'image LCP avec <link rel="preload">'),
        ActionStep(order: 2, description: 'Optimiser le temps de réponse serveur'),
        ActionStep(order: 3, description: 'Éliminer les ressources bloquantes'),
        ActionStep(order: 4, description: 'Utiliser un CDN pour les assets'),
      ],
    );
  }

  Recommendation _createCLSRecommendation(CoreWebVitals webVitals) {
    return Recommendation(
      id: 'rec_cls',
      title: 'Réduire le Cumulative Layout Shift',
      description: 'Stabilisez la mise en page pour une meilleure expérience.',
      priority: RecommendationPriority.high,
      estimatedImpact: 8,
      effort: EffortLevel.minimal,
      category: AuditCategory.performance,
      actionSteps: [
        ActionStep(order: 1, description: 'Ajouter width/height aux images et vidéos'),
        ActionStep(order: 2, description: 'Réserver l\'espace pour les publicités'),
        ActionStep(order: 3, description: 'Éviter d\'injecter du contenu au-dessus du contenu existant'),
        ActionStep(order: 4, description: 'Utiliser transform pour les animations au lieu de properties qui causent un reflow'),
      ],
    );
  }
}

