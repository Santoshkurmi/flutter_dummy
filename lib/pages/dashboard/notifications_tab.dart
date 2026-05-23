import 'package:flutter/material.dart';

class NotificationsTab extends StatelessWidget {
  final bool isDarkMode;

  const NotificationsTab({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active_rounded, size: 64, color: Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          Text(
            'Alerts & Notifications',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your secure notification inbox for transactions, deposits, and cooperative board updates.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
