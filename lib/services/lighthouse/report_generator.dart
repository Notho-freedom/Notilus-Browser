/// Service de génération de rapports Lighthouse
/// Génère des rapports PDF, JSON et CSV à partir des audits
library report_generator;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/lighthouse/audit_models.dart';

/// Service de génération de rapports
class ReportGenerator {
  /// Exporte un rapport au format JSON
  static String exportJSON(AuditResult result, {bool pretty = true}) {
    final data = result.toJson();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    return jsonEncode(data);
  }

  /// Exporte un rapport au format CSV
  static String exportCSV(AuditResult result) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Notilus Lighthouse - Audit Report');
    buffer.writeln('URL,${result.url}');
    buffer.writeln('Date,${result.timestamp.toIso8601String()}');
    buffer.writeln('Score Global,${result.overallScore}');
    buffer.writeln('Grade,${result.grade.letter}');
    buffer.writeln();

    // Scores par catégorie
    buffer.writeln('SCORES PAR CATÉGORIE');
    buffer.writeln('Category,Score,Grade');
    for (final entry in result.categories.entries) {
      buffer.writeln('${entry.key.displayName},${entry.value.score},${entry.value.grade.letter}');
    }
    buffer.writeln();

    // Core Web Vitals
    buffer.writeln('CORE WEB VITALS');
    buffer.writeln('Metric,Value,Status');
    buffer.writeln('LCP,${result.webVitals.formattedLCP},${result.webVitals.lcpStatus.displayName}');
    buffer.writeln('FID,${result.webVitals.formattedFID},${result.webVitals.fidStatus.displayName}');
    buffer.writeln('CLS,${result.webVitals.formattedCLS},${result.webVitals.clsStatus.displayName}');
    buffer.writeln('TTFB,${result.webVitals.formattedTTFB},${result.webVitals.ttfbStatus.displayName}');
    buffer.writeln();

    // Problèmes
    buffer.writeln('PROBLÈMES DÉTECTÉS (${result.issues.length})');
    buffer.writeln('Severity,Category,Title,Description');
    for (final issue in result.sortedIssues) {
      final desc = issue.description.replaceAll(',', ';').replaceAll('\n', ' ');
      buffer.writeln('${issue.severity.displayName},${issue.category.displayName},"${issue.title}","$desc"');
    }
    buffer.writeln();

    // Recommandations
    buffer.writeln('RECOMMANDATIONS (${result.recommendations.length})');
    buffer.writeln('Priority,Category,Title,Impact');
    for (final rec in result.sortedRecommendations) {
      buffer.writeln('${rec.priority.displayName},${rec.category.displayName},"${rec.title}",${rec.estimatedImpact}');
    }

