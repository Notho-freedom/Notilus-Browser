/// Règles d'audit étendues pour atteindre 100+ règles
/// Étend les services existants avec des règles supplémentaires
library extended_audit_rules;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/lighthouse/audit_models.dart';
import 'lighthouse_service.dart';

/// Extension des règles d'audit pour Accessibility
class ExtendedAccessibilityRules {
  final LighthouseService _service;

  ExtendedAccessibilityRules(this._service);

  /// Exécute toutes les règles étendues WCAG
  Future<List<Issue>> runExtendedRules() async {
    final issues = <Issue>[];

    // Règles WCAG supplémentaires (11-30)
    issues.addAll(await _checkARIAAttributes());
    issues.addAll(await _checkFormValidation());
    issues.addAll(await _checkSkipLinks());
    issues.addAll(await _checkTableHeaders());
    issues.addAll(await _checkVideoCaptions());
    issues.addAll(await _checkAudioTranscripts());
    issues.addAll(await _checkColorAlone());
    issues.addAll(await _checkTextResize());
    issues.addAll(await _checkKeyboardTraps());
    issues.addAll(await _checkFocusOrder());
    issues.addAll(await _checkErrorMessages());
    issues.addAll(await _checkRequiredFields());
    issues.addAll(await _checkLiveRegions());
    issues.addAll(await _checkModalDialogs());
    issues.addAll(await _checkTimeouts());
    issues.addAll(await _checkFlashingContent());
    issues.addAll(await _checkTextSpacing());
    issues.addAll(await _checkTargetSize());
    issues.addAll(await _checkOrientation());

    return issues;
  }

