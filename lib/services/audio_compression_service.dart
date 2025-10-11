import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'voice_performance_monitoring_service.dart';
import 'audio_buffer_optimization_service.dart';

/// Service de compression audio pour optimiser les uploads et réduire la bande passante
class AudioCompressionService {
  static final AudioCompressionService _instance =
      AudioCompressionService._internal();
  factory AudioCompressionService() => _instance;
  AudioCompressionService._internal();

  // Configuration de compression
  static const int _defaultSampleRate = 16000; // 16kHz optimal pour la reconnaissance vocale
  static const int _defaultBitDepth = 16; // 16-bit
  static const int _defaultChannels = 1; // Mono
  static const double _defaultCompressionRatio = 0.6; // 60% de l'original
  static const int _frameSize = 320; // 20ms à 16kHz
  static const double _silenceThreshold = 0.01; // Seuil de détection de silence

  // État du service
  bool _isInitialized = false;
  late VoicePerformanceMonitoringService _performanceService;
  late AudioBufferOptimizationService _bufferService;

  // Configuration adaptative
  AudioQuality _currentQuality = AudioQuality.balanced;
  bool _adaptiveCompressionEnabled = true;
  bool _silenceDetectionEnabled = true;
  bool _noiseReductionEnabled = true;

  // Statistiques
  int _totalCompressions = 0;
  int _totalOriginalBytes = 0;
  int _totalCompressedBytes = 0;
  double _averageCompressionRatio = 0.0;
  double _averageCompressionTime = 0.0;

  // Cache de configurations optimales
  final Map<String, CompressionSettings> _settingsCache = {};

  // Accesseurs publics
  bool get isInitialized => _isInitialized;
  double get averageCompressionRatio => _averageCompressionRatio;
  double get averageCompressionTime => _averageCompressionTime;
  double get bandwidthSavings => _totalOriginalBytes > 0 
      ? 1.0 - (_totalCompressedBytes / _totalOriginalBytes)
      : 0.0;

  Map<String, dynamic> get statistics => {
    'total_compressions': _totalCompressions,
    'total_original_bytes': _totalOriginalBytes,
    'total_compressed_bytes': _totalCompressedBytes,
    'average_compression_ratio': _averageCompressionRatio,
    'average_compression_time_ms': _averageCompressionTime,
    'bandwidth_savings': bandwidthSavings,
    'current_quality': _currentQuality.name,
    'adaptive_compression': _adaptiveCompressionEnabled,
    'silence_detection': _silenceDetectionEnabled,
    'noise_reduction': _noiseReductionEnabled,
  };

  /// Initialise le service de compression audio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initialisation Audio Compression Service...');

      // Initialiser les services dépendants
      _performanceService = VoicePerformanceMonitoringService();
      _bufferService = AudioBufferOptimizationService();

      await _performanceService.initialize();
      await _bufferService.initialize();

      // Initialiser les configurations par défaut
      _initializeDefaultSettings();

