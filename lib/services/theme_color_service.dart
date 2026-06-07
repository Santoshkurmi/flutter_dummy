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
  final String colorTheme;
  const LightThemeColors(this.colorTheme);

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
  Color get accent {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'orange':
        return const Color(0xFFF97316);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'rose':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Color get primary => accent;
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
  Color get bottomBarSelected => accent;
  @override
  Color get bottomBarUnselected => const Color(0xFF64748B);

  @override
  Color get iconActive => accent;
  @override
  Color get iconInactive => const Color(0xFF94A3B8);

  @override
  Color get success => const Color(0xFF10B981);
  @override
  Color get error => const Color(0xFFF43F5E);
  @override
  Color get warning => const Color(0xFFF97316);
  @override
  Color get info => accent;

  @override
  Color get infoBadgeBg {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFFE6F4EA);
      case 'orange':
        return const Color(0xFFFFF9E6);
      case 'purple':
        return const Color(0xFFF5F3FF);
      case 'rose':
        return const Color(0xFFFFF1F2);
      default:
        return const Color(0xFFEEF2FF);
    }
  }

  @override
  Color get infoBadgeText {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFF065F46);
      case 'orange':
        return const Color(0xFFC2410C);
      case 'purple':
        return const Color(0xFF6D28D9);
      case 'rose':
        return const Color(0xFFBE123C);
      default:
        return const Color(0xFF4F46E5);
    }
  }

  @override
  Color get successBadgeBg => const Color(0xFFECFDF5);
  @override
  Color get successBadgeText => const Color(0xFF10B981);
  @override
  Color get warningBadgeBg => const Color(0xFFFEF3C7);
  @override
  Color get warningBadgeText => const Color(0xFFF97316);
  @override
  Color get errorBadgeBg => const Color(0xFFFEF2F2);
  @override
  Color get errorBadgeText => const Color(0xFFF43F5E);

  @override
  LinearGradient get overviewGradient {
    switch (colorTheme) {
      case 'emerald':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'orange':
        return const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'rose':
        return const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  LinearGradient get savingsGradient => const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFFD946EF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  @override
  LinearGradient get sharesGradient => const LinearGradient(
        colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
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
  Color get quickActionBackground {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFFECFDF5);
      case 'orange':
        return const Color(0xFFFFF7ED);
      case 'purple':
        return const Color(0xFFF5F3FF);
      case 'rose':
        return const Color(0xFFFFF1F2);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  @override
  Color get quickActionBorder {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFFD1FAE5);
      case 'orange':
        return const Color(0xFFFFEDD5);
      case 'purple':
        return const Color(0xFFEDE9FE);
      case 'rose':
        return const Color(0xFFFFE4E6);
      default:
        return const Color(0xFFDBEAFE);
    }
  }

  @override
  Color get quickActionIcon => accent;

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
  final String colorTheme;
  const DarkThemeColors(this.colorTheme);

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
  Color get accent {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFF059669);
      case 'orange':
        return const Color(0xFFEA580C);
      case 'purple':
        return const Color(0xFF7C3AED);
      case 'rose':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Color get primary => accent;
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
  Color get bottomBarSelected {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'orange':
        return const Color(0xFFF97316);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'rose':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFF3B82F6);
    }
  }
  @override
  Color get bottomBarUnselected => const Color(0xFF64748B);

  @override
  Color get iconActive => accent;
  @override
  Color get iconInactive => const Color(0xFF64748B);

  @override
  Color get success => const Color(0xFF34D399);
  @override
  Color get error => const Color(0xFFF87171);
  @override
  Color get warning => const Color(0xFFF59E0B);
  @override
  Color get info => accent;

  @override
  Color get infoBadgeBg {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFF064E3B);
      case 'orange':
        return const Color(0xFF451A03);
      case 'purple':
        return const Color(0xFF2E1065);
      case 'rose':
        return const Color(0xFF4C0519);
      default:
        return const Color(0xFF1E1B4B);
    }
  }

  @override
  Color get infoBadgeText {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFF34D399);
      case 'orange':
        return const Color(0xFFFDBA74);
      case 'purple':
        return const Color(0xFFC084FC);
      case 'rose':
        return const Color(0xFFFDA4AF);
      default:
        return const Color(0xFF818CF8);
    }
  }

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
  LinearGradient get overviewGradient {
    switch (colorTheme) {
      case 'emerald':
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'orange':
        return const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'rose':
        return const LinearGradient(
          colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

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
  Color get quickActionBackground {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0x1A10B981);
      case 'orange':
        return const Color(0x1AF97316);
      case 'purple':
        return const Color(0x1A8B5CF6);
      case 'rose':
        return const Color(0x1AF43F5E);
      default:
        return const Color(0x1A3B82F6);
    }
  }

  @override
  Color get quickActionBorder {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0x2610B981);
      case 'orange':
        return const Color(0x26F97316);
      case 'purple':
        return const Color(0x268B5CF6);
      case 'rose':
        return const Color(0x26F43F5E);
      default:
        return const Color(0x263B82F6);
    }
  }

  @override
  Color get quickActionIcon {
    switch (colorTheme) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'orange':
        return const Color(0xFFF97316);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'rose':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFF3B82F6);
    }
  }

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
    final theme = AuthStore().colorTheme;
    return isDark ? DarkThemeColors(theme) : LightThemeColors(theme);
  }
}

extension ThemeColorExtension on BuildContext {
  ThemeColorSchema get colors => ThemeColorService.colors;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
