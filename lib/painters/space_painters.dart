import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../widgets/spacial_avatar_view.dart';

/// Painter pour le fond spatial avec parallaxe et effets dynamiques
class SpaceBackgroundPainter extends CustomPainter {
  final double starsRotation;
  final double nebulaFlow;
  final List<Star> stars;
  final List<NebulaParticle> nebulaParticles;

  SpaceBackgroundPainter({
    required this.starsRotation,
    required this.nebulaFlow,
    required this.stars,
    required this.nebulaParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient de fond spatial profond
    final backgroundGradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.8,
      [
        const Color(0xFF000511), // Bleu très sombre au centre
        const Color(0xFF001122), // Bleu nuit
        const Color(0xFF000000), // Noir aux bords
      ],
      [0.0, 0.6, 1.0],
    );

    final backgroundPaint = Paint()..shader = backgroundGradient;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Ajouter des effets de nébuleuse lointaine
    _paintDistantNebulae(canvas, size);
  }

  void _paintDistantNebulae(Canvas canvas, Size size) {
    final nebulaPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    // Nébuleuse principale en arrière-plan
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Nébuleuse violette
    nebulaPaint.color = const Color(0xFF4A148C).withOpacity(0.1);
    canvas.drawCircle(
      Offset(centerX + math.sin(nebulaFlow * math.pi) * 100, centerY - 150),
      200,
      nebulaPaint,
    );

    // Nébuleuse bleue
    nebulaPaint.color = const Color(0xFF1565C0).withOpacity(0.08);
    canvas.drawCircle(
      Offset(
        centerX - math.cos(nebulaFlow * math.pi * 0.7) * 150,
        centerY + 100,
      ),
      180,
      nebulaPaint,
    );

    // Nébuleuse rouge lointaine
    nebulaPaint.color = const Color(0xFFB71C1C).withOpacity(0.06);
    canvas.drawCircle(
      Offset(
        centerX + math.cos(nebulaFlow * math.pi * 0.5) * 200,
        centerY + 200,
      ),
      150,
      nebulaPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SpaceBackgroundPainter oldDelegate) {
    return oldDelegate.starsRotation != starsRotation ||
        oldDelegate.nebulaFlow != nebulaFlow;
  }
}

/// Painter pour les nébuleuses intermédiaires avec effets de flux
class NebulaePainter extends CustomPainter {
  final double animationValue;
  final List<NebulaParticle> particles;

  NebulaePainter({required this.animationValue, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      _paintNebulaParticle(canvas, size, particle);
    }
  }

  void _paintNebulaParticle(Canvas canvas, Size size, NebulaParticle particle) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 0.3);

    // Position avec drift animé
    final driftX =
        math.sin(animationValue * 2 * math.pi + particle.driftDirection) * 20;
    final driftY =
        math.cos(animationValue * 2 * math.pi + particle.driftDirection) * 15;

    final x = particle.x * size.width + driftX;
    final y = particle.y * size.height + driftY;

    // Gradient radial pour la particule
    final gradient = ui.Gradient.radial(
      Offset(x, y),
      particle.size,
      [
        particle.color.withOpacity(particle.opacity),
        particle.color.withOpacity(particle.opacity * 0.5),
        particle.color.withOpacity(0.0),
      ],
      [0.0, 0.7, 1.0],
    );

