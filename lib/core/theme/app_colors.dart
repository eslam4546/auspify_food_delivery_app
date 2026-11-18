import 'package:flutter/material.dart';

/// Google Stitch "Warm Courier" Design System color, spacing, radius,
/// and elevation tokens (`assets/34c208b6abd74102bc54f1230279bb0b`).
abstract final class AppColors {
  // Brand & Semantic Accents
  static const Color primary = Color(0xFFFF4B26);
  static const Color primaryDeep = Color(0xFFB32100);
  static const Color primaryContainer = Color(0xFFDC320D);
  static const Color primarySoft = Color(0xFFFFDAD3);

  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryDeep = Color(0xFF047857);
  static const Color secondarySoft = Color(0x1F10B981);

  static const Color tertiary = Color(0xFFF59E0B);
  static const Color tertiaryDeep = Color(0xFF825100);
  static const Color tertiarySoft = Color(0xFFFFDDB8);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Light Mode Neutrals & Surfaces
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightSurfaceAlt = Color(0xFFFAF8FF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInputBg = Color(0xFFFFFFFF);
  static const Color lightInk = Color(0xFF0F172A);
  static const Color lightInkSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0x100F172A);
  static const Color lightOutline = Color(0xFFCBD5E1);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightShimmerBase = Color(0xFFE2E8F0);
  static const Color lightShimmerHighlight = Color(0xFFF8FAFC);

  // Dark Mode Neutrals & Surfaces
  static const Color darkCanvas = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF131B2E);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardElevated = Color(0xFF283548);
  static const Color darkInputBg = Color(0xFF172033);
  static const Color darkInk = Color(0xFFF8FAFC);
  static const Color darkInkSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0x2694A3B8);
  static const Color darkOutline = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF293548);
  static const Color darkShimmerBase = Color(0xFF1E293B);
  static const Color darkShimmerHighlight = Color(0xFF334155);

  // Radius Tokens
  static const double radiusSm = 8.0;
  static const double radiusControl = 12.0; // rounded-xl (buttons, inputs)
  static const double radiusCard = 16.0; // rounded-2xl (cards, tiles)
  static const double radiusSheet = 24.0;
  static const double radiusPill = 999.0;

  // Spacing Tokens (Base-4 Scale)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;

  // Ambient Elevation Shadows
  static List<BoxShadow> cardShadow(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];
    }
    return const [
      BoxShadow(color: Color(0x0D0F172A), blurRadius: 10, offset: Offset(0, 2)),
    ];
  }

  static List<BoxShadow> stickyBarShadow(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x140F172A),
        blurRadius: 20,
        offset: Offset(0, -4),
      ),
    ];
  }
}
