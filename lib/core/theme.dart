import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// One full set of theme colors. `AppColors` swaps between [light] and [dark]
/// instances at runtime — see [AppColors.apply].
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceSoft,
    required this.chip,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.gold,
    required this.goldSoft,
    required this.ctaBg,
    required this.ctaOnBg,
    required this.track,
    required this.error,
  });

  final Color bg;
  final Color surface;
  final Color surfaceSoft;

  /// Small elevated chip sitting on top of a card — pure white on the cream
  /// theme, a lighter-than-surface tone on the dark one.
  final Color chip;

  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color gold;
  final Color goldSoft;

  /// The high-contrast "always readable" pair used for primary CTAs and
  /// selected radio/checkbox fills: near-black on cream, cream on near-black.
  final Color ctaBg;
  final Color ctaOnBg;

  final Color track;
  final Color error;

  /// Warm cream paper, muted clay surfaces, near-black ink — the reference
  /// design as given.
  static const light = AppPalette(
    bg: Color(0xFFF1EDE5),
    surface: Color(0xFFE4E0D4),
    surfaceSoft: Color(0xFFEAE6DC),
    chip: Color(0xFFFFFFFF),
    ink: Color(0xFF2B2825),
    inkSoft: Color(0xFF6F6C65),
    inkFaint: Color(0xFF9A968D),
    gold: Color(0xFFD5A44F),
    goldSoft: Color(0xFFE8CFA0),
    ctaBg: Color(0xFF24221E),
    ctaOnBg: Color(0xFFFFFFFF),
    track: Color(0xFFDFDBD0),
    error: Color(0xFFB3462F),
  );

  /// Same structure inverted onto the dark base the user picked (#272624),
  /// with warm off-white ink and the same gold accent throughout.
  static const dark = AppPalette(
    bg: Color(0xFF272624),
    surface: Color(0xFF322F2A),
    surfaceSoft: Color(0xFF3A362F),
    chip: Color(0xFF3E3A33),
    ink: Color(0xFFF1EADD),
    inkSoft: Color(0xFFB6AFA3),
    inkFaint: Color(0xFF7C766C),
    gold: Color(0xFFD5A44F),
    goldSoft: Color(0xFF4A3B22),
    ctaBg: Color(0xFFF1EADD),
    ctaOnBg: Color(0xFF24221E),
    track: Color(0xFF3A362F),
    error: Color(0xFFE0836A),
  );
}

/// Palette accessors used throughout the app. Backed by a mutable current
/// [AppPalette] so the whole tree can flip between light and dark without
/// threading a `BuildContext` through every helper — call [apply] once from
/// the root widget whenever the desired brightness changes, then rebuild.
class AppColors {
  const AppColors._();

  static AppPalette _palette = AppPalette.light;
  static bool isDark = false;

  static void apply(bool dark) {
    isDark = dark;
    _palette = dark ? AppPalette.dark : AppPalette.light;
  }

  static Color get bg => _palette.bg;
  static Color get surface => _palette.surface;
  static Color get surfaceSoft => _palette.surfaceSoft;
  static Color get chip => _palette.chip;
  static Color get ink => _palette.ink;
  static Color get inkSoft => _palette.inkSoft;
  static Color get inkFaint => _palette.inkFaint;
  static Color get gold => _palette.gold;
  static Color get goldSoft => _palette.goldSoft;
  static Color get ctaBg => _palette.ctaBg;
  static Color get ctaOnBg => _palette.ctaOnBg;
  static Color get track => _palette.track;
  static Color get error => _palette.error;

  /// Literal white — used only for spots that stay bright regardless of theme
  /// (the welcome screen's CTA over its fixed photo, checkmarks on gold).
  static const white = Color(0xFFFFFFFF);
}

/// True when the system theme is dark, or when it's evening/night locally
/// (19:00–06:00) — either is reason enough to open onboarding in dark mode.
bool computeSystemIsDark() {
  final systemDark =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
  final hour = DateTime.now().hour;
  final isEvening = hour >= 19 || hour < 6;
  return systemDark || isEvening;
}

void syncStatusBarStyle(bool dark) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    ),
  );
}

/// Serif for headings, grotesque for everything else — as in the design.
class AppText {
  const AppText._();

  static TextStyle serif({
    double size = 28,
    Color? color,
    FontWeight weight = FontWeight.w700,
    double height = 1.24,
    FontStyle? style,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        color: color ?? AppColors.ink,
        fontWeight: weight,
        height: height,
        fontStyle: style,
      );

  static TextStyle sans({
    double size = 16,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    double? spacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color ?? AppColors.inkSoft,
        fontWeight: weight,
        height: height,
        letterSpacing: spacing,
      );

  /// Small all-caps label used above summary cards.
  static TextStyle overline({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        color: color ?? AppColors.gold,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        height: 1.2,
      );

  /// Chunky rounded numeral for the streak count on the sun badge — reads
  /// friendlier and punchier at a glance than the serif heading font.
  static TextStyle numeral({
    double size = 34,
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.baloo2(
        fontSize: size,
        color: color ?? AppColors.ink,
        fontWeight: weight,
        height: 1.0,
      );
}

/// Splits `**highlighted**` runs out of a string so headings can mix ink and
/// gold the way the reference screens do.
List<TextSpan> markup(String source, TextStyle base, TextStyle accent) {
  final spans = <TextSpan>[];
  final parts = source.split('**');
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    spans.add(TextSpan(text: parts[i], style: i.isOdd ? accent : base));
  }
  return spans;
}

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.gold,
      surface: AppColors.bg,
      onSurface: AppColors.ink,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
