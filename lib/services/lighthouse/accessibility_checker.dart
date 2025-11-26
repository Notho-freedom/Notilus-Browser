/// Vérificateur d'accessibilité pour Notilus Lighthouse
/// Analyse WCAG 2.1 niveau AA
library accessibility_checker;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/lighthouse/audit_models.dart';
import 'lighthouse_service.dart';

/// Vérificateur d'accessibilité WCAG
class AccessibilityChecker {
  final LighthouseService _lighthouseService;

  AccessibilityChecker(this._lighthouseService);

  /// Analyse complète de l'accessibilité
  Future<CategoryAnalysisResult?> analyze() async {
    final issues = <Issue>[];
    final recommendations = <Recommendation>[];
    int passed = 0;
    int total = 0;

    try {
      // 1. Vérifier les images sans alt
      final altResult = await _checkImageAlts();
      if (altResult != null) {
        total++;
        if (altResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(altResult['issues'] as List<Issue>);
        }
      }

      // 2. Vérifier la structure des headings
      final headingsResult = await _checkHeadingStructure();
      if (headingsResult != null) {
        total++;
        if (headingsResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(headingsResult['issues'] as List<Issue>);
        }
      }

      // 3. Vérifier le contraste des couleurs
      final contrastResult = await _checkColorContrast();
      if (contrastResult != null) {
        total++;
        if (contrastResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(contrastResult['issues'] as List<Issue>);
          recommendations.addAll(contrastResult['recommendations'] as List<Recommendation>);
        }
      }

      // 4. Vérifier les labels de formulaire
      final formsResult = await _checkFormLabels();
      if (formsResult != null) {
        total++;
        if (formsResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(formsResult['issues'] as List<Issue>);
        }
      }

      // 5. Vérifier les liens
      final linksResult = await _checkLinks();
      if (linksResult != null) {
        total++;
        if (linksResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(linksResult['issues'] as List<Issue>);
        }
      }

      // 6. Vérifier les boutons
      final buttonsResult = await _checkButtons();
      if (buttonsResult != null) {
        total++;
        if (buttonsResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(buttonsResult['issues'] as List<Issue>);
        }
      }

      // 7. Vérifier la langue du document
      final langResult = await _checkDocumentLanguage();
      if (langResult != null) {
        total++;
        if (langResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(langResult['issues'] as List<Issue>);
        }
      }

      // 8. Vérifier les zones cliquables
      final tapTargetsResult = await _checkTapTargets();
      if (tapTargetsResult != null) {
        total++;
        if (tapTargetsResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(tapTargetsResult['issues'] as List<Issue>);
        }
      }

      // 9. Vérifier les landmarks ARIA
      final landmarksResult = await _checkARIALandmarks();
      if (landmarksResult != null) {
        total++;
        if (landmarksResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(landmarksResult['issues'] as List<Issue>);
        }
      }

      // 10. Vérifier le focus visible
      final focusResult = await _checkFocusVisible();
      if (focusResult != null) {
        total++;
        if (focusResult['passed'] == true) {
          passed++;
        } else {
          issues.addAll(focusResult['issues'] as List<Issue>);
        }
      }

      final score = total > 0 ? ((passed / total) * 100).round() : 0;

      return CategoryAnalysisResult(
        categoryScore: CategoryScore(
          category: AuditCategory.accessibility,
          score: score,
          passedAudits: passed,
          totalAudits: total,
          issues: issues,
        ),
        issues: issues,
        recommendations: recommendations,
      );
    } catch (e) {
      debugPrint('Accessibility check error: $e');
      return null;
    }
  }

  /// Vérifie les attributs alt des images
  Future<Map<String, dynamic>?> _checkImageAlts() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const images = document.querySelectorAll('img');
        const issues = [];
        
        images.forEach((img, i) => {
          if (!img.hasAttribute('alt')) {
            issues.push({
              src: img.src,
              type: 'missing'
            });
          } else if (img.alt.trim() === '') {
            // Alt vide est OK pour les images décoratives
            // mais signalons-le quand même
            if (!img.getAttribute('role') !== 'presentation' && !img.getAttribute('aria-hidden')) {
              issues.push({
                src: img.src,
                type: 'empty'
              });
            }
          }
        });
        
