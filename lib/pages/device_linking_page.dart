import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../store/auth_store.dart';
import 'dashboard_page.dart';
import 'status_check_page.dart';

class DeviceLinkingPage extends StatefulWidget {
  final String mobileNumber;
  const DeviceLinkingPage({super.key, required this.mobileNumber});

  @override
  State<DeviceLinkingPage> createState() => _DeviceLinkingPageState();
}

class _DeviceLinkingPageState extends State<DeviceLinkingPage> {
  int _step = 1; // Step 1 to 5
  bool _isLoading = false;
  String _errorMessage = '';

  // Form Keys
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _membershipController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // API State Loaded during validation
  bool _isSmsEnabled = false;
  bool _needsPasswordSetup = true;

  @override
  void initState() {
    super.initState();
    // DOB Auto-formatter listener
    _dobController.addListener(_formatDobInput);
  }

  @override
  void dispose() {
    _dobController.removeListener(_formatDobInput);
    _membershipController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Automatic YYYY-MM-DD hyphen insertion formatting helper
  void _formatDobInput() {
    final text = _dobController.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 8) return;
    
    String formatted = text;
    if (text.length > 4) {
      formatted = '${text.substring(0, 4)}-${text.substring(4)}';
    }
    if (text.length > 6) {
      formatted = '${formatted.substring(0, 7)}-${formatted.substring(7)}';
    }
    
    if (formatted != _dobController.text) {
      _dobController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // STEP 1: Verify Identity API request
  Future<void> _handleStep1Validate() async {
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final devId = await ApiService.getDeviceId();
      final res = await ApiService().activateValidate({
        'mobile': widget.mobileNumber,
        'membership_number': _membershipController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'date_of_birth_bs': _dobController.text.trim(),
        'device_id': devId,
      });

      final responseCode = res['response_code'];
      if (responseCode == 1 || responseCode == 4) { // Success or Device Linking Needed
        setState(() {
          _isSmsEnabled = res['is_sms_enabled'] ?? false;
          _needsPasswordSetup = res['needs_password_setup'] ?? true;
          
          if (_needsPasswordSetup) {
            _step = 2; // Move to Step 2 (Password)
          } else {
            _step = 3; // Skip password, move directly to PIN setup
          }
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Identity validation failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // STEP 2: Password Update
  void _handleStep2Password() {
    if (!_step2FormKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = '';
      _step = 3; // Move to PIN / Verification Setup
    });
  }

  // STEP 3: Pin Setup / Submit OTP Request
  Future<void> _handleStep3PinSubmit(bool withOtp) async {
    if (_needsPasswordSetup) {
      if (!_step3FormKey.currentState!.validate()) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (withOtp) {
      try {
        final devId = await ApiService.getDeviceId();
        await ApiService().sendDeviceLinkOtp(
          widget.mobileNumber,
          devId,
        );

        // response_code 2 indicates success OTP sent (or response code returned from backend)
        setState(() {
          _step = 4; // Move to final OTP confirmation step
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Direct Admin submission if SMS verification is disabled or user opts for manual review
      await _handleSubmitFinal('');
    }
  }

  // STEP 4: Final Submission with OTP Verification
  Future<void> _handleSubmitFinal(String otpCode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final devId = await ApiService.getDeviceId();
      final payload = {
        'mobile': widget.mobileNumber,
        'membership_number': _membershipController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'date_of_birth_bs': _dobController.text.trim(),
        'password': _needsPasswordSetup ? _passwordController.text : null,
        'transaction_pin': _needsPasswordSetup ? _pinController.text : null,
        'otp': otpCode.isNotEmpty ? otpCode : null,
        'device_id': devId,
        'device_name': Platform.isAndroid ? 'Android Device' : 'iOS Device',
      };

      final res = await ApiService().submitDeviceLink(payload);
      final responseCode = res['response_code'];

      if (responseCode == 1 || responseCode == 4) { // Success or auto login
        final data = res['data'];
        if (data != null && data['token'] != null) {
          // Dynamic Session Autologin inside AuthStore
          final store = AuthStore();
          await store.setToken(data['token']);
          await store.setMobile(widget.mobileNumber);
          await store.setRegisteredMobile(widget.mobileNumber);
          final profileRes = await ApiService().getProfile();
          if (profileRes['data'] != null) {
            await store.setProfile(profileRes['data']);
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device synchronized successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );

          // Route immediately to main dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
            (route) => false,
          );
        } else {
          setState(() {
            _step = 5; // Move to Admin pending sync approval screen
          });
        }
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Device synchronization submission failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () {
            if (_step > 1) {
              setState(() {
                if (_step == 3 && !_needsPasswordSetup) {
                  _step = 1;
                } else {
                  _step--;
                }
                _errorMessage = '';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Device Sync',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dynamic Horizontal Multi-Step Progress Tracker Bar
            if (_step < 5) _buildStepIndicator(isDarkMode),
            const SizedBox(height: 20),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Main Step Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: _buildCurrentFormStep(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Visual Multi-Step Header Indicator
  Widget _buildStepIndicator(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final stepNum = index + 1;
          final isActive = _step == stepNum;
          final isDone = _step > stepNum;
          
          return Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isDone
                      ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                      : isActive
                          ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)])
                          : null,
                  color: !isActive && !isDone
                      ? (isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9))
                      : null,
                  boxShadow: isActive
                      ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : Text(
                          '$stepNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isActive || isDone
                                ? Colors.white
                                : (isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          ),
                        ),
                ),
              ),
              if (index < 3) ...[
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 2,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : (isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
                ),
                const SizedBox(width: 8),
              ]
            ],
          );
        }),
      ),
    );
  }

  // Switches between step widget designs dynamically
  Widget _buildCurrentFormStep(bool isDarkMode) {
    switch (_step) {
      case 1:
        return _buildStep1Identity(isDarkMode);
      case 2:
        return _buildStep2Password(isDarkMode);
      case 3:
        return _buildStep3Pin(isDarkMode);
      case 4:
        return _buildStep4Otp(isDarkMode);
      case 5:
        return _buildStep5Complete(isDarkMode);
      default:
        return _buildStep1Identity(isDarkMode);
    }
  }

  // STEP 1 WIDGET: Identity Verification
  Widget _buildStep1Identity(bool isDarkMode) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.phonelink_lock_rounded, color: Color(0xFF2563EB), size: 36),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sync New Device',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your cooperative membership identity for mobile number ${widget.mobileNumber} to authorize and register this device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 28),

          // Membership ID Input
          const Text('MEMBERSHIP ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _membershipController,
            hint: 'Enter Cooperative Membership ID',
            icon: Icons.badge_rounded,
            isDarkMode: isDarkMode,
            validator: (v) => v == null || v.trim().isEmpty ? 'Membership ID is required' : null,
          ),
          const SizedBox(height: 20),

          // Full Name Input
          const Text('FULL NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _fullNameController,
            hint: 'Enter your profile Full Name',
            icon: Icons.person_outline_rounded,
            isDarkMode: isDarkMode,
            validator: (v) => v == null || v.trim().isEmpty ? 'Full Name is required' : null,
          ),
          const SizedBox(height: 20),

          // Date of Birth (BS) Input
          const Text('DATE OF BIRTH (BS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _dobController,
            hint: 'YYYY-MM-DD (e.g. 2045-10-24)',
            icon: Icons.calendar_today_rounded,
            keyboardType: TextInputType.datetime,
            isDarkMode: isDarkMode,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Date of Birth (BS) is required';
              if (v.trim().length < 10) return 'Enter birthdate in YYYY-MM-DD BS format';
              return null;
            },
          ),
          const SizedBox(height: 36),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleStep1Validate,
            style: _getPrimaryButtonStyle(),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify Identity', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // STEP 2 WIDGET: Update Password
  Widget _buildStep2Password(bool isDarkMode) {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.vpn_key_rounded, color: Color(0xFF2563EB), size: 36),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Security: Update Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your mobile banking profile login credentials or choose a new robust password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 28),

