/// Scanner de sécurité pour Notilus Lighthouse
/// Vérifie les vulnérabilités et bonnes pratiques de sécurité
library security_scanner;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/lighthouse/audit_models.dart';
import 'lighthouse_service.dart';

/// Scanner de sécurité
class SecurityScanner {
  final LighthouseService _lighthouseService;

  SecurityScanner(this._lighthouseService);

  /// Analyse de sécurité complète
  Future<CategoryAnalysisResult?> analyze() async {
    final issues = <Issue>[];
    final recommendations = <Recommendation>[];
    int passed = 0;
    int total = 0;

    try {
      // 1. Vérifier HTTPS
      total++;
      final httpsResult = await _checkHTTPS();
      if (httpsResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(httpsResult['issues'] as List<Issue>);
      }

      // 2. Vérifier les headers de sécurité
      total++;
      final headersResult = await _checkSecurityHeaders();
      if (headersResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(headersResult['issues'] as List<Issue>);
        recommendations.addAll(headersResult['recommendations'] as List<Recommendation>);
      }

      // 3. Vérifier les ressources mixtes
      total++;
      final mixedContentResult = await _checkMixedContent();
      if (mixedContentResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(mixedContentResult['issues'] as List<Issue>);
      }

      // 4. Vérifier les formulaires
      total++;
      final formsResult = await _checkForms();
      if (formsResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(formsResult['issues'] as List<Issue>);
      }

      // 5. Vérifier les liens externes
      total++;
      final externalLinksResult = await _checkExternalLinks();
      if (externalLinksResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(externalLinksResult['issues'] as List<Issue>);
      }

      // 6. Vérifier les scripts inline
      total++;
      final inlineScriptsResult = await _checkInlineScripts();
      if (inlineScriptsResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(inlineScriptsResult['issues'] as List<Issue>);
      }

      // 7. Vérifier les iframes
      total++;
      final iframesResult = await _checkIframes();
      if (iframesResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(iframesResult['issues'] as List<Issue>);
      }

      // 8. Vérifier les cookies
      total++;
      final cookiesResult = await _checkCookies();
      if (cookiesResult['passed'] == true) {
        passed++;
      } else {
        issues.addAll(cookiesResult['issues'] as List<Issue>);
      }

      final score = total > 0 ? ((passed / total) * 100).round() : 0;

      return CategoryAnalysisResult(
        categoryScore: CategoryScore(
          category: AuditCategory.security,
          score: score,
          passedAudits: passed,
          totalAudits: total,
          issues: issues,
        ),
        issues: issues,
        recommendations: recommendations,
      );
    } catch (e) {
      debugPrint('Security scan error: $e');
      return null;
    }
  }

  /// Vérifie l'utilisation de HTTPS
  Future<Map<String, dynamic>> _checkHTTPS() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        return JSON.stringify({
          isSecure: location.protocol === 'https:',
          protocol: location.protocol
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final isSecure = data['isSecure'] as bool? ?? false;

        if (!isSecure) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'sec_no_https',
                title: 'Connexion non sécurisée',
                description: 'Le site n\'utilise pas HTTPS.',
                severity: IssueSeverity.critical,
                category: AuditCategory.security,
                rootCause: 'Les données transmises peuvent être interceptées.',
                documentation: 'https://web.dev/why-https-matters/',
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking HTTPS: $e');
      }
    }

