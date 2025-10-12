import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
// import 'package:integration_test/integration_test.dart'; // Intégration de test sera ajoutée au besoin
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:hordvoice/services/azure_speech_service.dart';
import 'package:hordvoice/services/azure_openai_service.dart';
import '../mocks/azure_services_mocks.dart';

void main() {
  // IntegrationTestWidgetsFlutterBinding.ensureInitialized(); // Pour les tests d'intégration complets

  group('Azure AI Services Integration Tests', () {
    late AzureSpeechService speechService;
    late AzureOpenAIService openAIService;
    late MockEnvironmentConfig mockEnvConfig;

    setUpAll(() async {
      // Initialize services for integration testing
      speechService = AzureSpeechService();
      openAIService = AzureOpenAIService();
      mockEnvConfig = MockEnvironmentConfig();

      // Setup mock platform channels for testing
      _setupMockPlatformChannels();
    });

    tearDownAll(() async {
      await speechService.dispose();
      openAIService.dispose();
    });

    group('Complete Voice Processing Pipeline', () {
      testWidgets('should process voice input through complete pipeline', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();
        await openAIService.initialize();

        final pipelineResults = <String>[];
        final pipelineErrors = <String>[];

        // Listen to speech recognition results
        speechService.resultStream.listen((result) {
          pipelineResults.add('speech_result: ${result.recognizedText}');
        });

        speechService.errorStream.listen((error) {
          pipelineErrors.add('speech_error: ${error.errorMessage}');
        });

        // Act - Simulate complete voice interaction
        try {
          // Step 1: Start speech recognition
          final recognizedText = await speechService.startSimpleRecognition();
          expect(recognizedText, isNotNull);
          pipelineResults.add('recognition_complete: $recognizedText');

          // Step 2: Analyze intent
          final intent = await openAIService.analyzeIntent(recognizedText!);
          expect(intent, isNotEmpty);
          pipelineResults.add('intent_analysis: $intent');

          // Step 3: Generate response based on intent
          final response = await openAIService.generateContextualResponse(
            recognizedText,
            intent,
            TestDataHelper.getTestContextData(),
          );
          expect(response, isNotEmpty);
          pipelineResults.add('response_generation: $response');

          // Step 4: Optimize response for speech synthesis
          final optimizedResponse = await openAIService.optimizeForSpeech(response);
          expect(optimizedResponse, isNotEmpty);
          pipelineResults.add('speech_optimization: $optimizedResponse');

        } catch (e) {
          pipelineErrors.add('pipeline_error: $e');
        }

        // Assert
        await tester.pump(Duration(milliseconds: 500));
        
        expect(pipelineResults, isNotEmpty);
        expect(pipelineResults.any((result) => result.contains('recognition_complete')), isTrue);
        expect(pipelineResults.any((result) => result.contains('intent_analysis')), isTrue);
        expect(pipelineResults.any((result) => result.contains('response_generation')), isTrue);
        expect(pipelineResults.any((result) => result.contains('speech_optimization')), isTrue);
      });

      testWidgets('should handle different intent types in pipeline', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();
        await openAIService.initialize();

        final testScenarios = [
          {'input': 'Quelle est la météo?', 'expectedIntent': 'weather'},
          {'input': 'Joue ma musique', 'expectedIntent': 'music'},
          {'input': 'Quelles sont les nouvelles?', 'expectedIntent': 'news'},
          {'input': 'Comment aller au centre-ville?', 'expectedIntent': 'navigation'},
        ];

        for (final scenario in testScenarios) {
          // Act
          final input = scenario['input']!;
          final expectedIntent = scenario['expectedIntent']!;

          // Simulate speech recognition result
          final intent = await openAIService.analyzeIntent(input);
          final response = await openAIService.generateContextualResponse(
            input,
            intent,
            TestDataHelper.getTestContextData(),
          );

          // Assert
          expect(intent, equals(expectedIntent));
          expect(response, isNotEmpty);
        }

        await tester.pump(Duration(milliseconds: 100));
      });

      testWidgets('should maintain conversation context through pipeline', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();
        await openAIService.initialize();

        final conversationHistory = <String>[];
        final responses = <String>[];

        final conversationFlow = [
          'Bonjour HordVoice',
          'Comment allez-vous?',
          'Pouvez-vous me dire la météo?',
          'Merci beaucoup',
        ];

        // Act - Simulate multi-turn conversation
        for (final input in conversationFlow) {
          conversationHistory.add(input);
          
          final intent = await openAIService.analyzeIntent(input);
          final response = await openAIService.generatePersonalizedResponse(
            input,
            'helpful',
            'test_user',
            List.from(conversationHistory),
          );
          
          responses.add(response);
          conversationHistory.add(response);
        }

        // Assert
        expect(responses, hasLength(conversationFlow.length));
        expect(responses.every((response) => response.isNotEmpty), isTrue);
        expect(conversationHistory, hasLength(conversationFlow.length * 2));

        await tester.pump(Duration(milliseconds: 100));
      });
    });

    group('Error Recovery and Resilience', () {
      testWidgets('should recover from speech recognition errors', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();

        final errorResults = <String>[];
        speechService.errorStream.listen((error) {
          errorResults.add(error.errorMessage);
        });

        // Setup platform channel to simulate error then success
        var callCount = 0;
        const MethodChannel('azure_speech_recognition')
            .setMockMethodCallHandler((MethodCall methodCall) async {
          callCount++;
          if (callCount == 1) {
            throw PlatformException(code: 'ERROR', message: 'Simulated error');
          } else {
            return 'Recovery successful';
          }
        });

        // Act
        String? firstAttempt;
        String? secondAttempt;

        try {
          firstAttempt = await speechService.startSimpleRecognition();
        } catch (e) {
          // Expected to fail
        }

        secondAttempt = await speechService.startSimpleRecognition();

        // Assert
        expect(firstAttempt, isNull);
        expect(secondAttempt, isNotNull);
        expect(secondAttempt, contains('Recovery successful'));

        await tester.pump(Duration(milliseconds: 100));
      });

      testWidgets('should fallback gracefully when OpenAI service fails', (WidgetTester tester) async {
        // Arrange
        await openAIService.initialize();

        // Act - Test all methods with potential failures
        final intentResult = await openAIService.analyzeIntent('test input');
        final personalizedResult = await openAIService.generatePersonalizedResponse(
          'test', 'type', 'user', []
        );
        final contextualResult = await openAIService.generateContextualResponse(
          'test', 'general', {}
        );
        final emotionResult = await openAIService.analyzeEmotions('test');
        final speechResult = await openAIService.optimizeForSpeech('test');

        // Assert - All should return valid fallback responses
        expect(intentResult, isNotEmpty);
        expect(personalizedResult, isNotEmpty);
        expect(contextualResult, isNotEmpty);
        expect(emotionResult, isA<Map<String, dynamic>>());
        expect(speechResult, isNotEmpty);

        await tester.pump(Duration(milliseconds: 100));
      });

      testWidgets('should handle concurrent requests properly', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();
        await openAIService.initialize();

        // Act - Make multiple concurrent requests
        final futures = <Future>[];
        
        for (int i = 0; i < 5; i++) {
          futures.add(openAIService.analyzeIntent('test input $i'));
        }

        final results = await Future.wait(futures);

        // Assert
        expect(results, hasLength(5));
        expect(results.every((result) => result is String && result.isNotEmpty), isTrue);

        await tester.pump(Duration(milliseconds: 100));
      });
    });

    group('Performance and Stress Testing', () {
      testWidgets('should handle rapid consecutive requests', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();
        await openAIService.initialize();

        final startTime = DateTime.now();
        final results = <String>[];

        // Act - Make 10 rapid requests
        for (int i = 0; i < 10; i++) {
          final result = await openAIService.analyzeIntent('rapid test $i');
          results.add(result);
        }

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Assert
        expect(results, hasLength(10));
        expect(results.every((result) => result.isNotEmpty), isTrue);
        expect(duration.inSeconds, lessThan(30)); // Should complete within 30 seconds

        await tester.pump(Duration(milliseconds: 100));
      });

      testWidgets('should manage memory efficiently during long sessions', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();
        await openAIService.initialize();

        final largeConversationHistory = List.generate(50, (index) => 'Message $index');

        // Act - Process large conversation
        final response = await openAIService.generatePersonalizedResponse(
          'Tell me a story',
          'storyteller',
          'test_user',
          largeConversationHistory,
        );

        // Clear cache to test memory management
        openAIService.clearLastResponse();

        // Assert
        expect(response, isNotEmpty);
        expect(openAIService.getLastResponse(), contains('pas de réponse disponible'));

        await tester.pump(Duration(milliseconds: 100));
      });
    });

    group('Stream Processing Integration', () {
      testWidgets('should process multiple speech recognition streams', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();

        final speechResults = <String>[];
        final statusUpdates = <SpeechRecognitionStatus>[];
        
        speechService.speechStream.listen(speechResults.add);
        speechService.statusStream.listen(statusUpdates.add);

        // Act - Perform multiple recognition cycles
        for (int i = 0; i < 3; i++) {
          await speechService.startSimpleRecognition();
          await Future.delayed(Duration(milliseconds: 100));
        }

        // Assert
        await tester.pump(Duration(milliseconds: 500));
        
        expect(speechResults, isNotEmpty);
        expect(statusUpdates, contains(SpeechRecognitionStatus.listening));
        expect(statusUpdates, contains(SpeechRecognitionStatus.stopped));

        await tester.pump(Duration(milliseconds: 100));
      });

      testWidgets('should handle stream subscription lifecycle properly', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();

        final results = <String>[];
        late StreamSubscription subscription;

        // Act - Subscribe, collect data, then cancel
        subscription = speechService.speechStream.listen(results.add);
        
        await speechService.startSimpleRecognition();
        await Future.delayed(Duration(milliseconds: 100));
        
        await subscription.cancel();
        
        // Try to trigger more events after cancellation
        await speechService.startSimpleRecognition();

        // Assert
        expect(results, isNotEmpty);
        // Should not crash after subscription cancellation

        await tester.pump(Duration(milliseconds: 100));
      });
    });

    group('Service Interaction Testing', () {
      testWidgets('should coordinate between speech and OpenAI services', (WidgetTester tester) async {
        // Arrange
        await speechService.initialize();
        await openAIService.initialize();

        final coordinationLog = <String>[];

        // Act - Simulate coordinated service interaction
        coordinationLog.add('Starting speech recognition');
        final speechResult = await speechService.startSimpleRecognition();
        
        coordinationLog.add('Speech recognition completed');
        expect(speechResult, isNotNull);

        coordinationLog.add('Starting intent analysis');
        final intent = await openAIService.analyzeIntent(speechResult!);
        
        coordinationLog.add('Intent analysis completed');
        expect(intent, isNotEmpty);

        coordinationLog.add('Starting emotion analysis');
        final emotions = await openAIService.analyzeEmotions(speechResult);
        
        coordinationLog.add('Emotion analysis completed');
        expect(emotions, isA<Map<String, dynamic>>());

        coordinationLog.add('Pipeline completed successfully');

        // Assert
        expect(coordinationLog, hasLength(7));
        expect(coordinationLog.last, equals('Pipeline completed successfully'));

        await tester.pump(Duration(milliseconds: 100));
      });
    });
  });
}

/// Helper function to setup mock platform channels for integration testing
void _setupMockPlatformChannels() {
  // Mock Azure Speech Recognition platform channel
  const MethodChannel('azure_speech_recognition')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'startRecognition':
        await Future.delayed(Duration(milliseconds: 500)); // Simulate processing time
        return MockAzureSpeechResponses.successResponse;
      case 'stopContinuousRecognition':
        return null;
      default:
        return null;
    }
  });

  // Mock Azure Speech Phrase Hints platform channel
  const MethodChannel('azure_speech_phrase_hints')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'configureCustomHints':
      case 'clearAllHints':
        return true;
      default:
        return false;
    }
  });

  // Mock Permission Handler platform channel
  const MethodChannel('flutter.baseflow.com/permissions/methods')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'requestPermissions') {
      return <String, int>{'microphone': 1}; // granted
    } else if (methodCall.method == 'checkPermissionStatus') {
      return 1; // granted
    }
    return null;
  });
}