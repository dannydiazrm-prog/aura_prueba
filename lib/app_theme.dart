import 'package:flutter/material.dart';

ThemeData buildTheme(Color primaryColor) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'SF Pro Display',

    // TIPOGRAFÍA
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 11, color: Colors.grey),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
    ),

    // APPBAR
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.2,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // CARDS
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shadowColor: Colors.black12,
    ),

    // BOTONES ELEVADOS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // BOTONES OUTLINED
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: primaryColor, width: 1.5),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    // BOTONES DE TEXTO
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // INPUTS
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8ECF0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
      ),
      labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBC0C8)),
      errorStyle: const TextStyle(fontSize: 11),
    ),

    // CHIPS
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      side: BorderSide.none,
    ),

    // DIVIDER
    dividerTheme: const DividerThemeData(
      color: Color(0xFFF0F0F0),
      thickness: 1,
      space: 1,
    ),

    // SNACKBAR
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      elevation: 4,
    ),

    // DIALOG
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      titleTextStyle: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87),
      contentTextStyle: const TextStyle(fontSize: 14, color: Colors.black54),
    ),

    // BOTTOM SHEET
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      elevation: 8,
    ),

    // FLOATING ACTION BUTTON
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // LIST TILE
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 0,
    ),

    scaffoldBackgroundColor: const Color(0xFFF8F9FB),
  );
}