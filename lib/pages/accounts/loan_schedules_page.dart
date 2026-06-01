import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';

class LoanSchedulesPage extends StatefulWidget {
  final Map<String, dynamic> account;

  const LoanSchedulesPage({
    super.key,
    required this.account,
  });

  @override
  State<LoanSchedulesPage> createState() => _LoanSchedulesPageState();
}

class _LoanSchedulesPageState extends State<LoanSchedulesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _schedules = [];
  bool _showInterest = false;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accountId = widget.account['id'];
      if (accountId == null) {
        throw Exception('Account ID not available.');
      }
      final res = await ApiService().getLoanPaymentSchedules(
          accountId is int ? accountId : int.parse(accountId.toString()));
      if (res['response_code'] == 1 && res['data'] != null) {
        final List<dynamic> data = res['data'];
        setState(() {
          _schedules = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _schedules = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatAmount(dynamic amt) {
    if (amt == null) return '0.00';
    double d = 0.0;
    if (amt is num) {
      d = amt.toDouble();
    } else {
      final str = amt.toString().replaceAll(',', '');
      d = double.tryParse(str) ?? 0.0;
    }
    final formatted = d.toStringAsFixed(2);
    return AuthStore().language == 'ne'
        ? TranslationService.toNepaliNumbers(formatted)
        : formatted;
  }

  String _formatDateField(dynamic val) {
    if (val == null) return '';
    final s = val.toString();
    if (AuthStore().language == 'ne') return s.trd;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AuthStore().isDarkMode;
    final schemeName = AuthStore().language == 'ne'
        ? (widget.account['scheme_name_nepali'] ?? widget.account['scheme_name'] ?? '')
        : (widget.account['scheme_name'] ?? '');

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
          'Loan Payment Schedules'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB))))
          : _errorMessage != null
              ? _buildErrorState(isDarkMode)
              : _buildBody(isDarkMode, schemeName),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: isDarkMode ? const Color(0xFFEF4444) : const Color(0xFFDC2626)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchSchedules,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDarkMode, String schemeName) {
    final filteredSchedules = _showInterest
        ? _schedules
        : _schedules.where((s) => (s['installment_amount'] ?? 0) > 0).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Scheme header card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: isDarkMode ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schemeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.account['accNo'] ?? ''} • ${'${filteredSchedules.length} installments'.tr}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Show Interest Switch Control
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Show Interest Schedule'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Switch(
                value: _showInterest,
                onChanged: (val) {
                  setState(() {
                    _showInterest = val;
                  });
                },
                activeColor: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // List of entries (Cards)
        if (filteredSchedules.isEmpty)
          _buildEmptyState(isDarkMode)
        else
          ...filteredSchedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;
            return _buildCard(schedule, index + 1, _showInterest, isDarkMode);
          }),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> schedule, int sn, bool showInterest, bool isDarkMode) {
    final date = schedule['payment_date_bs']?.toString() ?? '';
    final daysPassed = schedule['days_passed'] ?? 0;
    final instAmt = schedule['installment_amount'];
    final intAmt = schedule['interest_amount'];
    final paidAmt = schedule['paid_installment_amount'];
    final status = schedule['status']?.toString() ?? 'pending';

    // Status colors (only when showInterest is false)
    Color cardBgColor;
    Color borderCol;
    Color statusColor;
    String statusText;

    if (!showInterest) {
      if (status == 'paid') {
        cardBgColor = isDarkMode ? const Color(0xFF064E3B).withValues(alpha: 0.15) : const Color(0xFFD1FAE5).withValues(alpha: 0.5);
        borderCol = isDarkMode ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);
        statusColor = isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669);
        statusText = 'Paid'.tr;
      } else if (status == 'not_paid') {
        cardBgColor = isDarkMode ? const Color(0xFF7F1D1D).withValues(alpha: 0.15) : const Color(0xFFFEE2E2).withValues(alpha: 0.5);
        borderCol = isDarkMode ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5);
        statusColor = isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        statusText = 'Overdue'.tr;
      } else {
        // pending
        cardBgColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        borderCol = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
        statusColor = isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569);
        statusText = 'Upcoming'.tr;
      }
    } else {
      // Interest mode: no status colors, all are normal
      cardBgColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
      borderCol = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
      statusColor = isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569);
      statusText = '';
    }

    final String displaySN = AuthStore().language == 'ne' ? sn.toString().trd : sn.toString();
    final String displayDays = AuthStore().language == 'ne' ? daysPassed.toString().trd : daysPassed.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${'S.N.'.tr} $displaySN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (!showInterest && statusText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoLabel('Payment Date'.tr, isDarkMode),
                    const SizedBox(height: 4),
                    _buildInfoValue(_formatDateField(date), isDarkMode),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoLabel('Days'.tr, isDarkMode),
                    const SizedBox(height: 4),
                    _buildInfoValue(
                      daysPassed > 0 
                        ? '$displayDays ${'Days Passed'.tr}' 
                        : '$displayDays ${'Days'.tr}', 
                      isDarkMode,
                      color: daysPassed > 0 && !showInterest
                        ? (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                        : null
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoLabel('Installment Amount'.tr, isDarkMode),
                    const SizedBox(height: 4),
                    _buildInfoValue('Rs. ${_formatAmount(instAmt)}', isDarkMode, fontWeight: FontWeight.w700),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoLabel('Paid Principal'.tr, isDarkMode),
                    const SizedBox(height: 4),
                    _buildInfoValue(
                      'Rs. ${_formatAmount(paidAmt)}', 
                      isDarkMode, 
                      fontWeight: FontWeight.w700,
                      color: (paidAmt != null && double.tryParse(paidAmt.toString()) != 0.0)
                        ? const Color(0xFF10B981)
                        : null
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showInterest) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoLabel('Interest Amount'.tr, isDarkMode),
                      const SizedBox(height: 4),
                      _buildInfoValue('Rs. ${_formatAmount(intAmt)}', isDarkMode, fontWeight: FontWeight.w700),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoLabel(String label, bool isDarkMode) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildInfoValue(String val, bool isDarkMode, {FontWeight? fontWeight, Color? color}) {
    return Text(
      val,
      style: TextStyle(
        fontSize: 13,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? (isDarkMode ? Colors.white : const Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              'No schedules found.'.tr,
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
