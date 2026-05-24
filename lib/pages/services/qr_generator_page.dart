import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/translation_service.dart';
import '../../widgets/cooperative_qr_card.dart';

class QRGeneratorPage extends StatefulWidget {
  final bool isDarkMode;
  final String? initialData;

  const QRGeneratorPage({
    super.key,
    required this.isDarkMode,
    this.initialData,
  });

  @override
  State<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final GlobalKey _boundaryKey = GlobalKey();

  // Custom QR type configuration
  String _selectedType = 'URL';
  String _qrData = 'https://brightsahakari.org.np/pay';

  // Controllers
  late TextEditingController _labelController;
  late TextEditingController _urlController;
  late TextEditingController _textController;
  late TextEditingController _wifiSsidController;
  late TextEditingController _wifiPasswordController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _phoneController;
  late TextEditingController _smsPhoneController;
  late TextEditingController _smsMessageController;

  String _wifiSecurity = 'WPA';
  Color _themeColor = const Color(0xFF2563EB); // Default Blue
  bool _isSaving = false;
  bool _isFetchingLocation = false;

  final List<Color> _colorOptions = [
    const Color(0xFF2563EB), // Blue
    const Color(0xFF4F46E5), // Indigo
    const Color(0xFF0D9488), // Teal
    const Color(0xFF10B981), // Emerald
    const Color(0xFFE11D48), // Crimson
    const Color(0xFFD97706), // Amber
  ];

  final List<Map<String, dynamic>> _types = [
    {'name': 'URL', 'icon': Icons.link_rounded},
    {'name': 'Text', 'icon': Icons.text_fields_rounded},
    {'name': 'WiFi', 'icon': Icons.wifi_rounded},
    {'name': 'Location', 'icon': Icons.location_on_rounded},
    {'name': 'Phone', 'icon': Icons.phone_rounded},
    {'name': 'SMS', 'icon': Icons.sms_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: '');
    _urlController = TextEditingController(text: widget.initialData ?? 'https://brightsahakari.org.np/pay');
    _textController = TextEditingController(text: '');
    _wifiSsidController = TextEditingController(text: '');
    _wifiPasswordController = TextEditingController(text: '');
    _latController = TextEditingController(text: '');
    _lngController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: '');
    _smsPhoneController = TextEditingController(text: '');
    _smsMessageController = TextEditingController(text: '');

    // Add listeners to rebuild on text change
    _labelController.addListener(() => setState(() {}));
    _urlController.addListener(_updatePayload);
    _textController.addListener(_updatePayload);
    _wifiSsidController.addListener(_updatePayload);
    _wifiPasswordController.addListener(_updatePayload);
    _latController.addListener(_updatePayload);
    _lngController.addListener(_updatePayload);
    _phoneController.addListener(_updatePayload);
    _smsPhoneController.addListener(_updatePayload);
    _smsMessageController.addListener(_updatePayload);

