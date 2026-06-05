import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:downloadsfolder/downloadsfolder.dart' hide context, Context;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../store/auth_store.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';
import '../../services/nepali_calendar_service.dart';
import 'transaction_receipt_page.dart';
import '../../widgets/error_state_view.dart';


class DateMaskTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    
    var text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 8) {
      text = text.substring(0, 8);
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 3 && text.length > 4) || (i == 5 && text.length > 6)) {
        buffer.write('-');
      }
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CombinedStatementPage extends StatefulWidget {
  final int? currentIndex;

  const CombinedStatementPage({
    super.key,
    this.currentIndex,
  });

  @override
  State<CombinedStatementPage> createState() => _CombinedStatementPageState();
}

class _CombinedStatementPageState extends State<CombinedStatementPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<dynamic> _ledgerItems = [];
  
  // Date values for range filtering
  String _fromDateVal = '';
  String _toDateVal = '';
  
  // Active Preset: '7_days', '15_days', '1_month', or null
  String? _selectedPreset;
  StreamSubscription? _ledgerSubscription;

  // Selected Nepali Year and Month for '1_month' preset
  int? _selectedNepaliYear;
  int? _selectedNepaliMonth;

  @override
  void initState() {
    super.initState();
    final todayBs = NepaliCalendarService.adToBs(DateTime.now());
    _selectedNepaliYear = todayBs[0];
    _selectedNepaliMonth = todayBs[1];
    _loadLedger();
  }

  @override
  void dispose() {
    _ledgerSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CombinedStatementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == 1 && oldWidget.currentIndex != 1) {
      _loadLedger();
    }
  }

  bool _isValidDate(String dateStr) {
    if (dateStr.isEmpty) return true;
    final regExp = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    if (!regExp.hasMatch(dateStr)) return false;
    final match = regExp.firstMatch(dateStr);
    if (match == null) return false;
    final month = int.tryParse(match.group(2)!) ?? 0;
    final day = int.tryParse(match.group(3)!) ?? 0;
    return month >= 1 && month <= 12 && day >= 1 && day <= 32;
  }

  Future<void> _loadLedger({bool forceRefetch = false}) {
    final completer = Completer<void>();
    _ledgerSubscription?.cancel();

    String? fromDateParam = _fromDateVal.isNotEmpty ? _fromDateVal : null;
    String? toDateParam = _toDateVal.isNotEmpty ? _toDateVal : null;
    String? presetParam = _selectedPreset;

    if (_selectedPreset == '1_month') {
      final year = _selectedNepaliYear ?? 2083;
      final month = _selectedNepaliMonth ?? 1;
      final lastDay = NepaliCalendarService.getDaysInBsMonth(year, month);
      
      fromDateParam = '$year-${month.toString().padLeft(2, '0')}-01';
      toDateParam = '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
      presetParam = null;
    }

    _ledgerSubscription = ApiService().getAllAccountsLedgerStream(
      fromDate: fromDateParam,
      toDate: toDateParam,
      preset: presetParam,
      forceRefresh: forceRefetch,
    ).listen((response) {
      if (mounted) {
        if (response.isCacheNotModified) {
          setState(() {
            _isLoading = response.isLoading;
            _hasError = response.hasError;
            _errorMessage = response.hasError ? response.error : null;
            if (_ledgerItems.isEmpty && response.data != null) {
              _ledgerItems = response.data?['data'] ?? [];
            }
          });
        } else {
          setState(() {
            if (response.data != null) {
              _ledgerItems = response.data?['data'] ?? [];
            }
            _isLoading = response.isLoading;
            _hasError = response.hasError;
            _errorMessage = response.hasError ? response.error : null;
          });
        }
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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

    return completer.future;
  }

  void _selectPreset(String preset) {
    setState(() {
      if (_selectedPreset == preset) {
        _selectedPreset = null;
      } else {
        _selectedPreset = preset;
        _fromDateVal = '';
        _toDateVal = '';
      }
    });
    _loadLedger();
  }

  void _clearFilters() {
    setState(() {
      _fromDateVal = '';
      _toDateVal = '';
      _selectedPreset = null;
    });
    _loadLedger();
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

  // Opens a custom date range bottom sheet modal
  void _openFilterBottomSheet(BuildContext context, Color accentColor, bool isDarkMode) {
    final TextEditingController fromController = TextEditingController(text: _fromDateVal);
    final TextEditingController toController = TextEditingController(text: _toDateVal);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            String? fromError;
            String? toError;

            void submitFilter() {
              final fromStr = fromController.text.trim();
              final toStr = toController.text.trim();
              
              bool hasError = false;
              if (fromStr.isNotEmpty && !_isValidDate(fromStr)) {
                setBottomSheetState(() {
                  fromError = 'Use YYYY-MM-DD';
                });
                hasError = true;
              }
              if (toStr.isNotEmpty && !_isValidDate(toStr)) {
                setBottomSheetState(() {
                  toError = 'Use YYYY-MM-DD';
                });
                hasError = true;
              }

              if (hasError) return;

              Navigator.pop(context);
              setState(() {
                _fromDateVal = fromStr;
                _toDateVal = toStr;
                _selectedPreset = null;
              });
              _loadLedger();
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Custom Date Range (BS)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildBottomSheetTextField(
                            controller: fromController,
                            label: 'From Date',
                            errorText: fromError,
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildBottomSheetTextField(
                            controller: toController,
                            label: 'To Date',
                            errorText: toError,
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                              side: BorderSide(
                                color: isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: submitFilter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Apply Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetTextField({
    required TextEditingController controller,
    required String label,
    required String? errorText,
    required bool isDarkMode,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            DateMaskTextInputFormatter(),
          ],
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            hintStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 10, height: 0.8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String preset, String label, Color accentColor, bool isDarkMode) {
    final bool isSelected = _selectedPreset == preset;
    return InkWell(
      onTap: () => _selectPreset(preset),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? accentColor 
              : (isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? accentColor 
                : (isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected 
                ? Colors.white 
                : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(Color accentColor, bool isDarkMode) {
    final bool isCustomActive = _fromDateVal.isNotEmpty || _toDateVal.isNotEmpty;
    final String label = isCustomActive ? 'Filter Active' : 'Filter';
    return InkWell(
      onTap: () => _openFilterBottomSheet(context, accentColor, isDarkMode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCustomActive 
              ? accentColor 
              : (isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCustomActive 
                ? accentColor 
                : (isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 14,
              color: isCustomActive 
                  ? Colors.white 
                  : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCustomActive 
                    ? Colors.white 
                    : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearDropdown(bool isDarkMode) {
    final int todayBsYear = NepaliCalendarService.adToBs(DateTime.now())[0];
    final int startYear = 2078;
    int currentYear = _selectedNepaliYear ?? todayBsYear;
    if (currentYear < startYear) currentYear = startYear;
    if (currentYear > todayBsYear) currentYear = todayBsYear;

    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentYear,
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
          iconEnabledColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          dropdownColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
            fontSize: 12,
          ),
          items: () {
            final int yearCount = (todayBsYear >= startYear) ? (todayBsYear - startYear + 1) : 1;
            return List.generate(yearCount, (index) => startYear + index).map((yr) {
              final displayYear = AuthStore().language == 'ne' 
                  ? TranslationService.toNepaliNumbers(yr.toString()) 
                  : yr.toString();
              return DropdownMenuItem<int>(
                value: yr,
                child: Text(displayYear),
              );
            }).toList();
          }(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedNepaliYear = val;
              });
              _loadLedger();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMonthDropdown(bool isDarkMode) {
    final int currentMonth = _selectedNepaliMonth ?? 1;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentMonth,
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
          iconEnabledColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          dropdownColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
            fontSize: 12,
          ),
          items: List.generate(12, (index) => index + 1).map((mIdx) {
            final mName = NepaliCalendarService.nepaliMonths[mIdx - 1];
            return DropdownMenuItem<int>(
              value: mIdx,
              child: Text(mName.tr),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedNepaliMonth = val;
              });
              _loadLedger();
            }
          },
        ),
      ),
    );
  }

  String _getEmptyStateDescription() {
    final language = AuthStore().language;
    final isNepali = language == 'ne';

    if (_selectedPreset != null) {
      if (_selectedPreset == '7_days') {
        return 'No transactions found in the last 7 days.'.tr;
      } else if (_selectedPreset == '15_days') {
        return 'No transactions found in the last 15 days.'.tr;
      } else if (_selectedPreset == '1_month') {
        final year = _selectedNepaliYear ?? 2083;
        final month = _selectedNepaliMonth ?? 1;
        final monthIdx = month - 1;
        final monthName = isNepali 
            ? NepaliCalendarService.nepaliMonthsDevanagari[monthIdx]
            : NepaliCalendarService.nepaliMonths[monthIdx];
        final yearStr = isNepali
            ? TranslationService.toNepaliNumbers(year.toString())
            : year.toString();
        return isNepali
            ? '$monthName $yearStr मा कुनै कारोबार फेला परेन।'
            : 'No transactions found for $monthName $yearStr.';
      }
    } else if (_fromDateVal.isNotEmpty || _toDateVal.isNotEmpty) {
      final fromStr = _fromDateVal.isNotEmpty ? _fromDateVal : '';
      final toStr = _toDateVal.isNotEmpty ? _toDateVal : '';
      final displayFrom = isNepali ? TranslationService.toNepaliNumbers(fromStr) : fromStr;
      final displayTo = isNepali ? TranslationService.toNepaliNumbers(toStr) : toStr;
      return isNepali
          ? '$displayFrom देखि $displayTo सम्म कुनै कारोबार फेला परेन।'
          : 'No transactions found between $displayFrom and $displayTo.';
    }
    return 'There are no transactions recorded across your accounts.'.tr;
  }

  Future<pw.Document> _buildPdfDocument() async {
    final pdf = pw.Document();
    final profile = AuthStore().profile;
    final coop = AuthStore().selectedCooperative;
    final coopName = coop?['name'] ?? 'Bright Saving & Credit Co-operative';
    final coopAddress = coop?['address'] ?? 'Kathmandu, Nepal';
    final memberName = profile?['member_name'] ?? 'Sahakari User';
    final memberNo = profile?['member_no'] ?? profile?['member_code'] ?? 'M-783921';
    final mobile = profile?['mobile'] ?? AuthStore().mobile ?? '98XXXXXXXX';

    String filterDesc = 'All Transaction History';
    if (_selectedPreset != null) {
      if (_selectedPreset == '7_days') {
        final toAd = DateTime.now();
        final fromAd = toAd.subtract(const Duration(days: 7));
        final fromBs = NepaliCalendarService.adToBs(fromAd);
        final toBs = NepaliCalendarService.adToBs(toAd);
        final fromStr = '${fromBs[0]}-${fromBs[1].toString().padLeft(2, '0')}-${fromBs[2].toString().padLeft(2, '0')}';
        final toStr = '${toBs[0]}-${toBs[1].toString().padLeft(2, '0')}-${toBs[2].toString().padLeft(2, '0')}';
        filterDesc = 'Range: $fromStr - $toStr';
      } else if (_selectedPreset == '15_days') {
        final toAd = DateTime.now();
        final fromAd = toAd.subtract(const Duration(days: 15));
        final fromBs = NepaliCalendarService.adToBs(fromAd);
        final toBs = NepaliCalendarService.adToBs(toAd);
        final fromStr = '${fromBs[0]}-${fromBs[1].toString().padLeft(2, '0')}-${fromBs[2].toString().padLeft(2, '0')}';
        final toStr = '${toBs[0]}-${toBs[1].toString().padLeft(2, '0')}-${toBs[2].toString().padLeft(2, '0')}';
        filterDesc = 'Range: $fromStr - $toStr';
      } else if (_selectedPreset == '1_month') {
        final year = _selectedNepaliYear ?? 2083;
        final month = _selectedNepaliMonth ?? 1;
        final lastDay = NepaliCalendarService.getDaysInBsMonth(year, month);
        final fromStr = '$year-${month.toString().padLeft(2, '0')}-01';
        final toStr = '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
        filterDesc = 'Range: $fromStr - $toStr';
      }
    } else if (_fromDateVal.isNotEmpty || _toDateVal.isNotEmpty) {
      filterDesc = 'Range: $_fromDateVal - $_toDateVal';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  coopName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  coopAddress,
                  style: const pw.TextStyle(
                    fontSize: 9,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'COMBINED TRANSACTION STATEMENT',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            ),

            // Member Info Block
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Member Name: $memberName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text('Membership No: $memberNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Mobile Number: $mobile', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Statement Type: Combined', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Filter Criteria: $filterDesc', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Table of items
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(25), // S.N.
                1: const pw.FixedColumnWidth(65), // Date
                2: const pw.FixedColumnWidth(80), // Account No
                3: const pw.FixedColumnWidth(55), // Category
                4: const pw.FlexColumnWidth(),    // Description
                5: const pw.FixedColumnWidth(35), // CR/DR
                6: const pw.FixedColumnWidth(75), // Amount
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('S.N.', isHeader: true),
                    _pdfCell('Date (BS)', isHeader: true),
                    _pdfCell('Account No', isHeader: true),
                    _pdfCell('Category', isHeader: true),
                    _pdfCell('Description', isHeader: true),
                    _pdfCell('Type', isHeader: true),
                    _pdfCell('Amount', isHeader: true, alignRight: true),
                  ],
                ),
                // Data rows
                ...List.generate(_ledgerItems.length, (index) {
                  final tx = _ledgerItems[index];
                  final String typeStr = (tx['type'] ?? '').toString().toUpperCase();
                  final bool isCredit = typeStr == 'CR' || typeStr == 'CREDIT';
                  final double amount = (tx['amount'] ?? 0.0).toDouble();
                  
                  final String desc = tx['desc'] ?? tx['description'] ?? 'Transaction';
                  final String nepaliDate = tx['nepaliDate'] ?? tx['date'] ?? '';
                  final String accountType = tx['accountType'] ?? 'savings';
                  final String accountNo = tx['accountNo'] ?? 'N/A';

                  return pw.TableRow(
                    children: [
                      _pdfCell('${index + 1}'),
                      _pdfCell(nepaliDate),
                      _pdfCell(accountNo),
                      _pdfCell(accountType.toUpperCase()),
                      _pdfCell(desc),
                      _pdfCell(isCredit ? 'CR' : 'DR', textColor: isCredit ? PdfColors.green800 : PdfColors.red800),
                      _pdfCell('Rs. ${_formatAmount(amount)}', alignRight: true),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  Future<void> _printPdf(bool isDarkMode) async {
    final pdf = await _buildPdfDocument();
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'combined_statement_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _downloadPdf(bool isDarkMode) async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt < 29) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission is required to save PDF.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }
      }

      final pdf = await _buildPdfDocument();
      final pdfBytes = await pdf.save();

      final fileName = 'combined_statement_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfBytes);

      final bool? success = await copyFileIntoDownloadFolder(
        tempFile.path,
        fileName,
      );

      if (success == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: $fileName'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  final openResult = await OpenFilex.open(tempFile.path);
                  if (openResult.type != ResultType.done) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open PDF: ${openResult.message}'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening PDF: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ),
        );
      } else {
        throw Exception('Could not copy file to downloads folder');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save PDF: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false, bool alignRight = false, PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFF2563EB); // Royal Blue as standard for combined statement
    final bool isFilteredAtAll = _selectedPreset != null || _fromDateVal.isNotEmpty || _toDateVal.isNotEmpty;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Statement History',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf_rounded,
              color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            ),
            tooltip: 'Download PDF',
            onPressed: () => _downloadPdf(isDarkMode),
          ),
          IconButton(
            icon: Icon(
              Icons.print_rounded,
              color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            ),
            tooltip: 'Print',
            onPressed: () => _printPdf(isDarkMode),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadLedger(forceRefetch: true);
          },
          color: const Color(0xFF2563EB),
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24, top: 10),
            children: [
              // Presets & Filter Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  children: [
                    if (_selectedPreset != '1_month') ...[
                      _buildPresetChip('7_days', '7 Days', accentColor, isDarkMode),
                      const SizedBox(width: 8),
                      _buildPresetChip('15_days', '15 Days', accentColor, isDarkMode),
                      const SizedBox(width: 8),
                    ],
                    _buildPresetChip('1_month', 'Monthly'.tr, accentColor, isDarkMode),
                    const SizedBox(width: 8),
                    if (_selectedPreset == '1_month') ...[
                      _buildYearDropdown(isDarkMode),
                      const SizedBox(width: 8),
                      _buildMonthDropdown(isDarkMode),
                      const SizedBox(width: 8),
                    ],
                    _buildFilterChip(accentColor, isDarkMode),
                    if (isFilteredAtAll) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _clearFilters,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Results Container
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.3) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _buildMainContent(isDarkMode, accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode, Color accentColor) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ),
      );
    }

    if (_hasError && _ledgerItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: _buildErrorView(isDarkMode),
      );
    }

    if (_ledgerItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 60,
              color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found.'.tr,
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getEmptyStateDescription(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    String listTitle = 'Showing last 30';
    if (_selectedPreset != null) {
      if (_selectedPreset == '7_days') listTitle = 'Last 7 Days';
      if (_selectedPreset == '15_days') listTitle = 'Last 15 Days';
      if (_selectedPreset == '1_month') {
        final monthIdx = (_selectedNepaliMonth ?? 1) - 1;
        final monthName = AuthStore().language == 'ne' 
            ? NepaliCalendarService.nepaliMonthsDevanagari[monthIdx]
            : NepaliCalendarService.nepaliMonths[monthIdx];
        final yearStr = AuthStore().language == 'ne'
            ? TranslationService.toNepaliNumbers((_selectedNepaliYear ?? 2083).toString())
            : (_selectedNepaliYear ?? 2083).toString();
        listTitle = '$monthName $yearStr';
      }
    } else if (_fromDateVal.isNotEmpty || _toDateVal.isNotEmpty) {
      listTitle = 'Filtered Range';
    }

    String headerText = 'Statements'.tr;
    String rangeText = '';

    if (_selectedPreset != null) {
      if (_selectedPreset == '7_days') {
        final toAd = DateTime.now();
        final fromAd = toAd.subtract(const Duration(days: 7));
        final fromBs = NepaliCalendarService.adToBs(fromAd);
        final toBs = NepaliCalendarService.adToBs(toAd);
        final fromStr = '${fromBs[0]}-${fromBs[1].toString().padLeft(2, '0')}-${fromBs[2].toString().padLeft(2, '0')}';
        final toStr = '${toBs[0]}-${toBs[1].toString().padLeft(2, '0')}-${toBs[2].toString().padLeft(2, '0')}';
        rangeText = ' $fromStr - $toStr';
      } else if (_selectedPreset == '15_days') {
        final toAd = DateTime.now();
        final fromAd = toAd.subtract(const Duration(days: 15));
        final fromBs = NepaliCalendarService.adToBs(fromAd);
        final toBs = NepaliCalendarService.adToBs(toAd);
        final fromStr = '${fromBs[0]}-${fromBs[1].toString().padLeft(2, '0')}-${fromBs[2].toString().padLeft(2, '0')}';
        final toStr = '${toBs[0]}-${toBs[1].toString().padLeft(2, '0')}-${toBs[2].toString().padLeft(2, '0')}';
        rangeText = ' $fromStr - $toStr';
      } else if (_selectedPreset == '1_month') {
        final year = _selectedNepaliYear ?? 2083;
        final month = _selectedNepaliMonth ?? 1;
        final lastDay = NepaliCalendarService.getDaysInBsMonth(year, month);
        final fromStr = '$year-${month.toString().padLeft(2, '0')}-01';
        final toStr = '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
        rangeText = ' $fromStr - $toStr';
      }
    } else if (_fromDateVal.isNotEmpty || _toDateVal.isNotEmpty) {
      final fromStr = _fromDateVal.isNotEmpty ? _fromDateVal : '';
      final toStr = _toDateVal.isNotEmpty ? _toDateVal : '';
      rangeText = ' $fromStr - $toStr';
    }

    final displayRange = AuthStore().language == 'ne'
        ? TranslationService.toNepaliNumbers(rangeText)
        : rangeText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasError && _ledgerItems.isNotEmpty)
          _buildInlineErrorBanner(_errorMessage ?? 'Failed to refresh statement.', isDarkMode),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: headerText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                      ),
                    ),
                    if (rangeText.isNotEmpty)
                      TextSpan(
                        text: '  $displayRange',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                listTitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: _ledgerItems.map((tx) {
              final String typeStr = (tx['type'] ?? '').toString().toUpperCase();
              final bool isCredit = typeStr == 'CR' || typeStr == 'CREDIT';
              
              final double amount = (tx['amount'] ?? 0.0).toDouble();
              final String amountStr = '${isCredit ? "+" : "-"} Rs. ${_formatAmount(amount)}';
              
              final String desc = tx['desc'] ?? tx['description'] ?? 'Transaction';
              final String nepaliDate = tx['nepaliDate'] ?? tx['date'] ?? '';
              final String refNo = tx['refNo'] ?? tx['reference_number'] ?? '';
              
              final String accountType = tx['accountType'] ?? 'savings';
              final String accountNo = tx['accountNo'] ?? 'N/A';

              // Category Badge Styling
              Color badgeBg;
              Color badgeText;
              String typeLabel;
              if (accountType == 'savings') {
                typeLabel = 'Savings';
                badgeBg = isDarkMode ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF);
                badgeText = isDarkMode ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
              } else if (accountType == 'loans') {
                typeLabel = 'Loan';
                badgeBg = isDarkMode ? const Color(0xFF451A03) : const Color(0xFFFEF2F2);
                badgeText = isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626);
              } else if (accountType == 'shares') {
                typeLabel = 'Shares';
                badgeBg = isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
                badgeText = isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669);
              } else {
                typeLabel = 'Account';
                badgeBg = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
                badgeText = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionReceiptPage(
                        transaction: Map<String, dynamic>.from(tx),
                        accountType: accountType,
                        accountNo: accountNo,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                    boxShadow: isDarkMode
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            
                            // Account type tag and account number layout (using Wrap to prevent cropping on small screens)
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    typeLabel,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: badgeText,
                                    ),
                                  ),
                                ),
                                Text(
                                  accountNo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 6),
                            Text(
                              nepaliDate,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            if (refNo.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Ref: $refNo',
                                style: TextStyle(
                                    fontSize: 9.5,
                                    color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                    fontFamily: 'monospace',
                                  ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amountStr,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(bool isDarkMode) {
    return ErrorStateView(
      errorMessage: _errorMessage,
      onRetry: _loadLedger,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildInlineErrorBanner(String error, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626),
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
