import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Peintre pour l'univers spatial de fond (identique au splash screen)
class SpatialUniversePainter extends CustomPainter {
  final double animationValue;
  
  SpatialUniversePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);
    
    // Fond dégradé spatial
    _drawSpatialBackground(canvas, size, paint);
    
    // Étoiles animées
    _drawAnimatedStars(canvas, size, paint);
    
    // Particules flottantes
    _drawFloatingParticles(canvas, size, paint);
    
    // Ondes d'énergie
    _drawEnergyWaves(canvas, size, paint, center);
  }

  void _drawSpatialBackground(Canvas canvas, Size size, Paint paint) {
    // Dégradé radial du centre vers les bords
    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Color(0xFF0D1B2A).withOpacity(0.8),
        Color(0xFF1B263B).withOpacity(0.6),
        Color(0xFF000000),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawAnimatedStars(Canvas canvas, Size size, Paint paint) {
    paint.shader = null;
    final random = math.Random(42); // Seed fixe pour cohérence
    
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      // Taille variable des étoiles
      final baseSize = random.nextDouble() * 2 + 0.5;
      final pulsation = math.sin(animationValue * 2 * math.pi + i * 0.1) * 0.3 + 0.7;
      final starSize = baseSize * pulsation;
      
      // Couleur variable
      final hue = (animationValue + i * 0.1) % 1.0;
      paint.color = HSLColor.fromAHSL(
        0.6 + pulsation * 0.4,
        hue * 360,
        0.8,
        0.6,
      ).toColor();
      
      canvas.drawCircle(Offset(x, y), starSize, paint);
      
      // Effet de scintillement
      paint.color = paint.color.withOpacity(0.3);
      canvas.drawCircle(Offset(x, y), starSize * 2, paint);
    }
  }

  void _drawFloatingParticles(Canvas canvas, Size size, Paint paint) {
    final random = math.Random(123);
    
    for (int i = 0; i < 30; i++) {
      // Position avec mouvement lent
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      
      final moveX = math.sin(animationValue + i * 0.2) * 20;
      final moveY = math.cos(animationValue * 0.7 + i * 0.3) * 15;
      
      final x = baseX + moveX;
      final y = baseY + moveY;
      
      // Taille et opacité variables
      final size_particle = random.nextDouble() * 3 + 1;
      final opacity = (math.sin(animationValue * 2 + i * 0.5) + 1) * 0.3;
      
      paint.color = Color(0xFF64B5F6).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), size_particle, paint);
    }
  }

  void _drawEnergyWaves(Canvas canvas, Size size, Paint paint, Offset center) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;
    
    // 3 ondes concentriques
    for (int wave = 0; wave < 3; wave++) {
      final phase = animationValue + wave * 0.3;
      final radius = (math.sin(phase * 2 * math.pi) + 1) * 100 + 50 + wave * 30;
      final opacity = (math.sin(phase * 2 * math.pi + math.pi) + 1) * 0.2;
      
      paint.color = Color(0xFF42A5F5).withOpacity(opacity);
      canvas.drawCircle(center, radius, paint);
      
      // Onde secondaire
      paint.color = Color(0xFF1976D2).withOpacity(opacity * 0.5);
      canvas.drawCircle(center, radius + 10, paint);
    }
    
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant SpatialUniversePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}