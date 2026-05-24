import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/biometric_signature_service.dart';
import '../../store/auth_store.dart';
import '../dashboard/dashboard_page.dart';

class BiometricSetupPage extends StatefulWidget {
  const BiometricSetupPage({super.key});

  @override
  State<BiometricSetupPage> createState() => _BiometricSetupPageState();
}

class _BiometricSetupPageState extends State<BiometricSetupPage> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _enableBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authStore = AuthStore();
      final mobile = authStore.mobile ?? authStore.registeredMobile;
      if (mobile == null) {
        throw Exception('User mobile session is not initialized.');
      }

      // 1. Check if biometrics is available
      final isAvailable = await BiometricSignatureService.isAvailable();
      if (!isAvailable) {
        throw Exception('Secure hardware biometrics is not available or registered on this device.');
      }

      // 2. Prompt user for biometric identity verification
      final verified = await BiometricSignatureService.verifyIdentity(
        title: 'Setup Biometrics',
        subtitle: 'Authenticate to register this device',
      );
      if (!verified) {
        throw Exception('Identity verification failed. Please try again.');
      }

      // 3. Create KeyStore RSA KeyPair
      final publicKeyPem = await BiometricSignatureService.createKeyPair(mobile);

      // 4. Register key on cooperative server
      final res = await ApiService().registerBiometric(publicKeyPem);
      if (res['response_code'] == 1) {
        // Success
        await authStore.setBiometricEnabled(true);
        await authStore.setNeverAskBiometric(true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication registered successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
            (route) => false,
          );
        }
      } else {
        throw Exception(res['message'] ?? 'Failed to register keys on cooperative server.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  void _skipSetup() async {
    await AuthStore().setNeverAskBiometric(true);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipSetup,
            child: Text(
              'Skip',
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Giant Premium Lock/Fingerprint Circle
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB).withValues(alpha: isDarkMode ? 0.08 : 0.04),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2563EB).withValues(alpha: isDarkMode ? 0.15 : 0.08),
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        size: 56,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Title & Description
              const Text(
                'Biometric Log In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unlock your account instantly using fingerprint or face verification. Safe, secure, and passwordless.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // Error Notice
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Enable Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enableBiometrics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Enable Biometric Setup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Support Notice
              Text(
                'Uses your device\'s local secure hardware key isolation. Your biometric credentials are never sent to external servers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