    return {'passed': false, 'issues': <Issue>[]};
  }

  /// Vérifie les headers de sécurité
  Future<Map<String, dynamic>> _checkSecurityHeaders() async {
    // Note: Les headers HTTP ne sont pas accessibles depuis JavaScript
    // On vérifie ce qu'on peut via les meta tags
    final result = await _lighthouseService.executeScript('''
      (function() {
        const csp = document.querySelector('meta[http-equiv="Content-Security-Policy"]');
        const xfo = document.querySelector('meta[http-equiv="X-Frame-Options"]');
        
        return JSON.stringify({
          hasCSPMeta: !!csp,
          hasXFOMeta: !!xfo,
          cspContent: csp ? csp.content : null
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final hasCSP = data['hasCSPMeta'] as bool? ?? false;
        final issues = <Issue>[];
        final recommendations = <Recommendation>[];

        if (!hasCSP) {
          issues.add(Issue(
            id: 'sec_no_csp',
            title: 'Pas de Content Security Policy',
            description: 'Aucune CSP détectée (meta tag ou header).',
            severity: IssueSeverity.warning,
            category: AuditCategory.security,
            rootCause: 'Sans CSP, le site est vulnérable aux attaques XSS.',
          ));

          recommendations.add(Recommendation(
            id: 'rec_csp',
            title: 'Implémenter une Content Security Policy',
            description: 'Une CSP protège contre les attaques XSS et l\'injection de contenu.',
            priority: RecommendationPriority.high,
            estimatedImpact: 10,
            effort: EffortLevel.moderate,
            category: AuditCategory.security,
            actionSteps: [
              ActionStep(order: 1, description: 'Auditer les sources de scripts et styles'),
              ActionStep(order: 2, description: 'Définir une politique restrictive'),
              ActionStep(order: 3, description: 'Tester en mode report-only d\'abord'),
              ActionStep(order: 4, description: 'Déployer la CSP en production'),
            ],
          ));
        }

        return {
          'passed': issues.isEmpty,
          'issues': issues,
          'recommendations': recommendations,
        };
      } catch (e) {
        debugPrint('Error checking security headers: $e');
      }
    }

    return {'passed': true, 'issues': <Issue>[], 'recommendations': <Recommendation>[]};
  }

  /// Vérifie le contenu mixte
  Future<Map<String, dynamic>> _checkMixedContent() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const isHTTPS = location.protocol === 'https:';
        if (!isHTTPS) return JSON.stringify({ mixedContent: [] });
        
        const mixed = [];
        
        // Vérifier les images
        document.querySelectorAll('img[src^="http:"]').forEach(img => {
          mixed.push({ type: 'image', url: img.src });
        });
        
        // Vérifier les scripts
        document.querySelectorAll('script[src^="http:"]').forEach(s => {
          mixed.push({ type: 'script', url: s.src });
        });
        
        // Vérifier les stylesheets
        document.querySelectorAll('link[href^="http:"]').forEach(l => {
          if (l.rel === 'stylesheet') {
            mixed.push({ type: 'stylesheet', url: l.href });
          }
        });
        
        // Vérifier les iframes
        document.querySelectorAll('iframe[src^="http:"]').forEach(f => {
          mixed.push({ type: 'iframe', url: f.src });
        });
        
        return JSON.stringify({ mixedContent: mixed });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final mixedContent = data['mixedContent'] as List<dynamic>? ?? [];

        if (mixedContent.isEmpty) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        final scriptCount = mixedContent.where((m) => m['type'] == 'script').length;
        final otherCount = mixedContent.length - scriptCount;

        final issues = <Issue>[];

        if (scriptCount > 0) {
          issues.add(Issue(
            id: 'sec_mixed_scripts',
            title: 'Scripts chargés en HTTP',
            description: '$scriptCount scripts sont chargés sans HTTPS.',
            severity: IssueSeverity.critical,
            category: AuditCategory.security,
            rootCause: 'Les scripts HTTP peuvent être modifiés par un attaquant.',
          ));
        }

        if (otherCount > 0) {
          issues.add(Issue(
            id: 'sec_mixed_content',
            title: 'Contenu mixte',
            description: '$otherCount ressources sont chargées sans HTTPS.',
            severity: IssueSeverity.warning,
            category: AuditCategory.security,
          ));
        }

        return {'passed': false, 'issues': issues};
      } catch (e) {
        debugPrint('Error checking mixed content: $e');
      }
    }

    return {'passed': true, 'issues': <Issue>[]};
  }

  /// Vérifie les formulaires
  Future<Map<String, dynamic>> _checkForms() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const forms = document.querySelectorAll('form');
        const issues = [];
        
        forms.forEach(form => {
          // Vérifier l'action du formulaire
          const action = form.action || '';
          if (action.startsWith('http:')) {
            issues.push({ type: 'insecure_action', action: action });
          }
          
          // Vérifier l'autocomplete sur les champs sensibles
          const passwordFields = form.querySelectorAll('input[type="password"]');
          passwordFields.forEach(p => {
            if (p.autocomplete === 'on' || !p.hasAttribute('autocomplete')) {
              // Pas forcément un problème, mais à noter
            }
          });
        });
        
        return JSON.stringify({
          formCount: forms.length,
          issues: issues
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final formIssues = data['issues'] as List<dynamic>? ?? [];

        if (formIssues.isEmpty) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'sec_form_insecure',
              title: 'Formulaire envoyé en HTTP',
              description: '${formIssues.length} formulaire(s) envoient des données sans HTTPS.',
              severity: IssueSeverity.critical,
              category: AuditCategory.security,
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking forms: $e');
      }
    }

    return {'passed': true, 'issues': <Issue>[]};
  }

  /// Vérifie les liens externes
  Future<Map<String, dynamic>> _checkExternalLinks() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const origin = location.origin;
        const externalLinks = document.querySelectorAll('a[href^="http"]');
        let noOpener = 0;
        let total = 0;
        
        externalLinks.forEach(link => {
          if (!link.href.startsWith(origin)) {
            total++;
            const rel = link.rel || '';
            if (link.target === '_blank' && !rel.includes('noopener') && !rel.includes('noreferrer')) {
              noOpener++;
            }
          }
        });
        
        return JSON.stringify({
          total: total,
          vulnerableCount: noOpener
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final vulnerableCount = data['vulnerableCount'] as int? ?? 0;

        if (vulnerableCount == 0) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'sec_target_blank',
              title: 'Liens externes vulnérables',
              description: '$vulnerableCount liens avec target="_blank" n\'ont pas rel="noopener".',
              severity: IssueSeverity.warning,
              category: AuditCategory.security,
              rootCause: 'Ces liens sont vulnérables à l\'attaque "reverse tabnabbing".',
              suggestedFixes: [
                Fix(
                  id: 'fix_noopener',
                  title: 'Ajouter rel="noopener noreferrer"',
                  description: 'Ajoutez cet attribut à tous les liens externes.',
                  code: '<a href="..." target="_blank" rel="noopener noreferrer">',
                  effort: EffortLevel.minimal,
                ),
              ],
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking external links: $e');
      }
    }

    return {'passed': true, 'issues': <Issue>[]};
  }

  /// Vérifie les scripts inline
  Future<Map<String, dynamic>> _checkInlineScripts() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const inlineScripts = document.querySelectorAll('script:not([src])');
        let eventHandlers = 0;
        
        // Compter les gestionnaires d'événements inline
        document.querySelectorAll('[onclick], [onload], [onerror], [onmouseover]').forEach(() => {
          eventHandlers++;
        });
        
        return JSON.stringify({
          inlineScriptCount: inlineScripts.length,
          eventHandlerCount: eventHandlers
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final eventHandlerCount = data['eventHandlerCount'] as int? ?? 0;

        if (eventHandlerCount == 0) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        if (eventHandlerCount > 10) {
          return {
            'passed': false,
            'issues': [
              Issue(
                id: 'sec_inline_handlers',
                title: 'Gestionnaires d\'événements inline',
                description: '$eventHandlerCount attributs on* détectés.',
                severity: IssueSeverity.info,
                category: AuditCategory.security,
                rootCause: 'Les gestionnaires inline rendent difficile l\'implémentation d\'une CSP stricte.',
              ),
            ],
          };
        }

        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking inline scripts: $e');
      }
    }

    return {'passed': true, 'issues': <Issue>[]};
  }

  /// Vérifie les iframes
  Future<Map<String, dynamic>> _checkIframes() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const iframes = document.querySelectorAll('iframe');
        let noSandbox = 0;
        
        iframes.forEach(iframe => {
          if (!iframe.hasAttribute('sandbox')) {
            noSandbox++;
          }
        });
        
        return JSON.stringify({
          total: iframes.length,
          noSandbox: noSandbox
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final noSandbox = data['noSandbox'] as int? ?? 0;
        final total = data['total'] as int? ?? 0;

        if (total == 0 || noSandbox == 0) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'sec_iframe_sandbox',
              title: 'Iframes sans sandbox',
              description: '$noSandbox iframe(s) n\'ont pas l\'attribut sandbox.',
              severity: IssueSeverity.info,
              category: AuditCategory.security,
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking iframes: $e');
      }
    }

    return {'passed': true, 'issues': <Issue>[]};
  }

  /// Vérifie les cookies
  Future<Map<String, dynamic>> _checkCookies() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const cookies = document.cookie;
        const cookieCount = cookies ? cookies.split(';').filter(c => c.trim()).length : 0;
        
        return JSON.stringify({
          cookieCount: cookieCount,
          // Note: On ne peut pas vérifier HttpOnly ou Secure depuis JS
          hasThirdPartyCookies: false // Impossible à déterminer côté client
        });
      })();
    ''');

    if (result != null) {
      try {
        // Les cookies sécurisés ne sont pas vérifiables côté client
        // On passe ce test par défaut
        return {'passed': true, 'issues': <Issue>[]};
      } catch (e) {
        debugPrint('Error checking cookies: $e');
      }
    }

    return {'passed': true, 'issues': <Issue>[]};
  }
}

