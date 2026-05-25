import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';

class TransactionReceiptPage extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final String accountType;
  final String accountNo;

  const TransactionReceiptPage({
    super.key,
    required this.transaction,
    required this.accountType,
    required this.accountNo,
  });

  @override
  State<TransactionReceiptPage> createState() => _TransactionReceiptPageState();
}

class _TransactionReceiptPageState extends State<TransactionReceiptPage> {
  final GlobalKey _receiptBoundaryKey = GlobalKey();
  bool _isSavingPng = false;
  bool _isSavingPdf = false;
  bool _isPrinting = false;

  String _formatAmount(double amount) {
    final str = amount.toStringAsFixed(2);
    final parts = str.split('.');
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    parts[0] = parts[0].replaceAllMapped(reg, (Match m) => '${m[1]},');
    return parts.join('.');
  }

  Future<void> _saveAsPng() async {
    if (_isSavingPng) return;
    setState(() {
      _isSavingPng = true;
    });

    try {
      final RenderRepaintBoundary boundary = _receiptBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await Future.delayed(const Duration(milliseconds: 150));
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to serialize image bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(tempFilePath);
      await file.writeAsBytes(pngBytes);

      if (Platform.isAndroid) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          await Gal.requestAccess();
        }
      }

      await Gal.putImage(tempFilePath);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Receipt image saved to gallery successfully!'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save receipt: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPng = false;
        });
      }
    }
  }

  Future<Uint8List> _generateReceiptPdf() async {
    final pdf = pw.Document();
    
    final tx = widget.transaction;
    final String typeStr = (tx['type'] ?? '').toString().toUpperCase();
    final bool isCredit = typeStr == 'CR' || typeStr == 'CREDIT';
    final double amount = (tx['amount'] ?? 0.0).toDouble();
    final String desc = tx['desc'] ?? tx['description'] ?? 'Transaction';
    final String nepaliDate = tx['nepaliDate'] ?? tx['date'] ?? '';
    final String refNo = tx['refNo'] ?? tx['reference_number'] ?? 'N/A';
    final double? balance = tx['balance'] != null ? (tx['balance'] as num).toDouble() : null;

    final profile = AuthStore().profile;
    final coop = AuthStore().selectedCooperative;
    final coopName = coop?['name'] ?? 'Bright Saving & Credit Co-operative';
    final coopAddress = coop?['address'] ?? 'Kathmandu, Nepal';
    final memberName = profile?['member_name'] ?? 'Sahakari User';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                coopName.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                coopAddress,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 16),
                child: pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              ),

              pw.Text(
                'TRANSACTION RECEIPT',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Text(
                '${isCredit ? "+" : "-"} Rs. ${_formatAmount(amount)}',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: isCredit ? PdfColors.green800 : PdfColors.red800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Status: Successful',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  _pdfRow('Member Name', memberName),
                  _pdfRow('Account Number', widget.accountNo),
                  _pdfRow('Account Type', widget.accountType.toUpperCase()),
                  _pdfRow('Description', desc),
                  _pdfRow('Date (BS)', nepaliDate),
                  _pdfRow('Transaction ID', refNo),
                  if (balance != null)
                    _pdfRow('Ending Balance', 'Rs. ${_formatAmount(balance)}'),
                ],
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 24),
                child: pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              ),

              pw.Column(
                children: [
                  pw.Container(
                    height: 28,
                    width: 200,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(width: 1, color: PdfColors.black),
                        bottom: pw.BorderSide(width: 1, color: PdfColors.black),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '||||| | |||| || ||| |||| | ||||| |',
                        style: const pw.TextStyle(fontSize: 14, letterSpacing: 2),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    refNo,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.TableRow _pdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 8.5)),
        ),
      ],
    );
  }

  Future<void> _downloadAsPdf() async {
    if (_isSavingPdf) return;
    setState(() {
      _isSavingPdf = true;
    });

    try {
      final bytes = await _generateReceiptPdf();
      final tx = widget.transaction;
      final String refNo = tx['refNo'] ?? tx['reference_number'] ?? 'N/A';
      
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'receipt_$refNo.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPdf = false;
        });
      }
    }
  }

  Future<void> _printReceipt() async {
    if (_isPrinting) return;
    setState(() {
      _isPrinting = true;
    });

    try {
      final bytes = await _generateReceiptPdf();
      final tx = widget.transaction;
      final String refNo = tx['refNo'] ?? tx['reference_number'] ?? 'N/A';
      
      await Printing.layoutPdf(
        onLayout: (format) => bytes,
        name: 'receipt_$refNo',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print receipt: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final tx = widget.transaction;
    final String typeStr = (tx['type'] ?? '').toString().toUpperCase();
    final bool isCredit = typeStr == 'CR' || typeStr == 'CREDIT';
    final double amount = (tx['amount'] ?? 0.0).toDouble();
    final String desc = tx['desc'] ?? tx['description'] ?? 'Transaction';
    final String nepaliDate = tx['nepaliDate'] ?? tx['date'] ?? '';
    final String refNo = tx['refNo'] ?? tx['reference_number'] ?? 'N/A';
    final double? balance = tx['balance'] != null ? (tx['balance'] as num).toDouble() : null;

    final accentColor = isCredit ? const Color(0xFF10B981) : const Color(0xFF2563EB);
    final profile = AuthStore().profile;
    final coop = AuthStore().selectedCooperative;
    final coopName = coop?['name'] ?? 'Bright Saving & Credit Co-operative';
    final memberName = profile?['member_name'] ?? 'Sahakari User';

    final receiptBgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction Receipt'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable full-width receipt boundary
            Expanded(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _receiptBoundaryKey,
                  child: Container(
                    width: double.infinity,
                    color: receiptBgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top accent line
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Cooperative info
                        Text(
                          coopName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          coop?['address'] ?? 'Kathmandu, Nepal',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Divider(height: 1, thickness: 1, color: Color(0x1F64748B)),
                        ),

                        // Success checkmark badge
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: accentColor,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'TRANSACTION SUCCESSFUL'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Large Amount text
                        Text(
                          '${isCredit ? "+" : "-"} Rs. ${_formatAmount(amount)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Details rows
                        _buildDetailRow('Member Name'.tr, memberName, isDarkMode),
                        _buildDetailRow('Account Number'.tr, widget.accountNo, isDarkMode),
                        _buildDetailRow('Account Type'.tr, widget.accountType.toUpperCase(), isDarkMode),
                        _buildDetailRow('Description'.tr, desc, isDarkMode),
                        _buildDetailRow('Date (BS)'.tr, nepaliDate, isDarkMode),
                        _buildDetailRow('Transaction ID'.tr, refNo, isDarkMode),
                        if (balance != null)
                          _buildDetailRow('Ending Balance'.tr, 'Rs. ${_formatAmount(balance)}', isDarkMode),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Divider(height: 1, thickness: 1, color: Color(0x1F64748B)),
                        ),

                        // Barcode
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                28,
                                (index) => Container(
                                  width: index % 3 == 0
                                      ? 3
                                      : index % 2 == 0
                                          ? 1.5
                                          : 4,
                                  height: 35,
                                  color: isDarkMode ? Colors.white54 : Colors.black87,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              refNo,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                                color: Color(0xFF64748B),
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Action Controls Container
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Save PNG Button
                  ElevatedButton(
                    onPressed: _isSavingPng ? null : _saveAsPng,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isSavingPng
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.photo_library_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _isSavingPng ? 'Saving PNG...'.tr : 'Save to Gallery (PNG)'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Row of Download PDF & Print
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSavingPdf ? null : _downloadAsPdf,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode ? Colors.white70 : const Color(0xFF1E293B),
                            side: BorderSide(
                              color: isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
                            ),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isSavingPdf
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                    )
                                  : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _isSavingPdf ? 'PDF...'.tr : 'Download PDF'.tr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isPrinting ? null : _printReceipt,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode ? Colors.white70 : const Color(0xFF1E293B),
                            side: BorderSide(
                              color: isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
                            ),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isPrinting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                    )
                                  : const Icon(Icons.print_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _isPrinting ? 'Printing...'.tr : 'Print'.tr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  // Back / Close Link Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Statement'.tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
