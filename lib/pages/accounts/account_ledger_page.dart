import 'dart:io';
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
import '../../widgets/cooperative_account_card.dart';
import 'transaction_receipt_page.dart';


class DateMaskTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    
    // Strip non-digits inside the formatter to avoid conflicts with digitsOnly
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

class AccountLedgerPage extends StatefulWidget {
  final Map<String, dynamic> account;
  final String accountType;
  final String? heroTag;
  final List<Map<String, dynamic>>? swipableAccounts;
  final int? initialIndex;

  const AccountLedgerPage({
    super.key,
    required this.account,
    required this.accountType,
    this.heroTag,
    this.swipableAccounts,
    this.initialIndex,
  });

  @override
  State<AccountLedgerPage> createState() => _AccountLedgerPageState();
}

class _AccountLedgerPageState extends State<AccountLedgerPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _ledgerItems = [];
  
  // Date values for range filtering
  String _fromDateVal = '';
  String _toDateVal = '';
  
  // Active Preset: '7_days', '15_days', '1_month', or null
  String? _selectedPreset;

  late int _currentIndex;
  late List<Map<String, dynamic>> _accountsList;
  late String _activeType;
  late Map<String, dynamic> _activeAccount;

  // Custom swipe logic state (matching HomeTab)
  double _dragOffset = 0.0;
  late AnimationController _swipeController;
  double _animationStartOffset = 0.0;
  double _animationTargetOffset = 0.0;
  bool _isAnimating = false;
  bool _isDismissal = false;
  int _dismissDirection = 0;
  bool _isDraggingCard = false;
  Offset? _startPointerPos;
  double _dragStartOffset = 0.0;
  bool _isPointerDragging = false;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _accountsList = widget.swipableAccounts ?? [
      {'raw': widget.account, 'type': widget.accountType}
    ];
    _activeAccount = _accountsList[_currentIndex]['raw'];
    _activeType = _accountsList[_currentIndex]['type'];

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        setState(() {
          _dragOffset = Tween<double>(
            begin: _animationStartOffset,
            end: _animationTargetOffset,
          ).evaluate(_swipeController);
        });
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_isDismissal) {
            setState(() {
              int total = _accountsList.length;
              _currentIndex = (_currentIndex + _dismissDirection) % total;
              if (_currentIndex < 0) {
                _currentIndex += total;
              }
              _activeAccount = _accountsList[_currentIndex]['raw'];
              _activeType = _accountsList[_currentIndex]['type'];
              _dragOffset = 0.0;
              _isAnimating = false;
            });
            _loadLedger(); // Reload statement data for new card selection
          } else {
            setState(() {
              _dragOffset = 0.0;
              _isAnimating = false;
            });
          }
        }
      });

    _loadLedger();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _animateDismiss(int direction) {
    double screenWidth = MediaQuery.of(context).size.width;
    double pageWidth = screenWidth - 40.0;
    
    _isDismissal = true;
    _dismissDirection = direction;
    _animationStartOffset = _dragOffset;
    _animationTargetOffset = direction == 1 ? -pageWidth : pageWidth;
    
    _isAnimating = true;
    _swipeController.forward(from: 0.0);
  }

  void _animateSnapBack() {
    _isDismissal = false;
    _animationStartOffset = _dragOffset;
    _animationTargetOffset = 0.0;
    
    _isAnimating = true;
    _swipeController.forward(from: 0.0);
  }

  void _completeAnimationInstantly() {
    if (!_isAnimating) return;
    _swipeController.stop();
    if (_isDismissal) {
      int total = _accountsList.length;
      _currentIndex = (_currentIndex + _dismissDirection) % total;
      if (_currentIndex < 0) {
        _currentIndex += total;
      }
    }
    _dragOffset = 0.0;
    _isAnimating = false;
  }

  void _handleDragEnd(double primaryVelocity) {
    final bool didSwipe = _isDraggingCard;
    
    setState(() {
      _isPointerDragging = false;
      _isDraggingCard = false;
    });
    
    if (_isAnimating) return;
    
    final velocity = primaryVelocity.abs();
    
    if (_dragOffset.abs() > 80.0 || (didSwipe && velocity > 400.0)) {
      _animateDismiss(_dragOffset > 0 ? -1 : 1);
    } else {
      _animateSnapBack();
    }
    _startPointerPos = null;
  }

  void _handleDragCancel() {
    setState(() {
      _isPointerDragging = false;
      _isDraggingCard = false;
    });
    if (!_isAnimating) {
      _animateSnapBack();
    }
    _startPointerPos = null;
  }

  double get _currentPage {
    if (!mounted) return 0.0;
    double screenWidth = MediaQuery.of(context).size.width;
    double pageWidth = screenWidth - 40.0;
    double progress = (pageWidth > 0) ? (_dragOffset / pageWidth) : 0.0;
    return _currentIndex - progress;
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

  Future<void> _loadLedger() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final res = await ApiService().getAccountLedger(
        _activeType,
        _activeAccount['id'] ?? 0,
        fromDate: _fromDateVal.isNotEmpty ? _fromDateVal : null,
        toDate: _toDateVal.isNotEmpty ? _toDateVal : null,
        preset: _selectedPreset,
      );
      setState(() {
        _ledgerItems = res['data'] ?? [];
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _selectPreset(String preset) {
    setState(() {
      if (_selectedPreset == preset) {
        // Toggle off
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
    if (amt is num) {
      return amt.toStringAsFixed(2);
    }
    final str = amt.toString().replaceAll(',', '');
    final d = double.tryParse(str) ?? 0.0;
    return d.toStringAsFixed(2);
  }

  Color _getAccentColor() {
    switch (_activeType) {
      case 'loans':
        return const Color(0xFFEF4444);
      case 'shares':
        return const Color(0xFF10B981);
      case 'savings':
      default:
        return const Color(0xFF2563EB);
    }
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

              // Apply and load
              Navigator.pop(context);
              setState(() {
                _fromDateVal = fromStr;
                _toDateVal = toStr;
                _selectedPreset = null; // Clear active presets
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
                    // Sheet Header
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

                    // Input fields
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

                    // Actions
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
            DateMaskTextInputFormatter(), // safely handles masking & digit stripping inside
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

  Future<pw.Document> _buildPdfDocument() async {
    final pdf = pw.Document();
    final profile = AuthStore().profile;
    final coop = AuthStore().selectedCooperative;
    final coopName = coop?['name'] ?? 'Bright Saving & Credit Co-operative';
    final coopAddress = coop?['address'] ?? 'Kathmandu, Nepal';
    final memberName = profile?['member_name'] ?? 'Sahakari User';
    final memberNo = profile?['member_no'] ?? profile?['member_code'] ?? 'M-783921';
    final mobile = profile?['mobile'] ?? AuthStore().mobile ?? '98XXXXXXXX';

    final String accountTitle = (_activeAccount['scheme'] ?? _activeType).toString().toUpperCase();
    final String accountNo = (_activeAccount['accNo'] ?? _activeAccount['account_no'] ?? 'N/A').toString();
    final double rawBalance = (_activeAccount['balance'] ?? 0.0).toDouble();

    String filterDesc = 'All Transaction History';
    if (_selectedPreset != null) {
      if (_selectedPreset == '7_days') filterDesc = 'Last 7 Days';
      if (_selectedPreset == '15_days') filterDesc = 'Last 15 Days';
      if (_selectedPreset == '1_month') filterDesc = 'Last Month';
    } else if (_fromDateVal.isNotEmpty || _toDateVal.isNotEmpty) {
      filterDesc = 'Date Range: $_fromDateVal to $_toDateVal';
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
                  'ACCOUNT STATEMENT',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            ),

            // Member Info Block & Account Block
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
                      pw.Text('Account Scheme: $accountTitle', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Account Number: $accountNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text('Account Balance: Rs. ${_formatAmount(rawBalance)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
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
                2: const pw.FlexColumnWidth(),    // Description
                3: const pw.FixedColumnWidth(35), // CR/DR
                4: const pw.FixedColumnWidth(75), // Amount
                5: const pw.FixedColumnWidth(80), // Running Balance
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('S.N.', isHeader: true),
                    _pdfCell('Date (BS)', isHeader: true),
                    _pdfCell('Description', isHeader: true),
                    _pdfCell('Type', isHeader: true),
                    _pdfCell('Amount', isHeader: true, alignRight: true),
                    _pdfCell('Running Bal', isHeader: true, alignRight: true),
                  ],
                ),
                // Data rows
                ...List.generate(_ledgerItems.length, (index) {
                  final tx = _ledgerItems[index];
                  final String typeStr = (tx['type'] ?? '').toString().toUpperCase();
                  final bool isCredit = typeStr == 'CR' || typeStr == 'CREDIT';
                  final double amount = (tx['amount'] ?? 0.0).toDouble();
                  final double runningBal = (tx['balance'] ?? 0.0).toDouble();
                  
                  final String desc = tx['desc'] ?? tx['description'] ?? 'Transaction';
                  final String nepaliDate = tx['nepaliDate'] ?? tx['date'] ?? '';

                  return pw.TableRow(
                    children: [
                      _pdfCell('${index + 1}'),
                      _pdfCell(nepaliDate),
                      _pdfCell(desc),
                      _pdfCell(isCredit ? 'CR' : 'DR', textColor: isCredit ? PdfColors.green800 : PdfColors.red800),
                      _pdfCell('Rs. ${_formatAmount(amount)}', alignRight: true),
                      _pdfCell('Rs. ${_formatAmount(runningBal)}', alignRight: true),
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
    final String accountNo = (_activeAccount['accNo'] ?? _activeAccount['account_no'] ?? 'N/A').toString();
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'statement_${accountNo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
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

      final String accountNo = (_activeAccount['accNo'] ?? _activeAccount['account_no'] ?? 'N/A').toString();
      final fileName = 'statement_${accountNo}_${DateTime.now().millisecondsSinceEpoch}.pdf';

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
    final accentColor = _getAccentColor();
    final bool isFilteredAtAll = _selectedPreset != null || _fromDateVal.isNotEmpty || _toDateVal.isNotEmpty;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Account Statement',
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
          onRefresh: _loadLedger,
          color: const Color(0xFF2563EB),
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            physics: _isDraggingCard ? const NeverScrollableScrollPhysics() : null,
            children: [
              // Account Card Header (Swipe Deck)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: SizedBox(
                  height: 190,
                  child: ClipRRect(
                    clipBehavior: Clip.none,
                    child: _accountsList.length <= 1
                        ? _buildCardItem(context, _accountsList.first, isTopCard: true)
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              double pageWidth = constraints.maxWidth;
                              
                              int nextPageIndex = _dragOffset < 0
                                  ? (_currentIndex + 1) % _accountsList.length
                                  : (_currentIndex - 1 + _accountsList.length) % _accountsList.length;

                              double progress = (pageWidth > 0) ? (_dragOffset.abs() / pageWidth).clamp(0.0, 1.0) : 0.0;
                              double scale = 0.95 + progress * 0.05;

                              final Matrix4 bottomMatrix = Matrix4.identity()
                                ..scaleByDouble(scale, scale, 1.0, 1.0);

                              final Matrix4 topMatrix = Matrix4.identity()
                                ..translateByDouble(_dragOffset, 0.0, 0.0, 1.0);

                              return Listener(
                                onPointerDown: (event) {
                                  if (_isAnimating) {
                                    setState(() {
                                      _completeAnimationInstantly();
                                    });
                                  }
                                },
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onHorizontalDragStart: (details) {
                                    setState(() {
                                      _isDraggingCard = true;
                                    });
                                    _startPointerPos = details.globalPosition;
                                    _dragStartOffset = _dragOffset;
                                    _isPointerDragging = true;
                                  },
                                  onHorizontalDragUpdate: (details) {
                                    if (_isPointerDragging && _startPointerPos != null) {
                                      final delta = details.globalPosition - _startPointerPos!;
                                      setState(() {
                                        _dragOffset = _dragStartOffset + delta.dx;
                                      });
                                    }
                                  },
                                  onHorizontalDragEnd: (details) {
                                    _handleDragEnd(details.primaryVelocity ?? 0.0);
                                  },
                                  onHorizontalDragCancel: () {
                                    _handleDragCancel();
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Bottom Card
                                      Positioned.fill(
                                        child: Transform(
                                          transform: bottomMatrix,
                                          alignment: Alignment.center,
                                          child: IgnorePointer(
                                            child: _buildCardItem(context, _accountsList[nextPageIndex]),
                                          ),
                                        ),
                                      ),
                                      // Top Card
                                      Positioned.fill(
                                        child: Transform(
                                          transform: topMatrix,
                                          alignment: Alignment.center,
                                          child: _buildCardItem(context, _accountsList[_currentIndex], isTopCard: true),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),

              // Dots indicator
              if (_accountsList.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_accountsList.length, (index) {
                    double difference = index - _currentPage;
                    double activeRatio = (1.0 - difference.abs().clamp(0.0, 1.0));
                    double width = 6.0 + (14.0 * activeRatio);

                    final card = _accountsList[index];
                    final type = card['type'] as String?;
                    Color cardAccentColor;
                    if (type == 'savings') {
                      cardAccentColor = const Color(0xFF6366F1);
                    } else if (type == 'shares') {
                      cardAccentColor = const Color(0xFF10B981);
                    } else if (type == 'loans') {
                      cardAccentColor = const Color(0xFFF43F5E);
                    } else {
                      cardAccentColor = const Color(0xFF2563EB);
                    }

                    final inactiveColor = isDarkMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.15);
                    final dotColor = Color.lerp(inactiveColor, cardAccentColor, activeRatio) ?? cardAccentColor;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: dotColor,
                      ),
                    );
                  }),
                ),
              ],
              
              const SizedBox(height: 16),

              // Horizontal Presets & Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  children: [
                    _buildPresetChip('7_days', '7 Days', accentColor, isDarkMode),
                    const SizedBox(width: 8),
                    _buildPresetChip('15_days', '15 Days', accentColor, isDarkMode),
                    const SizedBox(width: 8),
                    _buildPresetChip('1_month', '1 Month', accentColor, isDarkMode),
                    const SizedBox(width: 8),
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

  Widget _buildCardItem(BuildContext context, Map<String, dynamic> cardData, {bool isTopCard = false}) {
    final acc = cardData['raw'];
    final type = cardData['type'];
    final double rawBalance = (acc['balance'] ?? 0.0).toDouble();
    final balance = 'Rs. ${_formatAmount(rawBalance)}';
    final accountNo = acc['accNo'] ?? acc['account_no'] ?? 'N/A';
    final title = acc['name'] ?? 'Account';

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CooperativeAccountCard(
      isOverview: false,
      accountType: type,
      title: title,
      balance: balance,
      accountNo: accountNo,
      interestRate: acc['interest_rate'],
      shareCount: acc['share_count'],
      maturityDate: acc['maturity_date'],
      showBalance: true,
      isDarkMode: isDarkMode,
      showArrow: false,
      heroTag: isTopCard ? widget.heroTag : null,
    );
  }

  Widget _buildMainContent(bool isDarkMode, Color accentColor) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ),
      );
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: _buildErrorView(isDarkMode),
      );
    }

    if (_ledgerItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 40.0),
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
              'No transactions found.',
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedPreset != null || _fromDateVal.isNotEmpty || _toDateVal.isNotEmpty
                  ? 'Try broadening your filter parameters.'
                  : 'This account has no recent activity.',
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

    String listTitle = 'Showing last 20';
    if (_selectedPreset != null) {
      if (_selectedPreset == '7_days') listTitle = 'Last 7 Days';
      if (_selectedPreset == '15_days') listTitle = 'Last 15 Days';
      if (_selectedPreset == '1_month') listTitle = 'Last Month';
    } else if (_fromDateVal.isNotEmpty || _toDateVal.isNotEmpty) {
      listTitle = 'Filtered Range';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRANSACTION HISTORY'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                ),
              ),
              Text(
                listTitle,
                style: TextStyle(
                  fontSize: 11,
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
              final double balance = (tx['balance'] ?? 0.0).toDouble();
              
              final String amountStr = '${isCredit ? "+" : "-"} Rs. ${_formatAmount(amount)}';
              final String balanceStr = 'Bal: Rs. ${_formatAmount(balance)}';
              
              final String desc = tx['desc'] ?? tx['description'] ?? 'Transaction';
              final String nepaliDate = tx['nepaliDate'] ?? tx['date'] ?? '';
              final String refNo = tx['refNo'] ?? tx['reference_number'] ?? '';

              return GestureDetector(
                onTap: () {
                  final String accNo = (_activeAccount['accNo'] ?? _activeAccount['account_no'] ?? 'N/A').toString();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionReceiptPage(
                        transaction: Map<String, dynamic>.from(tx),
                        accountType: _activeType,
                        accountNo: accNo,
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
                            Text(
                              nepaliDate,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : const Color(0xFF1E293B),
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
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              balanceStr,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  fontSize: 10,
                                ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, val, child) {
              return Transform.scale(
                scale: val,
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isDarkMode 
                      ? [const Color(0xFFEF4444).withValues(alpha: 0.2), const Color(0xFFF87171).withValues(alpha: 0.05)]
                      : [const Color(0xFFFEE2E2), const Color(0xFFFEF2F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 50,
                    color: isDarkMode ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Connection Failed'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'We had trouble communicating with the cooperative servers. Please check your internet connection.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _loadLedger,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Try Again'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
