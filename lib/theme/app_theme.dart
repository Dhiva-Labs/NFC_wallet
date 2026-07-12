import 'package:flutter/material.dart';

/// Central design tokens + light/dark [ThemeData] for NFC Wallet.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF6D5DF6); // electric indigo
  static const Color accent = Color(0xFF16C79A); // teal

  // Dark palette
  static const Color darkBg = Color(0xFF0B0E14);
  static const Color darkSurface = Color(0xFF151A23);
  static const Color darkSurfaceHi = Color(0xFF1E2530);

  // Light palette
  static const Color lightBg = Color(0xFFF4F5FA);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: darkSurface,
      secondary: accent,
    );
    return _base(scheme, darkBg);
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: lightSurface,
      secondary: accent,
    );
    return _base(scheme, lightBg);
  }

  static ThemeData _base(ColorScheme scheme, Color bg) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? darkSurface : lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurfaceHi : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkSurfaceHi : const Color(0xFF2A2F3A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// Selectable base colors for a card. The visual builds a diagonal gradient
/// from the chosen base via [CardPalettes.gradientFor].
class CardPalettes {
  CardPalettes._();

  static const List<Color> swatches = [
    Color(0xFF6D5DF6), // indigo
    Color(0xFF16C79A), // teal
    Color(0xFF2D9CDB), // blue
    Color(0xFF27AE60), // green
    Color(0xFFF5A623), // amber
    Color(0xFFEB5757), // red
    Color(0xFFEB5AA0), // pink
    Color(0xFF9B51E0), // purple
    Color(0xFF00B8D9), // cyan
    Color(0xFF5B7089), // slate
    Color(0xFFEF6C4D), // coral
    Color(0xFF2D3748), // graphite
  ];

  /// Build a pleasing 2-stop gradient from a base color.
  static List<Color> gradientFor(Color base) {
    final hsl = HSLColor.fromColor(base);
    final top = hsl
        .withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0))
        .toColor();
    final bottom = hsl
        .withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0))
        .toColor();
    return [top, bottom];
  }
}