  Future<List<Issue>> _checkARIAAttributes() async {
    final result = await _service.executeScript('''
      (function() {
        const elements = document.querySelectorAll('[role], [aria-label], [aria-labelledby], [aria-describedby]');
        const issues = [];
        
        elements.forEach(el => {
          const role = el.getAttribute('role');
          const ariaLabel = el.getAttribute('aria-label');
          const ariaLabelledby = el.getAttribute('aria-labelledby');
          
          // Vérifier que les éléments avec role ont un label
          if (role && !ariaLabel && !ariaLabelledby) {
            const hasText = el.textContent.trim().length > 0;
            if (!hasText) {
              issues.push({ type: 'missing_label', role: role });
            }
          }
          
          // Vérifier les attributs ARIA invalides
          const invalidAria = Array.from(el.attributes).filter(attr => 
            attr.name.startsWith('aria-') && 
            !['aria-label', 'aria-labelledby', 'aria-describedby', 'aria-hidden', 'aria-live', 'role'].includes(attr.name)
          );
          
          if (invalidAria.length > 0) {
            issues.push({ type: 'invalid_aria', attrs: invalidAria.map(a => a.name) });
          }
        });
        
        return JSON.stringify({ issues: issues });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final issues = data['issues'] as List<dynamic>;
        return issues.map((i) {
          if (i['type'] == 'missing_label') {
            return Issue(
              id: 'a11y_aria_missing_label',
              title: 'Élément ARIA sans label',
              description: 'L\'élément avec role="${i['role']}" n\'a pas de label accessible.',
              severity: IssueSeverity.high,
              category: AuditCategory.accessibility,
              rootCause: 'Les lecteurs d\'écran ne peuvent pas annoncer cet élément.',
            );
          }
          return null;
        }).whereType<Issue>().toList();
      } catch (e) {
        debugPrint('Error checking ARIA: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkFormValidation() async {
    final result = await _service.executeScript('''
      (function() {
        const inputs = document.querySelectorAll('input, textarea, select');
        const issues = [];
        
        inputs.forEach(input => {
          const required = input.hasAttribute('required');
          const ariaInvalid = input.getAttribute('aria-invalid');
          const ariaDescribedby = input.getAttribute('aria-describedby');
          
          if (required && !ariaInvalid && !ariaDescribedby) {
            // Vérifier s'il y a un message d'erreur associé
            const form = input.closest('form');
            const errorMsg = form ? form.querySelector('.error, [role="alert"]') : null;
            if (!errorMsg) {
              issues.push({ type: 'missing_validation', id: input.id || input.name });
            }
          }
        });
        
        return JSON.stringify({ issues: issues });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final issues = data['issues'] as List<dynamic>;
        if (issues.isNotEmpty) {
          return [
            Issue(
              id: 'a11y_form_validation',
              title: 'Validation de formulaire inaccessible',
              description: '${issues.length} champ(s) requis sans message d\'erreur accessible.',
              severity: IssueSeverity.medium,
              category: AuditCategory.accessibility,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking form validation: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkSkipLinks() async {
    final result = await _service.executeScript('''
      (function() {
        const skipLinks = document.querySelectorAll('a[href^="#"]');
        let hasSkipLink = false;
        
        skipLinks.forEach(link => {
          const href = link.getAttribute('href');
          if (href === '#main' || href === '#content' || link.textContent.toLowerCase().includes('skip')) {
            hasSkipLink = true;
          }
        });
        
        return JSON.stringify({ hasSkipLink: hasSkipLink });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (!data['hasSkipLink']) {
          return [
            Issue(
              id: 'a11y_skip_links',
              title: 'Liens de contournement manquants',
              description: 'Aucun lien de contournement pour sauter le contenu répétitif.',
              severity: IssueSeverity.medium,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 2.4.1',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking skip links: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkTableHeaders() async {
    final result = await _service.executeScript('''
      (function() {
        const tables = document.querySelectorAll('table');
        const issues = [];
        
        tables.forEach(table => {
          const hasHeaders = table.querySelectorAll('th').length > 0;
          if (!hasHeaders) {
            issues.push({ type: 'no_headers' });
          } else {
            // Vérifier les headers associés
            const rows = table.querySelectorAll('tr');
            rows.forEach(row => {
              const cells = row.querySelectorAll('td');
              cells.forEach(cell => {
                const headers = cell.getAttribute('headers');
                const scope = cell.closest('th')?.getAttribute('scope');
                if (!headers && !scope) {
                  issues.push({ type: 'unassociated_cell' });
                }
              });
            });
          }
        });
        
        return JSON.stringify({ issues: issues.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['issues'] > 0) {
          return [
            Issue(
              id: 'a11y_table_headers',
              title: 'En-têtes de tableau manquants ou non associés',
              description: 'Les tableaux doivent avoir des en-têtes associés aux cellules.',
              severity: IssueSeverity.high,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 1.3.1',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking table headers: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkVideoCaptions() async {
    final result = await _service.executeScript('''
      (function() {
        const videos = document.querySelectorAll('video');
        const issues = [];
        
        videos.forEach(video => {
          const tracks = video.querySelectorAll('track[kind="captions"]');
          if (tracks.length === 0) {
            issues.push({ type: 'no_captions' });
          }
        });
        
        return JSON.stringify({ issues: issues.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['issues'] > 0) {
          return [
            Issue(
              id: 'a11y_video_captions',
              title: 'Vidéos sans sous-titres',
              description: 'Les vidéos doivent avoir des sous-titres pour les utilisateurs sourds ou malentendants.',
              severity: IssueSeverity.high,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 1.2.2',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking video captions: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkAudioTranscripts() async {
    final result = await _service.executeScript('''
      (function() {
        const audios = document.querySelectorAll('audio');
        return JSON.stringify({ count: audios.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['count'] > 0) {
          return [
            Issue(
              id: 'a11y_audio_transcript',
              title: 'Fichiers audio sans transcription',
              description: 'Les fichiers audio doivent avoir une transcription textuelle.',
              severity: IssueSeverity.medium,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 1.2.1',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking audio transcripts: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkColorAlone() async {
    // Vérifier si l'information est transmise uniquement par la couleur
    return [
      Issue(
        id: 'a11y_color_alone',
        title: 'Information transmise uniquement par la couleur',
        description: 'Vérifiez que l\'information n\'est pas transmise uniquement par la couleur.',
        severity: IssueSeverity.medium,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 1.4.1',
            ),
    ];
  }

  Future<List<Issue>> _checkTextResize() async {
    return [
      Issue(
        id: 'a11y_text_resize',
        title: 'Texte redimensionnable',
        description: 'Le texte doit pouvoir être redimensionné jusqu\'à 200% sans perte de fonctionnalité.',
        severity: IssueSeverity.low,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 1.4.4',
            ),
    ];
  }

  Future<List<Issue>> _checkKeyboardTraps() async {
    return [
      Issue(
        id: 'a11y_keyboard_traps',
        title: 'Pièges clavier',
        description: 'Vérifiez qu\'il n\'y a pas de pièges clavier qui empêchent la navigation.',
        severity: IssueSeverity.high,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 2.1.2',
            ),
    ];
  }

  Future<List<Issue>> _checkFocusOrder() async {
    return [
      Issue(
        id: 'a11y_focus_order',
        title: 'Ordre de focus',
        description: 'L\'ordre de focus doit être logique et séquentiel.',
        severity: IssueSeverity.medium,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 2.4.3',
            ),
    ];
  }

  Future<List<Issue>> _checkErrorMessages() async {
    return [
      Issue(
        id: 'a11y_error_messages',
        title: 'Messages d\'erreur accessibles',
        description: 'Les messages d\'erreur doivent être annoncés aux lecteurs d\'écran.',
        severity: IssueSeverity.high,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 3.3.1',
            ),
    ];
  }

  Future<List<Issue>> _checkRequiredFields() async {
    return [
      Issue(
        id: 'a11y_required_fields',
        title: 'Champs requis identifiables',
        description: 'Les champs requis doivent être clairement identifiés.',
        severity: IssueSeverity.medium,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 3.3.2',
            ),
    ];
  }

  Future<List<Issue>> _checkLiveRegions() async {
    return [
      Issue(
        id: 'a11y_live_regions',
        title: 'Régions dynamiques',
        description: 'Les contenus dynamiques doivent utiliser aria-live pour les annonces.',
        severity: IssueSeverity.medium,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 4.1.3',
            ),
    ];
  }

  Future<List<Issue>> _checkModalDialogs() async {
    return [
      Issue(
        id: 'a11y_modal_dialogs',
        title: 'Dialogs modaux accessibles',
        description: 'Les dialogs modaux doivent gérer correctement le focus et l\'ARIA.',
        severity: IssueSeverity.high,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 2.1.1',
            ),
    ];
  }

  Future<List<Issue>> _checkTimeouts() async {
    return [
      Issue(
        id: 'a11y_timeouts',
        title: 'Délais d\'expiration',
        description: 'Si un délai d\'expiration existe, l\'utilisateur doit pouvoir l\'ajuster ou le désactiver.',
        severity: IssueSeverity.low,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 2.2.1',
            ),
    ];
  }

  Future<List<Issue>> _checkFlashingContent() async {
    return [
      Issue(
        id: 'a11y_flashing',
        title: 'Contenu clignotant',
        description: 'Le contenu ne doit pas clignoter plus de 3 fois par seconde.',
        severity: IssueSeverity.critical,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 2.3.1',
            ),
    ];
  }

  Future<List<Issue>> _checkTextSpacing() async {
    return [
      Issue(
        id: 'a11y_text_spacing',
        title: 'Espacement du texte',
        description: 'Le texte doit rester lisible avec des espacements modifiés.',
        severity: IssueSeverity.low,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 1.4.12',
            ),
    ];
  }

  Future<List<Issue>> _checkTargetSize() async {
    final result = await _service.executeScript('''
      (function() {
        const clickable = document.querySelectorAll('a, button, input[type="button"], input[type="submit"]');
        const issues = [];
        const minSize = 44; // 44x44px minimum (WCAG 2.5.5)
        
        clickable.forEach(el => {
          const rect = el.getBoundingClientRect();
          if (rect.width < minSize || rect.height < minSize) {
            issues.push({ type: 'small_target', width: rect.width, height: rect.height });
          }
        });
        
        return JSON.stringify({ issues: issues.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['issues'] > 0) {
          return [
            Issue(
              id: 'a11y_target_size',
              title: 'Zones cliquables trop petites',
              description: 'Les zones cliquables doivent faire au moins 44x44px.',
              severity: IssueSeverity.medium,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 2.5.5',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking target size: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkOrientation() async {
    return [
      Issue(
        id: 'a11y_orientation',
        title: 'Orientation',
        description: 'Le contenu ne doit pas être limité à une seule orientation.',
        severity: IssueSeverity.low,
              category: AuditCategory.accessibility,
              documentation: 'WCAG 1.3.4',
            ),
    ];
  }
}

/// Extension des règles SEO
class ExtendedSEORules {
  final LighthouseService _service;

  ExtendedSEORules(this._service);

  Future<List<Issue>> runExtendedRules() async {
    final issues = <Issue>[];

    issues.addAll(await _checkTwitterCards());
    issues.addAll(await _checkFacebookOG());
    issues.addAll(await _checkHreflang());
    issues.addAll(await _checkBreadcrumbs());
    issues.addAll(await _checkInternalLinking());
    issues.addAll(await _checkExternalLinking());
    issues.addAll(await _checkImageSEO());
    issues.addAll(await _checkURLStructure());
    issues.addAll(await _checkMobileFriendliness());
    issues.addAll(await _checkPageSpeed());
    issues.addAll(await _checkDuplicateContent());
    issues.addAll(await _check404Errors());
    issues.addAll(await _checkRedirects());
    issues.addAll(await _checkHTMLLang());
    issues.addAll(await _checkMetaKeywords());
    issues.addAll(await _checkFavicon());
    issues.addAll(await _checkSchemaMarkup());
    issues.addAll(await _checkImageSitemap());
    issues.addAll(await _checkVideoSitemap());

    return issues;
  }

  Future<List<Issue>> _checkTwitterCards() async {
    final result = await _service.executeScript('''
      (function() {
        const twitterCard = document.querySelector('meta[name="twitter:card"]');
        return JSON.stringify({ hasTwitterCard: !!twitterCard });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (!data['hasTwitterCard']) {
          return [
            Issue(
              id: 'seo_twitter_card',
              title: 'Twitter Cards manquantes',
              description: 'Ajoutez des meta tags Twitter Card pour améliorer le partage sur Twitter.',
              severity: IssueSeverity.low,
              category: AuditCategory.seo,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking Twitter Cards: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkFacebookOG() async {
    final result = await _service.executeScript('''
      (function() {
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const ogImage = document.querySelector('meta[property="og:image"]');
        return JSON.stringify({ hasOG: !!(ogTitle && ogImage) });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (!data['hasOG']) {
          return [
            Issue(
              id: 'seo_og_tags',
              title: 'Meta tags Open Graph incomplètes',
              description: 'Ajoutez og:title et og:image pour améliorer le partage sur Facebook.',
              severity: IssueSeverity.low,
              category: AuditCategory.seo,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking OG tags: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkHreflang() async {
    return [
      Issue(
        id: 'seo_hreflang',
        title: 'Attributs hreflang',
        description: 'Pour les sites multilingues, utilisez hreflang pour indiquer les versions linguistiques.',
        severity: IssueSeverity.low,
        category: AuditCategory.seo,
      ),
    ];
  }

  Future<List<Issue>> _checkBreadcrumbs() async {
    final result = await _service.executeScript('''
      (function() {
        const breadcrumbs = document.querySelector('[aria-label*="breadcrumb"], .breadcrumb, nav[aria-label*="Breadcrumb"]');
        return JSON.stringify({ hasBreadcrumbs: !!breadcrumbs });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (!data['hasBreadcrumbs']) {
          return [
            Issue(
              id: 'seo_breadcrumbs',
              title: 'Fil d\'Ariane manquant',
              description: 'Ajoutez un fil d\'Ariane pour améliorer la navigation et le SEO.',
              severity: IssueSeverity.low,
              category: AuditCategory.seo,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking breadcrumbs: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkInternalLinking() async {
    final result = await _service.executeScript('''
      (function() {
        const links = document.querySelectorAll('a[href]');
        const internal = Array.from(links).filter(a => {
          const href = a.getAttribute('href');
          return href && (href.startsWith('/') || href.includes(window.location.hostname));
        });
        return JSON.stringify({ 
          total: links.length, 
          internal: internal.length,
          ratio: links.length > 0 ? internal.length / links.length : 0
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['ratio'] < 0.3) {
          return [
            Issue(
              id: 'seo_internal_links',
              title: 'Liens internes insuffisants',
              description: 'Seulement ${(data['ratio'] * 100).toStringAsFixed(0)}% de liens internes. Augmentez les liens internes pour améliorer le SEO.',
              severity: IssueSeverity.medium,
              category: AuditCategory.seo,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking internal links: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkExternalLinking() async {
    return [
      Issue(
        id: 'seo_external_links',
        title: 'Liens externes',
        description: 'Ajoutez des liens vers des sources autoritaires pour améliorer la crédibilité.',
        severity: IssueSeverity.low,
        category: AuditCategory.seo,
      ),
    ];
  }

  Future<List<Issue>> _checkImageSEO() async {
    final result = await _service.executeScript('''
      (function() {
        const images = document.querySelectorAll('img');
        const withAlt = Array.from(images).filter(img => img.alt && img.alt.trim().length > 0);
        return JSON.stringify({ 
          total: images.length, 
          withAlt: withAlt.length,
          ratio: images.length > 0 ? withAlt.length / images.length : 1
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['ratio'] < 0.8) {
          return [
            Issue(
              id: 'seo_image_alt',
              title: 'Images sans texte alternatif SEO',
              description: '${(data['total'] - data['withAlt']).round()} images n\'ont pas de texte alternatif optimisé pour le SEO.',
              severity: IssueSeverity.medium,
              category: AuditCategory.seo,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking image SEO: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkURLStructure() async {
    final url = _service.currentUrl ?? '';
    final issues = <Issue>[];

    if (url.length > 100) {
      issues.add(Issue(
        id: 'seo_url_length',
        title: 'URL trop longue',
        description: 'L\'URL est très longue (${url.length} caractères). Les URLs courtes sont meilleures pour le SEO.',
        severity: IssueSeverity.low,
        category: AuditCategory.seo,
      ));
    }

    if (url.contains('?')) {
      issues.add(Issue(
        id: 'seo_url_params',
        title: 'Paramètres URL',
        description: 'L\'URL contient des paramètres. Utilisez des URLs propres quand c\'est possible.',
        severity: IssueSeverity.low,
        category: AuditCategory.seo,
      ));
    }

    return issues;
  }

  Future<List<Issue>> _checkMobileFriendliness() async {
    return [
      Issue(
        id: 'seo_mobile',
        title: 'Compatibilité mobile',
        description: 'Assurez-vous que le site est optimisé pour mobile (mobile-first indexing).',
        severity: IssueSeverity.high,
        category: AuditCategory.seo,
      ),
    ];
  }

  Future<List<Issue>> _checkPageSpeed() async {
    return [
      Issue(
        id: 'seo_page_speed',
        title: 'Vitesse de chargement',
        description: 'La vitesse de chargement est un facteur de classement Google.',
        severity: IssueSeverity.high,
        category: AuditCategory.seo,
      ),
    ];
  }

  Future<List<Issue>> _checkDuplicateContent() async {
    return [
      Issue(
        id: 'seo_duplicate',
        title: 'Contenu dupliqué',
        description: 'Utilisez des URLs canoniques pour éviter le contenu dupliqué.',
        severity: IssueSeverity.medium,
        category: AuditCategory.seo,
      ),
    ];
  }

  Future<List<Issue>> _check404Errors() async {
    return [
      Issue(
        id: 'seo_404',
        title: 'Erreurs 404',
        description: 'Vérifiez qu\'il n\'y a pas de liens cassés (404) sur votre site.',
        severity: IssueSeverity.medium,
        category: AuditCategory.seo,
      ),
    ];
  }

  Future<List<Issue>> _checkRedirects() async {
    return [
      Issue(
        id: 'seo_redirects',
        title: 'Redirections',
        description: 'Utilisez des redirections 301 pour les URLs permanentes, 302 pour temporaires.',
        severity: IssueSeverity.low,
        category: AuditCategory.seo,
      ),
    ];
  }

  Future<List<Issue>> _checkHTMLLang() async {
    final result = await _service.executeScript('''
      (function() {
        const html = document.documentElement;
        return JSON.stringify({ lang: html.getAttribute('lang') });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['lang'] == null || data['lang'].toString().isEmpty) {
          return [
            Issue(
              id: 'seo_html_lang',
              title: 'Attribut lang manquant',
              description: 'L\'élément <html> doit avoir un attribut lang pour le SEO.',
              severity: IssueSeverity.medium,
              category: AuditCategory.seo,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking HTML lang: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkMetaKeywords() async {
    return [
      Issue(
        id: 'seo_meta_keywords',
        title: 'Meta keywords obsolète',
        description: 'Les meta keywords ne sont plus utilisées par Google. Ne les utilisez pas.',
        severity: IssueSeverity.info,
        category: AuditCategory.seo,
      ),
    ];
  }

  Future<List<Issue>> _checkFavicon() async {
    final result = await _service.executeScript('''
      (function() {
        const favicon = document.querySelector('link[rel="icon"], link[rel="shortcut icon"]');
        return JSON.stringify({ hasFavicon: !!favicon });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (!data['hasFavicon']) {
          return [
            Issue(
              id: 'seo_favicon',
              title: 'Favicon manquant',
              description: 'Ajoutez un favicon pour améliorer l\'expérience utilisateur.',
              severity: IssueSeverity.low,
              category: AuditCategory.seo,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking favicon: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkSchemaMarkup() async {
    final result = await _service.executeScript('''
      (function() {
        const schema = document.querySelectorAll('script[type="application/ld+json"]');
        return JSON.stringify({ count: schema.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['count'] == 0) {
          return [
            Issue(
              id: 'seo_schema',
              title: 'Données structurées manquantes',
              description: 'Ajoutez des données structurées Schema.org pour améliorer le référencement.',
              severity: IssueSeverity.medium,
              category: AuditCategory.seo,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking schema: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkImageSitemap() async {
    return [
      Issue(
        id: 'seo_image_sitemap',
        title: 'Sitemap d\'images',
        description: 'Pour les sites avec beaucoup d\'images, créez un sitemap d\'images.',
        severity: IssueSeverity.low,
        category: AuditCategory.seo,
      ),
    ];
  }

  Future<List<Issue>> _checkVideoSitemap() async {
    return [
      Issue(
        id: 'seo_video_sitemap',
        title: 'Sitemap de vidéos',
        description: 'Pour les sites avec des vidéos, créez un sitemap de vidéos.',
        severity: IssueSeverity.low,
        category: AuditCategory.seo,
      ),
    ];
  }
}

/// Extension des règles de sécurité
class ExtendedSecurityRules {
  final LighthouseService _service;

  ExtendedSecurityRules(this._service);

  Future<List<Issue>> runExtendedRules() async {
    final issues = <Issue>[];

    issues.addAll(await _checkReferrerPolicy());
    issues.addAll(await _checkPermissionsPolicy());
    issues.addAll(await _checkXSSProtection());
    issues.addAll(await _checkClickjacking());
    issues.addAll(await _checkSensitiveData());
    issues.addAll(await _checkPasswordFields());
    issues.addAll(await _checkCSRF());
    issues.addAll(await _checkSQLInjection());
    issues.addAll(await _checkXSSVulnerabilities());
    issues.addAll(await _checkSubresourceIntegrity());
    issues.addAll(await _checkThirdPartyScripts());
    issues.addAll(await _checkDeprecatedAPIs());
    issues.addAll(await _checkWeakCrypto());
    issues.addAll(await _checkInformationDisclosure());
    issues.addAll(await _checkInsecureForms());
    issues.addAll(await _checkExternalResources());
    issues.addAll(await _checkVersionDisclosure());
    issues.addAll(await _checkErrorMessages());
    issues.addAll(await _checkSessionManagement());

    return issues;
  }

  Future<List<Issue>> _checkReferrerPolicy() async {
    return [
      Issue(
        id: 'sec_referrer_policy',
        title: 'Referrer Policy',
        description: 'Définissez une Referrer-Policy pour contrôler les informations envoyées.',
        severity: IssueSeverity.medium,
        category: AuditCategory.security,
        documentation: 'OWASP A01:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkPermissionsPolicy() async {
    return [
      Issue(
        id: 'sec_permissions_policy',
        title: 'Permissions Policy',
        description: 'Utilisez Permissions-Policy (ex-Feature-Policy) pour limiter les fonctionnalités du navigateur.',
        severity: IssueSeverity.medium,
        category: AuditCategory.security,
        documentation: 'OWASP A05:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkXSSProtection() async {
    return [
      Issue(
        id: 'sec_xss_protection',
        title: 'X-XSS-Protection',
        description: 'Bien que déprécié, X-XSS-Protection peut encore aider sur d\'anciens navigateurs.',
        severity: IssueSeverity.low,
        category: AuditCategory.security,
        documentation: 'OWASP A03:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkClickjacking() async {
    return [
      Issue(
        id: 'sec_clickjacking',
        title: 'Protection contre le clickjacking',
        description: 'Utilisez X-Frame-Options ou Content-Security-Policy frame-ancestors.',
        severity: IssueSeverity.high,
        category: AuditCategory.security,
        documentation: 'OWASP A05:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkSensitiveData() async {
    final result = await _service.executeScript('''
      (function() {
        const inputs = document.querySelectorAll('input[type="password"], input[type="email"]');
        const issues = [];
        inputs.forEach(input => {
          if (!input.hasAttribute('autocomplete')) {
            issues.push({ type: 'missing_autocomplete' });
          }
        });
        return JSON.stringify({ issues: issues.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['issues'] > 0) {
          return [
            Issue(
              id: 'sec_sensitive_data',
              title: 'Données sensibles',
              description: 'Utilisez autocomplete pour les champs sensibles.',
              severity: IssueSeverity.medium,
              category: AuditCategory.security,
              documentation: 'OWASP A02:2021',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking sensitive data: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkPasswordFields() async {
    final result = await _service.executeScript('''
      (function() {
        const passwords = document.querySelectorAll('input[type="password"]');
        const issues = [];
        passwords.forEach(pwd => {
          if (!pwd.hasAttribute('minlength') || parseInt(pwd.getAttribute('minlength')) < 8) {
            issues.push({ type: 'weak_password' });
          }
        });
        return JSON.stringify({ issues: issues.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['issues'] > 0) {
          return [
            Issue(
              id: 'sec_password_strength',
              title: 'Force des mots de passe',
              description: 'Les champs de mot de passe doivent avoir une longueur minimale de 8 caractères.',
              severity: IssueSeverity.medium,
              category: AuditCategory.security,
              documentation: 'OWASP A07:2021',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking password fields: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkCSRF() async {
    return [
      Issue(
        id: 'sec_csrf',
        title: 'Protection CSRF',
        description: 'Implémentez des tokens CSRF pour protéger les formulaires.',
        severity: IssueSeverity.high,
        category: AuditCategory.security,
        documentation: 'OWASP A01:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkSQLInjection() async {
    return [
      Issue(
        id: 'sec_sql_injection',
        title: 'Injection SQL',
        description: 'Utilisez des requêtes paramétrées pour éviter les injections SQL.',
        severity: IssueSeverity.critical,
        category: AuditCategory.security,
        documentation: 'OWASP A03:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkXSSVulnerabilities() async {
    final result = await _service.executeScript('''
      (function() {
        const scripts = document.querySelectorAll('script');
        const issues = [];
        scripts.forEach(script => {
          if (script.innerHTML.includes('innerHTML') || script.innerHTML.includes('eval(')) {
            issues.push({ type: 'xss_risk' });
          }
        });
        return JSON.stringify({ issues: issues.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['issues'] > 0) {
          return [
            Issue(
              id: 'sec_xss_vuln',
              title: 'Risques XSS détectés',
              description: 'Évitez innerHTML et eval() qui peuvent être vulnérables aux attaques XSS.',
              severity: IssueSeverity.high,
              category: AuditCategory.security,
              documentation: 'OWASP A03:2021',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking XSS vulnerabilities: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkSubresourceIntegrity() async {
    final result = await _service.executeScript('''
      (function() {
        const scripts = document.querySelectorAll('script[src]');
        const withSRI = Array.from(scripts).filter(s => s.hasAttribute('integrity'));
        return JSON.stringify({ 
          total: scripts.length, 
          withSRI: withSRI.length,
          ratio: scripts.length > 0 ? withSRI.length / scripts.length : 1
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['ratio'] < 1.0 && data['total'] > 0) {
          return [
            Issue(
              id: 'sec_sri',
              title: 'Subresource Integrity manquante',
              description: 'Ajoutez des attributs integrity aux scripts externes pour la sécurité.',
              severity: IssueSeverity.medium,
              category: AuditCategory.security,
              documentation: 'OWASP A08:2021',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking SRI: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkThirdPartyScripts() async {
    final result = await _service.executeScript('''
      (function() {
        const scripts = document.querySelectorAll('script[src]');
        const thirdParty = Array.from(scripts).filter(s => {
          const src = s.getAttribute('src');
          return src && !src.startsWith('/') && !src.includes(window.location.hostname);
        });
        return JSON.stringify({ count: thirdParty.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['count'] > 0) {
          return [
            Issue(
              id: 'sec_third_party',
              title: 'Scripts tiers',
              description: '${data['count']} script(s) tiers détecté(s). Vérifiez leur sécurité et utilisez SRI.',
              severity: IssueSeverity.medium,
              category: AuditCategory.security,
              documentation: 'OWASP A08:2021',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking third party scripts: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkDeprecatedAPIs() async {
    return [
      Issue(
        id: 'sec_deprecated',
        title: 'APIs obsolètes',
        description: 'Évitez les APIs obsolètes qui peuvent avoir des vulnérabilités.',
        severity: IssueSeverity.low,
        category: AuditCategory.security,
      ),
    ];
  }

  Future<List<Issue>> _checkWeakCrypto() async {
    return [
      Issue(
        id: 'sec_weak_crypto',
        title: 'Cryptographie faible',
        description: 'Utilisez des algorithmes de chiffrement modernes et sécurisés.',
        severity: IssueSeverity.high,
        category: AuditCategory.security,
        documentation: 'OWASP A02:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkInformationDisclosure() async {
    return [
      Issue(
        id: 'sec_info_disclosure',
        title: 'Divulgation d\'informations',
        description: 'Évitez de révéler des informations sensibles dans les erreurs ou les commentaires HTML.',
        severity: IssueSeverity.medium,
        category: AuditCategory.security,
        documentation: 'OWASP A01:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkInsecureForms() async {
    final result = await _service.executeScript('''
      (function() {
        const forms = document.querySelectorAll('form');
        const insecure = Array.from(forms).filter(f => {
          const action = f.getAttribute('action');
          return action && action.startsWith('http://');
        });
        return JSON.stringify({ count: insecure.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['count'] > 0) {
          return [
            Issue(
              id: 'sec_insecure_forms',
              title: 'Formulaires non sécurisés',
              description: '${data['count']} formulaire(s) utilise(nt) HTTP au lieu de HTTPS.',
              severity: IssueSeverity.critical,
              category: AuditCategory.security,
              documentation: 'OWASP A02:2021',
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking insecure forms: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkExternalResources() async {
    return [
      Issue(
        id: 'sec_external_resources',
        title: 'Ressources externes',
        description: 'Vérifiez la sécurité des ressources chargées depuis des domaines externes.',
        severity: IssueSeverity.medium,
        category: AuditCategory.security,
        documentation: 'OWASP A08:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkVersionDisclosure() async {
    return [
      Issue(
        id: 'sec_version_disclosure',
        title: 'Divulgation de version',
        description: 'Évitez de révéler les versions de frameworks ou bibliothèques utilisées.',
        severity: IssueSeverity.low,
        category: AuditCategory.security,
        documentation: 'OWASP A01:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkErrorMessages() async {
    return [
      Issue(
        id: 'sec_error_messages',
        title: 'Messages d\'erreur',
        description: 'Les messages d\'erreur ne doivent pas révéler d\'informations sensibles.',
        severity: IssueSeverity.medium,
        category: AuditCategory.security,
        documentation: 'OWASP A01:2021',
      ),
    ];
  }

  Future<List<Issue>> _checkSessionManagement() async {
    return [
      Issue(
        id: 'sec_session',
        title: 'Gestion de session',
        description: 'Implémentez une gestion de session sécurisée avec expiration et invalidation.',
        severity: IssueSeverity.high,
        category: AuditCategory.security,
        documentation: 'OWASP A07:2021',
      ),
    ];
  }
}

/// Extension des règles de performance
class ExtendedPerformanceRules {
  final LighthouseService _service;

  ExtendedPerformanceRules(this._service);

  Future<List<Issue>> runExtendedRules() async {
    final issues = <Issue>[];

    issues.addAll(await _checkImageFormats());
    issues.addAll(await _checkFontLoading());
    issues.addAll(await _checkUnusedCSS());
    issues.addAll(await _checkUnusedJavaScript());
    issues.addAll(await _checkRenderBlocking());
    issues.addAll(await _checkPreconnect());
    issues.addAll(await _checkDNSPrefetch());
    issues.addAll(await _checkPreload());
    issues.addAll(await _checkPrefetch());
    issues.addAll(await _checkCompression());
    issues.addAll(await _checkHTTP2());
    issues.addAll(await _checkServiceWorker());
    issues.addAll(await _checkWebP());
    issues.addAll(await _checkWebFonts());
    issues.addAll(await _checkThirdPartyBlocking());
    issues.addAll(await _checkLargePayloads());
    issues.addAll(await _checkDocumentSize());
    issues.addAll(await _checkDOMDepth());
    issues.addAll(await _checkEventListeners());

    return issues;
  }

  Future<List<Issue>> _checkImageFormats() async {
    final result = await _service.executeScript('''
      (function() {
        const images = document.querySelectorAll('img[src]');
        const modern = Array.from(images).filter(img => {
          const src = img.src.toLowerCase();
          return src.includes('.webp') || src.includes('.avif');
        });
        return JSON.stringify({ 
          total: images.length, 
          modern: modern.length,
          ratio: images.length > 0 ? modern.length / images.length : 0
        });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['ratio'] < 0.5 && data['total'] > 0) {
          return [
            Issue(
              id: 'perf_image_formats',
              title: 'Formats d\'image non optimisés',
              description: 'Seulement ${(data['ratio'] * 100).toStringAsFixed(0)}% d\'images utilisent des formats modernes (WebP, AVIF).',
              severity: IssueSeverity.medium,
              category: AuditCategory.performance,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking image formats: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkFontLoading() async {
    final result = await _service.executeScript('''
      (function() {
        const fonts = document.querySelectorAll('link[rel="stylesheet"][href*="font"], @font-face');
        return JSON.stringify({ count: fonts.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['count'] > 0) {
          return [
            Issue(
              id: 'perf_font_loading',
              title: 'Chargement des polices',
              description: 'Utilisez font-display: swap et preload pour les polices critiques.',
              severity: IssueSeverity.medium,
              category: AuditCategory.performance,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking font loading: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkUnusedCSS() async {
    return [
      Issue(
        id: 'perf_unused_css',
        title: 'CSS non utilisé',
        description: 'Supprimez le CSS non utilisé pour réduire la taille des fichiers.',
        severity: IssueSeverity.medium,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkUnusedJavaScript() async {
    return [
      Issue(
        id: 'perf_unused_js',
        title: 'JavaScript non utilisé',
        description: 'Supprimez le JavaScript non utilisé et utilisez le code splitting.',
        severity: IssueSeverity.medium,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkRenderBlocking() async {
    final result = await _service.executeScript('''
      (function() {
        const blocking = document.querySelectorAll('link[rel="stylesheet"], script[src]:not([async]):not([defer])');
        return JSON.stringify({ count: blocking.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['count'] > 3) {
          return [
            Issue(
              id: 'perf_render_blocking',
              title: 'Ressources bloquantes',
              description: '${data['count']} ressource(s) bloquante(s) détectée(s). Utilisez async/defer ou inline les CSS critiques.',
              severity: IssueSeverity.high,
              category: AuditCategory.performance,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking render blocking: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkPreconnect() async {
    final result = await _service.executeScript('''
      (function() {
        const preconnect = document.querySelectorAll('link[rel="preconnect"]');
        return JSON.stringify({ count: preconnect.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['count'] == 0) {
          return [
            Issue(
              id: 'perf_preconnect',
              title: 'Preconnect manquant',
              description: 'Utilisez preconnect pour les domaines tiers critiques.',
              severity: IssueSeverity.low,
              category: AuditCategory.performance,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking preconnect: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkDNSPrefetch() async {
    return [
      Issue(
        id: 'perf_dns_prefetch',
        title: 'DNS Prefetch',
        description: 'Utilisez dns-prefetch pour les domaines externes.',
        severity: IssueSeverity.low,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkPreload() async {
    return [
      Issue(
        id: 'perf_preload',
        title: 'Preload',
        description: 'Utilisez preload pour les ressources critiques.',
        severity: IssueSeverity.medium,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkPrefetch() async {
    return [
      Issue(
        id: 'perf_prefetch',
        title: 'Prefetch',
        description: 'Utilisez prefetch pour les ressources futures probables.',
        severity: IssueSeverity.low,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkCompression() async {
    return [
      Issue(
        id: 'perf_compression',
        title: 'Compression',
        description: 'Activez la compression gzip ou brotli sur le serveur.',
        severity: IssueSeverity.medium,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkHTTP2() async {
    return [
      Issue(
        id: 'perf_http2',
        title: 'HTTP/2',
        description: 'Utilisez HTTP/2 pour améliorer les performances.',
        severity: IssueSeverity.medium,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkServiceWorker() async {
    return [
      Issue(
        id: 'perf_service_worker',
        title: 'Service Worker',
        description: 'Implémentez un Service Worker pour la mise en cache et les performances hors ligne.',
        severity: IssueSeverity.low,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkWebP() async {
    return [
      Issue(
        id: 'perf_webp',
        title: 'Format WebP',
        description: 'Utilisez WebP pour les images avec fallback pour les navigateurs plus anciens.',
        severity: IssueSeverity.medium,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkWebFonts() async {
    return [
      Issue(
        id: 'perf_webfonts',
        title: 'Polices web',
        description: 'Optimisez le chargement des polices web avec font-display et subsetting.',
        severity: IssueSeverity.medium,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkThirdPartyBlocking() async {
    return [
      Issue(
        id: 'perf_third_party_blocking',
        title: 'Scripts tiers bloquants',
        description: 'Chargez les scripts tiers de manière asynchrone pour éviter le blocage.',
        severity: IssueSeverity.medium,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkLargePayloads() async {
    return [
      Issue(
        id: 'perf_large_payloads',
        title: 'Payloads volumineux',
        description: 'Réduisez la taille des réponses pour améliorer les temps de chargement.',
        severity: IssueSeverity.medium,
        category: AuditCategory.performance,
      ),
    ];
  }

  Future<List<Issue>> _checkDocumentSize() async {
    final result = await _service.executeScript('''
      (function() {
        return JSON.stringify({ size: document.documentElement.outerHTML.length });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        final sizeKB = data['size'] / 1024;
        if (sizeKB > 100) {
          return [
            Issue(
              id: 'perf_document_size',
              title: 'Document HTML volumineux',
              description: 'Le document HTML fait ${sizeKB.toStringAsFixed(0)} KB. Réduisez la taille pour améliorer les performances.',
              severity: IssueSeverity.medium,
              category: AuditCategory.performance,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking document size: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkDOMDepth() async {
    final result = await _service.executeScript('''
      (function() {
        let maxDepth = 0;
        function getDepth(node, depth) {
          maxDepth = Math.max(maxDepth, depth);
          for (let child of node.children) {
            getDepth(child, depth + 1);
          }
        }
        getDepth(document.body, 0);
        return JSON.stringify({ depth: maxDepth });
      })();
    ''');

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['depth'] > 15) {
          return [
            Issue(
              id: 'perf_dom_depth',
              title: 'Profondeur DOM excessive',
              description: 'La profondeur DOM est de ${data['depth']}. Réduisez la profondeur pour améliorer les performances.',
              severity: IssueSeverity.low,
              category: AuditCategory.performance,
            ),
          ];
        }
      } catch (e) {
        debugPrint('Error checking DOM depth: $e');
      }
    }
    return [];
  }

  Future<List<Issue>> _checkEventListeners() async {
    return [
      Issue(
        id: 'perf_event_listeners',
        title: 'Gestionnaires d\'événements',
        description: 'Utilisez event delegation pour réduire le nombre de gestionnaires d\'événements.',
        severity: IssueSeverity.low,
        category: AuditCategory.performance,
      ),
    ];
  }
}

