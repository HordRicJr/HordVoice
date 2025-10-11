import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:hordvoice/services/azure_speech_service.dart';
import 'package:hordvoice/services/environment_config.dart';
import 'package:hordvoice/services/azure_speech_phrase_hints_service.dart';

// Generate mocks for dependencies
@GenerateMocks([
  EnvironmentConfig,
  AzureSpeechPhraseHintsService,
])
import 'azure_speech_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AzureSpeechService Tests', () {
    late AzureSpeechService service;
    late MockEnvironmentConfig mockEnvConfig;
    late StreamController<String> speechController;
    late StreamController<SpeechRecognitionStatus> statusController;

    setUp(() {
      // Reset singleton for testing
      service = AzureSpeechService();
      mockEnvConfig = MockEnvironmentConfig();
      speechController = StreamController<String>.broadcast();
      statusController = StreamController<SpeechRecognitionStatus>.broadcast();
    });

    tearDown(() async {
      await speechController.close();
      await statusController.close();
      await service.dispose();
    });

    group('Service Initialization', () {
      test('should initialize successfully with valid configuration', () async {
        // Arrange
        when(mockEnvConfig.loadConfig()).thenAnswer((_) async {});
        when(mockEnvConfig.azureSpeechKey).thenReturn('test_key_12345');
        when(mockEnvConfig.azureSpeechRegion).thenReturn('eastus');

        // Mock permission handler
        const MethodChannel('flutter.baseflow.com/permissions/methods')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'requestPermissions') {
            return <String, int>{'microphone': 1}; // granted
          }
          return null;
        });

        // Act
        await service.initialize();

        // Assert
        expect(service.isInitialized, isTrue);
        expect(service.currentLanguage, equals('fr-FR'));
        expect(service.isListening, isFalse);
      });

      test('should initialize in simulation mode with missing configuration', () async {
        // Arrange
        when(mockEnvConfig.loadConfig()).thenAnswer((_) async {});
        when(mockEnvConfig.azureSpeechKey).thenReturn(null);
        when(mockEnvConfig.azureSpeechRegion).thenReturn(null);

        // Act
        await service.initialize();

        // Assert
        expect(service.isInitialized, isTrue);
      });

      test('should not reinitialize if already initialized', () async {
        // Arrange
        when(mockEnvConfig.loadConfig()).thenAnswer((_) async {});
        when(mockEnvConfig.azureSpeechKey).thenReturn('test_key');
        when(mockEnvConfig.azureSpeechRegion).thenReturn('eastus');

        // Act
        await service.initialize();
        final firstInitialization = service.isInitialized;
        await service.initialize(); // Second call

        // Assert
        expect(firstInitialization, isTrue);
        expect(service.isInitialized, isTrue);
      });
    });

    group('Speech Recognition', () {
      setUp(() async {
        when(mockEnvConfig.loadConfig()).thenAnswer((_) async {});
        when(mockEnvConfig.azureSpeechKey).thenReturn('test_key');
        when(mockEnvConfig.azureSpeechRegion).thenReturn('eastus');
        
        const MethodChannel('flutter.baseflow.com/permissions/methods')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          return <String, int>{'microphone': 1};
        });
        
        await service.initialize();
      });

      test('should start simple recognition successfully', () async {
        // Arrange
        const expectedResult = 'HordVoice, je vous écoute';
        
        // Mock platform channel for Azure Speech
        const MethodChannel('azure_speech_recognition')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'startRecognition') {
            return expectedResult;
          }
          return null;
        });

        // Act
        final result = await service.startSimpleRecognition();

        // Assert
        expect(result, equals(expectedResult));
        expect(service.isListening, isFalse); // Should be false after completion
      });

      test('should handle platform channel errors gracefully', () async {
        // Arrange
        const MethodChannel('azure_speech_recognition')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          throw PlatformException(
            code: 'UNAVAILABLE',
            message: 'Platform channel not available',
          );
        });

        // Act
        final result = await service.startSimpleRecognition();

        // Assert
        expect(result, isNotNull);
        expect(result, contains('cours')); // Fallback message
        expect(service.isListening, isFalse);
      });

      test('should not start recognition if already listening', () async {
        // Arrange
        service = AzureSpeechService();
        // Simulate already listening state
        
        const MethodChannel('azure_speech_recognition')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          return 'first_call';
        });

        // Act
        await service.startSimpleRecognition(); // First call
        final secondResult = await service.startSimpleRecognition(); // Second call

        // Assert
        expect(secondResult, isNull);
      });

      test('should emit status updates during recognition', () async {
        // Arrange
        final statusList = <SpeechRecognitionStatus>[];
        service.statusStream.listen(statusList.add);

        const MethodChannel('azure_speech_recognition')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          return 'test result';
        });

        // Act
        await service.startSimpleRecognition();

        // Assert
        await Future.delayed(Duration(milliseconds: 100)); // Wait for streams
        expect(statusList, contains(SpeechRecognitionStatus.listening));
        expect(statusList, contains(SpeechRecognitionStatus.stopped));
      });

      test('should emit speech results in streams', () async {
        // Arrange
        final speechResults = <String>[];
        final recognitionResults = <SpeechRecognitionResult>[];
        
        service.speechStream.listen(speechResults.add);
        service.resultStream.listen(recognitionResults.add);

        const expectedText = 'Hello HordVoice';
        const MethodChannel('azure_speech_recognition')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          return expectedText;
        });

        // Act
        await service.startSimpleRecognition();

        // Assert
        await Future.delayed(Duration(milliseconds: 100));
        expect(speechResults, contains(expectedText));
        expect(recognitionResults, isNotEmpty);
        expect(recognitionResults.first.recognizedText, equals(expectedText));
        expect(recognitionResults.first.text, equals(expectedText)); // Alias
        expect(recognitionResults.first.isFinal, isTrue);
      });
    });

    group('Error Handling', () {
      test('should emit error when recognition fails', () async {
        // Arrange
        final errors = <SpeechRecognitionError>[];
        service.errorStream.listen(errors.add);

        // Force initialization without proper setup
        await service.initialize();

        const MethodChannel('azure_speech_recognition')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          throw Exception('Network error');
        });

        // Act & Assert
        expect(
          () => service.startSimpleRecognition(),
          throwsException,
        );
      });

      test('should handle initialization errors gracefully', () async {
        // Arrange
        when(mockEnvConfig.loadConfig()).thenThrow(Exception('Config error'));

        // Act
        await service.initialize();

        // Assert
        expect(service.isInitialized, isTrue); // Should continue in simulation mode
      });
    });

    group('Phrase Hints Management', () {
      test('should configure phrase hints successfully', () async {
        // Arrange
        await service.initialize();
        final hints = ['HordVoice', 'bonjour', 'météo'];

        // Mock AzureSpeechPhraseHintsService
        const MethodChannel('azure_speech_phrase_hints')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'configureCustomHints') {
            return true;
          }
          return false;
        });

        // Act
        service.configurePhraseHints(hints);

        // Assert - Should not throw exception
        await Future.delayed(Duration(milliseconds: 100));
      });

      test('should clear phrase hints successfully', () async {
        // Arrange
        await service.initialize();

        const MethodChannel('azure_speech_phrase_hints')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'clearAllHints') {
            return true;
          }
          return false;
        });

        // Act
        service.clearPhraseHints();

        // Assert - Should not throw exception
        await Future.delayed(Duration(milliseconds: 100));
      });
    });

    group('Service State Management', () {
      test('should stop recognition when requested', () async {
        // Arrange
        await service.initialize();
        
        const MethodChannel('azure_speech_recognition')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'startRecognition') {
            return 'test';
          } else if (methodCall.method == 'stopContinuousRecognition') {
            return null;
          }
          return null;
        });

        await service.startSimpleRecognition();

        // Act
        await service.stopRecognition();

        // Assert
        expect(service.isListening, isFalse);
      });

      test('should not stop recognition if not listening', () async {
        // Arrange
        await service.initialize();

        // Act & Assert - Should not throw
        await service.stopRecognition();
        expect(service.isListening, isFalse);
      });

      test('should provide correct service state', () async {
        // Arrange & Act
        await service.initialize();

        // Assert
        expect(service.isInitialized, isTrue);
        expect(service.isListening, isFalse);
        expect(service.currentLanguage, equals('fr-FR'));
      });
    });

    group('Stream Management', () {
      test('should provide broadcast streams', () async {
        // Arrange
        await service.initialize();

        // Act
        final speechStream = service.speechStream;
        final statusStream = service.statusStream;
        final confidenceStream = service.confidenceStream;
        final resultStream = service.resultStream;
        final errorStream = service.errorStream;

        // Assert
        expect(speechStream, isA<Stream<String>>());
        expect(statusStream, isA<Stream<SpeechRecognitionStatus>>());
        expect(confidenceStream, isA<Stream<double>>());
        expect(resultStream, isA<Stream<SpeechRecognitionResult>>());
        expect(errorStream, isA<Stream<SpeechRecognitionError>>());

        // Multiple listeners should be supported (broadcast)
        speechStream.listen((_) {});
        speechStream.listen((_) {}); // Should not throw
      });

      test('should dispose streams properly', () async {
        // Arrange
        await service.initialize();
        final statusList = <SpeechRecognitionStatus>[];
        final subscription = service.statusStream.listen(statusList.add);

        // Act
        await service.dispose();

        // Assert
        expect(service.isInitialized, isFalse);
        await subscription.cancel();
      });
    });

    group('Compatibility Methods', () {
      test('should support legacy method names', () async {
        // Arrange
        await service.initialize();
        
        const MethodChannel('azure_speech_recognition')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          return 'compatibility test';
        });

        // Act & Assert - All these methods should work
        await service.startListening();
        await service.stopListening();
        await service.startContinuousRecognition();
        await service.startSingleShotRecognition();
      });
    });

    group('SpeechRecognitionResult', () {
      test('should create result with all properties', () {
        // Arrange & Act
        const result = SpeechRecognitionResult(
          recognizedText: 'test text',
          confidence: 0.95,
          isFinal: true,
        );

        // Assert
        expect(result.recognizedText, equals('test text'));
        expect(result.text, equals('test text')); // Alias
        expect(result.confidence, equals(0.95));
        expect(result.isFinal, isTrue);
      });

      test('should use default values', () {
        // Arrange & Act
        const result = SpeechRecognitionResult(recognizedText: 'test');

        // Assert
        expect(result.confidence, equals(0.0));
        expect(result.isFinal, isFalse);
      });
    });

    group('SpeechRecognitionError', () {
      test('should create error with all properties', () {
        // Arrange & Act
        const error = SpeechRecognitionError(
          errorMessage: 'test error',
          errorType: SpeechErrorType.network,
        );

        // Assert
        expect(error.errorMessage, equals('test error'));
        expect(error.message, equals('test error')); // Alias
        expect(error.errorType, equals(SpeechErrorType.network));
        expect(error.type, equals(SpeechErrorType.network)); // Alias
      });

      test('should use default error type', () {
        // Arrange & Act
        const error = SpeechRecognitionError(errorMessage: 'test');

        // Assert
        expect(error.errorType, equals(SpeechErrorType.unknown));
        expect(error.type, equals(SpeechErrorType.unknown));
      });
    });
  });
}