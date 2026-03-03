/// Classe Result générique pour la gestion des succès/erreurs
/// Alternative aux exceptions pour le flow control
library result;

/// Représente le résultat d'une opération pouvant échouer
/// Similar au type Either de fp_dart ou Result de Rust
sealed class Result<T, E> {
  const Result();
  
  /// Crée un résultat succès
  factory Result.success(T value) => Success(value);
  
  /// Crée un résultat erreur
  factory Result.failure(E error) => Failure(error);
  
  /// Vérifie si c'est un succès
  bool get isSuccess => this is Success<T, E>;
  
  /// Vérifie si c'est une erreur
  bool get isFailure => this is Failure<T, E>;
  
  /// Récupère la valeur si succès, null sinon
  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    Failure() => null,
  };
  
  /// Récupère l'erreur si échec, null sinon
  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(error: final e) => e,
  };
  
  /// Récupère la valeur ou lance une exception si erreur
  T get valueOrThrow => switch (this) {
    Success(value: final v) => v,
    Failure(error: final e) => throw Exception('Unexpected failure: $e'),
  };
  
  /// Applique une fonction selon le cas
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onFailure,
  }) => switch (this) {
    Success(value: final v) => onSuccess(v),
    Failure(error: final e) => onFailure(e),
  };
  
  /// Transforme la valeur si succès
  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
    Success(value: final v) => Success(transform(v)),
    Failure(error: final e) => Failure(e),
  };
  
  /// Transforme l'erreur si échec
  Result<T, R> mapError<R>(R Function(E error) transform) => switch (this) {
    Success(value: final v) => Success(v),
    Failure(error: final e) => Failure(transform(e)),
  };
  
  /// Chaîne avec une autre opération qui peut échouer
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) => switch (this) {
    Success(value: final v) => transform(v),
    Failure(error: final e) => Failure(e),
  };
  
  /// Récupère la valeur ou une valeur par défaut
  T getOrElse(T defaultValue) => switch (this) {
    Success(value: final v) => v,
    Failure() => defaultValue,
  };
  
  /// Récupère la valeur ou calcule une valeur par défaut
  T getOrElseCompute(T Function(E error) compute) => switch (this) {
    Success(value: final v) => v,
    Failure(error: final e) => compute(e),
  };
}

/// Représente un succès avec une valeur
final class Success<T, E> extends Result<T, E> {
  final T value;
  
  const Success(this.value);
  
  @override
  String toString() => 'Success($value)';
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Success<T, E> && value == other.value;
  
  @override
  int get hashCode => value.hashCode;
}

/// Représente un échec avec une erreur
final class Failure<T, E> extends Result<T, E> {
  final E error;
  
  const Failure(this.error);
  
  @override
  String toString() => 'Failure($error)';
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Failure<T, E> && error == other.error;
  
  @override
  int get hashCode => error.hashCode;
}

/// Extension pour les fonctions async retournant Result
extension FutureResultExtension<T, E> on Future<Result<T, E>> {
  /// Applique une fonction selon le cas de manière async
  Future<R> foldAsync<R>({
    required Future<R> Function(T value) onSuccess,
    required Future<R> Function(E error) onFailure,
  }) async {
    final result = await this;
    return result.fold(
      onSuccess: (v) => onSuccess(v),
      onFailure: (e) => onFailure(e),
    );
  }
  
  /// Transforme la valeur si succès de manière async
  Future<Result<R, E>> mapAsync<R>(Future<R> Function(T value) transform) async {
    final result = await this;
    return switch (result) {
      Success(value: final v) => Success(await transform(v)),
      Failure(error: final e) => Failure(e),
    };
  }
}

/// Types d'erreurs d'authentification
enum AuthError {
  /// Backend non disponible
  backendUnavailable,
  
  /// Utilisateur a annulé
  userCancelled,
  
  /// Connexion réseau échouée
  networkError,
  
  /// Token invalide ou expiré
  invalidToken,
  
  /// Email non trouvé
  emailNotFound,
  
  /// Configuration incorrecte
  configurationError,
  
  /// Erreur inconnue
  unknown,
}

/// Extension pour convertir les erreurs en messages
extension AuthErrorExtension on AuthError {
  String get message => switch (this) {
    AuthError.backendUnavailable => 'Le backend OAuth n\'est pas disponible. Démarrez-le avec: cd backend && python main.py',
    AuthError.userCancelled => 'Authentification annulée par l\'utilisateur',
    AuthError.networkError => 'Erreur de connexion réseau',
    AuthError.invalidToken => 'Token invalide ou expiré',
    AuthError.emailNotFound => 'Aucun email trouvé pour ce compte',
    AuthError.configurationError => 'Erreur de configuration',
    AuthError.unknown => 'Une erreur inattendue s\'est produite',
  };
}

/// Résultat d'une opération d'authentification
typedef AuthResult<T> = Result<T, AuthError>;

/// Données pour le flow OAuth GitHub
class GitHubOAuthData {
  final String authUrl;
  final String state;
  
  const GitHubOAuthData({
    required this.authUrl,
    required this.state,
  });
}

/// Données pour le Device Flow Google
class GoogleDeviceFlowData {
  final String deviceCode;
  final String userCode;
  final String verificationUrl;
  final int expiresIn;
  final int interval;
  
  const GoogleDeviceFlowData({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.expiresIn,
    required this.interval,
  });
}

