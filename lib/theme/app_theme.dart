import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sage & Linen palette. Screens should use these tokens, not raw hex values.
abstract final class AppColors {
  static const ground = Color(0xFFF7F8F4);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B2A22);
  static const muted = Color(0xFF64716A);
  static const chipText = Color(0xFF3A4740);
  static const line = Color(0xFFE3E6DE);
  static const ringBorder = Color(0xFFCFD5CC);
  static const forest = Color(0xFF2E6B4E);
  static const sageSoft = Color(0xFFE5EFE8);
  static const sageTrack = Color(0xFFD7E5DB);
  static const sageBorder = Color(0xFF8DB59B);
  static const peachSoft = Color(0xFFFBEDE3);
  static const peachText = Color(0xFF9C4F22);
  static const skySoft = Color(0xFFE7EEF5);
  static const skyText = Color(0xFF35597A);
  static const roseSoft = Color(0xFFFBE8E6);
  static const roseText = Color(0xFFA3352B);
  static const roseBorder = Color(0xFFD9776C);
  static const butterSoft = Color(0xFFFBF3D6);
  static const butterText = Color(0xFF7A5B0E);
  static const imageBg = Color(0xFFEFE9DE);
  static const modeTrack = Color(0xFFE6E9E2);
  static const cameraPlaceholder = Color(0xFFEEF4EF);
  static const deckPeek = Color(0xFFE8EBE4);
  static const subtitle = Color(0xFF5A655F);
  static const proteinText = Color(0xFF9C4F22);
  static const carbsText = Color(0xFF0E7490);
  static const carbsSoft = Color(0xFFE5F4F8);
  static const fatText = Color(0xFF35597A);
  static const fibreText = Color(0xFF6D28A8);
  static const fibreSoft = Color(0xFFF3E8FF);

  /// Previous names, aliased so screens outside this pass keep compiling.
  static const cream = ground;
  static const creamDark = line;
  static const green = forest;
  static const greenDeep = forest;
  static const greenSoft = sageTrack;
  static const sageMuted = sageSoft;
  static const textPrimary = ink;
  static const textSecondary = muted;
  static const textMuted = muted;
  static const border = line;
  static const accent = roseText;
  static const error = roseText;
  static const heart = roseText;
  static const useSoon = roseText;
  static const forestDeep = forest;
  static const sage = sageSoft;
  static const peach = peachText;
  static const softPeach = peachSoft;
  static const sageBlob = sageTrack;
  static const lavender = skySoft;
  static const softBlue = skySoft;
}

abstract final class AppRadii {
  static const xs = 12.0;
  static const sm = 14.0;
  static const md = 16.0;
  static const mdLg = 18.0;
  static const lg = 20.0;
  static const lgLg = 24.0;
  static const xl = 26.0;
  static const xlLg = 28.0;
  static const xxl = 32.0;
  static const pill = 999.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x0A1B2A22),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x0F1B2A22),
      offset: Offset(0, 10),
      blurRadius: 30,
    ),
  ];

  static const chip = [
    BoxShadow(
      color: Color(0x0F1B2A22),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const floating = [
    BoxShadow(
      color: Color(0x0D1B2A22),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x1F1B2A22),
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  static const primaryGlow = [
    BoxShadow(
      color: Color(0x4D2E6B4E),
      offset: Offset(0, 10),
      blurRadius: 24,
    ),
  ];

  static const heroCard = [
    BoxShadow(
      color: Color(0x0A1B2A22),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x1A1B2A22),
      offset: Offset(0, 16),
      blurRadius: 40,
    ),
  ];

  static const selectedDay = [
    BoxShadow(
      color: Color(0x4D2E6B4E),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}

abstract final class AppText {
  static TextStyle get _display => GoogleFonts.bricolageGrotesque();
  static TextStyle get _ui => GoogleFonts.figtree();

  static TextStyle h1({Color color = AppColors.ink}) {
    return _display.copyWith(
      color: color,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.1,
      letterSpacing: -0.8,
    );
  }

  static TextStyle h1Small({Color color = AppColors.ink}) {
    return _display.copyWith(
      color: color,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.1,
      letterSpacing: -0.7,
    );
  }

  static TextStyle cardTitle({Color color = AppColors.ink}) {
    return _display.copyWith(
      color: color,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.6,
    );
  }

  static TextStyle stat({Color color = AppColors.ink}) {
    return _display.copyWith(
      color: color,
      fontSize: 36,
      fontWeight: FontWeight.w600,
      height: 1,
      letterSpacing: -1.08,
    );
  }

  static TextStyle section({Color color = AppColors.ink}) {
    return _display.copyWith(
      color: color,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.45,
    );
  }

  static TextStyle courseTitle({Color color = AppColors.ink}) {
    return _display.copyWith(
      color: color,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.5,
    );
  }

  static TextStyle body({
    Color color = AppColors.muted,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.45,
  }) {
    return _ui.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle itemTitle({
    Color color = AppColors.ink,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return _ui.copyWith(
      color: color,
      fontSize: 16,
      fontWeight: fontWeight,
      height: 1.25,
    );
  }

  static TextStyle label({
    Color color = AppColors.ink,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return _ui.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.2,
    );
  }

  static TextStyle caption({
    Color color = AppColors.muted,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return _ui.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.2,
    );
  }

  static TextStyle overline({Color color = AppColors.muted}) {
    return _ui.copyWith(
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.52,
      height: 1.2,
    );
  }

  static TextStyle display({
    Color color = AppColors.ink,
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.15,
    double letterSpacing = -0.7,
  }) {
    return _display.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle title({
    Color color = AppColors.ink,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.2,
  }) {
    return _display.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: fontSize * -0.025,
    );
  }

  static TextStyle button({
    Color color = Colors.white,
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return _ui.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.2,
    );
  }
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.light(
    surface: AppColors.surface,
    primary: AppColors.forest,
    onPrimary: Colors.white,
    secondary: AppColors.sageSoft,
    onSecondary: AppColors.forest,
    onSurface: AppColors.ink,
    outline: AppColors.line,
    error: AppColors.roseText,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.ground,
    colorScheme: scheme,
    textTheme: GoogleFonts.figtreeTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FadeSlideUpTransitionsBuilder(),
        TargetPlatform.iOS: _FadeSlideUpTransitionsBuilder(),
        TargetPlatform.macOS: _FadeSlideUpTransitionsBuilder(),
        TargetPlatform.linux: _FadeSlideUpTransitionsBuilder(),
        TargetPlatform.windows: _FadeSlideUpTransitionsBuilder(),
        TargetPlatform.fuchsia: _FadeSlideUpTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.ground,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppText.title(fontSize: 22),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: AppText.button(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppText.body(fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.forest, width: 1.4),
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.sageSoft,
      backgroundColor: AppColors.surface,
      shape: const StadiumBorder(),
      side: const BorderSide(color: AppColors.line),
      labelStyle: AppText.label(fontSize: 13),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.forest,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        side: const BorderSide(color: AppColors.sageBorder),
        shape: const StadiumBorder(),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.label(color: Colors.white),
    ),
  );
}

abstract final class AppTheme {
  static ThemeData get light => buildAppTheme();
}

/// Fade plus a 12px rise. Material routes last 300ms, so the curve finishes
/// at 250ms of that timeline.
class _FadeSlideUpTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlideUpTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 250 / 300, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 12 * (1 - curved.value)),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}