        return JSON.stringify({
          total: images.length,
          issues: issues
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final imageIssues = data['issues'] as List<dynamic>;

        if (imageIssues.isEmpty) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        final missingCount = imageIssues.where((i) => i['type'] == 'missing').length;

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'a11y_img_alt',
              title: 'Images sans texte alternatif',
              description: '$missingCount images n\'ont pas d\'attribut alt.',
              severity: IssueSeverity.critical,
              category: AuditCategory.accessibility,
              rootCause: 'Les utilisateurs de lecteurs d\'écran ne peuvent pas comprendre ces images.',
              documentation: 'https://www.w3.org/WAI/tutorials/images/',
              suggestedFixes: [
                Fix(
                  id: 'fix_img_alt',
                  title: 'Ajouter des textes alternatifs',
                  description: 'Ajoutez alt="description" à chaque image informative.',
                  effort: EffortLevel.minimal,
                ),
              ],
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking image alts: $e');
      }
    }

    return null;
  }

  /// Vérifie la structure des headings
  Future<Map<String, dynamic>?> _checkHeadingStructure() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
        const levels = [];
        const issues = [];
        
        headings.forEach(h => {
          const level = parseInt(h.tagName[1]);
          levels.push(level);
        });
        
        // Vérifier qu'il y a un h1
        const h1Count = levels.filter(l => l === 1).length;
        if (h1Count === 0) {
          issues.push({ type: 'no_h1' });
        } else if (h1Count > 1) {
          issues.push({ type: 'multiple_h1', count: h1Count });
        }
        
        // Vérifier qu'il n'y a pas de saut de niveau
        for (let i = 1; i < levels.length; i++) {
          if (levels[i] > levels[i-1] + 1) {
            issues.push({ 
              type: 'skip_level', 
              from: levels[i-1], 
              to: levels[i] 
            });
          }
        }
        
        return JSON.stringify({
          headingCount: headings.length,
          issues: issues
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final headingIssues = data['issues'] as List<dynamic>;

        if (headingIssues.isEmpty) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        final issues = <Issue>[];

        for (final issue in headingIssues) {
          if (issue['type'] == 'no_h1') {
            issues.add(Issue(
              id: 'a11y_no_h1',
              title: 'Pas de titre H1',
              description: 'La page n\'a pas de titre principal (h1).',
              severity: IssueSeverity.warning,
              category: AuditCategory.accessibility,
            ));
          } else if (issue['type'] == 'multiple_h1') {
            issues.add(Issue(
              id: 'a11y_multiple_h1',
              title: 'Plusieurs titres H1',
              description: 'La page a ${issue['count']} titres h1. Il ne devrait y en avoir qu\'un.',
              severity: IssueSeverity.warning,
              category: AuditCategory.accessibility,
            ));
          } else if (issue['type'] == 'skip_level') {
            issues.add(Issue(
              id: 'a11y_heading_skip',
              title: 'Saut de niveau de titre',
              description: 'Saut de h${issue['from']} à h${issue['to']}.',
              severity: IssueSeverity.warning,
              category: AuditCategory.accessibility,
            ));
          }
        }

        return {'passed': false, 'issues': issues};
      } catch (e) {
        debugPrint('Error checking headings: $e');
      }
    }

    return null;
  }

  /// Vérifie le contraste des couleurs
  Future<Map<String, dynamic>?> _checkColorContrast() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        function getLuminance(r, g, b) {
          const a = [r, g, b].map(v => {
            v /= 255;
            return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
          });
          return a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722;
        }
        
        function parseColor(color) {
          if (color.startsWith('rgb')) {
            const match = color.match(/\\d+/g);
            if (match) return match.map(Number);
          }
          return null;
        }
        
        function getContrastRatio(l1, l2) {
          const lighter = Math.max(l1, l2);
          const darker = Math.min(l1, l2);
          return (lighter + 0.05) / (darker + 0.05);
        }
        
        const issues = [];
        const textElements = document.querySelectorAll('p, span, a, li, td, th, h1, h2, h3, h4, h5, h6');
        
        textElements.forEach((el, i) => {
          if (i > 100) return; // Limiter pour les performances
          
          const style = getComputedStyle(el);
          const color = parseColor(style.color);
          const bgColor = parseColor(style.backgroundColor);
          
          if (color && bgColor && bgColor.some(c => c > 0)) {
            const textLum = getLuminance(...color);
            const bgLum = getLuminance(...bgColor);
            const ratio = getContrastRatio(textLum, bgLum);
            
            const fontSize = parseFloat(style.fontSize);
            const isBold = parseInt(style.fontWeight) >= 700;
            const isLargeText = fontSize >= 18 || (fontSize >= 14 && isBold);
            
            const minRatio = isLargeText ? 3 : 4.5;
            
            if (ratio < minRatio) {
              issues.push({
                text: el.textContent.substring(0, 50),
                ratio: ratio.toFixed(2),
                required: minRatio,
                color: style.color,
                bgColor: style.backgroundColor
              });
            }
          }
        });
        
        return JSON.stringify({ issues: issues.slice(0, 10) });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final contrastIssues = data['issues'] as List<dynamic>;

        if (contrastIssues.isEmpty) {
          return {'passed': true, 'issues': <Issue>[], 'recommendations': <Recommendation>[]};
        }

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'a11y_contrast',
              title: 'Contraste de couleur insuffisant',
              description: '${contrastIssues.length} éléments ont un contraste insuffisant.',
              severity: IssueSeverity.warning,
              category: AuditCategory.accessibility,
              rootCause: 'Le texte n\'est pas assez visible sur son arrière-plan.',
              documentation: 'https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html',
            ),
          ],
          'recommendations': [
            Recommendation(
              id: 'rec_contrast',
              title: 'Améliorer le contraste des couleurs',
              description: 'Assurez-vous que le ratio de contraste est d\'au moins 4.5:1 pour le texte normal.',
              priority: RecommendationPriority.medium,
              estimatedImpact: 5,
              effort: EffortLevel.minimal,
              category: AuditCategory.accessibility,
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking contrast: $e');
      }
    }

    return null;
  }

  /// Vérifie les labels de formulaire
  Future<Map<String, dynamic>?> _checkFormLabels() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const inputs = document.querySelectorAll('input:not([type="hidden"]):not([type="submit"]):not([type="button"]), select, textarea');
        const issues = [];
        
        inputs.forEach(input => {
          const hasLabel = input.labels && input.labels.length > 0;
          const hasAriaLabel = input.hasAttribute('aria-label') || input.hasAttribute('aria-labelledby');
          const hasTitle = input.hasAttribute('title');
          const hasPlaceholder = input.hasAttribute('placeholder');
          
          if (!hasLabel && !hasAriaLabel && !hasTitle) {
            issues.push({
              type: input.type || input.tagName.toLowerCase(),
              name: input.name || input.id,
              hasPlaceholder: hasPlaceholder
            });
          }
        });
        
        return JSON.stringify({
          total: inputs.length,
          issues: issues
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final formIssues = data['issues'] as List<dynamic>;

        if (formIssues.isEmpty) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'a11y_form_labels',
              title: 'Champs de formulaire sans label',
              description: '${formIssues.length} champs n\'ont pas de label associé.',
              severity: IssueSeverity.critical,
              category: AuditCategory.accessibility,
              rootCause: 'Les utilisateurs de lecteurs d\'écran ne peuvent pas identifier ces champs.',
              suggestedFixes: [
                Fix(
                  id: 'fix_form_labels',
                  title: 'Ajouter des labels',
                  description: 'Associez un <label> à chaque champ de formulaire.',
                  code: '<label for="email">Email</label>\n<input type="email" id="email">',
                  effort: EffortLevel.minimal,
                ),
              ],
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking form labels: $e');
      }
    }

    return null;
  }

  /// Vérifie les liens
  Future<Map<String, dynamic>?> _checkLinks() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const links = document.querySelectorAll('a');
        const issues = [];
        
        links.forEach(link => {
          const text = (link.textContent || '').trim();
          const ariaLabel = link.getAttribute('aria-label');
          const title = link.getAttribute('title');
          
          if (!text && !ariaLabel && !title && !link.querySelector('img[alt]')) {
            issues.push({
              type: 'empty',
              href: link.href
            });
          } else if (['cliquez ici', 'ici', 'lire la suite', 'plus', 'click here', 'here', 'read more', 'more'].includes(text.toLowerCase())) {
            issues.push({
              type: 'generic',
              text: text,
              href: link.href
            });
          }
        });
        
        return JSON.stringify({
          total: links.length,
          issues: issues
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final linkIssues = data['issues'] as List<dynamic>;

        if (linkIssues.isEmpty) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        final emptyCount = linkIssues.where((i) => i['type'] == 'empty').length;
        final genericCount = linkIssues.where((i) => i['type'] == 'generic').length;

        final issues = <Issue>[];

        if (emptyCount > 0) {
          issues.add(Issue(
            id: 'a11y_links_empty',
            title: 'Liens sans texte',
            description: '$emptyCount liens n\'ont pas de texte descriptif.',
            severity: IssueSeverity.critical,
            category: AuditCategory.accessibility,
          ));
        }

        if (genericCount > 0) {
          issues.add(Issue(
            id: 'a11y_links_generic',
            title: 'Liens avec texte générique',
            description: '$genericCount liens utilisent un texte générique comme "cliquez ici".',
            severity: IssueSeverity.warning,
            category: AuditCategory.accessibility,
          ));
        }

        return {'passed': false, 'issues': issues};
      } catch (e) {
        debugPrint('Error checking links: $e');
      }
    }

    return null;
  }

  /// Vérifie les boutons
  Future<Map<String, dynamic>?> _checkButtons() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const buttons = document.querySelectorAll('button, [role="button"], input[type="button"], input[type="submit"]');
        const issues = [];
        
        buttons.forEach(btn => {
          const text = (btn.textContent || btn.value || '').trim();
          const ariaLabel = btn.getAttribute('aria-label');
          const title = btn.getAttribute('title');
          
          if (!text && !ariaLabel && !title) {
            issues.push({
              type: btn.tagName.toLowerCase()
            });
          }
        });
        
        return JSON.stringify({
          total: buttons.length,
          issues: issues
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final buttonIssues = data['issues'] as List<dynamic>;

        if (buttonIssues.isEmpty) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'a11y_buttons',
              title: 'Boutons sans label accessible',
              description: '${buttonIssues.length} boutons n\'ont pas de texte accessible.',
              severity: IssueSeverity.critical,
              category: AuditCategory.accessibility,
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking buttons: $e');
      }
    }

    return null;
  }

  /// Vérifie la langue du document
  Future<Map<String, dynamic>?> _checkDocumentLanguage() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const html = document.documentElement;
        const lang = html.getAttribute('lang');
        return JSON.stringify({ lang: lang });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final lang = data['lang'] as String?;

        if (lang != null && lang.isNotEmpty) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'a11y_lang',
              title: 'Langue du document non définie',
              description: 'L\'attribut lang manque sur la balise <html>.',
              severity: IssueSeverity.warning,
              category: AuditCategory.accessibility,
              suggestedFixes: [
                Fix(
                  id: 'fix_lang',
                  title: 'Ajouter l\'attribut lang',
                  description: 'Ajoutez lang="fr" (ou la langue appropriée) à <html>.',
                  code: '<html lang="fr">',
                  effort: EffortLevel.minimal,
                  canAutoFix: true,
                ),
              ],
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking language: $e');
      }
    }

    return null;
  }

  /// Vérifie les zones cliquables
  Future<Map<String, dynamic>?> _checkTapTargets() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const interactive = document.querySelectorAll('a, button, input, select, textarea, [onclick], [tabindex]');
        const issues = [];
        
        interactive.forEach(el => {
          const rect = el.getBoundingClientRect();
          if (rect.width > 0 && rect.height > 0) {
            if (rect.width < 44 || rect.height < 44) {
              issues.push({
                tag: el.tagName.toLowerCase(),
                width: Math.round(rect.width),
                height: Math.round(rect.height)
              });
            }
          }
        });
        
        return JSON.stringify({
          total: interactive.length,
          issues: issues.slice(0, 20)
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final tapIssues = data['issues'] as List<dynamic>;

        if (tapIssues.isEmpty) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'a11y_tap_targets',
              title: 'Zones cliquables trop petites',
              description: '${tapIssues.length} éléments interactifs font moins de 44x44 pixels.',
              severity: IssueSeverity.warning,
              category: AuditCategory.accessibility,
              rootCause: 'Les petites zones cliquables sont difficiles à utiliser sur mobile.',
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking tap targets: $e');
      }
    }

    return null;
  }

  /// Vérifie les landmarks ARIA
  Future<Map<String, dynamic>?> _checkARIALandmarks() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        const landmarks = {
          main: document.querySelectorAll('main, [role="main"]').length,
          nav: document.querySelectorAll('nav, [role="navigation"]').length,
          header: document.querySelectorAll('header, [role="banner"]').length,
          footer: document.querySelectorAll('footer, [role="contentinfo"]').length
        };
        
        return JSON.stringify(landmarks);
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final issues = <Issue>[];

        if ((data['main'] as int? ?? 0) == 0) {
          issues.add(Issue(
            id: 'a11y_no_main',
            title: 'Pas de zone principale',
            description: 'La page n\'a pas de balise <main> ou role="main".',
            severity: IssueSeverity.info,
            category: AuditCategory.accessibility,
          ));
        }

        if ((data['nav'] as int? ?? 0) == 0) {
          issues.add(Issue(
            id: 'a11y_no_nav',
            title: 'Pas de navigation',
            description: 'La page n\'a pas de balise <nav> ou role="navigation".',
            severity: IssueSeverity.info,
            category: AuditCategory.accessibility,
          ));
        }

        return {
          'passed': issues.isEmpty,
          'issues': issues,
        };
      } catch (e) {
        debugPrint('Error checking landmarks: $e');
      }
    }

    return null;
  }

  /// Vérifie le focus visible
  Future<Map<String, dynamic>?> _checkFocusVisible() async {
    final result = await _lighthouseService.executeScript('''
      (function() {
        // Vérifier si le outline est supprimé globalement
        const styles = document.styleSheets;
        let outlineRemoved = false;
        
        for (const sheet of styles) {
          try {
            for (const rule of sheet.cssRules || []) {
              if (rule.cssText && rule.cssText.includes('outline: none') && 
                  (rule.selectorText === '*' || rule.selectorText === ':focus')) {
                outlineRemoved = true;
                break;
              }
            }
          } catch (e) {
            // CORS error for external stylesheets
          }
          if (outlineRemoved) break;
        }
        
        return JSON.stringify({ outlineRemoved: outlineRemoved });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final outlineRemoved = data['outlineRemoved'] as bool? ?? false;

        if (!outlineRemoved) {
          return {'passed': true, 'issues': <Issue>[]};
        }

        return {
          'passed': false,
          'issues': [
            Issue(
              id: 'a11y_focus_visible',
              title: 'Indicateur de focus supprimé',
              description: 'L\'outline de focus est supprimé globalement.',
              severity: IssueSeverity.critical,
              category: AuditCategory.accessibility,
              rootCause: 'Les utilisateurs au clavier ne peuvent pas voir quel élément est focalisé.',
              suggestedFixes: [
                Fix(
                  id: 'fix_focus',
                  title: 'Restaurer l\'indicateur de focus',
                  description: 'Ajoutez un style de focus personnalisé plutôt que de le supprimer.',
                  code: ':focus { outline: 2px solid #0066FF; outline-offset: 2px; }',
                  effort: EffortLevel.minimal,
                ),
              ],
            ),
          ],
        };
      } catch (e) {
        debugPrint('Error checking focus: $e');
      }
    }

    return null;
  }
}

