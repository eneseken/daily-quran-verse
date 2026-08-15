import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

/// Feed typography stays distinct, but its colors follow the app-wide
/// light/dark palette so home, loading, and settings match onboarding.
class FeedColors {
  const FeedColors._();

  static Color get bg => AppColors.bg;
  static Color get chip =>
      AppColors.isDark ? AppColors.chip : AppColors.bg.withValues(alpha: 0.5);
  static Color get chipBorder => AppColors.track;
  static Color get ink => AppColors.ink;
  static Color get inkSoft => AppColors.inkSoft;
  static Color get inkFaint => AppColors.inkFaint;
  static Color get gold => AppColors.gold;
  static Color get liked => AppColors.error;
  static Color get track => AppColors.track;
  static Color get sheet => AppColors.surface;
}

class FeedText {
  const FeedText._();

  static TextStyle arabic({double size = 30}) => GoogleFonts.amiri(
    fontSize: size,
    color: FeedColors.ink,
    fontWeight: FontWeight.w600,
    height: 2.0,
  );

  static TextStyle quote({double size = 27}) => GoogleFonts.playfairDisplay(
    fontSize: size,
    color: FeedColors.ink,
    fontWeight: FontWeight.w700,
    height: 1.38,
  );

  static TextStyle reference({double size = 13}) => GoogleFonts.playfairDisplay(
    fontSize: size,
    color: FeedColors.inkSoft,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
  );

  static TextStyle label({Color? color}) => GoogleFonts.inter(
    fontSize: 12.5,
    color: color ?? FeedColors.ink,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}