    paint.shader = gradient;
    canvas.drawCircle(Offset(x, y), particle.size, paint);
  }

  @override
  bool shouldRepaint(covariant NebulaePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Painter pour le champ d'étoiles avec scintillement et parallaxe
class StarFieldPainter extends CustomPainter {
  final double rotation;
  final List<Star> stars;

  StarFieldPainter({required this.rotation, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (final star in stars) {
      _paintStar(canvas, size, star, centerX, centerY);
    }
  }

  void _paintStar(
    Canvas canvas,
    Size size,
    Star star,
    double centerX,
    double centerY,
  ) {
    // Position avec rotation parallaxe
    final distance = star.distance;
    final parallaxFactor = 1.0 - distance; // Plus proche = plus de mouvement

    final rotatedAngle =
        math.atan2(star.y - 0.5, star.x - 0.5) + rotation * parallaxFactor;
    final distanceFromCenter =
        math.sqrt(math.pow(star.x - 0.5, 2) + math.pow(star.y - 0.5, 2)) *
        math.min(size.width, size.height);

    final x = centerX + math.cos(rotatedAngle) * distanceFromCenter;
    final y = centerY + math.sin(rotatedAngle) * distanceFromCenter;

    // Scintillement basé sur la phase
    final twinkle = (math.sin(rotation * 4 + star.twinklePhase) + 1) / 2;
    final brightness = star.brightness * (0.6 + 0.4 * twinkle);

    // Couleur de l'étoile selon la distance (plus proche = plus blanc)
    Color starColor;
    if (distance < 0.3) {
      starColor = Color.lerp(Colors.white, Colors.lightBlue, 0.3)!;
    } else if (distance < 0.6) {
      starColor = Color.lerp(Colors.lightBlue, Colors.yellow, 0.4)!;
    } else {
      starColor = Color.lerp(Colors.yellow, Colors.orange, 0.5)!;
    }

    final paint = Paint()
      ..color = starColor.withOpacity(brightness)
      ..style = PaintingStyle.fill;

    // Taille de l'étoile avec effet de perspective
    final adjustedSize = star.size * (0.5 + distance * 0.5);

    // Étoiles proches ont un effet de halo
    if (distance < 0.4 && brightness > 0.7) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, adjustedSize * 0.5);
    }

    canvas.drawCircle(Offset(x, y), adjustedSize, paint);

    // Effet de croix pour les étoiles brillantes
    if (brightness > 0.8 && adjustedSize > 1.5) {
      _paintStarCross(
        canvas,
        Offset(x, y),
        adjustedSize,
        starColor.withOpacity(brightness * 0.6),
      );
    }
  }

  void _paintStarCross(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final crossSize = size * 3;

    // Ligne horizontale
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx + crossSize, center.dy),
      paint,
    );

    // Ligne verticale
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy + crossSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant StarFieldPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

/// Painter pour la poussière cosmique avec mouvement fluide
class CosmicDustPainter extends CustomPainter {
  final double driftValue;
  final List<CosmicDust> particles;

  CosmicDustPainter({required this.driftValue, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    for (final particle in particles) {
      // Position avec dérive
      final driftX =
          math.cos(particle.direction) *
          particle.velocity *
          driftValue *
          size.width;
      final driftY =
          math.sin(particle.direction) *
          particle.velocity *
          driftValue *
          size.height;

      var x = (particle.x * size.width + driftX) % size.width;
      var y = (particle.y * size.height + driftY) % size.height;

      // Wraparound pour continuité
      if (x < 0) x += size.width;
      if (y < 0) y += size.height;

      paint.color = Colors.white.withOpacity(particle.opacity);
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CosmicDustPainter oldDelegate) {
    return oldDelegate.driftValue != driftValue;
  }
}

/// Painter pour les effets de lumière autour de l'avatar
class LightEffectsPainter extends CustomPainter {
  final double glowIntensity;
  final Color emotionalColor;
  final bool isVoiceActive;

  LightEffectsPainter({
    required this.glowIntensity,
    required this.emotionalColor,
    required this.isVoiceActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Halo principal émotionnel
    _paintEmotionalHalo(canvas, Offset(centerX, centerY));

    // Ondes vocales si actif
    if (isVoiceActive) {
      _paintVoiceWaves(canvas, Offset(centerX, centerY));
    }

    // Particules lumineuses flottantes
    _paintLightParticles(canvas, size);
  }

  void _paintEmotionalHalo(Canvas canvas, Offset center) {
    final haloPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    // Gradient radial émotionnel
    final gradient = ui.Gradient.radial(
      center,
      150 * glowIntensity,
      [
        emotionalColor.withOpacity(glowIntensity * 0.3),
        emotionalColor.withOpacity(glowIntensity * 0.1),
        emotionalColor.withOpacity(0.0),
      ],
      [0.0, 0.6, 1.0],
    );

    haloPaint.shader = gradient;
    canvas.drawCircle(center, 150 * glowIntensity, haloPaint);
  }

  void _paintVoiceWaves(Canvas canvas, Offset center) {
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = emotionalColor.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Ondes concentriques
    for (int i = 1; i <= 3; i++) {
      final radius = 120 + (i * 40 * glowIntensity);
      canvas.drawCircle(center, radius, wavePaint);
    }
  }

  void _paintLightParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final random = math.Random(42); // Seed fixe pour cohérence

    for (int i = 0; i < 20; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      final intensity = random.nextDouble() * glowIntensity;

      particlePaint.color = emotionalColor.withOpacity(intensity * 0.4);
      canvas.drawCircle(Offset(x, y), 1 + intensity * 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant LightEffectsPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.emotionalColor != emotionalColor ||
        oldDelegate.isVoiceActive != isVoiceActive;
  }
}
