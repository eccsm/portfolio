import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme – 2026 premium design system
class AppTheme {
  // ─── Brand Palette ───────────────────────────────────────────────
  static const Color primaryColor = Color(0xFFE8A33D); // Astro accent-fill
  static const Color primaryDark = Color(0xFF96610B); // AA text on light
  static const Color primaryLight = Color(0xFFF4C77F);
  static const Color secondaryColor = Color(0xFF6366F1); // indigo-500
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentRed = Color(0xFFF87171);

  /// Text/icon colour on amber fills (white on amber fails WCAG AA).
  static const Color onPrimary = Color(0xFF14100A);

  // ─── Dark-mode surfaces ──────────────────────────────────────────
  static const Color _darkBg = Color(0xFF0F1115);
  static const Color _darkSurface = Color(0xFF151821);
  static const Color _darkCard = Color(0xFF191D26);
  static const Color _darkCardHeader = Color(0xFF1F2430);
  static const Color _darkBorder = Color(0xFF2A2F3B);

  // ─── Light-mode surfaces ─────────────────────────────────────────
  static const Color _lightBg = Color(0xFFEDF0F5);       // cool blue-grey bg
  static const Color _lightSurface = Color(0xFFF8F9FC);
  static const Color _lightCard = Color(0xFFFBFCFE);     // very slightly off-white
  static const Color _lightCardHeader = Color(0xFFEEF1F6); // visible header tint
  static const Color _lightBorder = Color(0xFFD0D5E0);    // stronger borders

  // ═══════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════
  static ThemeData lightTheme() {
    final base = ThemeData(
      primaryColor: primaryColor,
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: secondaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: onPrimary,
        secondary: secondaryColor,
        surface: _lightSurface,
      ),
    );

    return base.copyWith(
      textTheme: _createTextTheme(const Color(0xFF1A1D26), base),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface.withAlpha(240),
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withAlpha(40),
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: _lightCard,
        shadowColor: const Color(0xFF1A1D26).withAlpha(30),
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      scaffoldBackgroundColor: _lightBg,
      dividerColor: _lightBorder,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF4A5068)),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightCard,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: const TabBarThemeData(indicatorColor: primaryColor),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════════
  static ThemeData darkTheme() {
    final base = ThemeData(
      primaryColor: primaryColor,
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: secondaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: onPrimary,
        secondary: secondaryColor,
        surface: _darkSurface,
      ),
    );

    return base.copyWith(
      textTheme: _createTextTheme(const Color(0xFFE8ECF4), base),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurface,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withAlpha(80),
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: _darkCard,
        shadowColor: Colors.black.withAlpha(60),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      scaffoldBackgroundColor: _darkBg,
      dividerColor: _darkBorder,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFB0B8CC)),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkCard,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _darkSurface,
        modalBackgroundColor: _darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(indicatorColor: primaryColor),
    );
  }

  // ─── Text Theme ──────────────────────────────────────────────────
  static TextTheme _createTextTheme(Color textColor, ThemeData baseTheme) {
    final headingColor = textColor;
    final bodyColor = textColor.withAlpha(230);

    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: headingColor, fontWeight: FontWeight.w800, letterSpacing: -1.5),
        displayMedium: TextStyle(color: headingColor, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displaySmall: TextStyle(color: headingColor, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: headingColor, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: TextStyle(
          color: headingColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(color: headingColor, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: headingColor, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium: TextStyle(color: bodyColor, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: bodyColor, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: bodyColor, fontSize: 16, height: 1.6),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          color: bodyColor,
          height: 1.55,
        ),
        bodySmall: TextStyle(color: bodyColor.withAlpha(180), fontSize: 13),
        labelLarge: TextStyle(color: bodyColor, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: bodyColor.withAlpha(200)),
        labelSmall: TextStyle(color: bodyColor.withAlpha(160)),
      ),
    );
  }

  // ─── Semantic Colors ─────────────────────────────────────────────
  static ThemeColors getColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return ThemeColors(
        background: _darkBg,
        surface: _darkSurface,
        card: _darkCard,
        cardHeader: _darkCardHeader,
        accent: primaryColor,
        accentSecondary: secondaryColor,
        text: const Color(0xFFE8ECF4),
        textSecondary: const Color(0xFF8B95B0),
        divider: _darkBorder,
        border: _darkBorder,
        profileCardBackground: _darkCard,
        chatBubbleUser: secondaryColor,
        chatBubbleBot: _darkCardHeader,
        glassSurface: _darkCard.withAlpha(180),
        glassStroke: Colors.white.withAlpha(15),
        glowColor: primaryColor.withAlpha(40),
        gradientStart: const Color(0xFF151821),
        gradientEnd: const Color(0xFF0F1115),
        navBackground: const Color(0xFF0D0F13),
        navSurface: const Color(0xFF151821),
      );
    } else {
      return ThemeColors(
        background: _lightBg,
        surface: _lightSurface,
        card: _lightCard,
        cardHeader: _lightCardHeader,
        accent: primaryColor,
        accentSecondary: secondaryColor,
        text: const Color(0xFF1A1D26),
        textSecondary: const Color(0xFF555B67),
        divider: _lightBorder,
        border: _lightBorder,
        profileCardBackground: const Color(0xFFF4F5FA),
        chatBubbleUser: secondaryColor,
        chatBubbleBot: const Color(0xFFECEEF4),
        glassSurface: Colors.white.withAlpha(220),
        glassStroke: const Color(0xFFD0D5E0),
        glowColor: primaryColor.withAlpha(30),
        gradientStart: const Color(0xFFE3E7EF),
        gradientEnd: const Color(0xFFF0F2F7),
        navBackground: const Color(0xFF232B3E),
        navSurface: const Color(0xFF2B3552),
      );
    }
  }
}

/// Semantic-level color tokens for the design system
class ThemeColors {
  final Color background;
  final Color surface;
  final Color card;
  final Color cardHeader;
  final Color accent;
  final Color accentSecondary;
  final Color text;
  final Color textSecondary;
  final Color divider;
  final Color border;
  final Color profileCardBackground;
  final Color chatBubbleUser;
  final Color chatBubbleBot;
  // Glassmorphism
  final Color glassSurface;
  final Color glassStroke;
  final Color glowColor;
  // Gradients
  final Color gradientStart;
  final Color gradientEnd;
  // Navigation
  final Color navBackground;
  final Color navSurface;

  const ThemeColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.cardHeader,
    required this.accent,
    required this.accentSecondary,
    required this.text,
    required this.textSecondary,
    required this.divider,
    required this.border,
    required this.profileCardBackground,
    required this.chatBubbleUser,
    required this.chatBubbleBot,
    required this.glassSurface,
    required this.glassStroke,
    required this.glowColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.navBackground,
    required this.navSurface,
  });
}