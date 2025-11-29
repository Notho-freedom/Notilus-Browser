# Modèles de données

Documentation des modèles de données principaux.

## ConsoleEntry

Représente une entrée de console.

```dart
class ConsoleEntry {
  final String message;
  final ConsoleLevel level;
  final DateTime timestamp;
  final String? source;
  final int? line;
}
```

## NetworkRequest

Représente une requête réseau.

```dart
class NetworkRequest {
  final String id;
  final String url;
  final RequestMethod method;
  final NetworkRequestStatus status;
  final int? statusCode;
  final DateTime timestamp;
  final Duration? duration;
}
```

## ViewportPreset

Présélection de viewport pour le responsive testing.

```dart
class ViewportPreset {
  final String id;
  final String name;
  final int width;
  final int height;
  final String? icon;
}
```

## AuditResult

Résultat d'un audit Lighthouse.

```dart
class AuditResult {
  final String url;
  final DateTime timestamp;
  final PerformanceMetrics performance;
  final List<Issue> issues;
  final List<Recommendation> recommendations;
  final double score;
}
```

## Issue

Problème détecté lors d'un audit.

```dart
class Issue {
  final String id;
  final String title;
  final String description;
  final IssueSeverity severity;
  final IssueCategory category;
  final String? element;
}
```

## Recommendation

Recommandation d'amélioration.

```dart
class Recommendation {
  final String id;
  final String title;
  final String description;
  final IssueCategory category;
  final double? impact;
  final String? codeExample;
}
```

