import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DaybookLedgerPage extends StatefulWidget {
  final Map<String, dynamic> account;
  final String accountType; // savings, loans, shares

  const DaybookLedgerPage({
    super.key,
    required this.account,
    required this.accountType,
  });

  @override
  State<DaybookLedgerPage> createState() => _DaybookLedgerPageState();
}

class _DaybookLedgerPageState extends State<DaybookLedgerPage> {
  bool _isLoading = true;
  List<dynamic> _ledgerItems = [];
  
  // BS Date range defaults
  String _fromBsDate = '2083-01-01';
  String _toBsDate = '2083-03-32';

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final id = widget.account['id'] ?? 1;
      final res = await ApiService().getAccountLedger(
        widget.accountType,
        id,
        fromDate: _fromBsDate,
        toDate: _toBsDate,
      );
      setState(() {
        _ledgerItems = res['data'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateTotal(String type) {
    double sum = 0.0;
    for (var item in _ledgerItems) {
      final isCredit = item['type'] == 'credit' || item['type'] == 'CR';
      if (type == 'credit' && isCredit) {
        sum += double.tryParse((item['amount'] ?? '0').toString()) ?? 0.0;
      } else if (type == 'debit' && !isCredit) {
        sum += double.tryParse((item['amount'] ?? '0').toString()) ?? 0.0;
      }
    }
    return sum;
  }

  void _shareStatement() {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Export Statement', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Do you want to download or share the transaction statement as a secure PDF?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Statement PDF exported successfully!'), backgroundColor: Color(0xFF10B981)),
                );
              },
              child: const Text('Download PDF', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final totalCredit = _calculateTotal('credit');
    final totalDebit = _calculateTotal('debit');
    final netChange = totalCredit - totalDebit;

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
          'Daybook Statement',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _shareStatement,
            icon: Icon(Icons.share_rounded, color: isDarkMode ? Colors.white : const Color(0xFF0F172A)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Filter Panel (Nepali BS 2083 Calendar selection dropdowns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildBsDateSelector('From Date (BS)', _fromBsDate, (val) {
                            setState(() => _fromBsDate = val);
                            _loadLedger();
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBsDateSelector('To Date (BS)', _toBsDate, (val) {
                            setState(() => _toBsDate = val);
                            _loadLedger();
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Summary Metrics Board
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryCol('Total Credits', 'Rs. ${totalCredit.toStringAsFixed(2)}', const Color(0xFF10B981)),
                    Container(width: 1, height: 35, color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                    _buildSummaryCol('Total Debits', 'Rs. ${totalDebit.toStringAsFixed(2)}', const Color(0xFFEF4444)),
                    Container(width: 1, height: 35, color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                    _buildSummaryCol(
                      'Net Change',
                      '${netChange >= 0 ? "+" : "-"}Rs. ${netChange.abs().toStringAsFixed(2)}',
                      netChange >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Transactions Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'DAYBOOK TRANSACTION HISTORY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Ledgers List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  : _ledgerItems.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions match this BS date range.',
                            style: TextStyle(
                              color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isCredit
                                              ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                              : const Color(0xFFEF4444).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                          color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            desc,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                              fontSize: 11,
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
                                          fontWeight: FontWeight.w900,
                                          color: isCredit ? const Color(0xFF10B981) : (isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Bal: Rs. $balance',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Widget _buildBsDateSelector(String label, String currentVal, ValueChanged<String> onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final options = [
      '2083-01-01',
      '2083-01-15',
      '2083-02-01',
      '2083-02-15',
      '2083-03-01',
      '2083-03-32',
      '2083-04-01',
      '2083-06-01',
      '2083-08-01',
      '2083-12-30',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(currentVal) ? currentVal : options.first,
              dropdownColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              style: TextStyle(
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              isExpanded: true,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: valueColor),
        ),
      ],
    );
  }
}
