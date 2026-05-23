import 'package:flutter/material.dart';

class PaymentsTab extends StatelessWidget {
  final bool isDarkMode;

  const PaymentsTab({
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
          Icon(Icons.payment_rounded, size: 64, color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
          const SizedBox(height: 16),
          Text(
            'Cooperative Bank Payments',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transfer funds, pay utility bills, and pay loans instantly.',
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
