import 'package:flutter/material.dart';
import '../store/auth_store.dart';

abstract class ThemeColorSchema {
  Color get scaffoldBackground;
  Color get primaryText;
  Color get secondaryText;
  Color get cardBackground;
  Color get containerBackground;
  Color get border;
  Color get accent;
  Color get primary;
  Color get surface;
  Color get snackBarBackground;
  Color get snackBarText;
  Color get snackBarActionText;
  Color get inputFill;

  // Bottom Navigation Bar
  Color get bottomBarBackground;
  Color get bottomBarSelected;
  Color get bottomBarUnselected;

  // Icon / Status indicators
  Color get iconActive;
  Color get iconInactive;

  // Semantic Colors
  Color get success;
  Color get error;
  Color get warning;
  Color get info;

  // Badges
  Color get infoBadgeBg;
  Color get infoBadgeText;
  Color get successBadgeBg;
  Color get successBadgeText;
  Color get warningBadgeBg;
  Color get warningBadgeText;
  Color get errorBadgeBg;
  Color get errorBadgeText;

  // Card Gradients
  LinearGradient get overviewGradient;
  LinearGradient get savingsGradient;
  LinearGradient get sharesGradient;
  LinearGradient get loansGradient;

  // Quick Action / Button Theme Colors
  Color get quickActionBackground;
  Color get quickActionBorder;
  Color get quickActionIcon;

  // Chip Colors
  Color get chipBackground;
  Color get chipBorder;
  Color get chipText;

  // Slider / Dot Indicators
  Color get sliderIndicatorActive;
  Color get sliderIndicatorInactive;
}

class LightThemeColors implements ThemeColorSchema {
  const LightThemeColors();

  @override
  Color get scaffoldBackground => const Color(0xFFF8FAFC);
  @override
  Color get primaryText => const Color(0xFF0F172A);
  @override
  Color get secondaryText => const Color(0xFF475569);
  @override
  Color get cardBackground => const Color(0xFFFFFFFF);
  @override
  Color get containerBackground => Colors.white;
  @override
  Color get border => const Color(0xFFF1F5F9);
  @override
  Color get accent => const Color(0xFF2563EB);
  @override
  Color get primary => const Color(0xFF2563EB);
  @override
  Color get surface => const Color(0xFFF8FAFC);
  @override
  Color get snackBarBackground => const Color(0xFF0F172A);
  @override
  Color get snackBarText => Colors.white;
  @override
  Color get snackBarActionText => const Color(0xFF60A5FA);
  @override
  Color get inputFill => const Color(0xFFF1F5F9);

  @override
  Color get bottomBarBackground => Colors.white;
  @override
  Color get bottomBarSelected => const Color(0xFF2563EB);
  @override
  Color get bottomBarUnselected => const Color(0xFF64748B);

  @override
  Color get iconActive => const Color(0xFF2563EB);
  @override
  Color get iconInactive => const Color(0xFF94A3B8);

  @override
  Color get success => const Color(0xFF059669);
  @override
  Color get error => const Color(0xFFDC2626);
  @override
  Color get warning => const Color(0xFFD97706);
  @override
  Color get info => const Color(0xFF2563EB);

  @override
  Color get infoBadgeBg => const Color(0xFFEEF2FF);
  @override
  Color get infoBadgeText => const Color(0xFF4F46E5);
  @override
  Color get successBadgeBg => const Color(0xFFECFDF5);
  @override
  Color get successBadgeText => const Color(0xFF059669);
  @override
  Color get warningBadgeBg => const Color(0xFFFEF3C7);
  @override
  Color get warningBadgeText => const Color(0xFFD97706);
  @override
  Color get errorBadgeBg => const Color(0xFFFEF2F2);
  @override
  Color get errorBadgeText => const Color(0xFFDC2626);

