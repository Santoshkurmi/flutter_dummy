import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';
import '../../widgets/error_state_view.dart';
import '../../services/theme_color_service.dart';

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

  StreamSubscription? _rateLogsSubscription;

  @override
  void dispose() {
    _rateLogsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchRateLogs({bool forceRefresh = false}) async {
    _rateLogsSubscription?.cancel();
    final completer = Completer<void>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final schemeId = widget.account['scheme_id'];
      if (schemeId == null) {
        throw Exception('Scheme ID not available for this account.');
      }
      final int parsedSchemeId = schemeId is int ? schemeId : int.parse(schemeId.toString());

      final stream = widget.accountType == 'savings'
          ? ApiService().getSavingSchemeRateLogsStream(parsedSchemeId, forceRefresh: forceRefresh)
          : ApiService().getLoanSchemeRateLogsStream(parsedSchemeId, forceRefresh: forceRefresh);

      _rateLogsSubscription = stream.listen((response) {
        if (mounted) {
          setState(() {
            _isLoading = response.isLoading;
            _errorMessage = response.hasError ? response.error : null;
            if (response.data != null) {
              final res = response.data!;
              if (res['response_code'] == 1 && res['data'] != null) {
                final List<dynamic> data = res['data'];
                _rateLogs = data.map((e) => Map<String, dynamic>.from(e)).toList();
              } else {
                _rateLogs = [];
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
          (widget.accountType == 'savings' ? 'Interest Rate Logs' : 'Loan Interest Log').tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colors.primaryText,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchRateLogs(forceRefresh: true),
        color: colors.accent,
        backgroundColor: colors.cardBackground,
        child: _isLoading && _errorMessage == null
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(colors.accent)))
            : _errorMessage != null && _rateLogs.isEmpty
                ? _buildErrorState(isDarkMode)
                : _buildBody(isDarkMode, schemeName),
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return ErrorStateView(
      errorMessage: _errorMessage,
      onRetry: _fetchRateLogs,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildBody(bool isDarkMode, String schemeName) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (_errorMessage != null && _rateLogs.isNotEmpty)
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
                  color: colors.accent.withValues(alpha: isDarkMode ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.trending_up_rounded, color: colors.accent, size: 22),
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
                      '${widget.account['accNo'] ?? ''} • ${'${_rateLogs.length} entries'.tr}',
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
    final colors = context.colors;

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
              ? colors.accent.withValues(alpha: isDarkMode ? 0.15 : 0.05)
              : colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFirst ? colors.accent : colors.border,
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
                        color: colors.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Period'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.secondaryText,
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
                            color: colors.primaryText,
                          ),
                        ),
                      ),
                      if (isOngoing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.success.withValues(alpha: isDarkMode ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ongoing'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.success,
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
                color: isFirst ? colors.accent : colors.inputFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatRate(rate),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isFirst ? Colors.white : colors.primaryText,
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
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.border,
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
                        color: colors.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Applied Date'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.secondaryText,
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
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${'Number of Days'.tr}: ${AuthStore().language == 'ne' ? numberOfDays.trd : numberOfDays}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatRate(rate),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: colors.primaryText,
                ),
              ),
            ),
          ],
        ),
      );
    }
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
              Icons.history_toggle_off_rounded,
              size: 48,
              color: colors.secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              'No rate change history found.'.tr,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The current rate has been applied since the beginning.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 12,
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
