import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service d'analyse émotionnelle via caméra et ML Kit
class CameraEmotionAnalysisService {
  static final CameraEmotionAnalysisService _instance =
      CameraEmotionAnalysisService._internal();
  factory CameraEmotionAnalysisService() => _instance;
  CameraEmotionAnalysisService._internal();

  // Contrôleurs et services
  CameraController? _cameraController;
  FaceDetector? _faceDetector;

  // État du service
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _hasPermission = false;

  // Streams pour les résultats
  final StreamController<EmotionAnalysisResult> _emotionController =
      StreamController.broadcast();
  final StreamController<bool> _analysisStatusController =
      StreamController.broadcast();

  // Getters pour les streams
  Stream<EmotionAnalysisResult> get emotionStream => _emotionController.stream;
  Stream<bool> get analysisStatusStream => _analysisStatusController.stream;

  // État
  bool get isInitialized => _isInitialized;
  bool get isAnalyzing => _isAnalyzing;
  bool get hasPermission => _hasPermission;
  CameraController? get cameraController => _cameraController;

  /// Initialise le service d'analyse émotionnelle
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('CameraEmotionAnalysisService déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation CameraEmotionAnalysisService...');

      // Vérifier et demander permission caméra
      await _requestCameraPermission();

      if (!_hasPermission) {
        throw Exception('Permission caméra refusée');
      }

      // Initialiser le détecteur de visages ML Kit
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true,
          minFaceSize: 0.15,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      // Obtenir les caméras disponibles
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Aucune caméra disponible');
      }

      // Utiliser la caméra frontale si disponible
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Initialiser le contrôleur caméra
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      _isInitialized = true;
      debugPrint('CameraEmotionAnalysisService initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur initialisation CameraEmotionAnalysisService: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Démarre l'analyse émotionnelle en temps réel
  Future<void> startAnalysis() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isAnalyzing) {
      debugPrint('Analyse émotionnelle déjà en cours');
      return;
    }

    try {
      _isAnalyzing = true;
      _analysisStatusController.add(true);

      debugPrint('Démarrage analyse émotionnelle temps réel...');

      // Démarrer le stream d'images
      await _cameraController!.startImageStream(_processImage);
    } catch (e) {
      debugPrint('Erreur démarrage analyse: $e');
      _isAnalyzing = false;
      _analysisStatusController.add(false);
      rethrow;
    }
  }

  /// Arrête l'analyse émotionnelle
  Future<void> stopAnalysis() async {
    if (!_isAnalyzing) return;

    try {
      debugPrint('Arrêt analyse émotionnelle...');

      await _cameraController?.stopImageStream();
      _isAnalyzing = false;
      _analysisStatusController.add(false);

      debugPrint('Analyse émotionnelle arrêtée');
    } catch (e) {
      debugPrint('Erreur arrêt analyse: $e');
    }
  }

  /// Traite une image pour détecter les émotions
  Future<void> _processImage(CameraImage image) async {
    if (!_isAnalyzing) return;

    try {
      // Convertir CameraImage en InputImage pour ML Kit
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return;

      // Détecter les visages
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        // Analyser le premier visage détecté
        final face = faces.first;
        final emotion = _analyzeEmotionFromFace(face);

        // Envoyer le résultat
        _emotionController.add(emotion);
      }
    } catch (e) {
      debugPrint('Erreur traitement image: $e');
    }
  }

  /// Convertit CameraImage en InputImage (version simplifiée)
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Version simplifiée pour éviter les erreurs de compilation
      // En production, utiliser une conversion plus robuste

      final Uint8List bytes = Uint8List.fromList(
        image.planes.fold<List<int>>([], (List<int> previous, Plane plane) {
          return previous..addAll(plane.bytes);
        }),
      );

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final camera = _cameraController!.description;
      final imageRotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );

      if (imageRotation == null) return null;

      final inputImageFormat = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );

      if (inputImageFormat == null) return null;

      // Version simplifiée sans métadonnées complexes
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Erreur conversion image: $e');
      return null;
    }
  }

  /// Analyse l'émotion à partir d'un visage détecté
  EmotionAnalysisResult _analyzeEmotionFromFace(Face face) {
    String emotion = 'neutre';
    double confidence = 0.5;

    // Analyser les probabilités de sourire et d'yeux ouverts
    final smilingProb = face.smilingProbability ?? 0.0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.5;

    // Logique simple d'analyse émotionnelle
    if (smilingProb > 0.7) {
      emotion = 'joie';
      confidence = smilingProb;
    } else if (smilingProb < 0.2) {
      emotion = 'tristesse';
      confidence = 1.0 - smilingProb;
    } else if (leftEyeOpen < 0.3 && rightEyeOpen < 0.3) {
      emotion = 'fatigue';
      confidence = 1.0 - ((leftEyeOpen + rightEyeOpen) / 2);
    } else if (face.headEulerAngleY != null &&
        face.headEulerAngleY!.abs() > 15) {
      emotion = 'confusion';
      confidence = face.headEulerAngleY!.abs() / 45.0;
    }

    return EmotionAnalysisResult(
      emotion: emotion,
      confidence: confidence,
      faceBounds: face.boundingBox,
      timestamp: DateTime.now(),
      smilingProbability: smilingProb,
      leftEyeOpenProbability: leftEyeOpen,
      rightEyeOpenProbability: rightEyeOpen,
    );
  }

  /// Demande la permission caméra
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      _hasPermission = true;
      return;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      _hasPermission = result.isGranted;
    } else {
      _hasPermission = false;
    }
  }

  /// Prend une photo pour analyse statique
  Future<EmotionAnalysisResult?> captureAndAnalyze() async {
    if (!_isInitialized || _cameraController == null) {
      throw Exception('Service caméra non initialisé');
    }

    try {
      // Prendre une photo
      final XFile imageFile = await _cameraController!.takePicture();

      // Convertir en InputImage
      final inputImage = InputImage.fromFilePath(imageFile.path);

      // Détecter les visages
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        return _analyzeEmotionFromFace(faces.first);
      }

      return null;
    } catch (e) {
      debugPrint('Erreur capture et analyse: $e');
      rethrow;
    }
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    try {
      await stopAnalysis();
      await _cameraController?.dispose();
      await _faceDetector?.close();

      _emotionController.close();
      _analysisStatusController.close();

      _isInitialized = false;
      _hasPermission = false;

      debugPrint('CameraEmotionAnalysisService nettoyé');
    } catch (e) {
      debugPrint('Erreur nettoyage CameraEmotionAnalysisService: $e');
    }
  }
}

/// Résultat d'analyse émotionnelle
class EmotionAnalysisResult {
  final String emotion;
  final double confidence;
  final Rect faceBounds;
  final DateTime timestamp;
  final double smilingProbability;
  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;

  const EmotionAnalysisResult({
    required this.emotion,
    required this.confidence,
    required this.faceBounds,
    required this.timestamp,
    required this.smilingProbability,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
  });

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'faceBounds': {
        'left': faceBounds.left,
        'top': faceBounds.top,
        'width': faceBounds.width,
        'height': faceBounds.height,
      },
      'timestamp': timestamp.toIso8601String(),
      'smilingProbability': smilingProbability,
      'leftEyeOpenProbability': leftEyeOpenProbability,
      'rightEyeOpenProbability': rightEyeOpenProbability,
    };
  }

  @override
  String toString() {
    return 'EmotionAnalysisResult(emotion: $emotion, confidence: ${confidence.toStringAsFixed(2)})';
  }
}
