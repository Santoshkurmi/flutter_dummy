import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import 'activation_page.dart';
import 'device_linking_page.dart';
import 'register_member_page.dart';
import 'login_page.dart';

class StatusCheckPage extends StatefulWidget {
  const StatusCheckPage({super.key});

  @override
  State<StatusCheckPage> createState() => _StatusCheckPageState();
}

class _StatusCheckPageState extends State<StatusCheckPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;

  bool get _isDarkMode => AuthStore().isDarkMode;

  LinearGradient _getGradient(String? gradientClass) {
    switch (gradientClass) {
      case 'bg-blue-600':
        return const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]);
      case 'bg-emerald-600':
        return const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]);
      case 'bg-purple-600':
        return const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF7E22CE)]);
      case 'bg-rose-600':
        return const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE123C)]);
      case 'bg-cyan-600':
        return const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF0E7490)]);
      case 'bg-amber-600':
        return const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)]);
      case 'bg-indigo-600':
        return const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF4338CA)]);
      case 'bg-teal-600':
        return const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]);
      default:
        return const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]);
    }
  }

  @override
  void initState() {
    super.initState();
    _mobileController.text = AuthStore().mobile ?? AuthStore().registeredMobile ?? '';
    _mobileController.addListener(_onMobileChanged);
    AuthStore().addListener(_onStoreChange);
  }

  @override
  void dispose() {
    _mobileController.removeListener(_onMobileChanged);
    _mobileController.dispose();
    AuthStore().removeListener(_onStoreChange);
    super.dispose();
  }

  void _onStoreChange() {
    if (mounted) setState(() {});
  }

  void _onMobileChanged() {
    setState(() {});
  }

  Future<void> _submit() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10) return;
    
    // Reset biometric preferences if logging in/registering with a different phone number
    final store = AuthStore();
    if (store.registeredMobile != mobile || store.mobile != mobile) {
      await store.setBiometricEnabled(false);
      await store.setNeverAskBiometric(false);
      await store.setBiometricType(null);
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final devId = await ApiService.getDeviceId();
      final res = await ApiService().checkStatus(mobile, devId);
      final responseCodeRaw = res['response_code'];
      final int responseCode = responseCodeRaw is int
          ? responseCodeRaw
          : int.tryParse(responseCodeRaw?.toString() ?? '0') ?? 0;
      final String message = res['message'] ?? '';
 
      if (!mounted) return;

      switch (responseCode) {
        case 1: // RESP_SUCCESS (Authenticated / Password required)
          await AuthStore().setRegisteredMobile(mobile);
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(mobileNumber: mobile),
            ),
            (route) => false,
          );
          break;
        case 2: // RESP_ACTIVATION_REQUIRED (Mobile service active but app registration required)
        case 5: // RESP_REGISTRATION_INCOMPLETE (Pending activation pin)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivationPage(mobileNumber: mobile),
            ),
          );
          break;
        case 6: // RESP_AWAITING_APPROVAL
          final resubmit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              title: Text('Request Pending', style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1E293B))),
              content: Text(
                'Your registration request is pending admin approval. Do you want to resubmit the form?',
                style: TextStyle(color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: TextStyle(color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Yes, Resubmit', style: TextStyle(color: _isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))),
                ),
              ],
            ),
          );
          if (resubmit == true && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivationPage(mobileNumber: mobile),
              ),
            );
          }
          break;
        case 9: // RESP_DEVICE_LINKING_REQUIRED (New device linking needed or password setup needed)
          {
            final needsPasswordSetup = res['needs_password_setup'] ?? false;
            final needsDeviceLink = res['needs_device_link'] ?? true;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeviceLinkingPage(
                  mobileNumber: mobile,
                  directPasswordSetup: !needsDeviceLink && needsPasswordSetup,
                ),
              ),
            );
          }
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.isNotEmpty ? message : 'Unhandled status code: $responseCode'),
              backgroundColor: Colors.amber.shade800,
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coop = AuthStore().selectedCooperative;
    final coopName = coop?['name'] ?? 'Your Cooperative';
    final isDark = _isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Premium Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF020617),
                          const Color(0xFF0B132B), // Premium dark blue-indigo accent
                          const Color(0xFF020617),
                        ]
                      : [
                          const Color(0xFFF8FAFC),
                          const Color(0xFFEEF2F6), // Premium light grey-blue accent
                          const Color(0xFFF8FAFC),
                        ],
                ),
              ),
            ),
          ),

          // 2. Content Screen
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: null,
            body: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 20),
                                  // Centered Cooperative Logo with premium design
                                  Builder(
                                    builder: (context) {
                                      final selectedSahakari = AuthStore().selectedCooperative;
                                      final String sahakariName = selectedSahakari?['name'] ?? 'Bright Sahakari';
                                      final String? logoUrl = selectedSahakari?['logo_url'];
                                      final String? gradientClass = selectedSahakari?['gradient'];
                                      final gradient = _getGradient(gradientClass);
                                      final String initialLetter = sahakariName.isNotEmpty ? sahakariName.substring(0, 1) : 'B';

                                      return Center(
                                        child: Container(
                                          width: 86,
                                          height: 86,
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.1)
                                                  : Colors.black.withValues(alpha: 0.05),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: logoUrl == null || logoUrl.isEmpty ? gradient : null,
                                              color: logoUrl != null && logoUrl.isNotEmpty ? Colors.white : null,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (logoUrl == null || logoUrl.isEmpty ? const Color(0xFF2563EB) : Colors.black).withValues(alpha: 0.2),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: logoUrl != null && logoUrl.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(40),
                                                    child: Image.network(
                                                      logoUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            gradient: gradient,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              initialLetter,
                                                              style: const TextStyle(
                                                                fontSize: 32,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : Center(
                                                    child: Text(
                                                      initialLetter,
                                                      style: const TextStyle(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Centered Cooperative Name (Improved size and styling)
                                  Text(
                                    coopName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  
                                  // Subtitle (Enter Mobile Number, reduced size)
                                  Text(
                                    'Enter Mobile Number'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Description (Centered)
                                  Text(
                                    'We will check your registration status and guide you to the next step.'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // TextFormField with native borders (no wrapper Container needed)
                                  TextFormField(
                                    controller: _mobileController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [PhoneNumberFormatter()],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.phone_iphone_rounded,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                      ),
                                      hintText: 'e.g. 98XXXXXXXX',
                                      hintStyle: TextStyle(
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.normal,
                                        letterSpacing: 1.0,
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.black.withValues(alpha: 0.08),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF60A5FA).withValues(alpha: 0.6)
                                              : const Color(0xFF2563EB).withValues(alpha: 0.6),
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Submit Button inside visual gradient wrapper
                                  Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: (_isLoading || _mobileController.text.trim().length != 10)
                                          ? null
                                          : LinearGradient(
                                              colors: [
                                                isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                                                isDark ? const Color(0xFF1D4ED8) : const Color(0xFF1D4ED8),
                                              ],
                                            ),
                                      color: (_isLoading || _mobileController.text.trim().length != 10)
                                          ? (isDark
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : Colors.black.withValues(alpha: 0.05))
                                          : null,
                                      boxShadow: (_isLoading || _mobileController.text.trim().length != 10)
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.2),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: (_isLoading || _mobileController.text.trim().length != 10) ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        disabledBackgroundColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              'Continue'.tr,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: (_isLoading || _mobileController.text.trim().length != 10)
                                                    ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                                    : Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                              
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Register New Member
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const RegisterMemberPage(),
                                          ),
                                        );
                                      },
                                      child: Text.rich(
                                        TextSpan(
                                          text: '${'New to Bright Sahakari?'.tr} ',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                            fontSize: 14,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Register New Member'.tr,
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Change Cooperative Bank
                                  Center(
                                    child: TextButton(
                                      onPressed: () async {
                                        // Show a confirmation dialog
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                            title: Text(
                                              'Switch Cooperative'.tr,
                                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                            ),
                                            content: Text(
                                              'Are you sure you want to disconnect and switch to a different cooperative bank? All local session data will be cleared.'.tr,
                                              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: Text(
                                                  'Cancel'.tr,
                                                  style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: Text('Switch'.tr, style: const TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await AuthStore().clearAll();
                                          if (!mounted) return;
                                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                        }
                                      },
                                      child: Text(
                                        'Change Cooperative Bank'.tr,
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = digitsOnly;
    if (digitsOnly.length > 10) {
      formatted = digitsOnly.substring(digitsOnly.length - 10);
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
