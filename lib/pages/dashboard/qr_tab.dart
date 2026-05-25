import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/translation_service.dart';
import '../../widgets/cooperative_qr_card.dart';

class QRTab extends StatefulWidget {
  final bool isDarkMode;

  const QRTab({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<QRTab> createState() => QRTabState();
}

class QRTabState extends State<QRTab> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _isScanning = false;
  bool _torchEnabled = false;
  bool _hasResult = false;
  String? _scannedValue;
  String? _scannedType;
  bool _cameraError = false;
  String _cameraErrorMessage = '';
  bool _isActive = false;

  bool get _isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get hasResult => _hasResult;
  void resetScanner() => _resetScanner();

  // Custom QR Mode
  bool _customQrMode = false;
  String _customQrLabel = 'Cooperative Payment QR';
  final GlobalKey _customQrBoundaryKey = GlobalKey();
  bool _isSavingCustom = false;
  TextEditingController? _customLabelController;


  late AnimationController _overlayAnimationController;
  List<Offset>? _scannedCorners;
  Size? _scannedFrameSize;

  @override
  void initState() {
    super.initState();
    if (_isSupported) {
      WidgetsBinding.instance.addObserver(this);
    }
    _overlayAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        setState(() {});
      });
  }

  /// Call this from outside when the tab becomes visible
  Future<void> startCamera() async {
    if (!_isSupported) return;
    if (_isActive) return;

    if (mounted) {
      setState(() {
        _isActive = true;
      });
    }

    // If we have scanned a result and are showing the result view, do NOT spin up camera
    if (_hasResult) {
      return;
    }

    await _startCameraController();
  }

  Future<void> _startCameraController() async {
    // Check camera permission first explicitly
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _cameraError = true;
          _cameraErrorMessage = 'Camera permission is required to scan QR codes.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isScanning = true;
        _cameraError = false;
        _cameraErrorMessage = '';
        
        // Initialize the controller safely here, right when we are ready to spin up the camera
        _controller = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          torchEnabled: false,
          autoStart: true,
        );
      });
    }
  }

  /// Call this from outside when the tab becomes hidden
  void stopCamera() {
    if (!_isSupported) return;
    if (!_isActive) return;
    
    if (_controller != null) {
      try {
        _controller?.stop();
      } catch (_) {}
      try {
        _controller?.dispose(); // Clean up native resources completely
      } catch (_) {}
    }
    
    if (mounted) {
      setState(() {
        _isActive = false;
        _isScanning = false;
        _controller = null; // Reset instance to avoid operating on a stale runtime pointer
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isSupported) return;
    if (!_isActive || _controller == null) return;
    
    if (state == AppLifecycleState.paused) {
      try {
        _controller?.stop();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed && _isScanning && !_hasResult) {
      // Safely access the value property now that initialization is gated
      if (_controller != null && !_controller!.value.isRunning) {
        try {
          _controller?.start();
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    if (_isSupported) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _overlayAnimationController.dispose();
    _controller?.dispose();
    _controller = null;
    _customLabelController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasResult) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    // Single-scan mode (default)
    final barcode = barcodes.first;
    final value = barcode.rawValue ?? '';
    if (value.isEmpty) return;

    setState(() {
      _hasResult = true;
    });

    HapticFeedback.mediumImpact();

    if (barcode.corners.isNotEmpty) {
      setState(() {
        _scannedCorners = barcode.corners;
        _scannedFrameSize = capture.size;
      });
      _overlayAnimationController.forward(from: 0.0).then((_) {
        _processScanResult(value);
      });
    } else {
      _processScanResult(value);
    }
  }

  void _processScanResult(String value) {
    if (!mounted) return;
    setState(() {
      _scannedValue = value;
      _scannedType = _detectContentType(value);
      _isScanning = false;
      _scannedCorners = null;
      _scannedFrameSize = null;
      if (_customQrMode) {
        _customQrLabel = '';
        _customLabelController = TextEditingController(text: _customQrLabel);
      }
    });

    _controller?.stop();
    _controller?.dispose();
    _controller = null;
  }

  String _detectContentType(String value) {
    final lower = value.toLowerCase().trim();

    if (lower.startsWith('http://') || lower.startsWith('https://')) return 'URL';
    if (lower.startsWith('wifi:')) return 'WiFi';
    if (lower.startsWith('tel:') || RegExp(r'^\+?\d{7,15}$').hasMatch(lower)) return 'Phone';
    if (lower.startsWith('mailto:') || RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(lower)) return 'Email';
    if (lower.startsWith('smsto:') || lower.startsWith('sms:')) return 'SMS';
    if (lower.startsWith('geo:') || lower.contains(',') && RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(lower.replaceAll(' ', ''))) return 'Location';
    if (lower.startsWith('begin:vcard')) return 'Contact';
    if (lower.startsWith('begin:vevent')) return 'Event';
    if (lower.startsWith('upi://')) return 'UPI Payment';

    return 'Text';
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'URL': return Icons.language_rounded;
      case 'WiFi': return Icons.wifi_rounded;
      case 'Phone': return Icons.phone_rounded;
      case 'Email': return Icons.email_rounded;
      case 'SMS': return Icons.sms_rounded;
      case 'Location': return Icons.location_on_rounded;
      case 'Contact': return Icons.contact_phone_rounded;
      case 'Event': return Icons.event_rounded;
      case 'UPI Payment': return Icons.payment_rounded;
      default: return Icons.text_fields_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'URL': return const Color(0xFF2563EB);
      case 'WiFi': return const Color(0xFF9333EA);
      case 'Phone': return const Color(0xFF10B981);
      case 'Email': return const Color(0xFFEA580C);
      case 'SMS': return const Color(0xFF0D9488);
      case 'Location': return const Color(0xFFEF4444);
      case 'Contact': return const Color(0xFF3B82F6);
      case 'Event': return const Color(0xFFF59E0B);
      case 'UPI Payment': return const Color(0xFF059669);
      default: return const Color(0xFF64748B);
    }
  }

  Map<String, String>? _parseWifi(String value) {
    final typeMatch = RegExp(r'T:([^;]*)').firstMatch(value);
    final ssidMatch = RegExp(r'S:([^;]*)').firstMatch(value);
    final passMatch = RegExp(r'P:([^;]*)').firstMatch(value);
    final hiddenMatch = RegExp(r'H:([^;]*)').firstMatch(value);

    if (ssidMatch == null) return null;
    return {
      'type': typeMatch?.group(1) ?? 'WPA',
      'ssid': ssidMatch.group(1) ?? '',
      'password': passMatch?.group(1) ?? '',
      'hidden': hiddenMatch?.group(1) ?? 'false',
    };
  }

  void _resetScanner() {
    _customLabelController?.dispose();
    _customLabelController = null;

    if (_controller != null) {
      try {
        _controller?.stop();
      } catch (_) {}
      try {
        _controller?.dispose();
      } catch (_) {}
      _controller = null;
    }

    setState(() {
      _hasResult = false;
      _scannedValue = null;
      _scannedType = null;
      _torchEnabled = false;
      _cameraError = false;
      _scannedCorners = null;
      _scannedFrameSize = null;
    });
    
    if (_isActive) {
      _startCameraController();
    }
  }

  void _toggleTorch() async {
    try {
      await _controller?.toggleTorch();
      setState(() {
        _torchEnabled = !_torchEnabled;
      });
    } catch (_) {}
  }

  void _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final file = File(image.path);
      final controller = _controller;
      if (controller == null) return;

      final result = await controller.analyzeImage(file.path);

      if (result != null && result.barcodes.isNotEmpty) {
        final barcode = result.barcodes.first;
        final value = barcode.rawValue ?? '';
        if (value.isNotEmpty) {
          HapticFeedback.mediumImpact();
          setState(() {
            _hasResult = true;
            _scannedValue = value;
            _scannedType = _detectContentType(value);
            _isScanning = false;
          });
          controller.stop();
          controller.dispose();
          _controller = null;
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No QR code or barcode found in the image.'.tr),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  void _copyToClipboard() {
    if (_scannedValue == null) return;
    Clipboard.setData(ClipboardData(text: _scannedValue!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    if (!_isSupported) {
      return _buildUnsupportedPlatformView(isDark);
    }

    if (_hasResult && _scannedValue != null) {
      final resultView = _customQrMode ? _buildCustomQrResultView(isDark) : _buildResultView(isDark);
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _resetScanner();
          }
        },
        child: resultView,
      );
    }

    // If not active yet, show a placeholder
    if (!_isActive || _controller == null) {
      return _buildPlaceholder(isDark);
    }

    return _buildScannerView(isDark);
  }

  Widget _buildPlaceholder(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 64,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan QR'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to activate camera',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView(bool isDark) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Camera preview
              if (!_cameraError && _controller != null)
                MobileScanner(
                  controller: _controller!,
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _cameraError = true;
                          _cameraErrorMessage = error.errorDetails?.message ?? 'Camera error';
                        });
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),

              // Camera error state
              if (_cameraError)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_rounded, size: 64, color: Color(0xFF64748B)),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Unavailable',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _cameraErrorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                ),

              // Overlay with cutout (static scanner viewfinder OR animated glowing detection overlay)
              if (!_cameraError)
                _scannedCorners != null && _scannedFrameSize != null
                    ? Positioned.fill(
                        child: CustomPaint(
                          painter: QRScannerOverlayPainter(
                            corners: _scannedCorners!,
                            frameSize: _scannedFrameSize!,
                            animationProgress: _overlayAnimationController.value,
                          ),
                        ),
                      )
                    : _buildScanOverlay(),

              // Top action bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Scan QR'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Custom QR Mode toggle
                          _buildActionButton(
                            icon: _customQrMode ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                            onTap: () {
                              setState(() {
                                _customQrMode = !_customQrMode;
                              });
                            },
                            color: _customQrMode ? const Color(0xFF10B981) : Colors.white,
                          ),
                          const SizedBox(width: 10),
                          // Torch toggle
                          _buildActionButton(
                            icon: _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            onTap: _toggleTorch,
                            color: _torchEnabled ? const Color(0xFFFFA825) : Colors.white,
                          ),
                          const SizedBox(width: 10),
                          // Gallery picker
                          _buildActionButton(
                            icon: Icons.photo_library_rounded,
                            onTap: _pickImage,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom hint
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _customQrMode
                          ? 'Scan & Convert to Custom QR is active'.tr
                          : 'Point camera at a QR code or barcode',
                      style: TextStyle(
                        color: _customQrMode
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - scanSize) / 2;
        final top = (constraints.maxHeight - scanSize) / 2 - 30;

        return Stack(
          children: [
            // Dark mask around scanner area
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Corner accents
            Positioned(
              left: left,
              top: top,
              child: _buildCorner(Alignment.topLeft),
            ),
            Positioned(
              right: left,
              top: top,
              child: _buildCorner(Alignment.topRight),
            ),
            Positioned(
              left: left,
              bottom: constraints.maxHeight - top - scanSize,
              child: _buildCorner(Alignment.bottomLeft),
            ),
            Positioned(
              right: left,
              bottom: constraints.maxHeight - top - scanSize,
              child: _buildCorner(Alignment.bottomRight),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(Alignment alignment) {
    const size = 28.0;
    const thickness = 4.0;
    const color = Color(0xFF2563EB);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(alignment, thickness, color),
      ),
    );
  }

  Widget _buildResultView(bool isDark) {
    final type = _scannedType ?? 'Text';
    final value = _scannedValue ?? '';
    final typeIcon = _getTypeIcon(type);
    final typeColor = _getTypeColor(type);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: _resetScanner,
        ) : null,
        title: Text(
          'Scan Result'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            ),
            onPressed: _resetScanner,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            // Type badge
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: typeColor.withValues(alpha: 0.1),
                  border: Border.all(color: typeColor.withValues(alpha: 0.2), width: 2),
                ),
                child: Icon(typeIcon, color: typeColor, size: 42),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Content card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.data_object_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'SCANNED DATA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      height: 1.6,
                    ),
                  ),

                  // WiFi details
                  if (type == 'WiFi') ..._buildWifiDetails(value, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildResultAction(
                    icon: Icons.copy_rounded,
                    label: 'Copy'.tr,
                    color: const Color(0xFF2563EB),
                    isDark: isDark,
                    onTap: _copyToClipboard,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResultAction(
                    icon: Icons.share_rounded,
                    label: 'Share'.tr,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share functionality coming soon.'), backgroundColor: Color(0xFF64748B)),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Full width scan again button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _resetScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                label: Text(
                  'Scan Again'.tr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomQrResultView(bool isDark) {
    final value = _scannedValue ?? '';
    final themeColor = const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: _resetScanner,
        ) : null,
        title: Text(
          'Custom QR Generated'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Custom QR Card Preview
            Center(
              child: CooperativeQrCard(
                boundaryKey: _customQrBoundaryKey,
                data: value,
                label: _customQrLabel,
                themeColor: themeColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 24),

            // Card details & Label editor
            Text(
              'QR DETAILS'.tr,
              style: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Description Label Input card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: TextField(
                controller: _customLabelController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onChanged: (val) {
                  setState(() {
                    _customQrLabel = val;
                  });
                },
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Text Below QR Code'.tr,
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.label_outline_rounded, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Scanned payload card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, color: Color(0xFF64748B), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'SCANNED PAYLOAD'.tr,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Row: Download & Scan Again
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSavingCustom ? null : _downloadCustomQrCode,
                      icon: _isSavingCustom
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isSavingCustom ? 'Saving...'.tr : 'Download'.tr,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: themeColor.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _resetScanner,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      label: Text(
                        'Scan Again'.tr,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCustomQrCode() async {
    if (_isSavingCustom) return;
    setState(() {
      _isSavingCustom = true;
    });

    try {
      final RenderRepaintBoundary boundary = _customQrBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await Future.delayed(const Duration(milliseconds: 100));
      final ui.Image image = await boundary.toImage(pixelRatio: 4.0); // 4x pixel density for extremely high quality
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate image bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/custom_sahakari_qr_${DateTime.now().millisecondsSinceEpoch}.png';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Custom QR Code saved to gallery successfully!'.tr)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save QR Code: ${e.toString()}'.tr),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingCustom = false;
        });
      }
    }
  }

  List<Widget> _buildWifiDetails(String value, bool isDark) {
    final wifi = _parseWifi(value);
    if (wifi == null) return [];

    return [
      const SizedBox(height: 16),
      Container(
        height: 1,
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
      ),
      const SizedBox(height: 16),
      _wifiDetailRow('Network (SSID)', wifi['ssid'] ?? '', isDark),
      _wifiDetailRow('Security', wifi['type'] ?? 'WPA', isDark),
      if ((wifi['password'] ?? '').isNotEmpty)
        _wifiDetailRow('Password', wifi['password']!, isDark),
      _wifiDetailRow('Hidden', wifi['hidden'] == 'true' ? 'Yes' : 'No', isDark),
    ];
  }

  Widget _wifiDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedPlatformView(bool isDark) {
    final bgColor = isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF020617), const Color(0xFF0B1329)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEEF2F6)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Icon Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [Colors.white, const Color(0xFFE2E8F0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.no_photography_rounded,
                      size: 64,
                      color: Colors.white, // needed for ShaderMask to work
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Platform Not Supported'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'QR Scanning is only available on iOS and Android devices. Please open this app on a supported mobile device to scan QR codes.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: subTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Platform status card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEVICE COMPATIBILITY'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: subTextColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPlatformStatusRow('Android', true, isDark),
                      const SizedBox(height: 12),
                      _buildPlatformStatusRow('iOS', true, isDark),
                      const SizedBox(height: 12),
                      _buildPlatformStatusRow('Web & Desktop Platforms', false, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformStatusRow(String platform, bool isSupported, bool isDark) {
    final statusColor = isSupported ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final statusBgColor = statusColor.withValues(alpha: isDark ? 0.12 : 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: statusBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSupported ? Icons.check_rounded : Icons.close_rounded,
            size: 14,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          platform,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const Spacer(),
        Text(
          isSupported ? 'Supported'.tr : 'Not Supported'.tr,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Alignment alignment;
  final double thickness;
  final Color color;

  _CornerPainter(this.alignment, this.thickness, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const len = 20.0;

    if (alignment == Alignment.topLeft) {
      path.moveTo(0, len);
      path.lineTo(0, 0);
      path.lineTo(len, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(size.width - len, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, len);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, size.height - len);
      path.lineTo(0, size.height);
      path.lineTo(len, size.height);
    } else if (alignment == Alignment.bottomRight) {
      path.moveTo(size.width - len, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - len);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class QRScannerOverlayPainter extends CustomPainter {
  final List<Offset> corners;
  final Size frameSize;
  final double animationProgress;

  QRScannerOverlayPainter({
    required this.corners,
    required this.frameSize,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length < 4 || frameSize.width == 0 || frameSize.height == 0) return;

    // ML Kit provides cornerPoints already rotated to the display orientation.
    // However, capture.size comes from mediaImage.width/height which is the
    // raw sensor resolution (typically landscape, e.g. 640x480).
    // The MobileScanner widget displays the preview using FittedBox(BoxFit.cover)
    // with the already-rotated size. So we must:
    // 1. Swap frameSize to portrait if sensor is landscape but widget is portrait
    // 2. Apply BoxFit.cover scaling (same as the widget)
    // 3. Do NOT rotate the corners — they're already correct

    final bool isWidgetPortrait = size.height > size.width;
    final bool isFrameLandscape = frameSize.width > frameSize.height;

    // Effective frame size in display orientation
    final Size effectiveFrame = (isWidgetPortrait && isFrameLandscape)
        ? Size(frameSize.height, frameSize.width)  // swap to portrait
        : frameSize;

    // BoxFit.cover: scale to fill the widget, cropping the excess
    final double scaleX = size.width / effectiveFrame.width;
    final double scaleY = size.height / effectiveFrame.height;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    // Centering offset (one axis will be cropped, the other fits exactly)
    final double offsetX = (size.width - effectiveFrame.width * scale) / 2;
    final double offsetY = (size.height - effectiveFrame.height * scale) / 2;

    final List<Offset> projectedCorners = corners.map((pt) {
      return Offset(pt.dx * scale + offsetX, pt.dy * scale + offsetY);
    }).toList();

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (final pt in projectedCorners) {
      if (pt.dx < minX) minX = pt.dx;
      if (pt.dx > maxX) maxX = pt.dx;
      if (pt.dy < minY) minY = pt.dy;
      if (pt.dy > maxY) maxY = pt.dy;
    }

    final rect = Rect.fromLTRB(minX, minY, maxX, maxY);

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6 * (1.0 - animationProgress))
      ..style = PaintingStyle.fill;
      
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    final double pulseScale = 1.0 + 0.08 * animationProgress;
    final center = rect.center;
    final rotatedRect = Rect.fromCenter(
      center: center,
      width: rect.width * pulseScale,
      height: rect.height * pulseScale,
    );

    final boxPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 1.0 - animationProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
      
    final rrect = RRect.fromRectAndRadius(rotatedRect, const Radius.circular(12));
    canvas.drawRRect(rrect, boxPaint);

    final bracketPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 1.0 - animationProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final double length = (rect.width * 0.2).clamp(15.0, 30.0);
    canvas.drawPath(
      Path()
        ..moveTo(rotatedRect.left, rotatedRect.top + length)
        ..lineTo(rotatedRect.left, rotatedRect.top)
        ..lineTo(rotatedRect.left + length, rotatedRect.top),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rotatedRect.right - length, rotatedRect.top)
        ..lineTo(rotatedRect.right, rotatedRect.top)
        ..lineTo(rotatedRect.right, rotatedRect.top + length),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rotatedRect.left, rotatedRect.bottom - length)
        ..lineTo(rotatedRect.left, rotatedRect.bottom)
        ..lineTo(rotatedRect.left + length, rotatedRect.bottom),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rotatedRect.right - length, rotatedRect.bottom)
        ..lineTo(rotatedRect.right, rotatedRect.bottom)
        ..lineTo(rotatedRect.right, rotatedRect.bottom - length),
      bracketPaint,
    );

    final double scanLineY = rotatedRect.top + (rotatedRect.height * animationProgress);
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.0),
          const Color(0xFF10B981).withValues(alpha: 0.8 * (1.0 - animationProgress)),
          const Color(0xFF10B981).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(rotatedRect.left, scanLineY - 10, rotatedRect.right, scanLineY + 10))
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(rotatedRect.left + 4, scanLineY - 8, rotatedRect.right - 4, scanLineY + 8),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant QRScannerOverlayPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.corners != corners ||
        oldDelegate.frameSize != frameSize;
  }
}
