import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../services/biometric_signature_service.dart';
import '../../store/auth_store.dart';

class BiometricSetupPage extends StatefulWidget {
  const BiometricSetupPage({super.key});

  @override
  State<BiometricSetupPage> createState() => _BiometricSetupPageState();
}

class _BiometricSetupPageState extends State<BiometricSetupPage> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFaceId = false;

  @override
  void initState() {
    super.initState();
    _detectBiometricType();
  }

  Future<void> _detectBiometricType() async {
    try {
      final isIOS = Platform.isIOS;
      final localAuth = LocalAuthentication();
      final availableBiometrics = await localAuth.getAvailableBiometrics();
      final hasFace = availableBiometrics.contains(BiometricType.face);
      if (mounted) {
        setState(() {
          _isFaceId = hasFace || isIOS;
        });
      }
    } catch (_) {}
  }

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
        // Success — clear the pending flag then go to Dashboard
        await authStore.setBiometricEnabled(true);
        await authStore.setNeverAskBiometric(true);
        // ... detect and save biometric type
        try {
          final localAuth = LocalAuthentication();
          final availableBiometrics = await localAuth.getAvailableBiometrics();
          final hasFace = availableBiometrics.contains(BiometricType.face);
          final isIOS = Platform.isIOS;
          final type = (hasFace || isIOS) ? 'face' : 'fingerprint';
          await authStore.setBiometricType(type);
        } catch (_) {}

        authStore.setPendingBiometricSetup(false);
        if (mounted) {
          // If pushed from Settings, pop back. Otherwise InitialRouter
          // handles the transition to Dashboard via pendingBiometricSetup=false.
          if (Navigator.canPop(context)) Navigator.pop(context);
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

  void _skipSetup() {
    AuthStore().setPendingBiometricSetup(false);
    // If pushed from Settings, pop back. Otherwise InitialRouter handles
    // the transition to Dashboard via pendingBiometricSetup=false.
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  void _neverAskSetup() async {
    await AuthStore().setNeverAskBiometric(true);
    AuthStore().setPendingBiometricSetup(false);
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
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
                      child: Icon(
                        _isFaceId ? Icons.face_unlock_rounded : Icons.fingerprint_rounded,
                        size: 56,
                        color: const Color(0xFF2563EB),
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
              if (!_isLoading) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _neverAskSetup,
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Don\'t Ask Again',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
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
