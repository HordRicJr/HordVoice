import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// États du circuit breaker
enum CircuitState {
  closed, // Normal - appels passent
  open, // Erreurs - appels bloqués
  halfOpen, // Test - appels limités
}

/// Circuit Breaker pour services externes (Azure, APIs)
/// Empêche les appels répétés qui échouent et cascade les erreurs
class CircuitBreaker {
  final String serviceName;
  final int failureThreshold;
  final Duration timeout;
  final Duration retryTimeout;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  Timer? _retryTimer;

  // Métriques
  int _totalCalls = 0;
  int _totalFailures = 0;
  int _totalSuccesses = 0;

  CircuitBreaker({
    required this.serviceName,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
    this.retryTimeout = const Duration(minutes: 1),
  });

  /// État actuel
  CircuitState get state => _state;
  bool get isOpen => _state == CircuitState.open;
  bool get isClosed => _state == CircuitState.closed;
  bool get isHalfOpen => _state == CircuitState.halfOpen;

  /// Métriques
  Map<String, dynamic> get metrics => {
    'service': serviceName,
    'state': _state.toString(),
    'failure_count': _failureCount,
    'success_count': _successCount,
    'total_calls': _totalCalls,
    'total_failures': _totalFailures,
    'total_successes': _totalSuccesses,
    'failure_rate': _totalCalls > 0 ? _totalFailures / _totalCalls : 0.0,
    'last_failure': _lastFailureTime?.toIso8601String(),
  };

  /// Exécute un appel protégé par le circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    _totalCalls++;

    // Si circuit ouvert, refuser l'appel
    if (_state == CircuitState.open) {
      _logCircuitAction('call_rejected', 'Circuit ouvert');
      throw CircuitBreakerOpenException(serviceName);
    }

    try {
      final result = await operation().timeout(timeout);
      await _onSuccess();
      return result;
    } catch (e) {
      await _onFailure(e);
      rethrow;
    }
  }

  /// Appel avec fallback
  Future<T> executeWithFallback<T>(
    Future<T> Function() operation,
    T Function() fallback,
  ) async {
    try {
      return await execute(operation);
    } catch (e) {
      _logCircuitAction('fallback_used', 'Utilisation fallback: $e');
      return fallback();
    }
  }

  /// Gestion du succès
  Future<void> _onSuccess() async {
    _successCount++;
    _totalSuccesses++;

    if (_state == CircuitState.halfOpen) {
      // Succès en half-open, retour au closed
      if (_successCount >= 2) {
        await _transitionTo(CircuitState.closed);
        _failureCount = 0;
        _successCount = 0;
      }
    } else if (_state == CircuitState.closed) {
      // Reset failure count sur succès
      _failureCount = max(0, _failureCount - 1);
    }
  }

  /// Gestion de l'échec
  Future<void> _onFailure(Object error) async {
    _failureCount++;
    _totalFailures++;
    _lastFailureTime = DateTime.now();

    _logCircuitAction('failure', 'Échec: $error');

    if (_state == CircuitState.closed) {
      // Vérifier si on doit ouvrir le circuit
      if (_failureCount >= failureThreshold) {
        await _transitionTo(CircuitState.open);
        _scheduleRetry();
      }
    } else if (_state == CircuitState.halfOpen) {
      // Échec en half-open, retour à open
      await _transitionTo(CircuitState.open);
      _scheduleRetry();
    }
  }

  /// Transition d'état
  Future<void> _transitionTo(CircuitState newState) async {
    final oldState = _state;
    _state = newState;

    _logCircuitAction('state_change', '$oldState → $newState');

    // Actions spécifiques selon l'état
    switch (newState) {
      case CircuitState.open:
        _successCount = 0;
        break;
      case CircuitState.halfOpen:
        _successCount = 0;
        break;
      case CircuitState.closed:
        _failureCount = 0;
        _successCount = 0;
        break;
    }
  }

  /// Programme un retry automatique
  void _scheduleRetry() {
    _retryTimer?.cancel();

    _retryTimer = Timer(retryTimeout, () async {
      if (_state == CircuitState.open) {
        await _transitionTo(CircuitState.halfOpen);
        _logCircuitAction('retry_scheduled', 'Passage en half-open pour test');
      }
    });
  }

  /// Réinitialise le circuit (pour tests ou recovery manuelle)
  Future<void> reset() async {
    _retryTimer?.cancel();
    _failureCount = 0;
    _successCount = 0;
    _lastFailureTime = null;
    await _transitionTo(CircuitState.closed);

    _logCircuitAction('reset', 'Circuit réinitialisé manuellement');
  }

  /// Logging des actions
  void _logCircuitAction(String action, String message) {
    if (kDebugMode) {
      debugPrint('🔌 [$serviceName] Circuit Breaker [$action]: $message');
    }
  }

  /// Nettoyage
  void dispose() {
    _retryTimer?.cancel();
    _logCircuitAction('dispose', 'Circuit breaker nettoyé');
  }
}

/// Exception levée quand le circuit est ouvert
class CircuitBreakerOpenException implements Exception {
  final String serviceName;
  CircuitBreakerOpenException(this.serviceName);

  @override
  String toString() => 'Circuit breaker ouvert pour $serviceName';
}

/// Manager pour tous les circuit breakers
class CircuitBreakerManager {
  static final CircuitBreakerManager _instance = CircuitBreakerManager._();
  static CircuitBreakerManager get instance => _instance;
  CircuitBreakerManager._();

  final Map<String, CircuitBreaker> _circuits = {};

  /// Obtient ou crée un circuit breaker
  CircuitBreaker getCircuit(
    String serviceName, {
    int? failureThreshold,
    Duration? timeout,
    Duration? retryTimeout,
  }) {
    return _circuits.putIfAbsent(serviceName, () {
      return CircuitBreaker(
        serviceName: serviceName,
        failureThreshold: failureThreshold ?? 5,
        timeout: timeout ?? Duration(seconds: 30),
        retryTimeout: retryTimeout ?? Duration(minutes: 1),
      );
    });
  }

  /// Obtient les métriques de tous les circuits
  Map<String, dynamic> getAllMetrics() {
    return Map.fromEntries(
      _circuits.entries.map((e) => MapEntry(e.key, e.value.metrics)),
    );
  }

  /// Réinitialise tous les circuits
  Future<void> resetAll() async {
    for (final circuit in _circuits.values) {
      await circuit.reset();
    }
    debugPrint('🔌 Tous les circuit breakers réinitialisés');
  }

  /// Nettoyage
  void dispose() {
    for (final circuit in _circuits.values) {
      circuit.dispose();
    }
    _circuits.clear();
    debugPrint('🧹 CircuitBreakerManager nettoyé');
  }
}
