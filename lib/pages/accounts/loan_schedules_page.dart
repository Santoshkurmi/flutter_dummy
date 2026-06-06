import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';
import '../../widgets/error_state_view.dart';
import '../../services/theme_color_service.dart';

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

  StreamSubscription? _schedulesSubscription;

  @override
  void dispose() {
    _schedulesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchSchedules({bool forceRefresh = false}) async {
    _schedulesSubscription?.cancel();
    final completer = Completer<void>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accountId = widget.account['id'];
      if (accountId == null) {
        throw Exception('Account ID not available.');
      }
      final int parsedAccountId = accountId is int ? accountId : int.parse(accountId.toString());

      _schedulesSubscription = ApiService().getLoanPaymentSchedulesStream(
        parsedAccountId,
        forceRefresh: forceRefresh,
      ).listen((response) {
        if (mounted) {
          setState(() {
            _isLoading = response.isLoading;
            _errorMessage = response.hasError ? response.error : null;
            if (response.data != null) {
              final res = response.data!;
              if (res['response_code'] == 1 && res['data'] != null) {
                final List<dynamic> data = res['data'];
                _schedules = data.map((e) => Map<String, dynamic>.from(e)).toList();
              } else {
                _schedules = [];
              }
            }
          });
        }
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().replaceAll('Exception: ', '');
            _isLoading = false;
          });
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      }, onDone: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    return completer.future;
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
    final colors = context.colors;
    final isDarkMode = context.isDarkMode;
    final schemeName = AuthStore().language == 'ne'
        ? (widget.account['scheme_name_nepali'] ?? widget.account['scheme_name'] ?? '')
        : (widget.account['scheme_name'] ?? '');

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.primaryText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Loan Payment Schedules'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colors.primaryText,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchSchedules(forceRefresh: true),
        color: colors.accent,
        backgroundColor: colors.cardBackground,
        child: _isLoading && _errorMessage == null
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(colors.accent)))
            : _errorMessage != null && _schedules.isEmpty
                ? _buildErrorState(isDarkMode)
                : _buildBody(isDarkMode, schemeName),
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return ErrorStateView(
      errorMessage: _errorMessage,
      onRetry: _fetchSchedules,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildBody(bool isDarkMode, String schemeName) {
    final colors = context.colors;
    final filteredSchedules = _showInterest
        ? _schedules
        : _schedules.where((s) => (s['installment_amount'] ?? 0) > 0).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (_errorMessage != null && _schedules.isNotEmpty)
          _buildInlineErrorBanner(_errorMessage!, isDarkMode),
        // Scheme header card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: isDarkMode ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_month_rounded, color: colors.error, size: 22),
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
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.account['accNo'] ?? ''} • ${'${filteredSchedules.length} installments'.tr}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.secondaryText,
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
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.border,
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
                  color: colors.primaryText,
                ),
              ),
              Switch(
                value: _showInterest,
                onChanged: (val) {
                  setState(() {
                    _showInterest = val;
                  });
                },
                activeThumbColor: colors.accent,
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
    final colors = context.colors;
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
        cardBgColor = colors.success.withValues(alpha: 0.1);
        borderCol = colors.success.withValues(alpha: 0.2);
        statusColor = colors.success;
        statusText = 'Paid'.tr;
      } else if (status == 'not_paid') {
        cardBgColor = colors.error.withValues(alpha: 0.1);
        borderCol = colors.error.withValues(alpha: 0.2);
        statusColor = colors.error;
        statusText = 'Overdue'.tr;
      } else {
        // pending
        cardBgColor = colors.cardBackground;
        borderCol = colors.border;
        statusColor = colors.secondaryText;
        statusText = 'Upcoming'.tr;
      }
    } else {
      // Interest mode: no status colors, all are normal
      cardBgColor = colors.cardBackground;
      borderCol = colors.border;
      statusColor = colors.secondaryText;
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
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${'S.N.'.tr} $displaySN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.primaryText,
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
            color: colors.border,
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
                        ? colors.error
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
                        ? colors.success
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
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.secondaryText,
      ),
    );
  }

  Widget _buildInfoValue(String val, bool isDarkMode, {FontWeight? fontWeight, Color? color}) {
    final colors = context.colors;
    return Text(
      val,
      style: TextStyle(
        fontSize: 13,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? colors.primaryText,
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: colors.secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              'No schedules found.'.tr,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineErrorBanner(String error, bool isDarkMode) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
