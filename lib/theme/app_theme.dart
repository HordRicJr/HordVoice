import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: DesignTokens.primaryBlue,
      scaffoldBackgroundColor: DesignTokens.lightBackground,

      // Police principale
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: DesignTokens.textH1,
          fontWeight: FontWeight.bold,
          color: DesignTokens.textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: DesignTokens.textH2,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: DesignTokens.textH3,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: DesignTokens.textBody,
          fontWeight: FontWeight.normal,
          color: DesignTokens.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: DesignTokens.textBody,
          fontWeight: FontWeight.normal,
          color: DesignTokens.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: DesignTokens.textCaption,
          fontWeight: FontWeight.normal,
          color: DesignTokens.textSecondary,
        ),
      ),

      // Couleurs
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignTokens.primaryBlue,
        brightness: Brightness.light,
        primary: DesignTokens.primaryBlue,
        secondary: DesignTokens.accentOrange,
        error: DesignTokens.errorRed,
        surface: Colors.white,
        onSurface: DesignTokens.textPrimary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: DesignTokens.textH2,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        ),
        iconTheme: const IconThemeData(color: DesignTokens.textPrimary),
      ),

      // Cards
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(DesignTokens.radiusM)),
        ),
        color: Colors.white,
        shadowColor: Color(0x1A000000),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceL,
            vertical: DesignTokens.spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: DesignTokens.textBody,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Boutons de texte
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.primaryBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: DesignTokens.spaceS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: DesignTokens.textBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration (paramètres uniquement)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: const BorderSide(
            color: DesignTokens.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: const BorderSide(color: DesignTokens.errorRed),
        ),
        contentPadding: const EdgeInsets.all(DesignTokens.spaceM),
        hintStyle: GoogleFonts.inter(
          color: DesignTokens.textSecondary,
          fontSize: DesignTokens.textBody,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryBlue;
          }
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryBlue.withOpacity(0.3);
          }
          return Colors.grey[300];
        }),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: DesignTokens.primaryBlue,
      scaffoldBackgroundColor: DesignTokens.darkBackground,

      // Police principale
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.inter(
              fontSize: DesignTokens.textH1,
              fontWeight: FontWeight.bold,
              color: DesignTokens.textOnDark,
            ),
            displayMedium: GoogleFonts.inter(
              fontSize: DesignTokens.textH2,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textOnDark,
            ),
            displaySmall: GoogleFonts.inter(
              fontSize: DesignTokens.textH3,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textOnDark,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: DesignTokens.textBody,
              fontWeight: FontWeight.normal,
              color: DesignTokens.textOnDark,
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: DesignTokens.textBody,
              fontWeight: FontWeight.normal,
              color: DesignTokens.textOnDark.withOpacity(0.7),
            ),
            bodySmall: GoogleFonts.inter(
              fontSize: DesignTokens.textCaption,
              fontWeight: FontWeight.normal,
              color: DesignTokens.textOnDark.withOpacity(0.7),
            ),
          ),

      // Couleurs
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignTokens.primaryBlue,
        brightness: Brightness.dark,
        primary: DesignTokens.primaryBlue,
        secondary: DesignTokens.accentOrange,
        error: DesignTokens.errorRed,
        surface: const Color(0xFF2C2C2E),
        onSurface: DesignTokens.textOnDark,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: DesignTokens.textH2,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textOnDark,
        ),
        iconTheme: const IconThemeData(color: DesignTokens.textOnDark),
      ),

      // Cards
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(DesignTokens.radiusM)),
        ),
        color: Color(0xFF2C2C2E),
        shadowColor: Color(0x4D000000),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceL,
            vertical: DesignTokens.spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: DesignTokens.textBody,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Boutons de texte
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.primaryBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: DesignTokens.spaceS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: DesignTokens.textBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration (paramètres uniquement)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3A3A3C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: const BorderSide(color: Color(0xFF48484A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: const BorderSide(
            color: DesignTokens.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: const BorderSide(color: DesignTokens.errorRed),
        ),
        contentPadding: const EdgeInsets.all(DesignTokens.spaceM),
        hintStyle: GoogleFonts.inter(
          color: DesignTokens.textOnDark.withOpacity(0.7),
          fontSize: DesignTokens.textBody,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryBlue;
          }
          return Colors.grey[600];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryBlue.withOpacity(0.3);
          }
          return Colors.grey[700];
        }),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF48484A),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
