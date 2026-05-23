import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'account_details_page.dart';
import 'nepali_calendar_page.dart';
import 'register_member_page.dart';

class AllServicesPage extends StatelessWidget {
  final bool isDarkMode;
  final void Function(int) onTabChange;

  const AllServicesPage({
    super.key,
    required this.isDarkMode,
    required this.onTabChange,
  });

  void _handleActionTap(BuildContext context, String label) {
    if (label == 'Statement' || label == 'Savings') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage()));
    } else if (label == 'Calendar') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NepaliCalendarPage()));
    } else if (label == 'Ledger') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage()));
    } else if (label == 'Self Register') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterMemberPage()));
    } else if (label == 'Utility' || label == 'Payment' || label == 'Send Money') {
      onTabChange(1); // Payments Tab
    } else if (label == 'Scan QR' || label == 'QR Scan') {
      onTabChange(2); // Scan QR Tab
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label service initialized.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allActions = [
      {'icon': Icons.send_rounded, 'label': 'Send Money', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.arrow_downward_rounded, 'label': 'Receive', 'color': const Color(0xFF10B981)},
      {'icon': Icons.receipt_long_rounded, 'label': 'Statement', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.savings_rounded, 'label': 'Deposit', 'color': const Color(0xFFF97316)},
      {'icon': Icons.menu_book_rounded, 'label': 'Ledger', 'color': const Color(0xFFD97706)},
      {'icon': Icons.pie_chart_rounded, 'label': 'Share', 'color': const Color(0xFF6366F1)},
      {'icon': Icons.business_center_rounded, 'label': 'Loan', 'color': const Color(0xFFF43F5E)},
      {'icon': Icons.calendar_month_rounded, 'label': 'Calendar', 'color': const Color(0xFFF57C00)},
      {'icon': Icons.bolt_rounded, 'label': 'Utility', 'color': const Color(0xFFEAB308)},
      {'icon': Icons.newspaper_rounded, 'label': 'Notice', 'color': const Color(0xFF0D9488)},
      {'icon': Icons.calculate_rounded, 'label': 'Calculator', 'color': const Color(0xFF64748B)},
      {'icon': Icons.app_registration_rounded, 'label': 'Self Register', 'color': const Color(0xFF06B6D4)},
      {'icon': Icons.history_rounded, 'label': 'History', 'color': const Color(0xFF475569)},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Transfer', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.trending_up_rounded, 'label': 'Growth', 'color': const Color(0xFF10B981)},
      {'icon': Icons.shield_rounded, 'label': 'Security', 'color': const Color(0xFF2563EB)},
      {'icon': Icons.card_giftcard_rounded, 'label': 'Rewards', 'color': const Color(0xFFE11D48)},
      {'icon': Icons.public_rounded, 'label': 'Remittance', 'color': const Color(0xFF4F46E5)},
      {'icon': Icons.qr_code_scanner_rounded, 'label': 'Scan QR', 'color': const Color(0xFF9333EA)},
      {'icon': Icons.help_outline_rounded, 'label': 'Support', 'color': const Color(0xFF64748B)},
    ];

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Services'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: allActions.map((act) {
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                _handleActionTap(context, act['label'] as String);
              },
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (act['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (act['color'] as Color).withValues(alpha: 0.2)),
                    ),
                    child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (act['label'] as String).tr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
