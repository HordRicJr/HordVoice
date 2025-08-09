import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../theme/design_tokens.dart';

/// Widget pour afficher les ondes audio en temps réel (optimisé)
class AudioWaveform extends ConsumerWidget {
  final double height;
  final Color? color;
  final int barsCount;
  final double barWidth;
  final double spacing;
  final bool isActive;
  final AnimationController? controller;

  const AudioWaveform({
    super.key,
    this.height = 60.0,
    this.color,
    this.barsCount = 20,
    this.barWidth = 3.0,
    this.spacing = 2.0,
    this.isActive = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioLevel = ref.watch(audioLevelProvider);
    final emotion = ref.watch(currentEmotionProvider);

    final waveColor = color ?? emotion.primaryColor;

    return Container(
      height: height,
      width: (barWidth + spacing) * barsCount,
      child: CustomPaint(
        painter: OptimizedWaveformPainter(
          audioLevel: audioLevel,
          color: waveColor,
          barsCount: barsCount,
          barWidth: barWidth,
          spacing: spacing,
          isActive: isActive,
          animationValue: controller?.value ?? 0.0,
        ),
        size: Size((barWidth + spacing) * barsCount, height),
      ),
    );
  }
}

/// Provider pour le niveau audio actuel
final audioLevelProvider = StateProvider<double>((ref) => 0.0);

/// Provider pour l'émotion actuelle
final currentEmotionProvider = StateProvider<EmotionType>(
  (ref) => EmotionType.neutral,
);

/// Painter optimisé pour les performances temps réel
class OptimizedWaveformPainter extends CustomPainter {
  final double audioLevel;
  final Color color;
  final int barsCount;
  final double barWidth;
  final double spacing;
  final bool isActive;
  final double animationValue;

  // Cache statique pour optimisation performance
  static final List<double> _heightCache = List.filled(32, 0.0);
  static double _lastAudioLevel = 0.0;
  static double _lastAnimationValue = 0.0;
  static bool _cacheValid = false;

  OptimizedWaveformPainter({
    required this.audioLevel,
    required this.color,
    required this.barsCount,
    required this.barWidth,
    required this.spacing,
    required this.isActive,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint optimisé pour performance
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = false; // Performance: désactiver anti-aliasing

    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.8;

    // Optimisation: recalculer cache seulement si changement significatif
    final shouldRecalculate =
        !_cacheValid ||
        (_lastAudioLevel - audioLevel).abs() > 0.02 ||
        (_lastAnimationValue - animationValue).abs() > 0.1;

    if (shouldRecalculate) {
      _updateHeightCache(maxBarHeight);
      _lastAudioLevel = audioLevel;
      _lastAnimationValue = animationValue;
      _cacheValid = true;
    }

    // Dessiner barres avec cache optimisé
    final effectiveCount = math.min(barsCount, _heightCache.length);

    for (int i = 0; i < effectiveCount; i++) {
      final x = i * (barWidth + spacing);
      final barHeight = _heightCache[i];

      // Optimisation: ne dessiner que barres visibles (culling)
      if (barHeight > 2.0 && x < size.width) {
        _drawOptimizedBar(canvas, paint, x, centerY, barHeight);
      }
    }
  }

  /// Dessine une barre optimisée
  void _drawOptimizedBar(
    Canvas canvas,
    Paint paint,
    double x,
    double centerY,
    double barHeight,
  ) {
    // Version rectangulaire simple pour performance maximale
    final rect = Rect.fromLTWH(x, centerY - barHeight / 2, barWidth, barHeight);

    // Gradient conditionnel seulement si audio actif
    if (isActive && audioLevel > 0.4) {
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withOpacity(0.7)],
      );
      paint.shader = gradient.createShader(rect);
    } else {
      paint.shader = null;
    }

    canvas.drawRect(rect, paint);
  }

  /// Met à jour le cache de hauteurs de manière optimisée
  void _updateHeightCache(double maxBarHeight) {
    final effectiveCount = math.min(barsCount, _heightCache.length);

    for (int i = 0; i < effectiveCount; i++) {
      if (isActive && audioLevel > 0.05) {
        // Calcul optimisé pour audio actif
        final normalizedIndex = i / effectiveCount;
        final wavePhase =
            normalizedIndex * math.pi * 2 + animationValue * math.pi * 4;
        final waveOffset = math.sin(wavePhase) * 0.5 + 0.5;

        // Variation aléatoire réduite pour performance
        final randomPhase = animationValue * math.pi * 2 + i * 0.8;
        final randomVariation = math.sin(randomPhase) * 0.3 + 0.7;

        // Hauteur finale avec lissage
        final targetHeight =
            maxBarHeight * audioLevel * waveOffset * randomVariation;
        final minHeight = math.max(4.0, maxBarHeight * 0.1);

        _heightCache[i] = math.max(targetHeight, minHeight);
      } else {
        // Mode repos optimisé
        final restHeight = 6.0 + (maxBarHeight * 0.15 * math.sin(i * 0.6));
        _heightCache[i] = restHeight;
      }
    }
  }

