import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6E00FF);
  static const Color secondaryColor = Color(0xFF00E5FF);
  static const Color backgroundColor = Color(0xFF0F172A);
  static const Color cardColor = Color(0xFF1E293B);
  static const Color surfaceColor = Color(0xFF1E293B);
  static const Color errorColor = Color(0xFFFF4B2B);
  static const Color accentColor = Color(0xFF00E5FF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.black,
        error: errorColor,
        surface: surfaceColor,
        onSurface: Colors.white,
        outline: Colors.white10,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.rajdhaniTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.white),
        headlineLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: GoogleFonts.rajdhani(fontWeight: FontWeight.w600, color: Colors.white),
        titleSmall: GoogleFonts.rajdhani(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.rajdhani(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF161E31),
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return GoogleFonts.rajdhani(color: Colors.white54, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accentColor, size: 28);
          }
          return const IconThemeData(color: Colors.white54, size: 24);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accentColor,
        unselectedLabelColor: Colors.white38,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: accentColor,
        labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1),
        unselectedLabelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
          elevation: 8,
          shadowColor: primaryColor.withValues(alpha: 0.4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: const BorderSide(color: Colors.white10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        hintStyle: GoogleFonts.rajdhani(color: Colors.white24, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E293B),
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
    );
  }

  // Helper for gradients
  static Gradient primaryGradient = const LinearGradient(
    colors: [primaryColor, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient accentGradient = const LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
