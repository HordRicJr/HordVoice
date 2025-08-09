import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../theme/design_tokens.dart';

/// Widget pour afficher les ondes audio en temps réel
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
        painter: WaveformPainter(
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

/// Painter personnalisé optimisé pour les ondes audio temps réel
class WaveformPainter extends CustomPainter {
  final double audioLevel;
  final Color color;
  final int barsCount;
  final double barWidth;
  final double spacing;
  final bool isActive;
  final double animationValue;

  // Cache pour optimisation performance
  static final List<double> _heightCache = List.filled(32, 0.0);
  static double _lastAudioLevel = 0.0;
  static double _lastAnimationValue = 0.0;

  WaveformPainter({
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
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = false; // Désactiver anti-aliasing pour performance

    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.8;

    // Optimisation: ne recalculer que si nécessaire
    final bool shouldRecalculate =
        (_lastAudioLevel - audioLevel).abs() > 0.01 ||
        (_lastAnimationValue - animationValue).abs() > 0.05;

    if (shouldRecalculate) {
      _lastAudioLevel = audioLevel;
      _lastAnimationValue = animationValue;
      _updateHeightCache(maxBarHeight);
    }

    // Dessiner les barres avec optimisation
    for (int i = 0; i < barsCount && i < _heightCache.length; i++) {
      final x = i * (barWidth + spacing);
      final barHeight = _heightCache[i];

      // Optimisation: ne dessiner que les barres visibles
      if (barHeight > 1.0) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - barHeight / 2, barWidth, barHeight),
          Radius.circular(barWidth / 4),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  /// Met à jour le cache de hauteurs pour optimiser les performances
  void _updateHeightCache(double maxBarHeight) {
    for (int i = 0; i < barsCount && i < _heightCache.length; i++) {
      double barHeight;

      if (isActive && audioLevel > 0.1) {
        // Barres animées avec variation
        final normalizedIndex = i / barsCount;
        final waveOffset =
            math.sin(
                  normalizedIndex * math.pi * 2 + animationValue * math.pi * 2,
                ) *
                0.5 +
            0.5;
        final randomVariation =
            math.sin(animationValue * math.pi * 4 + i * 0.5) * 0.3 + 0.7;

        barHeight = maxBarHeight * audioLevel * waveOffset * randomVariation;
        barHeight = math.max(barHeight, 4.0); // Hauteur minimale
      } else {
        // Barres au repos
        barHeight = 4.0 + (maxBarHeight * 0.1 * math.sin(i * 0.5));
      }

      _heightCache[i] = barHeight;
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.audioLevel != audioLevel ||
        oldDelegate.isActive != isActive ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}

/// Widget pour une waveform circulaire autour de l'avatar
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
    this.segmentsCount = 32,
    this.isActive = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioLevel = ref.watch(audioLevelProvider);
    final emotion = ref.watch(currentEmotionProvider);

    final waveColor = color ?? emotion.primaryColor;

    return Container(
      width: radius * 2,
      height: radius * 2,
      child: CustomPaint(
        painter: CircularWaveformPainter(
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

/// Painter pour la waveform circulaire
class CircularWaveformPainter extends CustomPainter {
  final double audioLevel;
  final Color color;
  final double radius;
  final double strokeWidth;
  final int segmentsCount;
  final bool isActive;
  final double animationValue;

  CircularWaveformPainter({
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
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = (math.pi * 2) / segmentsCount;

    for (int i = 0; i < segmentsCount; i++) {
      final angle = i * angleStep;

      // Calculer la longueur du segment basée sur le niveau audio
      double segmentLength;

      if (isActive) {
        final waveOffset =
            math.sin(angle * 2 + animationValue * math.pi * 2) * 0.5 + 0.5;
        final randomVariation =
            math.sin(animationValue * math.pi * 3 + i * 0.3) * 0.4 + 0.6;

        segmentLength = 10 + (audioLevel * 20 * waveOffset * randomVariation);
      } else {
        segmentLength = 5 + (5 * math.sin(i * 0.5));
      }

      // Calculer les points de début et fin du segment
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

      // Dessiner le segment
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(CircularWaveformPainter oldDelegate) {
    return oldDelegate.audioLevel != audioLevel ||
        oldDelegate.isActive != isActive ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