    return buffer.toString();
  }

  /// Génère le contenu HTML d'un rapport
  static String generateHTML(AuditResult result) {
    final template = '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rapport Notilus Lighthouse - ${_escapeHtml(result.url)}</title>
  <style>
    :root {
      --primary: #0EA5E9;
      --success: #22C55E;
      --warning: #F59E0B;
      --danger: #EF4444;
      --bg: #0f0f15;
      --surface: #17171f;
      --border: #252530;
      --text: #f5f5f5;
      --text-muted: #9ca3af;
    }
    
    * { box-sizing: border-box; margin: 0; padding: 0; }
    
    body {
      font-family: 'Segoe UI', system-ui, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
      padding: 40px;
    }
    
    .container { max-width: 1200px; margin: 0 auto; }
    
    .header {
      text-align: center;
      padding: 40px;
      background: linear-gradient(135deg, #0EA5E920, #8B5CF620);
      border-radius: 16px;
      margin-bottom: 32px;
    }
    
    .header h1 {
      font-size: 28px;
      margin-bottom: 8px;
      background: linear-gradient(90deg, #0EA5E9, #8B5CF6);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    
    .header .url { color: var(--text-muted); font-size: 14px; }
    .header .date { color: var(--text-muted); font-size: 12px; margin-top: 8px; }
    
    .score-hero {
      display: flex;
      justify-content: center;
      gap: 32px;
      padding: 32px;
      background: var(--surface);
      border-radius: 16px;
      margin-bottom: 32px;
    }
    
    .score-circle {
      width: 140px;
      height: 140px;
      border-radius: 50%;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      position: relative;
    }
    
    .score-circle::before {
      content: '';
      position: absolute;
      inset: 0;
      border-radius: 50%;
      padding: 4px;
      background: conic-gradient(var(--score-color) calc(var(--score) * 3.6deg), var(--border) 0);
      mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
      mask-composite: exclude;
    }
    
    .score-value { font-size: 42px; font-weight: 700; color: var(--score-color); }
    .score-label { font-size: 12px; color: var(--text-muted); }
    
    .scores-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }
    
    .score-card {
      background: var(--surface);
      padding: 20px;
      border-radius: 12px;
      text-align: center;
    }
    
    .score-card h3 { font-size: 14px; color: var(--text-muted); margin-bottom: 8px; }
    .score-card .value { font-size: 32px; font-weight: 700; }
    
    .section {
      background: var(--surface);
      border-radius: 16px;
      padding: 24px;
      margin-bottom: 24px;
    }
    
    .section h2 {
      font-size: 18px;
      margin-bottom: 16px;
      padding-bottom: 12px;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    
    .vitals-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 12px;
    }
    
    .vital-card {
      padding: 16px;
      border-radius: 8px;
      background: var(--bg);
    }
    
    .vital-card h4 { font-size: 14px; font-weight: 600; }
    .vital-card .value { font-size: 24px; font-weight: 700; margin: 8px 0 4px; }
    .vital-card .label { font-size: 11px; color: var(--text-muted); }
    
    .issue-list { list-style: none; }
    
    .issue-item {
      padding: 12px;
      margin-bottom: 8px;
      background: var(--bg);
      border-radius: 8px;
      border-left: 4px solid;
    }
    
    .issue-item.critical { border-color: var(--danger); }
    .issue-item.high { border-color: #F97316; }
    .issue-item.medium { border-color: var(--warning); }
    .issue-item.low { border-color: #3B82F6; }
    .issue-item.info { border-color: #6B7280; }
    
    .issue-title { font-weight: 600; margin-bottom: 4px; }
    .issue-desc { font-size: 13px; color: var(--text-muted); }
    .issue-meta { font-size: 11px; color: var(--text-muted); margin-top: 8px; }
    
    .recommendation-item {
      padding: 16px;
      margin-bottom: 12px;
      background: var(--bg);
      border-radius: 8px;
    }
    
    .recommendation-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }
    
    .recommendation-title { font-weight: 600; }
    
    .badge {
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 10px;
      font-weight: 600;
      text-transform: uppercase;
    }
    
    .badge.high { background: var(--success); color: #fff; }
    .badge.medium { background: var(--warning); color: #000; }
    .badge.low { background: #3B82F6; color: #fff; }
    
    .steps-list {
      margin-top: 12px;
      padding-left: 20px;
    }
    
    .steps-list li {
      font-size: 13px;
      color: var(--text-muted);
      margin-bottom: 4px;
    }
    
    .footer {
      text-align: center;
      padding: 24px;
      color: var(--text-muted);
      font-size: 12px;
    }
    
    @media print {
      body { background: #fff; color: #000; padding: 20px; }
      .section { page-break-inside: avoid; }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚀 Notilus Lighthouse Report</h1>
      <div class="url">${_escapeHtml(result.url)}</div>
      <div class="date">${_formatDate(result.timestamp)} · ${result.auditDuration.inSeconds}s</div>
    </div>
    
    <div class="score-hero">
      <div class="score-circle" style="--score: ${result.overallScore}; --score-color: ${_scoreColor(result.overallScore)}">
        <span class="score-value">${result.overallScore}</span>
        <span class="score-label">Score Global</span>
      </div>
    </div>
    
    <div class="scores-grid">
      ${_buildCategoryScoresHTML(result)}
    </div>
    
    <div class="section">
      <h2>📊 Core Web Vitals</h2>
      <div class="vitals-grid">
        ${_buildWebVitalsHTML(result)}
      </div>
    </div>
    
    ${result.issues.isNotEmpty ? '''
    <div class="section">
      <h2>⚠️ Problèmes détectés (${result.issues.length})</h2>
      <ul class="issue-list">
        ${_buildIssuesHTML(result)}
      </ul>
    </div>
    ''' : ''}
    
    ${result.recommendations.isNotEmpty ? '''
    <div class="section">
      <h2>💡 Recommandations (${result.recommendations.length})</h2>
      ${_buildRecommendationsHTML(result)}
    </div>
    ''' : ''}
    
    <div class="footer">
      Généré par Notilus Lighthouse · ${DateTime.now().toIso8601String()}
    </div>
  </div>
</body>
</html>
''';
    return template;
  }

  /// Génère le contenu Markdown d'un rapport
  static String generateMarkdown(AuditResult result) {
    final buffer = StringBuffer();

    buffer.writeln('# 🚀 Rapport Notilus Lighthouse');
    buffer.writeln();
    buffer.writeln('**URL:** ${result.url}');
    buffer.writeln('**Date:** ${_formatDate(result.timestamp)}');
    buffer.writeln('**Durée:** ${result.auditDuration.inSeconds}s');
    buffer.writeln();

    // Score global
    buffer.writeln('## Score Global');
    buffer.writeln();
    buffer.writeln('| Score | Grade |');
    buffer.writeln('|-------|-------|');
    buffer.writeln('| **${result.overallScore}** | ${result.grade.letter} (${result.grade.label}) |');
    buffer.writeln();

    // Scores par catégorie
    buffer.writeln('## Scores par Catégorie');
    buffer.writeln();
    buffer.writeln('| Catégorie | Score | Grade |');
    buffer.writeln('|-----------|-------|-------|');
    for (final entry in result.categories.entries) {
      buffer.writeln('| ${entry.key.displayName} | ${entry.value.score} | ${entry.value.grade.letter} |');
    }
    buffer.writeln();

    // Core Web Vitals
    buffer.writeln('## Core Web Vitals');
    buffer.writeln();
    buffer.writeln('| Métrique | Valeur | Status |');
    buffer.writeln('|----------|--------|--------|');
    buffer.writeln('| LCP (Largest Contentful Paint) | ${result.webVitals.formattedLCP} | ${_statusEmoji(result.webVitals.lcpStatus)} |');
    buffer.writeln('| FID (First Input Delay) | ${result.webVitals.formattedFID} | ${_statusEmoji(result.webVitals.fidStatus)} |');
    buffer.writeln('| CLS (Cumulative Layout Shift) | ${result.webVitals.formattedCLS} | ${_statusEmoji(result.webVitals.clsStatus)} |');
    buffer.writeln('| TTFB (Time to First Byte) | ${result.webVitals.formattedTTFB} | ${_statusEmoji(result.webVitals.ttfbStatus)} |');
    buffer.writeln();

    // Problèmes
    if (result.issues.isNotEmpty) {
      buffer.writeln('## ⚠️ Problèmes Détectés (${result.issues.length})');
      buffer.writeln();
      for (final issue in result.sortedIssues) {
        buffer.writeln('### ${_severityEmoji(issue.severity)} ${issue.title}');
        buffer.writeln();
        buffer.writeln('**Catégorie:** ${issue.category.displayName}');
        buffer.writeln('**Sévérité:** ${issue.severity.displayName}');
        buffer.writeln();
        buffer.writeln(issue.description);
        if (issue.suggestion != null) {
          buffer.writeln();
          buffer.writeln('> 💡 **Suggestion:** ${issue.suggestion}');
        }
        buffer.writeln();
      }
    }

    // Recommandations
    if (result.recommendations.isNotEmpty) {
      buffer.writeln('## 💡 Recommandations (${result.recommendations.length})');
      buffer.writeln();
      for (final rec in result.sortedRecommendations) {
        buffer.writeln('### ${rec.title}');
        buffer.writeln();
        buffer.writeln('**Priorité:** ${rec.priority.displayName}');
        buffer.writeln('**Impact estimé:** +${rec.estimatedImpact} points');
        buffer.writeln('**Effort:** ${rec.effort.displayName}');
        buffer.writeln();
        buffer.writeln(rec.description);
        if (rec.steps.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('**Étapes:**');
          for (var i = 0; i < rec.steps.length; i++) {
            buffer.writeln('${i + 1}. ${rec.steps[i]}');
          }
        }
        buffer.writeln();
      }
    }

    buffer.writeln('---');
    buffer.writeln('*Généré par Notilus Lighthouse · ${DateTime.now().toIso8601String()}*');

    return buffer.toString();
  }

  /// Sauvegarde un rapport sur le disque
  static Future<String?> saveReport(AuditResult result, ReportFormat format) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${dir.path}/Notilus/Reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final timestamp = result.timestamp.toIso8601String().replaceAll(':', '-').split('.').first;
      final sanitizedUrl = result.url.replaceAll(RegExp(r'[^\w\-]'), '_').substring(0, 50);
      final baseName = 'lighthouse_${sanitizedUrl}_$timestamp';

      String content;
      String extension;

      switch (format) {
        case ReportFormat.json:
          content = exportJSON(result);
          extension = 'json';
          break;
        case ReportFormat.csv:
          content = exportCSV(result);
          extension = 'csv';
          break;
        case ReportFormat.html:
          content = generateHTML(result);
          extension = 'html';
          break;
        case ReportFormat.markdown:
          content = generateMarkdown(result);
          extension = 'md';
          break;
      }

      final file = File('${reportsDir.path}/$baseName.$extension');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      debugPrint('Error saving report: $e');
      return null;
    }
  }

  // Helpers
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static String _scoreColor(int score) {
    if (score >= 90) return '#22C55E';
    if (score >= 50) return '#F59E0B';
    return '#EF4444';
  }

  static String _statusEmoji(IssueSeverity status) {
    switch (status) {
      case IssueSeverity.passed:
        return '✅ Bon';
      case IssueSeverity.warning:
        return '⚠️ À améliorer';
      case IssueSeverity.critical:
        return '❌ Mauvais';
      default:
        return '❓ Inconnu';
    }
  }

  static String _severityEmoji(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.critical:
        return '🔴';
      case IssueSeverity.high:
        return '🟠';
      case IssueSeverity.medium:
      case IssueSeverity.warning:
        return '🟡';
      case IssueSeverity.low:
        return '🔵';
      case IssueSeverity.info:
        return 'ℹ️';
      case IssueSeverity.passed:
        return '✅';
    }
  }

  static String _buildCategoryScoresHTML(AuditResult result) {
    final buffer = StringBuffer();
    for (final entry in result.categories.entries) {
      buffer.writeln('''
        <div class="score-card">
          <h3>${entry.key.displayName}</h3>
          <div class="value" style="color: ${_scoreColor(entry.value.score)}">${entry.value.score}</div>
        </div>
      ''');
    }
    return buffer.toString();
  }

  static String _buildWebVitalsHTML(AuditResult result) {
    return '''
      <div class="vital-card" style="border-left: 4px solid ${_vitalColor(result.webVitals.lcpStatus)}">
        <h4>LCP</h4>
        <div class="value">${result.webVitals.formattedLCP}</div>
        <div class="label">Largest Contentful Paint</div>
      </div>
      <div class="vital-card" style="border-left: 4px solid ${_vitalColor(result.webVitals.fidStatus)}">
        <h4>FID</h4>
        <div class="value">${result.webVitals.formattedFID}</div>
        <div class="label">First Input Delay</div>
      </div>
      <div class="vital-card" style="border-left: 4px solid ${_vitalColor(result.webVitals.clsStatus)}">
        <h4>CLS</h4>
        <div class="value">${result.webVitals.formattedCLS}</div>
        <div class="label">Cumulative Layout Shift</div>
      </div>
      <div class="vital-card" style="border-left: 4px solid ${_vitalColor(result.webVitals.ttfbStatus)}">
        <h4>TTFB</h4>
        <div class="value">${result.webVitals.formattedTTFB}</div>
        <div class="label">Time to First Byte</div>
      </div>
    ''';
  }

  static String _vitalColor(IssueSeverity status) {
    switch (status) {
      case IssueSeverity.passed:
        return '#22C55E';
      case IssueSeverity.warning:
        return '#F59E0B';
      case IssueSeverity.critical:
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  static String _buildIssuesHTML(AuditResult result) {
    final buffer = StringBuffer();
    for (final issue in result.sortedIssues) {
      final severityClass = issue.severity.name.toLowerCase();
      buffer.writeln('''
        <li class="issue-item $severityClass">
          <div class="issue-title">${_escapeHtml(issue.title)}</div>
          <div class="issue-desc">${_escapeHtml(issue.description)}</div>
          <div class="issue-meta">${issue.category.displayName} · ${issue.severity.displayName}</div>
        </li>
      ''');
    }
    return buffer.toString();
  }

  static String _buildRecommendationsHTML(AuditResult result) {
    final buffer = StringBuffer();
    for (final rec in result.sortedRecommendations) {
      final impactClass = rec.impact.name.toLowerCase();
      buffer.writeln('''
        <div class="recommendation-item">
          <div class="recommendation-header">
            <span class="recommendation-title">${_escapeHtml(rec.title)}</span>
            <span class="badge $impactClass">${rec.impact.displayName}</span>
          </div>
          <div class="issue-desc">${_escapeHtml(rec.description)}</div>
          ${rec.steps.isNotEmpty ? '''
          <ol class="steps-list">
            ${rec.steps.map((s) => '<li>${_escapeHtml(s)}</li>').join('\n')}
          </ol>
          ''' : ''}
        </div>
      ''');
    }
    return buffer.toString();
  }
}

/// Formats de rapport disponibles
enum ReportFormat {
  json,
  csv,
  html,
  markdown,
}

