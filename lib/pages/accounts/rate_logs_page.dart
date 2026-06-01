import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';

class RateLogsPage extends StatefulWidget {
  final Map<String, dynamic> account;
  final String accountType; // 'savings' or 'loans'

  const RateLogsPage({
    super.key,
    required this.account,
    required this.accountType,
  });

  @override
  State<RateLogsPage> createState() => _RateLogsPageState();
}

class _RateLogsPageState extends State<RateLogsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _rateLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchRateLogs();
  }

  Future<void> _fetchRateLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final schemeId = widget.account['scheme_id'];
      if (schemeId == null) {
        throw Exception('Scheme ID not available for this account.');
      }
      final res = widget.accountType == 'savings'
          ? await ApiService().getSavingSchemeRateLogs(schemeId is int ? schemeId : int.parse(schemeId.toString()))
          : await ApiService().getLoanSchemeRateLogs(schemeId is int ? schemeId : int.parse(schemeId.toString()));
      if (res['response_code'] == 1 && res['data'] != null) {
        final List<dynamic> data = res['data'];
        setState(() {
          _rateLogs = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _rateLogs = [];
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

  String _formatRate(dynamic rate) {
    if (rate == null) return '0%';
    final num val = rate is num ? rate : num.tryParse(rate.toString()) ?? 0;
    final formatted = val == val.truncateToDouble()
        ? val.toInt().toString()
        : val.toStringAsFixed(2);
    if (AuthStore().language == 'ne') {
      return '${formatted.trd}%';
    }
    return '$formatted%';
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
          (widget.accountType == 'savings' ? 'Interest Rate Logs' : 'Loan Interest Log').tr,
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
              onPressed: _fetchRateLogs,
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
                  color: const Color(0xFF2563EB).withValues(alpha: isDarkMode ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Color(0xFF2563EB), size: 22),
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
                      '${widget.account['accNo'] ?? ''} • ${'${_rateLogs.length} entries'.tr}',
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

        const SizedBox(height: 8),

        // List of entries (Cards)
        if (_rateLogs.isEmpty)
          _buildEmptyState(isDarkMode)
        else
          ..._rateLogs.asMap().entries.map((entry) {
            final index = entry.key;
            final log = entry.value;
            final isFirst = index == 0;
            return _buildLogRow(log, isFirst, isDarkMode);
          }),
      ],
    );
  }

  Widget _buildLogRow(Map<String, dynamic> log, bool isFirst, bool isDarkMode) {
    final isSavings = widget.accountType == 'savings';

    if (isSavings) {
      final from = log['from']?.toString() ?? '';
      final to = log['to']?.toString() ?? '';
      final rate = log['interest_rate'];

      final bool isOngoing = to.contains('Ongoing') || to.contains('🔮');
      final bool isBefore = from.contains('Before') || from.contains('⏳');

      final String fromStr = isBefore ? 'Before'.tr : _formatDateField(from);
      final String toStr = isOngoing ? 'Ongoing'.tr : _formatDateField(to);
      final String dateRange = '$fromStr - $toStr';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFirst
              ? (isDarkMode ? const Color(0xFF2563EB).withValues(alpha: 0.1) : const Color(0xFF2563EB).withValues(alpha: 0.05))
              : (isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFirst
                ? const Color(0xFF2563EB)
                : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            width: isFirst ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Period'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          dateRange,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (isOngoing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: isDarkMode ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ongoing'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFirst
                    ? const Color(0xFF2563EB)
                    : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatRate(rate),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isFirst ? Colors.white : (isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final appliedDate = log['applied_date']?.toString() ?? '';
      final numberOfDays = log['number_of_days']?.toString() ?? '0';
      final rate = log['interest_rate'];

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Applied Date'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDateField(appliedDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${'Number of Days'.tr}: ${AuthStore().language == 'ne' ? numberOfDays.trd : numberOfDays}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatRate(rate),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              'No rate change history found.'.tr,
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The current rate has been applied since the beginning.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
