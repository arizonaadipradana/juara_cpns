import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern color palette with more subtle tones
  static const Color primaryColor = Color(0xFF3F51B5); // Deep indigo
  static const Color secondaryColor = Color(0xFFFC5C65); // Strawberry
  static const Color accentColor = Color(0xFF45AAF2); // Sky blue
  static const Color successColor = Color(0xFF26DE81); // Vibrant green
  static const Color errorColor = Color(0xFFEB3B5A); // Rose
  static const Color warningColor = Color(0xFFFD9644); // Tangerine
  static const Color backgroundColor = Color(0xFFF9FAFC); // Almost white
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF2C3E50); // Dark blue-grey
  static const Color textSecondaryColor = Color(0xFF78909C); // Blue-grey
  static const Color surfaceColor = Color(0xFFFEFEFE); // Pure white surface

  // Gradients with more modern colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF45AAF2), Color(0xFF2D98DA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF26DE81), Color(0xFF20BF6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Softer shadows for modern look
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      spreadRadius: 0,
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.18),
      spreadRadius: 0,
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  // Modern, cleaner text styles
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
      color: textPrimaryColor,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      height: 1.2,
    ),
    displayMedium: GoogleFonts.poppins(
      color: textPrimaryColor,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      height: 1.25,
    ),
    displaySmall: GoogleFonts.poppins(
      color: textPrimaryColor,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      height: 1.3,
    ),
    headlineMedium: GoogleFonts.poppins(
      color: textPrimaryColor,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: -0.2,
    ),
    headlineSmall: GoogleFonts.poppins(
      color: textPrimaryColor,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: -0.2,
    ),
    titleLarge: GoogleFonts.poppins(
      color: textPrimaryColor,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    titleMedium: GoogleFonts.poppins(
      color: textPrimaryColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.inter(
      color: textPrimaryColor,
      fontSize: 16,
      fontWeight: FontWeight.normal,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      color: textPrimaryColor,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      color: textSecondaryColor,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      height: 1.5,
    ),
  );

  // Modern button styles with larger radius and better padding
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primaryColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: primaryColor, width: 1.5),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    textStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  // More modern input decoration
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: errorColor, width: 1),
    ),
    hintStyle: GoogleFonts.inter(
      color: textSecondaryColor.withOpacity(0.7),
      fontSize: 14,
    ),
    prefixIconColor: textSecondaryColor,
    labelStyle: GoogleFonts.inter(
      color: textSecondaryColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  // Modern card theme with softer shadow
  static CardTheme cardTheme = CardTheme(
    color: cardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
    clipBehavior: Clip.antiAlias,
  );

  // Create theme data
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
      tertiary: accentColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: textTheme,
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    textButtonTheme: TextButtonThemeData(
      style: textButtonStyle,
    ),
    inputDecorationTheme: inputDecorationTheme,
    cardTheme: cardTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: const IconThemeData(
        color: textPrimaryColor,
      ),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      color: Color(0xFFEEEEEE),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondaryColor,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      labelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    ),
  );
}