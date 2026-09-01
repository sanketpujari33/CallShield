import 'package:flutter/material.dart';

enum AppThemeMode {
  system('system'),
  light('light'),
  graphite('graphite'),
  amoled('amoled'),
  dark('graphite');

  final String storageValue;
  const AppThemeMode(this.storageValue);
}

class CallShieldColors {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceBright;
  final Color surfaceElevated;
  final Color primary;
  final Color onPrimary;
  final Color error;
  final Color blue;
  final Color warning;
  final Color mauve;
  final Color peach;
  final Color teal;
  final Color lavender;
  final Color text;
  final Color subtext;
  final Color overlay;
  final Color muted;
  final bool isLight;

  const CallShieldColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceBright,
    required this.surfaceElevated,
    required this.primary,
    required this.onPrimary,
    required this.error,
    required this.blue,
    required this.warning,
    required this.mauve,
    required this.peach,
    required this.teal,
    required this.lavender,
    required this.text,
    required this.subtext,
    required this.overlay,
    required this.muted,
    required this.isLight,
  });

  static const amoled = CallShieldColors(
    background: Color(0xFF000000),
    surface: Color(0xFF070807),
    surfaceVariant: Color(0xFF0D0F0E),
    surfaceBright: Color(0xFF151715),
    surfaceElevated: Color(0xFF1A1C1A),
    primary: Color(0xFFA6E3A1),
    onPrimary: Color(0xFF071108),
    error: Color(0xFFF38BA8),
    blue: Color(0xFF89B4FA),
    warning: Color(0xFFF9E2AF),
    mauve: Color(0xFFCBA6F7),
    peach: Color(0xFFFAB387),
    teal: Color(0xFF94E2D5),
    lavender: Color(0xFFB4BEFE),
    text: Color(0xFFF2F3F0),
    subtext: Color(0xFFA8ADA8),
    overlay: Color(0xFF828882),
    muted: Color(0xFF2B2F2C),
    isLight: false,
  );

  static const graphite = CallShieldColors(
    background: Color(0xFF0F1216),
    surface: Color(0xFF14181D),
    surfaceVariant: Color(0xFF1A2027),
    surfaceBright: Color(0xFF222A33),
    surfaceElevated: Color(0xFF29333E),
    primary: Color(0xFF8FD3B2),
    onPrimary: Color(0xFF082117),
    error: Color(0xFFFF9AAE),
    blue: Color(0xFF8AB8FF),
    warning: Color(0xFFE9CC81),
    mauve: Color(0xFFC7B1FF),
    peach: Color(0xFFF0AD7F),
    teal: Color(0xFF82CEC7),
    lavender: Color(0xFFABB9FF),
    text: Color(0xFFF3F6F8),
    subtext: Color(0xFFB1BBC5),
    overlay: Color(0xFF939FAC),
    muted: Color(0xFF333D48),
    isLight: false,
  );

  static const light = CallShieldColors(
    background: Color(0xFFF7F8F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F4F0),
    surfaceBright: Color(0xFFE9EEEA),
    surfaceElevated: Color(0xFFFFFFFF),
    primary: Color(0xFF087A55),
    onPrimary: Color(0xFFFFFFFF),
    error: Color(0xFFC62D4D),
    blue: Color(0xFF2A63B7),
    warning: Color(0xFFA66F00),
    mauve: Color(0xFF7641B5),
    peach: Color(0xFF98552D),
    teal: Color(0xFF126B66),
    lavender: Color(0xFF4E5F9E),
    text: Color(0xFF0A1932),
    subtext: Color(0xFF536176),
    overlay: Color(0xFF627083),
    muted: Color(0xFFD9E0DA),
    isLight: true,
  );
}

class SignalLedgerTheme {
  // Aliases for quick theme access
  static const Color cyan = Color(0xFF8FD3B2);
  static const Color green = Color(0xFF8FD3B2);
  static const Color red = Color(0xFFFF9AAE);
  static const Color blue = Color(0xFF8AB8FF);
  static const Color amber = Color(0xFFE9CC81);
  static const Color yellow = Color(0xFFE9CC81);
  static const Color purple = Color(0xFFC7B1FF);
  static const Color mauve = Color(0xFFC7B1FF);
  static const Color peach = Color(0xFFF0AD7F);
  static const Color teal = Color(0xFF82CEC7);

  static const Color darkBackground = Color(0xFF0F1216);
  static const Color darkCard = Color(0xFF14181D);
  static const Color darkSurface = Color(0xFF1A2027);
  static const Color darkBorder = Color(0xFF222A33);
  static const Color darkText = Color(0xFFF3F6F8);
  static const Color darkTextMuted = Color(0xFFB1BBC5);

  static const Color lightBackground = Color(0xFFF7F8F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF1F4F0);
  static const Color lightBorder = Color(0xFFE9EEEA);
  static const Color lightText = Color(0xFF0A1932);
  static const Color lightTextMuted = Color(0xFF536176);

  static CallShieldColors getColors(AppThemeMode mode, BuildContext? context) {
    switch (mode) {
      case AppThemeMode.amoled:
        return CallShieldColors.amoled;
      case AppThemeMode.graphite:
      case AppThemeMode.dark:
        return CallShieldColors.graphite;
      case AppThemeMode.light:
        return CallShieldColors.light;
      case AppThemeMode.system:
        final isDark = context != null ? MediaQuery.of(context).platformBrightness == Brightness.dark : true;
        return isDark ? CallShieldColors.graphite : CallShieldColors.light;
    }
  }

  static ThemeData getTheme(AppThemeMode mode, BuildContext context) {
    final colors = getColors(mode, context);
    final brightness = colors.isLight ? Brightness.light : Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.teal,
        onSecondary: Colors.black,
        error: colors.error,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.text,
        surfaceContainerHighest: colors.surfaceVariant,
        outline: colors.surfaceBright,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.surfaceBright, width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.subtext,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.surfaceBright),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.surfaceBright),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colors.overlay, fontSize: 14),
        labelStyle: TextStyle(color: colors.subtext, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.surfaceBright),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 22),
        titleLarge: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 15),
        bodyLarge: TextStyle(color: colors.text, fontSize: 15),
        bodyMedium: TextStyle(color: colors.subtext, fontSize: 13, height: 1.4),
        bodySmall: TextStyle(color: colors.overlay, fontSize: 11),
      ),
      dividerTheme: DividerThemeData(
        color: colors.surfaceBright,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

class BorderStroke {
  final double width;
  final Color color;
  const BorderStroke(this.width, this.color);
}