  @override
  bool shouldRepaint(OptimizedWaveformPainter oldDelegate) {
    // Optimisation: repeindre seulement si changement significatif
    return (oldDelegate.audioLevel - audioLevel).abs() > 0.02 ||
        oldDelegate.isActive != isActive ||
        (oldDelegate.animationValue - animationValue).abs() > 0.1 ||
        oldDelegate.color != color;
  }
}

/// Widget pour waveform circulaire optimisée
class CircularWaveform extends ConsumerWidget {
  final double radius;
  final double strokeWidth;
  final Color? color;
  final int segmentsCount;
  final bool isActive;
  final AnimationController? controller;

  const CircularWaveform({
    super.key,
    this.radius = 100.0,
    this.strokeWidth = 3.0,
    this.color,
    this.segmentsCount = 24, // Réduit pour performance
    this.isActive = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioLevel = ref.watch(audioLevelProvider);
    final emotion = ref.watch(currentEmotionProvider);

    final waveColor = color ?? emotion.primaryColor;

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: CustomPaint(
        painter: OptimizedCircularWaveformPainter(
          audioLevel: audioLevel,
          color: waveColor,
          radius: radius,
          strokeWidth: strokeWidth,
          segmentsCount: segmentsCount,
          isActive: isActive,
          animationValue: controller?.value ?? 0.0,
        ),
      ),
    );
  }
}

/// Painter circulaire optimisé
class OptimizedCircularWaveformPainter extends CustomPainter {
  final double audioLevel;
  final Color color;
  final double radius;
  final double strokeWidth;
  final int segmentsCount;
  final bool isActive;
  final double animationValue;

  // Cache pour optimisation
  static final List<double> _segmentCache = List.filled(32, 0.0);
  static double _lastCircularAudioLevel = 0.0;
  static double _lastCircularAnimationValue = 0.0;

  OptimizedCircularWaveformPainter({
    required this.audioLevel,
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.segmentsCount,
    required this.isActive,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true; // Nécessaire pour cercles

    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = (math.pi * 2) / segmentsCount;

    // Cache optimisé
    final shouldRecalculate =
        (_lastCircularAudioLevel - audioLevel).abs() > 0.03 ||
        (_lastCircularAnimationValue - animationValue).abs() > 0.1;

    if (shouldRecalculate) {
      _updateSegmentCache();
      _lastCircularAudioLevel = audioLevel;
      _lastCircularAnimationValue = animationValue;
    }

    // Dessiner segments
    final effectiveCount = math.min(segmentsCount, _segmentCache.length);

    for (int i = 0; i < effectiveCount; i++) {
      final angle = i * angleStep;
      final segmentLength = _segmentCache[i];

      // Points de début et fin du segment
      final startRadius = radius - segmentLength / 2;
      final endRadius = radius + segmentLength / 2;

      final startPoint = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );

      final endPoint = Offset(
        center.dx + endRadius * math.cos(angle),
        center.dy + endRadius * math.sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  /// Met à jour le cache des segments
  void _updateSegmentCache() {
    final effectiveCount = math.min(segmentsCount, _segmentCache.length);

    for (int i = 0; i < effectiveCount; i++) {
      if (isActive && audioLevel > 0.05) {
        final angle = i * (math.pi * 2) / effectiveCount;
        final waveOffset =
            math.sin(angle * 2 + animationValue * math.pi * 2) * 0.5 + 0.5;
        final randomVariation =
            math.sin(animationValue * math.pi * 3 + i * 0.4) * 0.4 + 0.6;

        _segmentCache[i] = 8 + (audioLevel * 25 * waveOffset * randomVariation);
      } else {
        _segmentCache[i] = 4 + (6 * math.sin(i * 0.7));
      }
    }
  }

  @override
  bool shouldRepaint(OptimizedCircularWaveformPainter oldDelegate) {
    return (oldDelegate.audioLevel - audioLevel).abs() > 0.03 ||
        oldDelegate.isActive != isActive ||
        (oldDelegate.animationValue - animationValue).abs() > 0.1;
  }
}
