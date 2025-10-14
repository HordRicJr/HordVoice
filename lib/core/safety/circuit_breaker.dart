import 'package:flutter/foundation.dart';
import 'safety_config.dart';

enum CircuitState { closed, open, halfOpen }

class CircuitBreaker {
  final String label;
  final int failureThreshold;
  final Duration rollingWindow;
  final Duration openDuration;
  final int halfOpenProbeCount;

  CircuitState _state = CircuitState.closed;
  final List<DateTime> _failures = [];
  DateTime? _openedAt;
  int _probes = 0;

  CircuitBreaker({
    required this.label,
    int? failureThreshold,
    Duration? rollingWindow,
    Duration? openDuration,
    int? halfOpenProbeCount,
  })  : failureThreshold = failureThreshold ?? SafetyConfig.circuitFailureThreshold,
        rollingWindow = rollingWindow ?? SafetyConfig.circuitRollingWindow,
        openDuration = openDuration ?? SafetyConfig.circuitOpenDuration,
        halfOpenProbeCount = halfOpenProbeCount ?? SafetyConfig.circuitHalfOpenProbeCount;

  CircuitState get state => _state;

  bool get allowsExecution {
    _transitionIfNeeded();
    if (_state == CircuitState.open) return false;
    return true;
  }

  void recordSuccess() {
    if (_state == CircuitState.halfOpen) {
      _probes++;
      if (_probes >= halfOpenProbeCount) {
        _close();
      }
    }
  }

  void recordFailure() {
    final now = DateTime.now();
    _failures.add(now);
    _prune(now);
    if (_state == CircuitState.halfOpen) {
      _open();
      return;
    }
    if (_failures.length >= failureThreshold && _state == CircuitState.closed) {
      _open();
    }
  }

  void _open() {
    _state = CircuitState.open;
    _openedAt = DateTime.now();
    _probes = 0;
    debugPrint('[CircuitBreaker][$label] OPEN');
  }

  void _close() {
    _state = CircuitState.closed;
    _failures.clear();
    _probes = 0;
    _openedAt = null;
    debugPrint('[CircuitBreaker][$label] CLOSED');
  }

  void _halfOpen() {
    _state = CircuitState.halfOpen;
    _probes = 0;
    debugPrint('[CircuitBreaker][$label] HALF_OPEN');
  }

  void _transitionIfNeeded() {
    if (_state == CircuitState.open && _openedAt != null) {
      if (DateTime.now().difference(_openedAt!) >= openDuration) {
        _halfOpen();
      }
    }
    _prune(DateTime.now());
  }

  void _prune(DateTime now) {
    _failures.removeWhere((t) => now.difference(t) > rollingWindow);
  }
}
