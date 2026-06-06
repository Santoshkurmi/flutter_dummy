import 'package:flutter/material.dart';
import '../../services/theme_color_service.dart';

class PaymentsTab extends StatelessWidget {
  final bool isDarkMode;

  const PaymentsTab({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_rounded, size: 64, color: colors.accent),
          const SizedBox(height: 16),
          Text(
            'Cooperative Bank Payments',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transfer funds, pay utility bills, and pay loans instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