    _updatePayload();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    _textController.dispose();
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _phoneController.dispose();
    _smsPhoneController.dispose();
    _smsMessageController.dispose();
    super.dispose();
  }

  void _updatePayload() {
    String computed = '';
    switch (_selectedType) {
      case 'URL':
        computed = _urlController.text;
        break;
      case 'Text':
        computed = _textController.text;
        break;
      case 'WiFi':
        final ssid = _wifiSsidController.text;
        final pass = _wifiPasswordController.text;
        final sec = _wifiSecurity == 'None' ? 'nopass' : _wifiSecurity;
        computed = 'WIFI:S:$ssid;T:$sec;P:$pass;;';
        break;
      case 'Location':
        final lat = _latController.text;
        final lng = _lngController.text;
        computed = 'geo:$lat,$lng';
        break;
      case 'Phone':
        computed = 'tel:${_phoneController.text}';
        break;
      case 'SMS':
        computed = 'SMSTO:${_smsPhoneController.text}:${_smsMessageController.text}';
        break;
    }
    setState(() {
      _qrData = computed;
    });
  }

  Future<void> _getCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latController.text = position.latitude.toString();
      _lngController.text = position.longitude.toString();
      _updatePayload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully loaded current location!'.tr),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'.tr),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _downloadQrCode() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await Future.delayed(const Duration(milliseconds: 100));
      final ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to generate image bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/sahakari_qr_${DateTime.now().millisecondsSinceEpoch}.png';
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
                Expanded(
                  child: Text('QR Code saved to gallery successfully!'.tr),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving QR code: $e');
      }
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'QR Generator'.tr,
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
            // Reusable QR Card Preview
            Center(
              child: CooperativeQrCard(
                boundaryKey: _boundaryKey,
                data: _qrData,
                label: _labelController.text,
                themeColor: _themeColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 24),

            // Theme Color Customization Selector
            Text(
              'THEME COLOR'.tr,
              style: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                itemBuilder: (context, index) {
                  final color = _colorOptions[index];
                  final isSelected = color == _themeColor;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _themeColor = color;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // QR Type Selector
            Text(
              'QR CODE TYPE'.tr,
              style: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length,
                itemBuilder: (context, index) {
                  final type = _types[index];
                  final name = type['name'] as String;
                  final icon = type['icon'] as IconData;
                  final isSelected = name == _selectedType;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = name;
                        _updatePayload();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _themeColor
                            : (isDark ? const Color(0xFF0F172A) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _themeColor
                              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name.tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Settings input group
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

            // Dynamic Form Field based on selected type
            _buildTypeSpecificFields(isDark),
            const SizedBox(height: 16),

            // Description Label textfield (Multi-line)
            _buildInputCard(
              isDark: isDark,
              child: TextField(
                controller: _labelController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
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
            const SizedBox(height: 28),

            // Download Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _downloadQrCode,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 22),
                label: Text(
                  _isSaving ? 'Generating...'.tr : 'Download QR Code'.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _themeColor.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificFields(bool isDark) {
    switch (_selectedType) {
      case 'URL':
        return _buildInputCard(
          isDark: isDark,
          child: TextField(
            controller: _urlController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
            decoration: InputDecoration(
              labelText: 'URL Link'.tr,
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF64748B)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      case 'Text':
        return _buildInputCard(
          isDark: isDark,
          child: TextField(
            controller: _textController,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Plain Text'.tr,
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.text_fields_rounded, color: Color(0xFF64748B)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      case 'WiFi':
        return Column(
          children: [
            _buildInputCard(
              isDark: isDark,
              child: TextField(
                controller: _wifiSsidController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'WiFi Network Name (SSID)'.tr,
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.wifi_rounded, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInputCard(
              isDark: isDark,
              child: TextField(
                controller: _wifiPasswordController,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'WiFi Password'.tr,
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SECURITY'.tr,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: ['WPA', 'WEP', 'None'].map((sec) {
                final isSel = _wifiSecurity == sec;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _wifiSecurity = sec;
                      _updatePayload();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? _themeColor : (isDark ? const Color(0xFF0F172A) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel
                            ? _themeColor
                            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                      ),
                    ),
                    child: Text(
                      sec,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      case 'Location':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInputCard(
                    isDark: isDark,
                    child: TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Latitude'.tr,
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        prefixIcon: const Icon(Icons.explore_rounded, color: Color(0xFF64748B)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputCard(
                    isDark: isDark,
                    child: TextField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Longitude'.tr,
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        prefixIcon: const Icon(Icons.explore_rounded, color: Color(0xFF64748B)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                icon: _isFetchingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  _isFetchingLocation ? 'Fetching location...'.tr : 'Get Current Location'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _themeColor,
                  side: BorderSide(color: _themeColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        );
      case 'Phone':
        return _buildInputCard(
          isDark: isDark,
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Phone Number'.tr,
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF64748B)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      case 'SMS':
        return Column(
          children: [
            _buildInputCard(
              isDark: isDark,
              child: TextField(
                controller: _smsPhoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Recipient Phone Number'.tr,
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInputCard(
              isDark: isDark,
              child: TextField(
                controller: _smsMessageController,
                maxLines: 2,
                keyboardType: TextInputType.multiline,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Message Body'.tr,
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.sms_rounded, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInputCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: child,
    );
  }
}
