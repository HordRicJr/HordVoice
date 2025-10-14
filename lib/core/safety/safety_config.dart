class SafetyConfig {
  static const bool enableVerboseLogging = true; // set false for production
  static const int maxGenericLoopIterations = 10000;
  static const Duration maxLoopTimeBudget = Duration(seconds: 2);

  static const int defaultMaxRetries = 5;
  static const Duration retryBaseDelay = Duration(milliseconds: 200);
  static const Duration retryMaxDelay = Duration(seconds: 4);

  static const int circuitFailureThreshold = 8;
  static const Duration circuitRollingWindow = Duration(seconds: 30);
  static const Duration circuitOpenDuration = Duration(seconds: 30);
  static const int circuitHalfOpenProbeCount = 2;

  static const Duration watchdogInterval = Duration(seconds: 5);
  static const Duration heartbeatStaleAfter = Duration(seconds: 15);
  static const int timerWarnThresholdPer10s = 200;
  static const int timerKillThresholdPer10s = 500;
}
