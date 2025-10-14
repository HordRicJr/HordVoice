import 'dart:async';
import 'dart:math';
import 'safety_config.dart';
import 'package:flutter/foundation.dart';

class LoopGuard {
  final String label;
  final int maxIterations;
  final DateTime _start = DateTime.now();
  final Duration timeBudget;
  int _iteration = 0;
  LoopGuard({
    required this.label,
    int? maxIterations,
    Duration? timeBudget,
  })  : maxIterations = maxIterations ?? SafetyConfig.maxGenericLoopIterations,
        timeBudget = timeBudget ?? SafetyConfig.maxLoopTimeBudget;

  bool next() {
    _iteration++;
    if (_iteration > maxIterations) {
      debugPrint('[LoopGuard][$label] Max iterations ($maxIterations) reached – breaking.');
      return false;
    }
    if (DateTime.now().difference(_start) > timeBudget) {
      debugPrint('[LoopGuard][$label] Time budget ($timeBudget) exceeded at iteration $_iteration – breaking.');
      return false;
    }
    return true;
  }
}

class RetryGuard<T> {
  final int maxAttempts;
  final String label;
  final Duration baseDelay;
  final Duration maxDelay;
  RetryGuard({
    this.maxAttempts = SafetyConfig.defaultMaxRetries,
    this.label = 'retry',
    Duration? baseDelay,
    Duration? maxDelay,
  })  : baseDelay = baseDelay ?? SafetyConfig.retryBaseDelay,
        maxDelay = maxDelay ?? SafetyConfig.retryMaxDelay;

  Future<T> run(Future<T> Function() action, {bool Function(Object error)? shouldRetry}) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await action();
      } catch (e, st) {
        final canRetry = attempt < maxAttempts && (shouldRetry == null || shouldRetry(e));
        debugPrint('[RetryGuard][$label] Attempt $attempt failed: $e');
        if (!canRetry) rethrow;
        final delayMs = _calcDelay(attempt);
        debugPrint('[RetryGuard][$label] Retrying in ${delayMs}ms');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  int _calcDelay(int attempt) {
    final exp = baseDelay.inMilliseconds * pow(2, attempt - 1);
    final jitter = Random().nextInt(150);
    return min(exp.toInt() + jitter, maxDelay.inMilliseconds);
  }
}
