import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../data/locations.dart';

class RegisterMemberPage extends StatefulWidget {
  const RegisterMemberPage({super.key});

  @override
  State<RegisterMemberPage> createState() => _RegisterMemberPageState();
}

class _RegisterMemberPageState extends State<RegisterMemberPage> {
  bool _showForm = false;
  int _currentStep = 1;
  bool _isLoading = false;
  late PageController _pageController;

  // Saved Applications (Dashboard)
  List<dynamic> _submittedApplications = [];

  // Step 1: Personal Details
  String _title = 'Mr';
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController(); // YYYY-MM-DD
  String _gender = 'Male';

  // Step 2: Bio & Family
  String _caste = 'Aadibasi/Janajati';
  final _fatherNameController = TextEditingController();
  final _grandfatherNameController = TextEditingController();
  String _maritalStatus = 'Unmarried';
  final _spouseNameController = TextEditingController();
  String _bloodGroup = 'A+';
  String _occupation = 'Government Service';

  // Step 3: Identity Docs
  final _citizenshipNoController = TextEditingController();
  String _citizenshipDistrict = 'Kathmandu';
  final _panController = TextEditingController();

  // Step 4: Address Details
  String _permProvince = 'Province No. 3';
  String _permDistrict = 'Kathmandu';
  String _permMunicipality = 'Kathmandu';
  final _permWardController = TextEditingController();
  final _permStreetController = TextEditingController();
  
  bool _tempSameAsPermanent = true;
  String _tempProvince = 'Province No. 3';
  String _tempDistrict = 'Kathmandu';
  String _tempMunicipality = 'Kathmandu';
  final _tempWardController = TextEditingController();
  final _tempStreetController = TextEditingController();

  // Step 5: Nominee Details
  final _nomineeNameController = TextEditingController();
  final _nomineeRelationController = TextEditingController();

  // Step 6: Documents (Simulated Base64 Upload paths)
  String? _profilePhoto;
  String? _citizenshipPhoto;
  String? _signaturePhoto;

  // Additional user documents
  final List<Map<String, String>> _additionalDocuments = [];

  List<String> _getProvinceNames() {
    return LocationData.provinces.map((p) => p['name'] as String).toList();
  }

  List<String> _getDistrictNamesForProvince(String provinceName) {
    final province = LocationData.provinces.firstWhere(
      (p) => p['name'] == provinceName,
      orElse: () => <String, dynamic>{},
    );
    if (province.isEmpty) return [];
    final provinceId = province['id'] as int;
    return LocationData.districts
        .where((d) => d['province_id'] == provinceId)
        .map((d) => d['name'] as String)
        .toList();
  }

  List<String> _getVdcNamesForDistrict(String districtName) {
    final district = LocationData.districts.firstWhere(
      (d) => d['name'] == districtName,
      orElse: () => <String, dynamic>{},
    );
    if (district.isEmpty) return [];
    final districtId = district['id'] as int;
    return LocationData.vdcs
        .where((v) => v['district_id'] == districtId)
        .map((v) => v['name'] as String)
        .toList();
  }

  void _onPermProvinceChanged(String val) {
    setState(() {
      _permProvince = val;
      final districts = _getDistrictNamesForProvince(val);
      if (districts.isNotEmpty) {
        _permDistrict = districts.first;
        final vdcs = _getVdcNamesForDistrict(_permDistrict);
        if (vdcs.isNotEmpty) {
          _permMunicipality = vdcs.first;
        } else {
          _permMunicipality = '';
        }
      } else {
        _permDistrict = '';
        _permMunicipality = '';
      }
    });
  }

  void _onPermDistrictChanged(String val) {
    setState(() {
      _permDistrict = val;
      final vdcs = _getVdcNamesForDistrict(val);
      if (vdcs.isNotEmpty) {
        _permMunicipality = vdcs.first;
      } else {
        _permMunicipality = '';
      }
    });
  }

  void _onTempProvinceChanged(String val) {
    setState(() {
      _tempProvince = val;
      final districts = _getDistrictNamesForProvince(val);
      if (districts.isNotEmpty) {
        _tempDistrict = districts.first;
        final vdcs = _getVdcNamesForDistrict(_tempDistrict);
        if (vdcs.isNotEmpty) {
          _tempMunicipality = vdcs.first;
        } else {
          _tempMunicipality = '';
        }
      } else {
        _tempDistrict = '';
        _tempMunicipality = '';
      }
    });
  }

