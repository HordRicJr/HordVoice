import 'dart:async';
import 'package:flutter/foundation.dart';
import 'safety_config.dart';

class WatchdogService {
  WatchdogService._();
  static final instance = WatchdogService._();

  final Map<String, DateTime> _heartbeats = {};
  final Map<String, int> _timerCounts = {};
  Timer? _loop;

  void start() {
    _loop ??= Timer.periodic(SafetyConfig.watchdogInterval, (_) => _tick());
  }

  void stop() {
    _loop?.cancel();
    _loop = null;
  }

  void heartbeat(String id) {
    _heartbeats[id] = DateTime.now();
  }

  void notifyTimerCallback(String id) {
    _timerCounts[id] = (_timerCounts[id] ?? 0) + 1;
  }

  void _tick() {
    final now = DateTime.now();
    _heartbeats.forEach((id, last) {
      if (now.difference(last) > SafetyConfig.heartbeatStaleAfter) {
        debugPrint('[Watchdog] WARN heartbeat stale: $id last=${now.difference(last).inSeconds}s ago');
      }
    });
    // Analyze timer bursts over 10s window using cumulative counts
    _timerCounts.forEach((id, count) {
      if (count > SafetyConfig.timerKillThresholdPer10s) {
        debugPrint('[Watchdog] KILL threshold exceeded for timer $id count=$count/interval');
      } else if (count > SafetyConfig.timerWarnThresholdPer10s) {
        debugPrint('[Watchdog] WARN high frequency timer $id count=$count/interval');
      }
    });
    _timerCounts.clear();
  }
}
