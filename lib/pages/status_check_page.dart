import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../store/auth_store.dart';
import 'activation_page.dart';
import 'device_linking_page.dart';
import 'login_page.dart';
import 'register_member_page.dart';

class StatusCheckPage extends StatefulWidget {
  const StatusCheckPage({super.key});

  @override
  State<StatusCheckPage> createState() => _StatusCheckPageState();
}

class _StatusCheckPageState extends State<StatusCheckPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onMobileChanged);
  }

  @override
  void dispose() {
    _mobileController.removeListener(_onMobileChanged);
    _mobileController.dispose();
    super.dispose();
  }

  void _onMobileChanged() {
    setState(() {});
  }

  Future<void> _submit() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final devId = await ApiService.getDeviceId();
      final res = await ApiService().checkStatus(mobile, devId);
      final responseCodeRaw = res['response_code'];
      final int responseCode = responseCodeRaw is int
          ? responseCodeRaw
          : int.tryParse(responseCodeRaw?.toString() ?? '') ?? 0;
      final message = res['message'] ?? '';

      // Persist the mobile number in global state
      await AuthStore().setMobile(mobile);

      if (!mounted) return;

      // Debug SnackBar to show exact response code & message returned by the backend
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Debug Response Code: $responseCode - Message: $message'),
      //     backgroundColor: const Color(0xFF1E293B),
      //     duration: const Duration(seconds: 4),
      //   ),
      // );

      switch (responseCode) {
        case 1: // RESP_SUCCESS (Already active, directly go to Login)
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
        case 2: // RESP_ACTIVATION_REQUIRED (Activation needed)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivationPage(mobileNumber: mobile),
            ),
          );
          break;
        case 6: // RESP_AWAITING_APPROVAL (Request Pending admin approval)
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivationPage(mobileNumber: mobile),
              ),
            );
          }
          break;
        case 9: // RESP_DEVICE_LINKING_REQUIRED (New device linking needed)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceLinkingPage(mobileNumber: mobile),
            ),
          );
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
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                            const SizedBox(height: 20),
                            // Heading
                            Text(
                              coopName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF60A5FA),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Enter Mobile Number',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'We will check your registration status and guide you to the next step.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Mobile Input Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.phone_iphone_rounded, color: Color(0xFF64748B)),
                                  hintText: 'e.g. 98XXXXXXXX',
                                  hintStyle: TextStyle(color: Color(0xFF64748B)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Submit Button
                            ElevatedButton(
                              onPressed: (_isLoading || _mobileController.text.trim().length != 10) ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
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
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
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
                                    text: 'New to Bright Sahakari? ',
                                    style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: 'Register New Member',
                                        style: TextStyle(
                                          color: const Color(0xFF3B82F6),
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
                                      backgroundColor: const Color(0xFF0F172A),
                                      title: const Text('Switch Cooperative', style: TextStyle(color: Colors.white)),
                                      content: const Text(
                                        'Are you sure you want to disconnect and switch to a different cooperative bank? All local session data will be cleared.',
                                        style: TextStyle(color: Color(0xFF94A3B8)),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Switch', style: TextStyle(color: Colors.red)),
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
                                child: const Text(
                                  'Change Cooperative Bank',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
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