  void _onTempDistrictChanged(String val) {
    setState(() {
      _tempDistrict = val;
      final vdcs = _getVdcNamesForDistrict(val);
      if (vdcs.isNotEmpty) {
        _tempMunicipality = vdcs.first;
      } else {
        _tempMunicipality = '';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep - 1);
    _loadSubmittedApplications();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmittedApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final appsStr = prefs.getString('submitted_memberships');
    if (appsStr != null) {
      try {
        setState(() {
          _submittedApplications = jsonDecode(appsStr);
        });
        _refreshApplicationStatuses();
      } catch (_) {}
    }
  }

  Future<void> _refreshApplicationStatuses() async {
    if (_submittedApplications.isEmpty) return;

    final phoneNumbers = _submittedApplications
        .map((app) => app['mobile'] as String)
        .toList();

    try {
      final devId = await ApiService.getDeviceId();
      final res = await ApiService().checkRegistrationsStatus(phoneNumbers, devId);
      final resCode = res['response_code'];
      if ((resCode == 1 || resCode == '1') && res['statuses'] != null) {
        final statuses = res['statuses'] as Map<String, dynamic>;
        
        setState(() {
          for (var app in _submittedApplications) {
            final phone = app['mobile'] as String;
            if (statuses.containsKey(phone)) {
              app['status'] = statuses[phone]['status'] ?? 'pending';
              app['status_message'] = statuses[phone]['message'] ?? 'Under review';
            }
          }
        });

        // Persist updated statuses
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('submitted_memberships', jsonEncode(_submittedApplications));
      }
    } catch (_) {}
  }

  Future<void> _deleteApplication(String phone) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final devId = await ApiService.getDeviceId();
      final res = await ApiService().deleteRegistrationApp(phone, devId);
      final resCode = res['response_code'];
      if (resCode == 1 || resCode == '1') {
        setState(() {
          _submittedApplications.removeWhere((app) => app['mobile'] == phone);
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('submitted_memberships', jsonEncode(_submittedApplications));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application cancelled and deleted successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception:', ''))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_validateStep()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Capture GPS Coordinates
    String lat = '';
    String lng = '';
    try {
      final loc = await LocationService().getLocation(forceRequestPermission: true);
      lat = loc['latitude'] ?? '';
      lng = loc['longitude'] ?? '';
    } catch (_) {}

    final formData = {
      'latitude': lat,
      'longitude': lng,
      'personal': {
        'first_name': _firstNameController.text.trim(),
        'middle_name': _middleNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'mobile_number': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
        'gender': _gender,
      },
      'family': {
        'caste_group': _caste,
        'father_name': _fatherNameController.text.trim(),
        'grandfather_name': _grandfatherNameController.text.trim(),
        'marital_status': _maritalStatus,
        'spouse_name': _maritalStatus == 'Married' ? _spouseNameController.text.trim() : null,
        'blood_group': _bloodGroup,
        'occupation': _occupation,
      },
      'identity': {
        'citizenship_number': _citizenshipNoController.text.trim(),
        'citizenship_district': _citizenshipDistrict,
        'pan': _panController.text.trim(),
      },
      'address': {
        'perm_province': _permProvince,
        'perm_district': _permDistrict,
        'perm_municipality': _permMunicipality,
        'perm_ward': _permWardController.text.trim(),
        'perm_street': _permStreetController.text.trim(),
        'same_as_permanent': _tempSameAsPermanent,
        'temp_province': _tempSameAsPermanent ? _permProvince : _tempProvince,
        'temp_district': _tempSameAsPermanent ? _permDistrict : _tempDistrict,
        'temp_municipality': _tempSameAsPermanent ? _permMunicipality : _tempMunicipality,
        'temp_ward': _tempSameAsPermanent ? _permWardController.text.trim() : _tempWardController.text.trim(),
        'temp_street': _tempSameAsPermanent ? _permStreetController.text.trim() : _tempStreetController.text.trim(),
      },
      'nominee': {
        'name': _nomineeNameController.text.trim().isEmpty ? null : _nomineeNameController.text.trim(),
        'relation': _nomineeRelationController.text.trim().isEmpty ? null : _nomineeRelationController.text.trim(),
      },
      'documents': {
        'profile_photo': _profilePhoto ?? 'mock_profile.png',
        'citizenship_photo': _citizenshipPhoto ?? 'mock_citizenship.png',
        'signature_photo': _signaturePhoto ?? 'mock_signature.png',
        'additional': _additionalDocuments.map((doc) => {
          'title': doc['title']!,
          'file': doc['file']!,
        }).toList(),
      },
    };

    try {
      final devId = await ApiService.getDeviceId();
      final res = await ApiService().registerMember(formData, devId);
      final resCode = res['response_code'];
      if (resCode == 1 || resCode == '1') {
        // Success
        final newApp = {
          'name': '${_firstNameController.text} ${_lastNameController.text}',
          'mobile': _mobileController.text,
          'date': DateTime.now().toString().split(' ')[0],
          'status': 'pending',
          'status_message': 'Under review by bank staff',
        };

        setState(() {
          _submittedApplications.add(newApp);
          _showForm = false;
          _currentStep = 1;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('submitted_memberships', jsonEncode(_submittedApplications));

        _clearFormFields();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membership Self-Registration submitted successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFormFields() {
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _mobileController.clear();
    _emailController.clear();
    _dobController.clear();
    _fatherNameController.clear();
    _grandfatherNameController.clear();
    _spouseNameController.clear();
    _citizenshipNoController.clear();
    _panController.clear();
    _permProvince = 'Province No. 3';
    _permDistrict = 'Kathmandu';
    _permMunicipality = 'Kathmandu';
    _permWardController.clear();
    _permStreetController.clear();
    _tempProvince = 'Province No. 3';
    _tempDistrict = 'Kathmandu';
    _tempMunicipality = 'Kathmandu';
    _tempWardController.clear();
    _tempStreetController.clear();
    _tempSameAsPermanent = true;
    _nomineeNameController.clear();
    _nomineeRelationController.clear();
    _profilePhoto = null;
    _citizenshipPhoto = null;
    _signaturePhoto = null;
    _additionalDocuments.clear();
  }

  void _nextStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_validateStep()) {
      if (_currentStep < 6) {
        setState(() {
          _currentStep++;
        });
        _pageController.animateToPage(
          _currentStep - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _prevStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Exit Registration?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'All entered data will be lost. Are you sure you want to exit?',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text(
                'Exit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _handleBackNavigation() async {
    if (_showForm) {
      if (_currentStep > 1) {
        _prevStep();
      } else {
        final exitConfirmed = await _showExitConfirmationDialog();
        if (exitConfirmed) {
          setState(() {
            _showForm = false;
            _currentStep = 1;
          });
        }
      }
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateStep() {
    if (_currentStep == 1) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _mobileController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _dobController.text.trim().isEmpty) {
        _showErrorSnackBar('Please fill in all required personal details.');
        return false;
      }
      final mobileText = _mobileController.text.trim();
      if (mobileText.length != 10) {
        _showErrorSnackBar('Mobile number must be exactly 10 digits.');
        return false;
      }
      final dobText = _dobController.text.trim();
      final dobRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!dobRegex.hasMatch(dobText)) {
        _showErrorSnackBar('Date of Birth must be in YYYY-MM-DD format.');
        return false;
      }
      final emailText = _emailController.text.trim();
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(emailText)) {
        _showErrorSnackBar('Please enter a valid email address.');
        return false;
      }
    } else if (_currentStep == 2) {
      if (_fatherNameController.text.trim().isEmpty ||
          _grandfatherNameController.text.trim().isEmpty ||
          (_maritalStatus == 'Married' && _spouseNameController.text.trim().isEmpty)) {
        _showErrorSnackBar('Please fill in all required family details.');
        return false;
      }
    } else if (_currentStep == 3) {
      if (_citizenshipNoController.text.trim().isEmpty) {
        _showErrorSnackBar('Citizenship number is required.');
        return false;
      }
    } else if (_currentStep == 4) {
      if (_permWardController.text.trim().isEmpty ||
          (!_tempSameAsPermanent && _tempWardController.text.trim().isEmpty)) {
        _showErrorSnackBar('Address fields (Ward) are required.');
        return false;
      }
    } else if (_currentStep == 6) {
      if (_profilePhoto == null || _citizenshipPhoto == null || _signaturePhoto == null) {
        _showErrorSnackBar('All document scans (profile photo, citizenship certificate, and signature specimen) are required.');
        return false;
      }
    }
    return true;
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_showForm,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Navigator.canPop(context) ? IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: _handleBackNavigation,
          ) : null,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _showForm ? 'Membership Application' : 'Self Registration',
              key: ValueKey(_showForm),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                fontSize: 20,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  final isIncoming = child.key == ValueKey(_showForm ? 'form_wizard' : 'dashboard');
                  final double slideOffset = _showForm ? 0.05 : -0.05;
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: isIncoming ? Offset(slideOffset, 0.0) : Offset(-slideOffset, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _showForm
                    ? KeyedSubtree(
                        key: const ValueKey('form_wizard'),
                        child: _buildFormWizard(isDarkMode),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('dashboard'),
                        child: _buildDashboard(isDarkMode),
                      ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Dashboard layout listing submitted memberships
  Widget _buildDashboard(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Apply Button Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Become a Bank Member',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Submit your details self-registration details directly to bank board reviews.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showForm = true;
                        _currentStep = 1;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.black : Colors.white,
                      foregroundColor: isDarkMode ? Colors.white : const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: isDarkMode 
                            ? BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1)
                            : BorderSide.none,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply New Membership',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Heading
          Text(
            'Submitted Applications'.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),

          // Applications List
          Expanded(
            child: _submittedApplications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.feed_outlined,
                          size: 48,
                          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No registrations submitted yet.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _submittedApplications.length,
                    itemBuilder: (context, index) {
                      final app = _submittedApplications[index];
                      final name = app['name'] ?? 'Application';
                      final phone = app['mobile'] ?? 'N/A';
                      final date = app['date'] ?? '';
                      final status = app['status'] ?? 'pending';
                      final isPending = status.toString().toLowerCase() == 'pending';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mobile: $phone  •  $date',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPending 
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.08) 
                                          : const Color(0xFF10B981).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPending)
                              IconButton(
                                onPressed: () => _deleteApplication(phone),
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormWizard(bool isDarkMode) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        final stepNum = index + 1;
        return _buildStepPage(stepNum, isDarkMode);
      },
    );
  }

  Widget _buildStepPage(int stepNum, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepsIndicator(stepNum, isDarkMode),
          const SizedBox(height: 24),
          _buildActiveStepFieldsForStep(stepNum, isDarkMode),
          const SizedBox(height: 32),
          _buildStepNavigationControls(stepNum, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStepsIndicator(int currentStep, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (idx) {
          final stepNum = idx + 1;
          final isCurrent = stepNum == currentStep;
          final isCompleted = stepNum < currentStep;

          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? const Color(0xFF2563EB)
                  : isCompleted
                      ? const Color(0xFF10B981)
                      : isDarkMode
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFE2E8F0),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF2563EB)
                    : isCompleted
                        ? const Color(0xFF10B981)
                        : isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFCBD5E1),
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Text(
                      '$stepNum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isCurrent || isCompleted
                            ? Colors.white
                            : isDarkMode
                                ? const Color(0xFF64748B)
                                : const Color(0xFF475569),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepNavigationControls(int stepNum, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (stepNum > 1)
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        if (stepNum > 1) const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: stepNum == 6 ? _submitForm : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                stepNum == 6 ? 'Submit Application' : 'Continue',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveStepFieldsForStep(int stepNum, bool isDarkMode) {
    switch (stepNum) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepTitle('Personal Information'),
            _buildDropdown(
              label: 'Title',
              value: _title,
              items: const ['Mr', 'Mrs', 'Ms'],
              onChanged: (val) => setState(() => _title = val!),
            ),
            _buildTextField(label: 'First Name *', controller: _firstNameController),
            _buildTextField(label: 'Middle Name (Optional)', controller: _middleNameController),
            _buildTextField(label: 'Last Name *', controller: _lastNameController),
            _buildTextField(
              label: 'Mobile Number *',
              controller: _mobileController,
              type: TextInputType.phone,
              formatters: [PhoneNumberFormatter()],
            ),
            _buildTextField(label: 'Email Address *', controller: _emailController, type: TextInputType.emailAddress),
            _buildTextField(
              label: 'Date of Birth(BS) *',
              controller: _dobController,
              hint: '',
              type: TextInputType.number,
              formatters: [DateMaskTextInputFormatter()],
            ),
            _buildDropdown(
              label: 'Gender',
              value: _gender,
              items: const ['Male', 'Female', 'Other'],
              onChanged: (val) => setState(() => _gender = val!),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepTitle('Bio & Family Details'),
            _buildDropdown(
              label: 'Caste/Group',
              value: _caste,
              items: const ['Brahmin/Chhetri', 'Aadibasi/Janajati', 'Dalit', 'Madhesi', 'Other'],
              onChanged: (val) => setState(() => _caste = val!),
            ),
            _buildTextField(label: 'Father\'s Full Name *', controller: _fatherNameController),
            _buildTextField(label: 'Grandfather\'s Full Name *', controller: _grandfatherNameController),
            _buildDropdown(
              label: 'Marital Status',
              value: _maritalStatus,
              items: const ['Unmarried', 'Married', 'Divorced', 'Widowed'],
              onChanged: (val) => setState(() => _maritalStatus = val!),
            ),
            if (_maritalStatus == 'Married')
              _buildTextField(label: 'Spouse\'s Full Name *', controller: _spouseNameController),
            _buildDropdown(
              label: 'Blood Group',
              value: _bloodGroup,
              items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
              onChanged: (val) => setState(() => _bloodGroup = val!),
            ),
            _buildDropdown(
              label: 'Occupation',
              value: _occupation,
              items: const ['Government Service', 'Private Sector', 'Agriculture', 'Business', 'Student', 'Unemployed'],
              onChanged: (val) => setState(() => _occupation = val!),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepTitle('Identity Credentials'),
            _buildTextField(label: 'Citizenship Number *', controller: _citizenshipNoController),
            _buildDropdown(
              label: 'Citizenship Issue District *',
              value: _citizenshipDistrict,
              items: LocationData.districts.map((d) => d['name'] as String).toList(),
              onChanged: (val) => setState(() => _citizenshipDistrict = val!),
            ),
            _buildTextField(label: 'PAN Number (Optional)', controller: _panController),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepTitle('Permanent Address Details'),
            _buildDropdown(
              label: 'Province *',
              value: _permProvince,
              items: _getProvinceNames(),
              onChanged: (val) => _onPermProvinceChanged(val!),
            ),
            _buildDropdown(
              label: 'District *',
              value: _permDistrict,
              items: _getDistrictNamesForProvince(_permProvince),
              onChanged: (val) => _onPermDistrictChanged(val!),
            ),
            _buildDropdown(
              label: 'Municipality / Rural Mun *',
              value: _permMunicipality,
              items: _getVdcNamesForDistrict(_permDistrict),
              onChanged: (val) => setState(() => _permMunicipality = val!),
            ),
            _buildTextField(label: 'Ward Number *', controller: _permWardController, type: TextInputType.number),
            _buildTextField(label: 'Tole / Street Name', controller: _permStreetController),

            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _tempSameAsPermanent,
                  onChanged: (val) => setState(() => _tempSameAsPermanent = val!),
                  activeColor: const Color(0xFF2563EB),
                ),
                const Text('Temporary Address is same as Permanent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),

            if (!_tempSameAsPermanent) ...[
              const SizedBox(height: 20),
              _buildStepTitle('Temporary Address Details'),
              _buildDropdown(
                label: 'Province *',
                value: _tempProvince,
                items: _getProvinceNames(),
                onChanged: (val) => _onTempProvinceChanged(val!),
              ),
              _buildDropdown(
                label: 'District *',
                value: _tempDistrict,
                items: _getDistrictNamesForProvince(_tempProvince),
                onChanged: (val) => _onTempDistrictChanged(val!),
              ),
              _buildDropdown(
                label: 'Municipality / Rural Mun *',
                value: _tempMunicipality,
                items: _getVdcNamesForDistrict(_tempDistrict),
                onChanged: (val) => setState(() => _tempMunicipality = val!),
              ),
              _buildTextField(label: 'Ward Number *', controller: _tempWardController, type: TextInputType.number),
              _buildTextField(label: 'Tole / Street Name', controller: _tempStreetController),
            ],
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepTitle('Nominee Information (Optional)'),
            _buildTextField(label: 'Nominee Full Name', controller: _nomineeNameController),
            _buildTextField(label: 'Relation with Nominee', controller: _nomineeRelationController),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepTitle('Documents Upload'),
            const Text(
              'Please select or take clear photos of the requested documents. Tap each card to pick from camera or gallery.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            
            _buildDocUploadCard('Applicant Profile Photo *', _profilePhoto, (path) => setState(() => _profilePhoto = path), isDarkMode),
            _buildDocUploadCard('Citizenship Certificate Scan *', _citizenshipPhoto, (path) => setState(() => _citizenshipPhoto = path), isDarkMode),
            _buildDocUploadCard('Signature Specimen Scan *', _signaturePhoto, (path) => setState(() => _signaturePhoto = path), isDarkMode),

            // Additional Documents list
            if (_additionalDocuments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Additional Documents'.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 12),
              ..._additionalDocuments.asMap().entries.map((entry) {
                final idx = entry.key;
                final doc = entry.value;
                return _buildAdditionalDocCard(doc['title']!, doc['file']!, idx, isDarkMode);
              }),
            ],

            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _showAddCustomDocDialog(isDarkMode),
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Add Custom Document'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                  ),
                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
                  foregroundColor: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAdditionalDocCard(String title, String base64Str, int index, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_rounded, color: Color(0xFF2563EB), size: 20),
                    onPressed: () => _showImagePreviewDialog(base64Str),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    onPressed: () {
                      setState(() {
                        _additionalDocuments.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _base64ToBytes(base64Str),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 140,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomDocDialog(bool isDarkMode) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Custom Document',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Lalpurja, Nominee Citizenship',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          return;
                        }
                        Navigator.pop(context);
                        _showImageSourceSheet((base64Str) {
                          if (base64Str != null) {
                            setState(() {
                              _additionalDocuments.add({
                                'title': title,
                                'file': base64Str,
                              });
                            });
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.white : const Color(0xFF2563EB),
                        foregroundColor: isDarkMode ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Select Image'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    }

  Widget _buildStepTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    String? hint,
    List<TextInputFormatter>? formatters,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: type,
            inputFormatters: formatters,
            style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              _showSearchableSelect(
                title: label,
                options: items,
                currentValue: value,
                onSelected: (val) {
                  onChanged(val);
                },
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Uint8List _base64ToBytes(String base64Str) {
    final cleanStr = base64Str.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
    return base64.decode(cleanStr);
  }

  void _showImageSourceSheet(ValueChanged<String?> onUploaded) {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(context);
                      final ImagePicker picker = ImagePicker();
                      final XFile? file = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,
                      );
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        onUploaded('data:image/jpeg;base64,${base64.encode(bytes)}');
                      }
                    },
                    isDarkMode: isDarkMode,
                  ),
                  _buildSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(context);
                      final ImagePicker picker = ImagePicker();
                      final XFile? file = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                      );
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        onUploaded('data:image/jpeg;base64,${base64.encode(bytes)}');
                      }
                    },
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    ).then((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Widget _buildSourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2563EB)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreviewDialog(String base64Str) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _base64ToBytes(base64Str),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchableSelect({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SearchableSelectSheet(
          title: title,
          options: options,
          currentValue: currentValue,
          onSelected: onSelected,
        );
      },
    ).then((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Widget _buildDocUploadCard(
    String title,
    String? path,
    ValueChanged<String?> onUploaded,
    bool isDarkMode,
  ) {
    final hasFile = path != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              if (hasFile)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded, color: Color(0xFF2563EB), size: 20),
                      onPressed: () => _showImagePreviewDialog(path),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      onPressed: () => onUploaded(null),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: hasFile ? null : () => _showImageSourceSheet(onUploaded),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                ),
              ),
              child: hasFile
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _base64ToBytes(path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 36, color: const Color(0xFF2563EB).withValues(alpha: 0.8)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Camera or Gallery • Max 2MB',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchableSelectSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String currentValue;
  final ValueChanged<String> onSelected;

  const _SearchableSelectSheet({
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  State<_SearchableSelectSheet> createState() => _SearchableSelectSheetState();
}

class _SearchableSelectSheetState extends State<_SearchableSelectSheet> {
  late List<String> _filteredOptions;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options
            .where((opt) => opt.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Select ${widget.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          // Search Field
          if (widget.options.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    hintText: 'Search options...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Options List
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: _filteredOptions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: const Color(0xFF64748B).withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No matching options found',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                      itemCount: _filteredOptions.length,
                      itemBuilder: (context, index) {
                        final opt = _filteredOptions[index];
                        final isSelected = opt == widget.currentValue;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            onTap: () {
                              widget.onSelected(opt);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB).withValues(alpha: isDarkMode ? 0.15 : 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      opt,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : (isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          SizedBox(height: keyboardHeight),
        ],
      ),
    );
  }
}

class DateMaskTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    
    var text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 8) {
      text = text.substring(0, 8);
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 3 && text.length > 4) || (i == 5 && text.length > 6)) {
        buffer.write('-');
      }
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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