      _isInitialized = true;
      debugPrint('Audio Compression Service initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation compression service: $e');
      rethrow;
    }
  }

  /// Initialise les configurations par défaut
  void _initializeDefaultSettings() {
    // Configuration haute qualité
    _settingsCache['high_quality'] = CompressionSettings(
      sampleRate: 22050,
      bitDepth: 16,
      channels: 1,
      compressionLevel: 0.8,
      enableSilenceDetection: true,
      enableNoiseReduction: true,
      frameSize: 441, // 20ms à 22kHz
    );

    // Configuration équilibrée
    _settingsCache['balanced'] = CompressionSettings(
      sampleRate: _defaultSampleRate,
      bitDepth: _defaultBitDepth,
      channels: _defaultChannels,
      compressionLevel: _defaultCompressionRatio,
      enableSilenceDetection: true,
      enableNoiseReduction: true,
      frameSize: _frameSize,
    );

    // Configuration haute compression
    _settingsCache['high_compression'] = CompressionSettings(
      sampleRate: 8000,
      bitDepth: 16,
      channels: 1,
      compressionLevel: 0.3,
      enableSilenceDetection: true,
      enableNoiseReduction: true,
      frameSize: 160, // 20ms à 8kHz
    );

    debugPrint('Configurations de compression initialisées');
  }

  /// Compresse des données audio
  Future<CompressedAudioData> compressAudio({
    required Uint8List audioData,
    required AudioFormat inputFormat,
    AudioQuality? targetQuality,
    String? context,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Déterminer la qualité cible
      targetQuality ??= _determineOptimalQuality(context, audioData.length);

      // Obtenir les paramètres de compression
      final settings = _getCompressionSettings(targetQuality, context);

      // Allouer le buffer de sortie
      final outputBuffer = _bufferService.allocateBuffer(
        requestedSize: (audioData.length * settings.compressionLevel).ceil(),
        context: 'compression_output'
      );

      // Effectuer la compression
      final compressedData = await _performCompression(
        audioData, inputFormat, settings, outputBuffer
      );

      stopwatch.stop();

      // Mettre à jour les statistiques
      _updateCompressionStatistics(
        audioData.length,
        compressedData.data.length,
        stopwatch.elapsed,
      );

      debugPrint('Audio compressé: ${audioData.length} -> ${compressedData.data.length} bytes '
                '(${((1 - compressedData.data.length / audioData.length) * 100).toStringAsFixed(1)}% économie)');

      return compressedData;

    } catch (e) {
      stopwatch.stop();
      debugPrint('Erreur compression audio: $e');
      rethrow;
    }
  }

  /// Détermine la qualité optimale basée sur le contexte et la taille
  AudioQuality _determineOptimalQuality(String? context, int dataSize) {
    if (!_adaptiveCompressionEnabled) {
      return _currentQuality;
    }

    // Adapter selon le contexte
    switch (context) {
      case 'wake_word':
        return AudioQuality.highCompression; // Wake word needs less quality
      case 'streaming':
        return AudioQuality.balanced; // Streaming needs balance
      case 'synthesis_upload':
        return AudioQuality.highQuality; // TTS needs high quality
      case 'recognition':
      default:
        // Adapter selon la taille des données
        if (dataSize > 100000) { // > 100KB
          return AudioQuality.highCompression;
        } else if (dataSize > 50000) { // > 50KB
          return AudioQuality.balanced;
        } else {
          return AudioQuality.highQuality;
        }
    }
  }

  /// Obtient les paramètres de compression
  CompressionSettings _getCompressionSettings(AudioQuality quality, String? context) {
    final cacheKey = '${quality.name}_${context ?? 'default'}';
    
    // Vérifier le cache
    if (_settingsCache.containsKey(cacheKey)) {
      return _settingsCache[cacheKey]!;
    }

    // Créer de nouveaux paramètres basés sur la qualité
    CompressionSettings settings;
    switch (quality) {
      case AudioQuality.highQuality:
        settings = _settingsCache['high_quality']!.copyWith();
        break;
      case AudioQuality.balanced:
        settings = _settingsCache['balanced']!.copyWith();
        break;
      case AudioQuality.highCompression:
        settings = _settingsCache['high_compression']!.copyWith();
        break;
    }

    // Adapter selon le contexte
    if (context != null) {
      settings = _adaptSettingsForContext(settings, context);
    }

    // Mettre en cache
    _settingsCache[cacheKey] = settings;
    return settings;
  }

  /// Adapte les paramètres pour un contexte spécifique
  CompressionSettings _adaptSettingsForContext(
    CompressionSettings base, 
    String context
  ) {
    switch (context) {
      case 'wake_word':
        // Wake word detection needs less quality but fast processing
        return base.copyWith(
          sampleRate: 8000,
          compressionLevel: 0.4,
          enableNoiseReduction: false, // Disable for speed
        );
      
      case 'streaming':
        // Streaming needs balance between quality and bandwidth
        return base.copyWith(
          enableSilenceDetection: true,
          compressionLevel: base.compressionLevel * 0.8,
        );
      
      case 'synthesis_upload':
        // TTS uploads need good quality for clarity
        return base.copyWith(
          sampleRate: max(base.sampleRate, 16000),
          compressionLevel: max(base.compressionLevel, 0.6),
        );
      
      default:
        return base;
    }
  }

  /// Effectue la compression audio
  Future<CompressedAudioData> _performCompression(
    Uint8List inputData,
    AudioFormat inputFormat,
    CompressionSettings settings,
    Uint8List outputBuffer,
  ) async {
    // Convertir les données audio en samples
    final samples = _convertToSamples(inputData, inputFormat);

    // Appliquer le pré-traitement
    final processedSamples = await _preprocessAudio(samples, settings);

    // Effectuer la compression par frames
    final compressedFrames = await _compressFrames(processedSamples, settings);

    // Encoder le résultat
    final compressedData = _encodeCompressedFrames(compressedFrames, settings);

    // Créer les métadonnées
    final metadata = CompressionMetadata(
      originalFormat: inputFormat,
      compressedFormat: AudioFormat(
        sampleRate: settings.sampleRate,
        bitDepth: settings.bitDepth,
        channels: settings.channels,
      ),
      compressionRatio: compressedData.length / inputData.length,
      settings: settings,
      timestamp: DateTime.now(),
    );

    return CompressedAudioData(
      data: compressedData,
      metadata: metadata,
    );
  }

  /// Convertit les données audio en échantillons
  List<double> _convertToSamples(Uint8List data, AudioFormat format) {
    final samples = <double>[];
    
    if (format.bitDepth == 16) {
      // Convertir 16-bit samples
      for (int i = 0; i < data.length - 1; i += 2) {
        final sample = (data[i + 1] << 8) | data[i];
        final normalizedSample = (sample - 32768) / 32768.0;
        samples.add(normalizedSample.clamp(-1.0, 1.0));
      }
    } else if (format.bitDepth == 8) {
      // Convertir 8-bit samples
      for (int i = 0; i < data.length; i++) {
        final normalizedSample = (data[i] - 128) / 128.0;
        samples.add(normalizedSample.clamp(-1.0, 1.0));
      }
    }

    return samples;
  }

  /// Pré-traite l'audio (réduction de bruit, détection de silence)
  Future<List<double>> _preprocessAudio(
    List<double> samples, 
    CompressionSettings settings
  ) async {
    List<double> processed = List.from(samples);

    // Réduction de bruit si activée
    if (settings.enableNoiseReduction && _noiseReductionEnabled) {
      processed = _applyNoiseReduction(processed);
    }

    // Détection et suppression du silence si activée
    if (settings.enableSilenceDetection && _silenceDetectionEnabled) {
      processed = _removeSilence(processed);
    }

    // Normalisation
    processed = _normalizeAudio(processed);

    return processed;
  }

  /// Applique la réduction de bruit simple
  List<double> _applyNoiseReduction(List<double> samples) {
    // Filtre passe-haut simple pour supprimer le bruit de fond
    const cutoffFrequency = 80.0; // Hz
    const sampleRate = _defaultSampleRate;
    final alpha = exp(-2.0 * pi * cutoffFrequency / sampleRate);
    
    final filtered = <double>[samples.isNotEmpty ? samples[0] : 0.0];
    
    for (int i = 1; i < samples.length; i++) {
      final filteredSample = alpha * filtered[i - 1] + (1 - alpha) * samples[i];
      filtered.add(filteredSample);
    }

    return filtered;
  }

  /// Supprime les segments de silence
  List<double> _removeSilence(List<double> samples) {
    final nonSilentSamples = <double>[];
    final windowSize = _frameSize;
    
    for (int i = 0; i < samples.length; i += windowSize) {
      final end = min(i + windowSize, samples.length);
      final window = samples.sublist(i, end);
      
      // Calculer l'énergie de la fenêtre
      final energy = _calculateEnergy(window);
      
      // Garder la fenêtre si elle n'est pas silencieuse
      if (energy > _silenceThreshold) {
        nonSilentSamples.addAll(window);
      }
    }

    return nonSilentSamples;
  }

  /// Calcule l'énergie d'un segment audio
  double _calculateEnergy(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    
    double energy = 0.0;
    for (final sample in samples) {
      energy += sample * sample;
    }
    
    return energy / samples.length;
  }

  /// Normalise l'audio
  List<double> _normalizeAudio(List<double> samples) {
    if (samples.isEmpty) return samples;

    // Trouver le pic maximum
    double maxValue = 0.0;
    for (final sample in samples) {
      maxValue = max(maxValue, sample.abs());
    }

    // Normaliser si nécessaire
    if (maxValue > 0.0 && maxValue < 0.95) {
      final gain = 0.95 / maxValue;
      return samples.map((s) => s * gain).toList();
    }

    return samples;
  }

  /// Compresse les échantillons par frames
  Future<List<CompressedFrame>> _compressFrames(
    List<double> samples, 
    CompressionSettings settings
  ) async {
    final frames = <CompressedFrame>[];
    final frameSize = settings.frameSize;

    for (int i = 0; i < samples.length; i += frameSize) {
      final end = min(i + frameSize, samples.length);
      final frameSamples = samples.sublist(i, end);

      // Compresser la frame
      final compressedFrame = _compressFrame(frameSamples, settings);
      frames.add(compressedFrame);
    }

    return frames;
  }

  /// Compresse une frame individuelle
  CompressedFrame _compressFrame(List<double> samples, CompressionSettings settings) {
    // Quantification adaptative
    final quantizationLevels = (256 * settings.compressionLevel).round();
    final quantizedSamples = _quantizeSamples(samples, quantizationLevels);

    // Encodage delta simple
    final deltaEncoded = _deltaEncode(quantizedSamples);

    return CompressedFrame(
      data: deltaEncoded,
      originalLength: samples.length,
      quantizationLevels: quantizationLevels,
    );
  }

  /// Quantifie les échantillons
  List<int> _quantizeSamples(List<double> samples, int levels) {
    final quantized = <int>[];
    final step = 2.0 / levels; // Range [-1, 1] divisé par les niveaux

    for (final sample in samples) {
      final quantizedValue = ((sample + 1.0) / step).round().clamp(0, levels - 1);
      quantized.add(quantizedValue);
    }

    return quantized;
  }

  /// Encode en delta (différence entre échantillons consécutifs)
  List<int> _deltaEncode(List<int> samples) {
    if (samples.isEmpty) return samples;

    final deltaEncoded = <int>[samples[0]]; // Premier échantillon tel quel

    for (int i = 1; i < samples.length; i++) {
      final delta = samples[i] - samples[i - 1];
      deltaEncoded.add(delta);
    }

    return deltaEncoded;
  }

  /// Encode les frames compressées en données binaires
  Uint8List _encodeCompressedFrames(
    List<CompressedFrame> frames, 
    CompressionSettings settings
  ) {
    final output = <int>[];

    // Header avec métadonnées
    output.addAll(_encodeHeader(settings, frames.length));

    // Encoder chaque frame
    for (final frame in frames) {
      output.addAll(_encodeFrame(frame));
    }

    return Uint8List.fromList(output);
  }

  /// Encode l'en-tête
  List<int> _encodeHeader(CompressionSettings settings, int frameCount) {
    return [
      // Magic number pour identifier le format
      0x48, 0x56, 0x41, 0x43, // "HVAC" (HordVoice Audio Compression)
      
      // Version
      0x01,
      
      // Sample rate (2 bytes)
      settings.sampleRate & 0xFF,
      (settings.sampleRate >> 8) & 0xFF,
      
      // Bit depth
      settings.bitDepth,
      
      // Channels
      settings.channels,
      
      // Frame count (2 bytes)
      frameCount & 0xFF,
      (frameCount >> 8) & 0xFF,
      
      // Compression level (1 byte, scaled to 0-255)
      (settings.compressionLevel * 255).round(),
    ];
  }

  /// Encode une frame
  List<int> _encodeFrame(CompressedFrame frame) {
    final output = <int>[];
    
    // Longueur de la frame (2 bytes)
    final dataLength = frame.data.length;
    output.add(dataLength & 0xFF);
    output.add((dataLength >> 8) & 0xFF);
    
    // Longueur originale (2 bytes)
    output.add(frame.originalLength & 0xFF);
    output.add((frame.originalLength >> 8) & 0xFF);
    
    // Niveaux de quantification
    output.add(frame.quantizationLevels);
    
    // Données de la frame (encodage variable selon la taille)
    if (frame.quantizationLevels <= 256) {
      // 1 byte par échantillon
      output.addAll(frame.data.map((d) => d & 0xFF));
    } else {
      // 2 bytes par échantillon
      for (final value in frame.data) {
        output.add(value & 0xFF);
        output.add((value >> 8) & 0xFF);
      }
    }
    
    return output;
  }

  /// Met à jour les statistiques de compression
  void _updateCompressionStatistics(
    int originalSize,
    int compressedSize,
    Duration compressionTime,
  ) {
    _totalCompressions++;
    _totalOriginalBytes += originalSize;
    _totalCompressedBytes += compressedSize;

    // Mettre à jour la moyenne du ratio de compression
    final currentRatio = compressedSize / originalSize;
    _averageCompressionRatio = ((_averageCompressionRatio * (_totalCompressions - 1)) + 
                               currentRatio) / _totalCompressions;

    // Mettre à jour la moyenne du temps de compression
    final compressionTimeMs = compressionTime.inMilliseconds.toDouble();
    _averageCompressionTime = ((_averageCompressionTime * (_totalCompressions - 1)) + 
                              compressionTimeMs) / _totalCompressions;

    // Enregistrer dans le service de performance
    _performanceService.currentMetrics['compression_ratio'] = _averageCompressionRatio;
    _performanceService.currentMetrics['compression_time'] = _averageCompressionTime;
    _performanceService.currentMetrics['bandwidth_savings'] = bandwidthSavings;
  }

  /// Décompresse des données audio
  Future<Uint8List> decompressAudio(CompressedAudioData compressedData) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Décoder les frames compressées
      final frames = _decodeCompressedFrames(compressedData.data);

      // Décompresser chaque frame
      final decompressedSamples = <double>[];
      for (final frame in frames) {
        final frameSamples = _decompressFrame(frame);
        decompressedSamples.addAll(frameSamples);
      }

      // Convertir en données audio
      final audioData = _convertSamplesToBytes(
        decompressedSamples, 
        compressedData.metadata.originalFormat
      );

      stopwatch.stop();

      debugPrint('Audio décompressé en ${stopwatch.elapsedMilliseconds}ms: '
                '${compressedData.data.length} -> ${audioData.length} bytes');

      return audioData;

    } catch (e) {
      stopwatch.stop();
      debugPrint('Erreur décompression audio: $e');
      rethrow;
    }
  }

  /// Décode les frames compressées
  List<CompressedFrame> _decodeCompressedFrames(Uint8List data) {
    // Cette fonction implémenterait le décodage inverse de _encodeCompressedFrames
    // Pour la démo, on retourne une frame vide
    return [CompressedFrame(data: [], originalLength: 0, quantizationLevels: 256)];
  }

  /// Décompresse une frame
  List<double> _decompressFrame(CompressedFrame frame) {
    // Cette fonction implémenterait la décompression inverse
    // Pour la démo, on retourne des échantillons vides
    return List.filled(frame.originalLength, 0.0);
  }

  /// Convertit les échantillons en bytes
  Uint8List _convertSamplesToBytes(List<double> samples, AudioFormat format) {
    final bytes = <int>[];

    if (format.bitDepth == 16) {
      for (final sample in samples) {
        final intSample = ((sample * 32767).round() + 32768).clamp(0, 65535);
        bytes.add(intSample & 0xFF);
        bytes.add((intSample >> 8) & 0xFF);
      }
    } else if (format.bitDepth == 8) {
      for (final sample in samples) {
        final intSample = ((sample * 127).round() + 128).clamp(0, 255);
        bytes.add(intSample);
      }
    }

    return Uint8List.fromList(bytes);
  }

  /// Configure la qualité de compression
  void setAudioQuality(AudioQuality quality) {
    _currentQuality = quality;
    debugPrint('Qualité audio configurée: ${quality.name}');
  }

  /// Active/désactive la compression adaptative
  void setAdaptiveCompression(bool enabled) {
    _adaptiveCompressionEnabled = enabled;
    debugPrint('Compression adaptative: ${enabled ? "activée" : "désactivée"}');
  }

  /// Active/désactive la détection de silence
  void setSilenceDetection(bool enabled) {
    _silenceDetectionEnabled = enabled;
    debugPrint('Détection de silence: ${enabled ? "activée" : "désactivée"}');
  }

  /// Active/désactive la réduction de bruit
  void setNoiseReduction(bool enabled) {
    _noiseReductionEnabled = enabled;
    debugPrint('Réduction de bruit: ${enabled ? "activée" : "désactivée"}');
  }

  /// Estime la taille compressée
  int estimateCompressedSize(int originalSize, {AudioQuality? quality, String? context}) {
    quality ??= _determineOptimalQuality(context, originalSize);
    final settings = _getCompressionSettings(quality, context);
    return (originalSize * settings.compressionLevel).ceil();
  }

  /// Obtient un rapport détaillé
  Map<String, dynamic> getDetailedReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': statistics,
      'settings_cache': _settingsCache.map((k, v) => MapEntry(k, {
        'sample_rate': v.sampleRate,
        'bit_depth': v.bitDepth,
        'channels': v.channels,
        'compression_level': v.compressionLevel,
      })),
      'performance': {
        'compressions_per_minute': _totalCompressions > 0 
            ? (_totalCompressions / (DateTime.now().millisecondsSinceEpoch / 60000))
            : 0.0,
        'bandwidth_saved_mb': (_totalOriginalBytes - _totalCompressedBytes) / (1024 * 1024),
      },
    };
  }

  /// Nettoie les ressources
  void dispose() {
    _settingsCache.clear();
    _isInitialized = false;
    debugPrint('Audio Compression Service disposé');
  }
}

