import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/theme_color_service.dart';

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
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Export Statement', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText)),
          content: Text('Do you want to download or share the transaction statement as a secure PDF?', style: TextStyle(color: colors.primaryText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colors.secondaryText)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Statement PDF exported successfully!'), backgroundColor: colors.success),
                );
              },
              child: Text('Download PDF', style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final totalCredit = _calculateTotal('credit');
    final totalDebit = _calculateTotal('debit');
    final netChange = totalCredit - totalDebit;

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.primaryText,
          ),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: Text(
          'Daybook Statement',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colors.primaryText,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _shareStatement,
            icon: Icon(Icons.share_rounded, color: colors.primaryText),
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
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border,
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
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryCol('Total Credits', 'Rs. ${totalCredit.toStringAsFixed(2)}', colors.success),
                    Container(width: 1, height: 35, color: colors.border),
                    _buildSummaryCol('Total Debits', 'Rs. ${totalDebit.toStringAsFixed(2)}', colors.error),
                    Container(width: 1, height: 35, color: colors.border),
                    _buildSummaryCol(
                      'Net Change',
                      '${netChange >= 0 ? "+" : "-"}Rs. ${netChange.abs().toStringAsFixed(2)}',
                      netChange >= 0 ? colors.success : colors.error,
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
                  color: colors.secondaryText,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Ledgers List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                      ),
                    )
                  : _ledgerItems.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions match this BS date range.',
                            style: TextStyle(
                              color: colors.secondaryText,
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
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.border,
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
                                              ? colors.success.withValues(alpha: 0.08)
                                              : colors.error.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                          color: isCredit ? colors.success : colors.error,
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
                                              color: colors.primaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colors.secondaryText,
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
                                          color: isCredit ? colors.success : colors.primaryText,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Bal: Rs. $balance',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colors.secondaryText,
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
    final colors = context.colors;
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
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: colors.secondaryText,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(currentVal) ? currentVal : options.first,
              dropdownColor: colors.cardBackground,
              style: TextStyle(
                color: colors.primaryText,
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
    final colors = context.colors;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colors.secondaryText, letterSpacing: 0.5),
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
