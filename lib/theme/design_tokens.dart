import 'package:flutter/material.dart';

/// Design tokens pour HordVoice v2.0 - Voice-First Interface
class DesignTokens {
  // Couleurs primaires
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color accentOrange = Color(0xFFFF9500);

  // Fonds
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color darkBackground = Color(0xFF1C1C1E);

  // Couleurs émotionnelles
  static const Color joyYellow = Color(0xFFFFD60A);
  static const Color sadnessBlue = Color(0xFF0A84FF);
  static const Color angerRed = Color(0xFFFF453A);
  static const Color calmGreen = Color(0xFF30D158);

  // Couleurs système
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9F0A);

  // Gradients émotionnels
  static const LinearGradient joyGradient = LinearGradient(
    colors: [joyYellow, Color(0xFFFFF3C4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sadnessGradient = LinearGradient(
    colors: [sadnessBlue, Color(0xFFE3F2FD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient angerGradient = LinearGradient(
    colors: [angerRed, Color(0xFFFFEBEE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient calmGradient = LinearGradient(
    colors: [calmGreen, Color(0xFFE8F5E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Spacing - système de 8dp
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusCircular = 999.0;

  // Tailles de texte
  static const double textH1 = 28.0;
  static const double textH2 = 20.0;
  static const double textH3 = 18.0;
  static const double textBody = 16.0;
  static const double textCaption = 14.0;
  static const double textSmall = 12.0;

  // Durées d'animation
  static const Duration animationShort = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 600);

  // Courbes d'animation
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOut;

  // Ombres
  static const BoxShadow shadowLight = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowMedium = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowHeavy = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  // Opacités
  static const double opacityDisabled = 0.3;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.8;

  // Tailles d'avatar
  static const double avatarSizeSmall = 60.0;
  static const double avatarSizeMedium = 120.0;
  static const double avatarSizeLarge = 180.0;
  static const double avatarSizeXLarge = 240.0;

  // Couleurs selon l'heure de la journée
  static Color getTimeBasedColor(TimeOfDay time) {
    final hour = time.hour;

    if (hour >= 6 && hour < 12) {
      // Matin - couleurs chaudes
      return const Color(0xFFFFB347);
    } else if (hour >= 12 && hour < 18) {
      // Après-midi - couleurs vives
      return primaryBlue;
    } else if (hour >= 18 && hour < 22) {
      // Soirée - couleurs douces
      return const Color(0xFF9B59B6);
    } else {
      // Nuit - couleurs sombres
      return const Color(0xFF2C3E50);
    }
  }

  // Gradients selon l'heure
  static LinearGradient getTimeBasedGradient(TimeOfDay time) {
    final hour = time.hour;

    if (hour >= 6 && hour < 12) {
      // Matin
      return const LinearGradient(
        colors: [Color(0xFFFFB347), Color(0xFFFFF8DC)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (hour >= 12 && hour < 18) {
      // Après-midi
      return const LinearGradient(
        colors: [primaryBlue, Color(0xFFE3F2FD)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (hour >= 18 && hour < 22) {
      // Soirée
      return const LinearGradient(
        colors: [Color(0xFF9B59B6), Color(0xFFF3E5F5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      // Nuit
      return const LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }
}

/// Énumération pour les émotions supportées
enum EmotionType { joy, sadness, anger, calm, neutral, surprise, fear, disgust }

/// Extension pour obtenir les couleurs et gradients par émotion
extension EmotionColors on EmotionType {
  Color get primaryColor {
    switch (this) {
      case EmotionType.joy:
        return DesignTokens.joyYellow;
      case EmotionType.sadness:
        return DesignTokens.sadnessBlue;
      case EmotionType.anger:
        return DesignTokens.angerRed;
      case EmotionType.calm:
        return DesignTokens.calmGreen;
      case EmotionType.surprise:
        return const Color(0xFFFF6B35);
      case EmotionType.fear:
        return const Color(0xFF6C5CE7);
      case EmotionType.disgust:
        return const Color(0xFF00B894);
      case EmotionType.neutral:
        return DesignTokens.primaryBlue;
    }
  }

  LinearGradient get gradient {
    switch (this) {
      case EmotionType.joy:
        return DesignTokens.joyGradient;
      case EmotionType.sadness:
        return DesignTokens.sadnessGradient;
      case EmotionType.anger:
        return DesignTokens.angerGradient;
      case EmotionType.calm:
        return DesignTokens.calmGradient;
      case EmotionType.surprise:
        return const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFFF0E6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case EmotionType.fear:
        return const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFF0EFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case EmotionType.disgust:
        return const LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFFE8FFF8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case EmotionType.neutral:
        return const LinearGradient(
          colors: [DesignTokens.primaryBlue, Color(0xFFE3F2FD)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }
}
