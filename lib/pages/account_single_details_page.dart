import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'daybook_ledger_page.dart';

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

class _AccountSingleDetailsPageState extends State<AccountSingleDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingLedger = false;
  List<dynamic> _ledgerItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadLedger();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && _ledgerItems.isEmpty) {
      _loadLedger();
    }
  }

  Future<void> _loadLedger() async {
    setState(() {
      _isLoadingLedger = true;
    });

    try {
      final id = widget.account['id'] ?? 1;
      final res = await ApiService().getAccountLedger(widget.accountType, id);
      setState(() {
        _ledgerItems = res['data'] ?? [];
        _isLoadingLedger = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingLedger = false;
      });
    }
  }

  List<Map<String, String>> _getMetrics() {
    final acc = widget.account;
    final isSaving = widget.accountType == 'savings';
    final isLoan = widget.accountType == 'loans';

    if (isSaving) {
      return [
        { 'label': 'Interest Rate', 'value': '${acc['interest_rate'] ?? '8.5'}% p.a.', 'desc': 'Quarterly capitalization capitalization' },
        { 'label': 'Accrued Interest', 'value': 'Rs. ${acc['accrued_interest'] ?? '120.50'}', 'desc': 'Accumulated this quarter threshold' },
        { 'label': 'Minimum Balance', 'value': 'Rs. ${acc['min_balance'] ?? '500.00'}', 'desc': 'Required minimum balance threshold' },
        { 'label': 'Opened Date (BS)', 'value': acc['issued_date'] ?? '2081-02-15', 'desc': 'Active savings account setup date' },
      ];
    } else if (isLoan) {
      return [
        { 'label': 'Interest Rate', 'value': '${acc['interest_rate'] ?? '12.0'}% p.a.', 'desc': 'Calculated monthly capitalization capitalization' },
        { 'label': 'Accrued Interest Due', 'value': 'Rs. ${acc['accrued_interest'] ?? '1,250.00'}', 'desc': 'Pending current capitalization cycle' },
        { 'label': 'Opened Date (BS)', 'value': acc['issued_date'] ?? '2080-11-10', 'desc': 'Loan approval execution date' },
        { 'label': 'Maturity Date (BS)', 'value': acc['maturity_date'] ?? '2085-11-10', 'desc': 'Loan final maturity schedule' },
      ];
    } else {
      // shares
      return [
        { 'label': 'Share Capital Value', 'value': acc['balance'] ?? 'Rs. 10,000.00', 'desc': 'Total capitalized share investment value' },
        { 'label': 'Total Share Units', 'value': '${acc['share_count'] ?? '100'} Units', 'desc': 'NPR 100.00 face value per share unit' },
        { 'label': 'Opened Date (BS)', 'value': acc['issued_date'] ?? '2079-05-18', 'desc': 'Active member shareholding setup date' },
        { 'label': 'Member Status', 'value': 'Active Shareholder', 'desc': 'Bright Cooperative Member core status' },
      ];
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final acc = widget.account;
    final name = acc['name'] ?? 'Account';
    final balance = acc['balance'] ?? 'Rs. 0.00';
    final accountNo = acc['account_no'] ?? 'N/A';
    final scheme = (acc['scheme'] ?? widget.accountType.toUpperCase()).toString().toUpperCase();

    Color accentColor = const Color(0xFF2563EB); // savings blue
    Color cardBg = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color accentBarColor = const Color(0xFF2563EB);

    if (widget.accountType == 'loans') {
      accentColor = const Color(0xFFEF4444);
      accentBarColor = const Color(0xFFEF4444);
    } else if (widget.accountType == 'shares') {
      accentColor = const Color(0xFF10B981);
      accentBarColor = const Color(0xFF10B981);
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
            // Account Card
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
                ),
                boxShadow: isDarkMode
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Accent Line
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 6,
                      child: Container(color: accentBarColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scheme,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withOpacity(0.15),
                                  ),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ACCOUNT NUMBER',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    accountNo,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'CURRENT BALANCE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    balance,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
              children: [
                _buildActionGridButton('Deposit', Icons.add_circle_outline_rounded, const Color(0xFF3B82F6), isDarkMode),
                _buildActionGridButton('Payment', Icons.send_rounded, const Color(0xFF10B981), isDarkMode),
                _buildActionGridButton('Statement', Icons.download_rounded, const Color(0xFF8B5CF6), isDarkMode),
                _buildActionGridButton(
                  'Daybook',
                  Icons.receipt_long_rounded,
                  const Color(0xFFF59E0B),
                  isDarkMode,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DaybookLedgerPage(
                          account: acc,
                          accountType: widget.accountType,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Tabs Header
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2563EB),
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                tabs: const [
                  Tab(text: 'Account Metrics'),
                  Tab(text: 'Daybook Ledger'),
                ],
              ),
            ),

            // Tab Views Container (using direct height constraints or inner lists)
            const SizedBox(height: 16),
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMetricsView(isDarkMode),
                  _buildLedgerTab(isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGridButton(String label, IconData icon, Color color, bool isDarkMode, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _handleQuickAction(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsView(bool isDarkMode) {
    final metrics = _getMetrics();
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, idx) {
        final metric = metrics[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                metric['label']!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric['value']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric['desc']!,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerTab(bool isDarkMode) {
    return Column(
      children: [
        // Quick BS Daybook statement filter link
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DaybookLedgerPage(
                    account: widget.account,
                    accountType: widget.accountType,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB).withOpacity(0.04),
              side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 16),
            label: const Text(
              'Filter BS Daybook Statement',
              style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: _isLoadingLedger
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                )
              : _ledgerItems.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0), style: BorderStyle.none),
                        ),
                        child: const Text(
                          'No transactions found for this account.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _ledgerItems.length,
                      itemBuilder: (context, index) {
                        final tx = _ledgerItems[index];
                        final isCredit = tx['type'] == 'credit' || tx['type'] == 'CR';
                        final amount = tx['amount'] ?? '0.00';
                        final amountStr = '${isCredit ? "+" : "-"} Rs. $amount';
                        final balance = tx['balance'] ?? '0.00';
                        final desc = tx['description'] ?? tx['desc'] ?? 'Transaction';
                        final dateStr = tx['date'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isCredit
                                          ? const Color(0xFF10B981).withOpacity(0.08)
                                          : const Color(0xFFEF4444).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    amountStr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCredit ? const Color(0xFF10B981) : (isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Bal: Rs. $balance',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