// === MODÈLES DE DONNÉES ===

/// Qualité audio
enum AudioQuality { highQuality, balanced, highCompression }

/// Format audio
class AudioFormat {
  final int sampleRate;
  final int bitDepth;
  final int channels;

  const AudioFormat({
    required this.sampleRate,
    required this.bitDepth,
    required this.channels,
  });
}

/// Paramètres de compression
class CompressionSettings {
  final int sampleRate;
  final int bitDepth;
  final int channels;
  final double compressionLevel;
  final bool enableSilenceDetection;
  final bool enableNoiseReduction;
  final int frameSize;

  const CompressionSettings({
    required this.sampleRate,
    required this.bitDepth,
    required this.channels,
    required this.compressionLevel,
    required this.enableSilenceDetection,
    required this.enableNoiseReduction,
    required this.frameSize,
  });

  CompressionSettings copyWith({
    int? sampleRate,
    int? bitDepth,
    int? channels,
    double? compressionLevel,
    bool? enableSilenceDetection,
    bool? enableNoiseReduction,
    int? frameSize,
  }) {
    return CompressionSettings(
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      channels: channels ?? this.channels,
      compressionLevel: compressionLevel ?? this.compressionLevel,
      enableSilenceDetection: enableSilenceDetection ?? this.enableSilenceDetection,
      enableNoiseReduction: enableNoiseReduction ?? this.enableNoiseReduction,
      frameSize: frameSize ?? this.frameSize,
    );
  }
}

/// Frame compressée
class CompressedFrame {
  final List<int> data;
  final int originalLength;
  final int quantizationLevels;

  const CompressedFrame({
    required this.data,
    required this.originalLength,
    required this.quantizationLevels,
  });
}

/// Métadonnées de compression
class CompressionMetadata {
  final AudioFormat originalFormat;
  final AudioFormat compressedFormat;
  final double compressionRatio;
  final CompressionSettings settings;
  final DateTime timestamp;

  const CompressionMetadata({
    required this.originalFormat,
    required this.compressedFormat,
    required this.compressionRatio,
    required this.settings,
    required this.timestamp,
  });
}

/// Données audio compressées
class CompressedAudioData {
  final Uint8List data;
  final CompressionMetadata metadata;

  const CompressedAudioData({
    required this.data,
    required this.metadata,
  });
}