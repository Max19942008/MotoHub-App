import 'package:flutter/material.dart';

/// MOTOPRESTO brand, taken from the website (motopresto.online).
class Brand {
  Brand._();

  /// Site green: prices, primary buttons, active states.
  static const green = Color(0xFF25B44B);
  static const greenDark = Color(0xFF178F38);

  /// Site navbar / footer.
  static const ink = Color(0xFF181A20);

  /// "Popular / Top" sections on the site.
  static const indigo = Color(0xFF6366F1);
  static const indigoDark = Color(0xFF4F46E5);

  /// Floating "AI Assistant" button on the site.
  static const ai = Color(0xFFE8462B);

  static const page = Color(0xFFF7F8FA);
  static const card = Colors.white;
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);

  /// Light green pills (location row, spec chips on cards).
  static const greenSoft = Color(0xFFEFF8F1);

  static const greenGradient = LinearGradient(colors: [green, greenDark]);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      onPrimary: Colors.white,
      surface: Colors.white,
      brightness: Brightness.light,
    );
    final base = ThemeData(
        colorScheme: scheme, useMaterial3: true, fontFamily: 'Poppins');
    return base.copyWith(
      scaffoldBackgroundColor: page,
      appBarTheme: const AppBarTheme(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: green,
          side: const BorderSide(color: green, width: 1.5),
          textStyle: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: green, width: 1.5)),
      ),
      snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating, backgroundColor: ink),
      drawerTheme: const DrawerThemeData(backgroundColor: ink),
    );
  }
}

/// White MOTOPRESTO mark for dark backgrounds (navbar, drawer).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 34});
  final double height;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/brand/logo_white.png',
          height: height, fit: BoxFit.contain, semanticLabel: 'MOTOPRESTO');
}
