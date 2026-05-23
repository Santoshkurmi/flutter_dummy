import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class ActivationPage extends StatefulWidget {
  final String mobileNumber;
  const ActivationPage({super.key, required this.mobileNumber});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  int _step = 1; // Step 1 to 5
  bool _isLoading = false;
  String _errorMessage = '';

  // Form Keys
  final _step1FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();
  final _step5FormKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _membershipController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // API Data loaded at Step 1
  double _chargeAmount = 0.0;
  List<dynamic> _savingAccounts = [];
  String? _selectedAccountId;
  bool _isSmsEnabled = false;
  String _paymentMethod = 'saving'; // 'saving' or 'manual'

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

  // Automatic YYYY-MM-DD hyphen insertion format helper
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
      final res = await ApiService().activateValidate({
        'mobile': widget.mobileNumber,
        'membership_number': _membershipController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'date_of_birth_bs': _dobController.text.trim(),
        'device_id': 'flutter_device_unique_12345',
      });

      final responseCode = res['response_code'];
      if (responseCode == 1) { // Success
        setState(() {
          _chargeAmount = (res['charge_amount'] ?? 0).toDouble();
          _savingAccounts = res['saving_accounts'] ?? [];
          _isSmsEnabled = res['is_sms_enabled'] ?? false;
          if (_savingAccounts.isNotEmpty) {
            _selectedAccountId = _savingAccounts[0]['id'].toString();
          }
          _step = 2; // Move to Step 2
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

  // STEP 2: Payment Settle
  void _handleStep2Payment() {
    if (_chargeAmount > 0 && _paymentMethod == 'saving' && _selectedAccountId == null) {
      setState(() => _errorMessage = 'Please select a payment account.');
      return;
    }
    setState(() {
      _errorMessage = '';
      _step = 3; // Move to Password Setup
    });
  }

  // STEP 3: Setup Password
  void _handleStep3Password() {
    if (!_step3FormKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = '';
      _step = 4; // Move to PIN Setup
    });
  }

  // STEP 4: Submit & Request OTP
  Future<void> _handleStep4PinSubmit(bool withOtp) async {
    if (!_step4FormKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (withOtp) {
      try {
        final res = await ApiService().activateSendOtp({
          'mobile': widget.mobileNumber,
          'membership_number': _membershipController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'date_of_birth_bs': _dobController.text.trim(),
        });

        final responseCode = res['response_code'];
        if (responseCode == 2) { // RESP_OTP_SENT or success code
          setState(() {
            _step = 5; // Move to final OTP confirmation step
          });
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Failed to send verification OTP.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Direct Admin submission if SMS verification is disabled
      await _handleSubmitFinal('');
    }
  }

  // STEP 5: Final Submission with OTP Verification
  Future<void> _handleSubmitFinal(String otpCode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final res = await ApiService().activateSubmit({
        'mobile': widget.mobileNumber,
        'membership_number': _membershipController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'date_of_birth_bs': _dobController.text.trim(),
        'saving_account_id': _paymentMethod == 'saving' ? _selectedAccountId : null,
        'payment_method': _paymentMethod,
        'otp': otpCode,
        'password': _passwordController.text,
        'transaction_pin': _pinController.text,
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Activation request submitted successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      // Successfully activated, direct to LoginPage and clear history
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(mobileNumber: widget.mobileNumber),
        ),
        (route) => false,
      );
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
                _step--;
                _errorMessage = '';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Mobile Registration',
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
            _buildStepIndicator(isDarkMode),
            const SizedBox(height: 20),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
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
        children: List.generate(5, (index) {
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
                      ? (isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9))
                      : null,
                  boxShadow: isActive
                      ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
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
              if (index < 4) ...[
                const SizedBox(width: 8),
                Container(
                  width: 14,
                  height: 2,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : (isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0)),
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
        return _buildStep2Payment(isDarkMode);
      case 3:
        return _buildStep3Password(isDarkMode);
      case 4:
        return _buildStep4Pin(isDarkMode);
      case 5:
        return _buildStep5Otp(isDarkMode);
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
                color: const Color(0xFF2563EB).withOpacity(0.08),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2563EB), size: 36),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Identity Verification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome ${widget.mobileNumber}. Verify your cooperative membership profile identity to activate banking access.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 28),

          // Membership ID Input
          const Text('MEMBERSHIP ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _membershipController,
            hint: 'e.g. M-10294',
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
            hint: 'e.g. Ram Bahadur Thapa',
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
            hint: 'YYYY-MM-DD (e.g. 2040-02-15)',
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

  // STEP 2 WIDGET: Service Fee Settlement
  Widget _buildStep2Payment(bool isDarkMode) {
    if (_chargeAmount <= 0) {
      // Auto bypass payment screen if free
      Future.microtask(() {
        setState(() {
          _step = 3;
        });
      });
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withOpacity(0.08),
            ),
            child: const Icon(Icons.wallet_rounded, color: Color(0xFF10B981), size: 36),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Service Activation Charge',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.12)),
          ),
          child: Column(
            children: [
              const Text('TOTAL ACTIVATION CHARGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
              const SizedBox(height: 6),
              Text(
                'Rs. ${_chargeAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Deduct Choice Row Grid
        Row(
          children: [
            Expanded(
              child: _buildChoiceCard(
                title: 'DEDUCT SAVING',
                icon: Icons.account_balance_wallet_rounded,
                selected: _paymentMethod == 'saving',
                isDarkMode: isDarkMode,
                onTap: () => setState(() => _paymentMethod = 'saving'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceCard(
                title: 'MANUAL / BRANCH',
                icon: Icons.monetization_on_rounded,
                selected: _paymentMethod == 'manual',
                isDarkMode: isDarkMode,
                onTap: () => setState(() => _paymentMethod = 'manual'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_paymentMethod == 'saving') ...[
          const Text('SELECT SAVING ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAccountId,
                dropdownColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
                isExpanded: true,
                items: _savingAccounts.map((acc) {
                  return DropdownMenuItem<String>(
                    value: acc['id'].toString(),
                    child: Text(acc['scheme_name'] ?? 'Saving Account'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedAccountId = val;
                  });
                },
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'No account deduction is required. You can clear the registration fee manually at any cooperative branch office. Admin will review the request.',
              style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), height: 1.4, fontWeight: FontWeight.bold),
            ),
          ),
        ],

        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: _handleStep2Payment,
          style: _getPrimaryButtonStyle(),
          child: const Text('Confirm & Continue', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ],
    );
  }

  // CHOICE CARD
  Widget _buildChoiceCard({
    required String title,
    required IconData icon,
    required bool selected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF2563EB).withOpacity(0.08)
            : (isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFF2563EB) : (isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0)),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: selected ? const Color(0xFF2563EB) : const Color(0xFF64748B), size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 3 WIDGET: Set Login Password
  Widget _buildStep3Password(bool isDarkMode) {
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
                color: const Color(0xFF2563EB).withOpacity(0.08),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF2563EB), size: 36),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Security: Login Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a strong security password to secure access logs into your mobile banking profile.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 28),

          // Password Field
          const Text('NEW PASSWORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: 'Minimum 6 characters',
            icon: Icons.vpn_key_rounded,
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
            onPressed: _handleStep3Password,
            style: _getPrimaryButtonStyle(),
            child: const Text('Continue to PIN Setup', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // STEP 4 WIDGET: Set Transaction PIN
  Widget _buildStep4Pin(bool isDarkMode) {
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
                color: const Color(0xFF4F46E5).withOpacity(0.08),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF4F46E5), size: 36),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Security: Transaction PIN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a secure 4-digit numeric Transaction PIN required for completing transfers and bill payments.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 28),

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
          const Text('CONFIRM TRANSACTION PIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
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

          if (_isSmsEnabled) ...[
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleStep4PinSubmit(true),
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
              onPressed: _isLoading ? null : () => _handleStep4PinSubmit(false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Submit for Admin Approval',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleStep4PinSubmit(false),
              style: _getPrimaryButtonStyle(),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  // STEP 5 WIDGET: OTP verification code
  Widget _buildStep5Otp(bool isDarkMode) {
    return Form(
      key: _step5FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withOpacity(0.08),
              ),
              child: const Icon(Icons.sms_failed_rounded, color: Color(0xFF2563EB), size: 36),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Enter Verification Code',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit dynamic OTP verification code to your mobile number. Enter it below to complete registration.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 28),

          // OTP field
          const Text('OTP VERIFICATION CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _otpController,
            hint: 'Enter 6-digit code',
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
                : const Text('Finalize & Activate', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: _isLoading ? null : () => _handleStep4PinSubmit(true),
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
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0)),
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
