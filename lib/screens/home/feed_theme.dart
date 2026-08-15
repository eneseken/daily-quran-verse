import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The verse feed is a fixed "reading mode" — always dark, like the
/// reference design — independent of the app-wide light/dark palette used
/// elsewhere (onboarding, auth).
class FeedColors {
  const FeedColors._();

  /// Warm charcoal / espresso — the feed's fixed "reading mode" backdrop.
  static const bg = Color(0xFF252320);
  static const chip = Color(0x1FFFFFFF);
  static const chipBorder = Color(0x24FFFFFF);

  /// Warm ivory ink used for the dominant Arabic and translation text.
  static const ink = Color(0xFFF4EFE7);
  static const inkSoft = Color(0xFFA8A49C);
  static const inkFaint = Color(0xFF6E6A63);
  static const gold = Color(0xFFD5A44F);
  static const liked = Color(0xFFE0655A);
}

class FeedText {
  const FeedText._();

  /// Large, warm-ivory, generously leaded — the visually dominant element on
  /// the page, sitting above the translation.
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

  /// Small, muted, warm-gray — and serif, to sit quietly under the editorial
  /// translation rather than reading as UI chrome.
  static TextStyle reference() => GoogleFonts.playfairDisplay(
        fontSize: 13,
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
