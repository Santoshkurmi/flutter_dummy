import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import '../accounts/account_details_page.dart';
import 'nepali_calendar_page.dart';
import '../auth/register_member_page.dart';

class AllServicesPage extends StatelessWidget {
  final bool isDarkMode;
  final void Function(int) onTabChange;
  final Map<String, dynamic>? accountsData;

  const AllServicesPage({
    super.key,
    required this.isDarkMode,
    required this.onTabChange,
    this.accountsData,
  });

  void _handleActionTap(BuildContext context, String label) {
    if (label == 'Accounts') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailsPage(initialAccountsData: accountsData)));
    } else if (label == 'Statement') {
      onTabChange(1); // Switches to bottom Statement tab
    } else if (label == 'Savings' || label == 'Ledger') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailsPage(initialAccountsData: accountsData)));
    } else if (label == 'Calendar') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NepaliCalendarPage()));
    } else if (label == 'Self Register') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterMemberPage()));
    } else if (label == 'Utility' || label == 'Payment' || label == 'Send Money') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailsPage(initialAccountsData: accountsData)));
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
      {'icon': Icons.send_rounded, 'label': 'Send Money'},
      {'icon': Icons.arrow_downward_rounded, 'label': 'Receive'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Accounts'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Statement'},
      {'icon': Icons.qr_code_scanner_rounded, 'label': 'Scan QR'},
      {'icon': Icons.phone_android_rounded, 'label': 'Recharge'},
      {'icon': Icons.bolt_rounded, 'label': 'Utility'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Calendar'},
      {'icon': Icons.newspaper_rounded, 'label': 'Notice'},
      {'icon': Icons.calculate_rounded, 'label': 'Calculator'},
      {'icon': Icons.app_registration_rounded, 'label': 'Self Register'},
      {'icon': Icons.support_agent_rounded, 'label': 'Support'},
      {'icon': Icons.history_rounded, 'label': 'History'},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Transfer'},
      {'icon': Icons.trending_up_rounded, 'label': 'Growth'},
      {'icon': Icons.shield_rounded, 'label': 'Security'},
      {'icon': Icons.card_giftcard_rounded, 'label': 'Rewards'},
      {'icon': Icons.public_rounded, 'label': 'Remittance'},
    ];

    final Color containerColor = isDarkMode 
        ? Colors.white.withValues(alpha: 0.05) 
        : const Color(0xFFEFF6FF);
    final Color borderColor = isDarkMode 
        ? Colors.white.withValues(alpha: 0.08) 
        : const Color(0xFFDBEAFE);
    final Color iconColor = isDarkMode 
        ? const Color(0xFF60A5FA) 
        : const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ) : null,
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
                final label = act['label'] as String;
                if (label == 'Scan QR' ||
                    label == 'QR Scan' ||
                    label == 'Statement') {
                  Navigator.pop(context);
                  _handleActionTap(context, label);
                } else {
                  _handleActionTap(context, label);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(act['icon'] as IconData, color: iconColor, size: 24),
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
