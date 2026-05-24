import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AccountLedgerPage extends StatefulWidget {
  final String accountType;
  final int accountId;
  final String accountName;

  const AccountLedgerPage({
    super.key,
    required this.accountType,
    required this.accountId,
    required this.accountName,
  });

  @override
  State<AccountLedgerPage> createState() => _AccountLedgerPageState();
}

class _AccountLedgerPageState extends State<AccountLedgerPage> {
  bool _isLoading = true;
  List<dynamic> _ledgerItems = [];
  
  // Date Filters
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() {
      _isLoading = true;
    });

    final fromStr = _fromDate != null ? '${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}' : null;
    final toStr = _toDate != null ? '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}' : null;

    try {
      final res = await ApiService().getAccountLedger(
        widget.accountType,
        widget.accountId,
        fromDate: fromStr,
        toDate: toStr,
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

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              onSurface: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _loadLedger();
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadLedger();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDarkMode ? Colors.white : const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.accountName,
          style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF1E293B), fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Filter Panel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // From Date
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fromDate != null ? _formatDate(_fromDate!) : 'From Date',
                                  style: TextStyle(
                                    color: _fromDate != null ? (isDarkMode ? Colors.white : const Color(0xFF1E293B)) : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // To Date
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _toDate != null ? _formatDate(_toDate!) : 'To Date',
                                  style: TextStyle(
                                    color: _toDate != null ? (isDarkMode ? Colors.white : const Color(0xFF1E293B)) : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_fromDate != null || _toDate != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_rounded, size: 14, color: Color(0xFFEF4444)),
                        label: const Text('Clear Filters', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Statement Ledger List
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
                            'No transactions found for this period.',
                            style: TextStyle(color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _ledgerItems.length,
                          itemBuilder: (context, index) {
                            final tx = _ledgerItems[index];
                            final isCredit = tx['type'] == 'credit';
                            final amount = tx['amount'] ?? '0.00';
                            final amountStr = '${isCredit ? "+" : "-"} Rs. $amount';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                                ),
                                boxShadow: isDarkMode
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        )
                                      ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isCredit
                                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                                : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                          ),
                                          child: Icon(
                                            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                            color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx['description'] ?? 'Transaction',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                tx['date'] ?? '',
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    amountStr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCredit ? const Color(0xFF10B981) : (isDarkMode ? Colors.white : const Color(0xFF1E293B)),
                                      fontSize: 15,
                                    ),
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
}