  @override
  LinearGradient get overviewGradient => const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  @override
  LinearGradient get savingsGradient => const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFFD946EF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  @override
  LinearGradient get sharesGradient => const LinearGradient(
        colors: [Color(0xFF0D9488), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  @override
  LinearGradient get loansGradient => const LinearGradient(
        colors: [Color(0xFFF43F5E), Color(0xFFFB923C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Color get quickActionBackground => const Color(0xFFEFF6FF);
  @override
  Color get quickActionBorder => const Color(0xFFDBEAFE);
  @override
  Color get quickActionIcon => const Color(0xFF2563EB);

  @override
  Color get chipBackground => const Color(0xFFF1F5F9);
  @override
  Color get chipBorder => const Color(0xFFE2E8F0);
  @override
  Color get chipText => const Color(0xFF475569);

  @override
  Color get sliderIndicatorActive => const Color(0xFF1E293B);
  @override
  Color get sliderIndicatorInactive => const Color(0x26000000); // Colors.black.withOpacity(0.15)
}

class DarkThemeColors implements ThemeColorSchema {
  const DarkThemeColors();

  @override
  Color get scaffoldBackground => const Color(0xFF020617);
  @override
  Color get primaryText => Colors.white;
  @override
  Color get secondaryText => const Color(0xFF94A3B8);
  @override
  Color get cardBackground => const Color(0xFF0F172A);
  @override
  Color get containerBackground => const Color(0xFF0F172A);
  @override
  Color get border => const Color(0x0AFFFFFF); // white with alpha 0.04
  @override
  Color get accent => const Color(0xFF60A5FA);
  @override
  Color get primary => const Color(0xFF2563EB);
  @override
  Color get surface => const Color(0xFF020617);
  @override
  Color get snackBarBackground => const Color(0xFF1E293B);
  @override
  Color get snackBarText => Colors.white;
  @override
  Color get snackBarActionText => const Color(0xFF60A5FA);
  @override
  Color get inputFill => const Color(0xFF1E293B);

  @override
  Color get bottomBarBackground => const Color(0xFF020617);
  @override
  Color get bottomBarSelected => const Color(0xFF60A5FA);
  @override
  Color get bottomBarUnselected => const Color(0xFF64748B);

  @override
  Color get iconActive => const Color(0xFF60A5FA);
  @override
  Color get iconInactive => const Color(0xFF64748B);

  @override
  Color get success => const Color(0xFF34D399);
  @override
  Color get error => const Color(0xFFF87171);
  @override
  Color get warning => const Color(0xFFF59E0B);
  @override
  Color get info => const Color(0xFF60A5FA);

  @override
  Color get infoBadgeBg => const Color(0xFF1E1B4B);
  @override
  Color get infoBadgeText => const Color(0xFF818CF8);
  @override
  Color get successBadgeBg => const Color(0xFF064E3B);
  @override
  Color get successBadgeText => const Color(0xFF34D399);
  @override
  Color get warningBadgeBg => const Color(0xFF451A03);
  @override
  Color get warningBadgeText => const Color(0xFFF59E0B);
  @override
  Color get errorBadgeBg => const Color(0xFF451A03);
  @override
  Color get errorBadgeText => const Color(0xFFF87171);

  @override
  LinearGradient get overviewGradient => const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF4C1D95)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  @override
  LinearGradient get savingsGradient => const LinearGradient(
        colors: [Color(0xFF312E81), Color(0xFF701A75)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  @override
  LinearGradient get sharesGradient => const LinearGradient(
        colors: [Color(0xFF115E59), Color(0xFF065F46)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  @override
  LinearGradient get loansGradient => const LinearGradient(
        colors: [Color(0xFF9F1239), Color(0xFF7C2D12)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Color get quickActionBackground => const Color(0x0DFFFFFF);
  @override
  Color get quickActionBorder => const Color(0x14FFFFFF);
  @override
  Color get quickActionIcon => const Color(0xFF60A5FA);

  @override
  Color get chipBackground => const Color(0xFF0F172A);
  @override
  Color get chipBorder => const Color(0x0AFFFFFF);
  @override
  Color get chipText => const Color(0xFF94A3B8);

  @override
  Color get sliderIndicatorActive => Colors.white;
  @override
  Color get sliderIndicatorInactive => const Color(0x33FFFFFF); // Colors.white.withOpacity(0.2)
}


class ThemeColorService {
  static ThemeColorSchema get colors {
    final isDark = AuthStore().isDarkMode;
    // final theme = AuthStore().colorTheme;
    return isDark ? const DarkThemeColors() : const LightThemeColors();
  }
}

extension ThemeColorExtension on BuildContext {
  ThemeColorSchema get colors => ThemeColorService.colors;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
