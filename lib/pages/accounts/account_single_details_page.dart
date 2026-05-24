import 'package:flutter/material.dart';
import '../../widgets/cooperative_account_card.dart';

class AccountSingleDetailsPage extends StatefulWidget {
  final Map<String, dynamic> account;
  final String accountType; // savings, loans, shares

  const AccountSingleDetailsPage({
    super.key,
    required this.account,
    required this.accountType,
  });

  @override
  State<AccountSingleDetailsPage> createState() => _AccountSingleDetailsPageState();
}

class _AccountSingleDetailsPageState extends State<AccountSingleDetailsPage> {

  void _handleQuickAction(String title) {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text('The $title features are running in simulation modes for this demonstration account.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  void _showNotImplementedSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature is not implemented yet.'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B) 
            : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatAmount(dynamic amt) {
    if (amt == null) return '0.00';
    if (amt is num) {
      return amt.toStringAsFixed(2);
    }
    final str = amt.toString().replaceAll(',', '');
    final d = double.tryParse(str) ?? 0.0;
    return d.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final acc = widget.account;
    final name = acc['name'] ?? 'Account';
    
    final double rawBalance = (acc['balance'] ?? 0.0).toDouble();
    final balance = 'Rs. ${_formatAmount(rawBalance)}';
    
    final accountNo = acc['accNo'] ?? acc['account_no'] ?? 'N/A';
    final scheme = (acc['scheme'] ?? widget.accountType.toUpperCase()).toString().toUpperCase();

    final isSavings = widget.accountType == 'savings';
    final isLoan = widget.accountType == 'loans';
    final isShare = widget.accountType == 'shares';

    Color accentColor = const Color(0xFF2563EB); // savings blue
    if (widget.accountType == 'loans') {
      accentColor = const Color(0xFFEF4444);
    } else if (widget.accountType == 'shares') {
      accentColor = const Color(0xFF10B981);
    }

    IconData getIconForLabel(String label) {
      switch (label) {
        case 'Interest Rate':
          return Icons.percent_rounded;
        case 'Accrued Interest':
        case 'Accrued Interest Due':
        case 'Due Interest':
          return Icons.payments_rounded;
        case 'Minimum Balance':
          return Icons.wallet_rounded;
        case 'Opened Date (BS)':
          return Icons.calendar_today_rounded;
        case 'Maturity Date':
        case 'Maturity Date (BS)':
          return Icons.event_busy_rounded;
        case 'Interest Posting Date':
          return Icons.event_repeat_rounded;
        case 'Principal Fine':
        case 'Interest Fine':
          return Icons.gavel_rounded;
        case 'Matured Principal':
          return Icons.account_balance_rounded;
        case 'Share Capital Value':
          return Icons.monetization_on_rounded;
        case 'Total Share Units':
          return Icons.grid_view_rounded;
        case 'Member Status':
          return Icons.verified_user_rounded;
        default:
          return Icons.info_outline_rounded;
      }
    }

    // Build actions list dynamically based on account type
    final actions = <Map<String, dynamic>>[];

    if (!isLoan) {
      actions.add({
        'label': 'Deposit',
        'icon': Icons.add_circle_outline_rounded,
        'onTap': () => _showNotImplementedSnackBar('Deposit'),
      });
    }

    if (!isShare) {
      actions.add({
        'label': 'Payment',
        'icon': Icons.send_rounded,
        'onTap': () => _showNotImplementedSnackBar('Payment'),
      });
    }

    actions.add({
      'label': 'Statement',
      'icon': Icons.download_rounded,
      'onTap': () => _handleQuickAction('Statement'),
    });

    if (isSavings || isLoan) {
      actions.add({
        'label': 'Rate Logs',
        'icon': Icons.history_rounded,
        'onTap': () => _showNotImplementedSnackBar('Interest Rate Change Logs'),
      });
    }

    if (isLoan) {
      actions.add({
        'label': 'Schedules',
        'icon': Icons.calendar_month_rounded,
        'onTap': () => _showNotImplementedSnackBar('Schedules'),
      });
    }

    // Build details list dynamically based on account type
    final List<Map<String, String>> detailsList = [];
    if (isSavings) {
      detailsList.addAll([
        {'label': 'Interest Rate', 'value': '${acc['interest_rate'] ?? '8.5'}% p.a.'},
        {'label': 'Accrued Interest', 'value': 'Rs. ${_formatAmount(acc['accrued_interest'])}'},
        {'label': 'Minimum Balance', 'value': 'Rs. ${_formatAmount(acc['min_balance'])}'},
        {'label': 'Opened Date (BS)', 'value': acc['issued_date']?.toString() ?? '2081-02-15'},
        {'label': 'Maturity Date', 'value': 'N/A'},
        {'label': 'Interest Posting Date', 'value': 'Quarterly Capitalization'},
      ]);
    } else if (isLoan) {
      detailsList.addAll([
        {'label': 'Interest Rate', 'value': '${acc['interest_rate'] ?? '12.0'}% p.a.'},
        {'label': 'Accrued Interest Due', 'value': 'Rs. ${_formatAmount(acc['accrued_interest'])}'},
        {'label': 'Opened Date (BS)', 'value': acc['issued_date']?.toString() ?? '2080-11-10'},
        {'label': 'Maturity Date (BS)', 'value': acc['maturity_date']?.toString() ?? '2085-11-10'},
        {'label': 'Principal Fine', 'value': 'Rs. ${_formatAmount(acc['principal_fine'] ?? 0.0)}'},
        {'label': 'Interest Fine', 'value': 'Rs. ${_formatAmount(acc['interest_fine'] ?? 0.0)}'},
        {'label': 'Matured Principal', 'value': 'Rs. ${_formatAmount(acc['matured_principal'] ?? 0.0)}'},
        {'label': 'Due Interest', 'value': 'Rs. ${_formatAmount(acc['due_interest'] ?? 0.0)}'},
        {'label': 'Interest Posting Date', 'value': 'Monthly Capitalization'},
      ]);
    } else { // shares
      detailsList.addAll([
        {'label': 'Share Capital Value', 'value': 'Rs. ${_formatAmount(acc['balance'])}'},
        {'label': 'Total Share Units', 'value': '${acc['share_count'] ?? '100'} Units'},
        {'label': 'Opened Date (BS)', 'value': acc['issued_date']?.toString() ?? '2079-05-18'},
        {'label': 'Member Status', 'value': 'Active Shareholder'},
        {'label': 'Maturity Date', 'value': 'N/A'},
        {'label': 'Interest Posting Date', 'value': 'Annual Dividend Cycle'},
      ]);
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          children: [
            SizedBox(
              height: 190,
              child: CooperativeAccountCard(
                isOverview: false,
                accountType: widget.accountType,
                title: scheme,
                balance: balance,
                accountNo: accountNo,
                interestRate: acc['interest_rate'],
                shareCount: acc['share_count'],
                maturityDate: acc['maturity_date'],
                showBalance: true,
                isDarkMode: isDarkMode,
                showArrow: false,
              ),
            ),

            const SizedBox(height: 28),

            // Quick Actions Grid
            Text(
              'Quick Actions'.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: actions.map((act) {
                return _buildActionGridButton(
                  act['label'] as String,
                  act['icon'] as IconData,
                  isDarkMode,
                  onTap: act['onTap'] as VoidCallback,
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Detailed Card
            Text(
              'Account Information'.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: List.generate(detailsList.length, (index) {
                  final detail = detailsList[index];
                  final isLast = index == detailsList.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: isDarkMode ? 0.15 : 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                getIconForLabel(detail['label']!),
                                color: isDarkMode ? accentColor.withValues(alpha: 0.8) : accentColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                detail['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                detail['value']!,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFEFF6FF),
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGridButton(String label, IconData icon, bool isDarkMode, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFDBEAFE),
              ),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
