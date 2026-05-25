import 'package:flutter/material.dart';

extension NavigationExtension on BuildContext {
  /// Returns a back button if the current screen can be popped.
  /// If the screen cannot be popped (e.g. it is the root screen), it returns null.
  Widget? backButton({Color? color}) {
    if (!Navigator.canPop(this)) return null;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
      ),
      onPressed: () => Navigator.maybePop(this),
    );
  }
}
