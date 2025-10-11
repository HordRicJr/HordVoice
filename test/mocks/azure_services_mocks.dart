import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'package:hordvoice/services/environment_config.dart';
import 'package:hordvoice/services/circuit_breaker.dart';

/// Mock implementation of EnvironmentConfig for testing
class MockEnvironmentConfig extends Mock implements EnvironmentConfig {
  @override
  Future<void> loadConfig() async {
    // Mock implementation
  }

  @override
  bool hasValidValue(String key) {
    return super.noSuchMethod(
      Invocation.method(#hasValidValue, [key]),
      returnValue: true,
    );
  }

  @override
  String? get azureSpeechKey => super.noSuchMethod(
    Invocation.getter(#azureSpeechKey),
    returnValue: 'mock_speech_key',
  );

  @override
  String? get azureSpeechRegion => super.noSuchMethod(
    Invocation.getter(#azureSpeechRegion),
    returnValue: 'eastus',
  );

  @override
  String? get azureOpenAIKey => super.noSuchMethod(
    Invocation.getter(#azureOpenAIKey),
    returnValue: 'mock_openai_key',
  );

  @override
  String? get azureOpenAIEndpoint => super.noSuchMethod(
    Invocation.getter(#azureOpenAIEndpoint),
    returnValue: 'https://mock.openai.azure.com/',
  );

  @override
  String get azureOpenAIDeployment => super.noSuchMethod(
    Invocation.getter(#azureOpenAIDeployment),
    returnValue: 'gpt-35-turbo',
  );

  @override
  String get azureOpenAIApiVersion => super.noSuchMethod(
    Invocation.getter(#azureOpenAIApiVersion),
    returnValue: '2024-02-15-preview',
  );
}

/// Mock implementation of HTTP Client for testing API calls
class MockHttpClient extends Mock implements http.Client {
  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.noSuchMethod(
      Invocation.method(#post, [url], {
        #headers: headers,
        #body: body,
        #encoding: encoding,
      }),
      returnValue: Future.value(http.Response('{"error": "mock"}', 500)),
    );
  }

  @override
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) {
    return super.noSuchMethod(
      Invocation.method(#get, [url], {#headers: headers}),
      returnValue: Future.value(http.Response('{"error": "mock"}', 500)),
    );
  }

  @override
  void close() {
    super.noSuchMethod(Invocation.method(#close, []));
  }
}

/// Mock implementation of CircuitBreaker for testing resilience patterns
class MockCircuitBreaker extends Mock implements CircuitBreaker {
  @override
  Future<T> executeWithFallback<T>(
    Future<T> Function() operation,
    T Function() fallback,
  ) {
    return super.noSuchMethod(
      Invocation.method(#executeWithFallback, [operation, fallback]),
      returnValue: Future.value(fallback()),
    );
  }

  @override
  Future<T> execute<T>(Future<T> Function() operation) {
    return super.noSuchMethod(
      Invocation.method(#execute, [operation]),
      returnValue: operation(),
    );
  }

  @override
  bool get isOpen => super.noSuchMethod(
    Invocation.getter(#isOpen),
    returnValue: false,
  );

  @override
  bool get isClosed => super.noSuchMethod(
    Invocation.getter(#isClosed),
    returnValue: true,
  );

  @override
  bool get isHalfOpen => super.noSuchMethod(
    Invocation.getter(#isHalfOpen),
    returnValue: false,
  );

  @override
  void reset() {
    super.noSuchMethod(Invocation.method(#reset, []));
  }
}

/// Mock implementation of CircuitBreakerManager for testing
class MockCircuitBreakerManager extends Mock implements CircuitBreakerManager {
  @override
  CircuitBreaker getCircuit(
    String name, {
    int? failureThreshold,
    Duration? timeout,
    Duration? retryTimeout,
  }) {
    return super.noSuchMethod(
      Invocation.method(#getCircuit, [name], {
        #failureThreshold: failureThreshold,
        #timeout: timeout,
        #retryTimeout: retryTimeout,
      }),
      returnValue: MockCircuitBreaker(),
    );
  }

  @override
  void disposeCircuit(String name) {
    super.noSuchMethod(Invocation.method(#disposeCircuit, [name]));
  }

  @override
  void disposeAll() {
    super.noSuchMethod(Invocation.method(#disposeAll, []));
  }
}

/// Mock Azure Speech Recognition responses for testing
class MockAzureSpeechResponses {
  static const String successResponse = 'Bonjour HordVoice, comment allez-vous?';
  static const String weatherQuery = 'Quelle est la météo aujourd\'hui?';
  static const String musicQuery = 'Joue ma musique préférée';
  static const String navigationQuery = 'Comment aller au centre-ville?';
  static const String newsQuery = 'Quelles sont les dernières nouvelles?';

  static Map<String, String> getTestResponses() {
    return {
      'success': successResponse,
      'weather': weatherQuery,
      'music': musicQuery,
      'navigation': navigationQuery,
      'news': newsQuery,
    };
  }
}

/// Mock Azure OpenAI responses for testing
class MockAzureOpenAIResponses {
  static Map<String, dynamic> getIntentResponse(String intent) {
    return {
      'choices': [
        {
          'message': {
            'content': intent,
          }
        }
      ]
    };
  }

  static Map<String, dynamic> getPersonalizedResponse(String response) {
    return {
      'choices': [
        {
          'message': {
            'content': response,
          }
        }
      ]
    };
  }

  static Map<String, dynamic> getEmotionResponse(String emotion, double intensity, double confidence) {
    return {
      'choices': [
        {
          'message': {
            'content': jsonEncode({
              'emotion': emotion,
              'intensity': intensity,
              'confidence': confidence,
            }),
          }
        }
      ]
    };
  }

  static Map<String, dynamic> getOptimizedTextResponse(String text) {
    return {
      'choices': [
        {
          'message': {
            'content': text,
          }
        }
      ]
    };
  }

  static Map<String, dynamic> getErrorResponse(int statusCode, String message) {
    return {
      'error': {
        'code': statusCode,
        'message': message,
      }
    };
  }
}

/// Helper class for creating realistic test data
class TestDataHelper {
  static List<String> getTestConversationHistory() {
    return [
      'Bonjour HordVoice',
      'Comment allez-vous?',
      'Pouvez-vous m\'aider?',
    ];
  }

  static Map<String, dynamic> getTestContextData() {
    return {
      'location': 'Paris, France',
      'time': '14:30',
      'weather': {
        'temperature': '22°C',
        'condition': 'ensoleillé',
        'humidity': '65%',
      },
      'user_preferences': {
        'language': 'fr-FR',
        'voice_type': 'female',
        'response_length': 'short',
      },
    };
  }

  static List<String> getTestPhraseHints() {
    return [
      'HordVoice',
      'météo',
      'musique',
      'navigation',
      'actualités',
      'rendez-vous',
      'calendrier',
      'santé',
      'batterie',
      'paramètres',
      'bonjour',
      'au revoir',
      'merci',
      's\'il vous plaît',
    ];
  }

  static Map<String, String> getTestIntentMappings() {
    return {
      'Quelle est la météo?': 'weather',
      'Joue de la musique': 'music',
      'Quelles sont les nouvelles?': 'news',
      'Comment aller à...?': 'navigation',
      'Mon rendez-vous': 'calendar',
      'Comment va ma santé?': 'health',
      'État de la batterie': 'system',
      'Bonjour': 'general',
    };
  }
}

/// Mock for Azure Speech Service dependencies
class MockAzureSpeechServiceDependencies {
  static Future<void> setupPermissionMocks() async {
    // Mock permission handler for microphone access
    // This would be set up in individual tests
  }

  static void setupPlatformChannelMocks() {
    // Mock platform channels for Azure Speech SDK
    // This would be set up in individual tests
  }
}

/// Mock for testing stream controllers and async operations
class MockStreamHelper {
  static StreamController<T> createMockStream<T>() {
    return StreamController<T>.broadcast();
  }

  static Future<void> simulateAsyncDelay({Duration? duration}) async {
    await Future.delayed(duration ?? const Duration(milliseconds: 100));
  }

  static Stream<T> createMockStreamWithData<T>(List<T> data, {Duration? interval}) async* {
    for (final item in data) {
      if (interval != null) {
        await Future.delayed(interval);
      }
      yield item;
    }
  }
}

/// Mock for error scenarios testing
class MockErrorScenarios {
  static Exception createNetworkError() {
    return Exception('Network connection failed');
  }

  static Exception createAuthenticationError() {
    return Exception('Authentication failed - invalid API key');
  }

  static Exception createTimeoutError() {
    return Exception('Request timeout - service did not respond');
  }

  static Exception createServiceUnavailableError() {
    return Exception('Service temporarily unavailable');
  }

  static Exception createQuotaExceededError() {
    return Exception('API quota exceeded');
  }

  static Exception createMalformedResponseError() {
    return Exception('Malformed response from service');
  }
}