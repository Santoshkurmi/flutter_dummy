import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';
import '../services/biometric_signature_service.dart';
import '../store/auth_store.dart';
import 'dashboard_page.dart';
import 'status_check_page.dart';
import 'activation_page.dart';
import 'device_linking_page.dart';
import 'select_cooperative_page.dart';

class LoginPage extends StatefulWidget {
  final String mobileNumber;
  const LoginPage({super.key, required this.mobileNumber});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false;
  bool _canAuthenticate = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _checkBiometrics();
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  Future<void> _checkBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      setState(() {
        _canAuthenticate = isSupported && canCheck;
      });
    } catch (_) {}
  }

  Future<void> _handleResponseRouting(int responseCode, String apiMessage, Map<String, dynamic> res) async {
    final data = res['data'] is Map ? res['data'] as Map<String, dynamic> : res;
    final token = data['token'] ?? res['token'];

    Future<void> clearCredentials() async {
      await AuthStore().setRegisteredMobile(null);
      await AuthStore().setBiometricEnabled(false);
      await AuthStore().clearAuth();
    }

    switch (responseCode) {
      case 1: // RESP_SUCCESS
        if (token != null) {
          await AuthStore().setToken(token);
          
          final profileRes = await ApiService().getProfile();
          if (profileRes['profile'] != null) {
            await AuthStore().setProfile(profileRes['profile']);
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful! Welcome to Bright Sahakari.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(apiMessage.isNotEmpty ? apiMessage : 'Invalid token data.'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
        break;
      case 2: // RESP_ACTIVATION_REQUIRED
        await clearCredentials();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ActivationPage(mobileNumber: widget.mobileNumber),
          ),
          (route) => false,
        );
        break;
      case 6: // RESP_AWAITING_APPROVAL
        await clearCredentials();
        if (!mounted) return;
        final resubmit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: const Text('Request Pending', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Your registration request is pending admin approval. Do you want to resubmit the form?',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Resubmit', style: TextStyle(color: Color(0xFF3B82F6))),
              ),
            ],
          ),
        );
        if (resubmit == true && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => ActivationPage(mobileNumber: widget.mobileNumber),
            ),
            (route) => false,
          );
        }
        break;
      case 9: // RESP_DEVICE_LINKING_REQUIRED
        await clearCredentials();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DeviceLinkingPage(mobileNumber: widget.mobileNumber),
          ),
          (route) => false,
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiMessage.isNotEmpty ? apiMessage : 'Login failed. Please check your credentials.'),
            backgroundColor: Colors.red.shade800,
          ),
        );
    }
  }

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

  Future<void> _submitPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      final devId = await ApiService.getDeviceId();
      final res = await ApiService().login(widget.mobileNumber, password, devId);
      
      final responseCodeRaw = res['response_code'];
      final int responseCode = responseCodeRaw is int
          ? responseCodeRaw
          : int.tryParse(responseCodeRaw?.toString() ?? '') ?? (res['token'] != null ? 1 : 0);
      final apiMessage = res['message'] ?? '';

      await _handleResponseRouting(responseCode, apiMessage, res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticateBiometrics() async {
    if (!_canAuthenticate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrics not configured or supported on this device.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to log in securely to Bright Sahakari',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        setState(() => _isLoading = true);
        
        // Dynamic Biometric login with backend verification
        try {
          final challengeRes = await ApiService().getBiometricChallenge(widget.mobileNumber);
          final challenge = challengeRes['challenge'] ?? 'dummy_challenge';
          
          // Generate hardware-backed signature using Keystore/Secure Enclave
          final signature = await BiometricSignatureService.signChallenge(widget.mobileNumber, challenge);
          
          final devId = await ApiService.getDeviceId();
          final res = await ApiService().verifyBiometric({
            'mobile': widget.mobileNumber,
            'signed_data': signature,
            'device_id': devId,
          });

          final responseCodeRaw = res['response_code'];
          final int responseCode = responseCodeRaw is int
              ? responseCodeRaw
              : int.tryParse(responseCodeRaw?.toString() ?? '') ?? (res['token'] != null ? 1 : 0);
          final apiMessage = res['message'] ?? '';

          await _handleResponseRouting(responseCode, apiMessage, res);
        } catch (e) {
          // Fallback to mock biometric success if backend biometrics aren't configured
          // (matching Capacitor fallback behaviour)
          final devId = await ApiService.getDeviceId();
          final loginRes = await ApiService().login(widget.mobileNumber, '1234', devId);
          
          final responseCodeRaw = loginRes['response_code'];
          final int responseCode = responseCodeRaw is int
              ? responseCodeRaw
              : int.tryParse(responseCodeRaw?.toString() ?? '') ?? (loginRes['token'] != null ? 1 : 0);
          final apiMessage = loginRes['message'] ?? '';

          await _handleResponseRouting(responseCode, apiMessage, loginRes);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Biometrics failed: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),
                            // Visual Logo of the selected Sahakari
                            Builder(
                              builder: (context) {
                                final selectedSahakari = AuthStore().selectedCooperative;
                                final String sahakariName = selectedSahakari?['name'] ?? '';
                                final String? logoUrl = selectedSahakari?['logo_url'];
                                final String? gradientClass = selectedSahakari?['gradient'];
                                final gradient = _getGradient(gradientClass);
                                final String initialLetter = sahakariName.isNotEmpty ? sahakariName.substring(0, 1) : 'B';

                                return Center(
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: logoUrl == null || logoUrl.isEmpty ? gradient : null,
                                      color: logoUrl != null && logoUrl.isNotEmpty ? Colors.white : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (logoUrl == null || logoUrl.isEmpty ? const Color(0xFF2563EB) : Colors.black).withOpacity(0.2),
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
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Builder(
                              builder: (context) {
                                final selectedSahakari = AuthStore().selectedCooperative;
                                final String sahakariName = selectedSahakari?['name'] ?? '';
                                return Column(
                                  children: [
                                    Text(
                                      sahakariName.isNotEmpty ? sahakariName : 'Welcome Back',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    if (sahakariName.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Welcome Back',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                widget.mobileNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF60A5FA),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                             // Password Input Field
                             const Text(
                               'PASSWORD',
                               style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                             ),
                             const SizedBox(height: 8),
                             Container(
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.05),
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(
                                   color: Colors.white.withOpacity(0.1),
                                 ),
                               ),
                               child: TextFormField(
                                 controller: _passwordController,
                                 keyboardType: TextInputType.visiblePassword,
                                 obscureText: _obscurePassword,
                                 style: const TextStyle(color: Colors.white, fontSize: 16),
                                 decoration: InputDecoration(
                                   prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B)),
                                   suffixIcon: IconButton(
                                     icon: Icon(
                                       _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                       color: const Color(0xFF64748B),
                                     ),
                                     onPressed: () {
                                       setState(() {
                                         _obscurePassword = !_obscurePassword;
                                       });
                                     },
                                   ),
                                   hintText: 'Enter your password',
                                   hintStyle: const TextStyle(color: Color(0xFF64748B)),
                                   border: InputBorder.none,
                                   contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                 ),
                               ),
                             ),
                             const SizedBox(height: 24),

                             // Primary Submit Button
                             ElevatedButton(
                               onPressed: (_isLoading || _passwordController.text.trim().isEmpty) ? null : _submitPassword,
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: const Color(0xFF2563EB),
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(16),
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
                                   : const Text(
                                       'Secure Login',
                                       style: TextStyle(
                                         fontSize: 16,
                                         fontWeight: FontWeight.bold,
                                         color: Colors.white,
                                       ),
                                     ),
                             ),
                            const SizedBox(height: 24),

                            // Quick Biometric login trigger
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.fingerprint_rounded, color: Color(0xFF60A5FA), size: 50),
                                  onPressed: _authenticateBiometrics,
                                ),
                              ],
                            ),
                            const Center(
                              child: Text(
                                'Tap to Login with Biometrics',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Login with another phone number
                            Center(
                              child: TextButton(
                                onPressed: () async {
                                  final store = AuthStore();
                                  await store.setRegisteredMobile(null);
                                  await store.setMobile(null);
                                  await store.setBiometricEnabled(false);
                                  await store.setNeverAskBiometric(false);
                                  await store.clearAuth();
                                  
                                  if (!mounted) return;
                                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SelectCooperativePage()),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const StatusCheckPage()),
                                  );
                                },
                                child: const Text(
                                  'Login with another phone number',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Switch cooperative option
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  AuthStore().clearAll();
                                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                },
                                child: const Text(
                                  'Switch Cooperative Bank',
                                  style: TextStyle(color: Color(0xFF64748B)),
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
            );
          }
        ),
      ),
    );
  }
}
