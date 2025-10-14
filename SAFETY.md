# Runtime Safety & Loop Safeguards

This document describes the safeguards added to prevent infinite loops, runaway timers, and resource exhaustion.

## Goals
- Prevent infinite or unbounded while loops.
- Cap retries for external / unstable operations.
- Introduce circuit breaker around flaky external APIs.
- Add watchdog to detect abnormal callback frequency.
- Provide diagnostic logging that can be silenced in production.

## Core Components
| Component | File | Purpose |
|-----------|------|---------|
| LoopGuard | `lib/core/safety/loop_guard.dart` | Caps iterations; optional time budget. |
| RetryGuard | `lib/core/safety/loop_guard.dart` | Controlled retries w/ exponential backoff + jitter. |
| CircuitBreaker | `lib/core/safety/circuit_breaker.dart` | Opens after repeated failures; half-open probes. |
| SafetyConfig | `lib/core/safety/safety_config.dart` | Central tunable thresholds & toggles. |
| WatchdogService | `lib/core/safety/watchdog_service.dart` | Monitors registered heartbeat sources & timer burst frequency. |

## Circuit Breaker States
- CLOSED: normal operation.
- OPEN: short-circuits calls until cool-down period passes.
- HALF_OPEN: allow limited probes to decide CLOSE or OPEN again.

## Logging Levels

## Smoke Test: LoopGuard & Watchdog

To verify runtime safety, run the following smoke test in your Dart environment:

```dart
import 'package:hordvoice/core/safety/loop_guard.dart';
import 'package:hordvoice/core/safety/watchdog_service.dart';

void main() {
  final guard = LoopGuard(maxIterations: 10, timeout: Duration(milliseconds: 100), label: 'SmokeTest');
  int count = 0;
  while (true) {
    count++;
    guard.iterate();
    if (guard.shouldBreak) {
      WatchdogService.notify('LoopGuard triggered in smoke test', context: 'smoke_test');
      break;
    }
  }
  print('Loop exited after $count iterations.');
}
```

This test will exit after 10 iterations and send a notification to the WatchdogService, confirming that safeguards are active and effective.


## Default Thresholds (initial)
- Max loop iterations (generic): 10_000
- Max retry attempts (API): 5
- Base backoff: 200ms (exponential, capped at 4s)
- Circuit breaker failure threshold: 8 failures in rolling window
- Circuit breaker open duration: 30s
- Watchdog heartbeat interval: 5s
- Timer burst threshold: >200 callbacks / 10s window (warn), >500 (force cancel if supported)

## Integration Targets (Phase 1)
1. `azure_api_optimization_service.dart`: request queue draining while loops + retries.
2. `audio_buffer_optimization_service.dart`: dynamic buffer size loops (ensure upper bound).
3. `smart_wake_word_detection_service.dart`: confidence / energy history maintenance loops.
4. `voice_memory_optimization_service.dart`: pool trimming loops.
5. High-frequency Timer.periodic: wake word pipeline, performance monitoring.

## Usage Examples
```
final guard = LoopGuard(label: 'cache-trim');
while (condition) {
  if (!guard.next()) break; // stops if iteration or time budget exceeded
  // ... loop body
}

final retry = RetryGuard(maxAttempts: 5, label: 'azureCall');
await retry.run(() async {
  return await _callAzure();
});
```

## Watchdog Registration
Services can periodically call:
```
WatchdogService.instance.heartbeat('wake_word');
```
If heartbeats stop or a timer floods events, warnings are emitted.

## Future Enhancements
- Adaptive thresholds based on device performance tier.
- Persist breaker state across app sessions.
- Telemetry export for aggregated failure analytics.

---
This file will evolve as safeguards are rolled out.
