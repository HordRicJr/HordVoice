import 'package:flutter_test/flutter_test.dart';
import 'package:hordvoice/services/voice_performance_monitoring_service.dart';
import 'package:hordvoice/services/audio_buffer_optimization_service.dart';
import 'package:hordvoice/services/smart_wake_word_detection_service.dart';
import 'package:hordvoice/services/voice_memory_optimization_service.dart';

/// Tests simplifiés pour les services d'optimisation vocale
/// NOTE: Ces tests sont basiques et ne nécessitent pas de mocks complexes
void main() {
  group('Voice Optimization Services Tests', () {
    
    group('VoicePerformanceMonitoringService', () {
      late VoicePerformanceMonitoringService service;

      setUp(() {
        service = VoicePerformanceMonitoringService();
      });

      test('should initialize successfully', () async {
        await service.initialize();
        expect(service.isInitialized, isTrue);
      });

      test('should start monitoring', () async {
        await service.initialize();
        await service.startMonitoring();
        expect(service.isMonitoring, isTrue);
      });

      test('should record voice recognition metrics', () async {
        await service.initialize();
        await service.startMonitoring();

        service.recordVoiceRecognitionMetric(
          latency: const Duration(milliseconds: 100),
          confidence: 0.85,
          audioDataSize: 1024,
          recognizedText: 'test text',
        );

        expect(service.isMonitoring, isTrue);
      });

      test('should record speech synthesis metrics', () async {
        await service.initialize();
        await service.startMonitoring();

        await service.recordSpeechSynthesisMetric(
          latency: const Duration(milliseconds: 200),
          text: 'test synthesis',
          audioOutputSize: 2048,
        );

        expect(service.isMonitoring, isTrue);
      });
    });

    group('AudioBufferOptimizationService', () {
      late AudioBufferOptimizationService service;

      setUp(() {
        service = AudioBufferOptimizationService();
      });

      test('should initialize successfully', () async {
        await service.initialize();
        expect(service.isInitialized, isTrue);
      });

      test('should allocate and deallocate buffers', () async {
        await service.initialize();

        final buffer = service.allocateBuffer(requestedSize: 1024);
        expect(buffer.length, greaterThanOrEqualTo(1024));

        service.deallocateBuffer(buffer);
        // Test passed if no exception thrown
      });

      test('should allocate recognition buffer', () async {
        await service.initialize();

        final buffer = service.allocateRecognitionBuffer();
        expect(buffer.length, greaterThan(0));

        service.deallocateBuffer(buffer);
      });
    });

    group('SmartWakeWordDetectionService', () {
      late SmartWakeWordDetectionService service;

      setUp(() {
        service = SmartWakeWordDetectionService();
      });

      test('should initialize successfully', () async {
        await service.initialize();
        expect(service.isInitialized, isTrue);
      });

      test('should start and stop listening', () async {
        await service.initialize();
        
        await service.startListening();
        expect(service.isListening, isTrue);

        await service.stopListening();
        expect(service.isListening, isFalse);
      });
    });

    group('VoiceMemoryOptimizationService', () {
      late VoiceMemoryOptimizationService service;

      setUp(() {
        service = VoiceMemoryOptimizationService();
      });

      test('should initialize successfully', () async {
        await service.initialize();
        expect(service.isInitialized, isTrue);
      });

      test('should manage context pools', () async {
        await service.initialize();

        final recognitionContext = service.getRecognitionContext();
        expect(recognitionContext, isNotNull);

        service.returnRecognitionContext(recognitionContext);

        final audioContext = service.getAudioContext();
        expect(audioContext, isNotNull);

        service.returnAudioContext(audioContext);

        final synthesisContext = service.getSynthesisContext();
        expect(synthesisContext, isNotNull);

        service.returnSynthesisContext(synthesisContext);
      });

      test('should manage list pools', () async {
        await service.initialize();

        final doubleList = service.getDoubleList();
        expect(doubleList, isNotNull);
        expect(doubleList, isEmpty);

        service.returnDoubleList(doubleList);

        final intList = service.getIntList();
        expect(intList, isNotNull);
        expect(intList, isEmpty);

        service.returnIntList(intList);
      });
    });
  });
}