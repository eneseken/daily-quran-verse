import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/feed_background.dart';
import '../../core/theme.dart';

/// Feed typography stays distinct, but its colors follow the app-wide
/// light/dark palette so home, loading, and settings match onboarding —
/// unless a Customize screen background photo is active, in which case ink
/// tones follow that photo's own contrast needs instead: a photo doesn't
/// care what the system's light/dark setting is, only how bright it reads.
class FeedColors {
  const FeedColors._();

  static Color get bg => AppColors.bg;
  static Color get chip =>
      AppColors.isDark ? AppColors.chip : AppColors.bg.withValues(alpha: 0.5);
  static Color get chipBorder => AppColors.track;

  static Color get ink {
    if (FeedBackgroundController.instance.imagePath == null) {
      return AppColors.ink;
    }
    return FeedBackgroundController.instance.usesDarkText
        ? const Color(0xFF252320)
        : Colors.white;
  }

  static Color get inkSoft {
    if (FeedBackgroundController.instance.imagePath == null) {
      return AppColors.inkSoft;
    }
    return FeedBackgroundController.instance.usesDarkText
        ? const Color(0xFF252320).withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.82);
  }

  static Color get inkFaint {
    if (FeedBackgroundController.instance.imagePath == null) {
      return AppColors.inkFaint;
    }
    return FeedBackgroundController.instance.usesDarkText
        ? const Color(0xFF252320).withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.6);
  }

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

  static TextStyle quote({double size = 27}) => AppText.numeral(
    size: size,
    color: FeedColors.ink,
    weight: FontWeight.w700,
  ).copyWith(height: 1.18);

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