          // Password Field
          const Text('NEW LOGIN PASSWORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: 'Minimum 6 characters',
            icon: Icons.lock_outline_rounded,
            obscure: true,
            isDarkMode: isDarkMode,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Confirm Password Field
          const Text('CONFIRM PASSWORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Confirm secure password',
            icon: Icons.check_circle_outline_rounded,
            obscure: true,
            isDarkMode: isDarkMode,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm Password is required';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 36),

          ElevatedButton(
            onPressed: _handleStep2Password,
            style: _getPrimaryButtonStyle(),
            child: const Text('Continue to PIN Setup', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // STEP 3 WIDGET: Set Transaction PIN / Submit Options
  Widget _buildStep3Pin(bool isDarkMode) {
    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF4F46E5), size: 36),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _needsPasswordSetup ? 'Transaction Security' : 'Confirm Device Sync',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            _needsPasswordSetup 
                ? 'Choose a secure 4-digit numeric Transaction PIN required for transfers.' 
                : 'Confirm details to send a sync validation request for this mobile device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 28),

          if (_needsPasswordSetup) ...[
            // PIN field
            const Text('NEW TRANSACTION PIN (4 DIGITS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _pinController,
              hint: 'Set 4-digit PIN',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              isDarkMode: isDarkMode,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'PIN is required';
                if (v.trim().length != 4) return 'PIN must be exactly 4 digits';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Confirm PIN field
            const Text('CONFIRM PIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _confirmPinController,
              hint: 'Confirm 4-digit PIN',
              icon: Icons.check_circle_outline_rounded,
              obscure: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              isDarkMode: isDarkMode,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Confirm PIN is required';
                if (v.trim() != _pinController.text.trim()) return 'PINs do not match';
                return null;
              },
            ),
            const SizedBox(height: 36),
          ],

          if (_isSmsEnabled) ...[
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleStep3PinSubmit(true),
              style: _getPrimaryButtonStyle(),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sms_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Verify via SMS OTP', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : () => _handleStep3PinSubmit(false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Manual Admin Approval',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleStep3PinSubmit(false),
              style: _getPrimaryButtonStyle(),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Sync Request', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  // STEP 4 WIDGET: OTP Verification code
  Widget _buildStep4Otp(bool isDarkMode) {
    return Form(
      key: _step4FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.sms_failed_rounded, color: Color(0xFF2563EB), size: 36),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sync Verification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'A 6-digit dynamic verification sync code has been dispatched to your mobile. Enter it below to complete synchronization.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 28),

          // OTP field
          const Text('VERIFICATION CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _otpController,
            hint: 'Enter 6-digit OTP',
            icon: Icons.security_rounded,
            keyboardType: TextInputType.number,
            maxLength: 6,
            isDarkMode: isDarkMode,
            validator: (v) => v == null || v.trim().isEmpty ? 'OTP code is required' : null,
          ),
          const SizedBox(height: 36),

          ElevatedButton(
            onPressed: _isLoading ? null : () => _handleSubmitFinal(_otpController.text.trim()),
            style: _getPrimaryButtonStyle(),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Finalize Sync', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: _isLoading ? null : () => _handleStep3PinSubmit(true),
              child: const Text(
                'Resend Verification OTP',
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontSize: 13),
              ),
            ),
          )
        ],
      ),
    );
  }

  // STEP 5 WIDGET: Sync Request Initiated Pending Approval
  Widget _buildStep5Complete(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 64),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Sync Request Initiated',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Your device synchronization request has been recorded. '
            '${_isSmsEnabled ? "Your synchronization is complete! Please login from the main screen." : "An administrator will review and authorize your device link request within 24 hours."}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.5),
          ),
        ),
        const SizedBox(height: 48),

        ElevatedButton(
          onPressed: () {
            // Navigate back to status check screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const StatusCheckPage()),
              (route) => false,
            );
          },
          style: _getPrimaryButtonStyle(),
          child: const Text('Return to Home', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ],
    );
  }

  // TEXT FIELD DECORATOR UTILITY
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    required bool isDarkMode,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLength: maxLength,
        validator: validator,
        style: TextStyle(
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.normal, fontSize: 13),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // STYLE GENERATORS
  ButtonStyle _getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2563EB),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
    );
  }
}
