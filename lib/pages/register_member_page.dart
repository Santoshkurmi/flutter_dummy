import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

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
  String _permProvince = 'Bagmati';
  String _permDistrict = 'Kathmandu';
  final _permMunController = TextEditingController();
  final _permWardController = TextEditingController();
  final _permStreetController = TextEditingController();
  
  bool _tempSameAsPermanent = true;
  String _tempProvince = 'Bagmati';
  String _tempDistrict = 'Kathmandu';
  final _tempMunController = TextEditingController();
  final _tempWardController = TextEditingController();
  final _tempStreetController = TextEditingController();

  // Step 5: Nominee Details
  final _nomineeNameController = TextEditingController();
  final _nomineeRelationController = TextEditingController();

  // Step 6: Documents (Simulated Base64 Upload paths)
  String? _profilePhoto;
  String? _citizenshipPhoto;
  String? _signaturePhoto;

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
      if (res['response_code'] == 0 && res['statuses'] != null) {
        final statuses = res['statuses'] as Map<String, dynamic>;
        
        setState(() {
          for (var app in _submittedApplications) {
            final phone = app['mobile'] as String;
            if (statuses.containsKey(phone)) {
              app['status'] = statuses[phone]['status'] ?? 'Pending';
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
      if (res['response_code'] == 0) {
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
    setState(() {
      _isLoading = true;
    });

    final formData = {
      'title': _title,
      'first_name': _firstNameController.text,
      'middle_name': _middleNameController.text,
      'last_name': _lastNameController.text,
      'mobile': _mobileController.text,
      'email': _emailController.text,
      'dob': _dobController.text,
      'gender': _gender,
      'caste': _caste,
      'father_name': _fatherNameController.text,
      'grandfather_name': _grandfatherNameController.text,
      'marital_status': _maritalStatus,
      'spouse_name': _spouseNameController.text,
      'blood_group': _bloodGroup,
      'occupation': _occupation,
      'citizenship_no': _citizenshipNoController.text,
      'citizenship_district': _citizenshipDistrict,
      'pan': _panController.text,
      'perm_province': _permProvince,
      'perm_district': _permDistrict,
      'perm_mun': _permMunController.text,
      'perm_ward': _permWardController.text,
      'perm_street': _permStreetController.text,
      'temp_same_as_permanent': _tempSameAsPermanent,
      'temp_province': _tempSameAsPermanent ? _permProvince : _tempProvince,
      'temp_district': _tempSameAsPermanent ? _permDistrict : _tempDistrict,
      'temp_mun': _tempSameAsPermanent ? _permMunController.text : _tempMunController.text,
      'temp_ward': _tempSameAsPermanent ? _permWardController.text : _tempWardController.text,
      'temp_street': _tempSameAsPermanent ? _permStreetController.text : _tempStreetController.text,
      'nominee_name': _nomineeNameController.text,
      'nominee_relation': _nomineeRelationController.text,
      'profile_photo': _profilePhoto ?? 'mock_profile.png',
      'citizenship_photo': _citizenshipPhoto ?? 'mock_citizenship.png',
      'signature_photo': _signaturePhoto ?? 'mock_signature.png',
    };

    try {
      final devId = await ApiService.getDeviceId();
      final res = await ApiService().registerMember(formData, devId);
      if (res['response_code'] == 0) {
        // Success
        final newApp = {
          'name': '${_firstNameController.text} ${_lastNameController.text}',
          'mobile': _mobileController.text,
          'date': DateTime.now().toString().split(' ')[0],
          'status': 'Pending',
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
    _permMunController.clear();
    _permWardController.clear();
    _permStreetController.clear();
    _tempMunController.clear();
    _tempWardController.clear();
    _tempStreetController.clear();
    _nomineeNameController.clear();
    _nomineeRelationController.clear();
    _profilePhoto = null;
    _citizenshipPhoto = null;
    _signaturePhoto = null;
  }

  void _nextStep() {
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

  bool _validateStep() {
    if (_currentStep == 1) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _mobileController.text.trim().isEmpty ||
          _dobController.text.trim().isEmpty) {
        _showErrorSnackBar('Please fill in all required personal details.');
        return false;
      }
    } else if (_currentStep == 2) {
      if (_fatherNameController.text.trim().isEmpty ||
          _grandfatherNameController.text.trim().isEmpty) {
        _showErrorSnackBar('Family lineage detail fields are required.');
        return false;
      }
    } else if (_currentStep == 3) {
      if (_citizenshipNoController.text.trim().isEmpty) {
        _showErrorSnackBar('Citizenship number is required.');
        return false;
      }
    } else if (_currentStep == 4) {
      if (_permMunController.text.trim().isEmpty ||
          _permWardController.text.trim().isEmpty ||
          (!_tempSameAsPermanent &&
              (_tempMunController.text.trim().isEmpty || _tempWardController.text.trim().isEmpty))) {
        _showErrorSnackBar('Address fields (Municipality & Ward) are required.');
        return false;
      }
    } else if (_currentStep == 5) {
      if (_nomineeNameController.text.trim().isEmpty ||
          _nomineeRelationController.text.trim().isEmpty) {
        _showErrorSnackBar('Nominee fields are required.');
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
            if (_showForm) {
              setState(() {
                _showForm = false;
                _currentStep = 1;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _showForm ? 'Membership Application' : 'Self Registration',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              )
            : _showForm
                ? _buildFormWizard(isDarkMode)
                : _buildDashboard(isDarkMode),
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
                  color: const Color(0xFF2563EB).withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.8),
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
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                      final status = app['status'] ?? 'Pending';
                      final isPending = status == 'Pending';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
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
                                          ? const Color(0xFFF59E0B).withOpacity(0.08) 
                                          : const Color(0xFF10B981).withOpacity(0.08),
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
          color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
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
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFE2E8F0),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF2563EB)
                    : isCompleted
                        ? const Color(0xFF10B981)
                        : isDarkMode
                            ? Colors.white.withOpacity(0.08)
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
                    color: isDarkMode ? Colors.white.withOpacity(0.1) : const Color(0xFFCBD5E1),
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
            _buildTextField(label: 'Mobile Number *', controller: _mobileController, type: TextInputType.phone),
            _buildTextField(label: 'Email Address', controller: _emailController, type: TextInputType.emailAddress),
            _buildTextField(label: 'Date of Birth (YYYY-MM-DD) *', controller: _dobController, hint: 'e.g. 2045-05-12'),
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
              _buildTextField(label: 'Spouse\'s Full Name', controller: _spouseNameController),
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
              items: const ['Kathmandu', 'Lalitpur', 'Bhaktapur', 'Kaski', 'Morang', 'Jhapa', 'Dang', 'Chitwan', 'Rupandehi'],
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
              items: const ['Koshi', 'Madhesh', 'Bagmati', 'Gandaki', 'Lumbini', 'Karnali', 'Sudurpashchim'],
              onChanged: (val) => setState(() => _permProvince = val!),
            ),
            _buildDropdown(
              label: 'District *',
              value: _permDistrict,
              items: const ['Kathmandu', 'Lalitpur', 'Bhaktapur', 'Kaski', 'Morang', 'Jhapa', 'Dang', 'Chitwan', 'Rupandehi'],
              onChanged: (val) => setState(() => _permDistrict = val!),
            ),
            _buildTextField(label: 'Municipality / Rural Mun *', controller: _permMunController),
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
                items: const ['Koshi', 'Madhesh', 'Bagmati', 'Gandaki', 'Lumbini', 'Karnali', 'Sudurpashchim'],
                onChanged: (val) => setState(() => _tempProvince = val!),
              ),
              _buildDropdown(
                label: 'District *',
                value: _tempDistrict,
                items: const ['Kathmandu', 'Lalitpur', 'Bhaktapur', 'Kaski', 'Morang', 'Jhapa', 'Dang', 'Chitwan', 'Rupandehi'],
                onChanged: (val) => setState(() => _tempDistrict = val!),
              ),
              _buildTextField(label: 'Municipality / Rural Mun *', controller: _tempMunController),
              _buildTextField(label: 'Ward Number *', controller: _tempWardController, type: TextInputType.number),
              _buildTextField(label: 'Tole / Street Name', controller: _tempStreetController),
            ],
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepTitle('Nominee Information'),
            _buildTextField(label: 'Nominee Full Name *', controller: _nomineeNameController),
            _buildTextField(label: 'Relation with Nominee *', controller: _nomineeRelationController),
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
            
            _buildDocUploadCard('Applicant Profile Photo', _profilePhoto, (path) => setState(() => _profilePhoto = path), isDarkMode),
            _buildDocUploadCard('Citizenship Certificate Scan', _citizenshipPhoto, (path) => setState(() => _citizenshipPhoto = path), isDarkMode),
            _buildDocUploadCard('Signature Specimen Scan', _signaturePhoto, (path) => setState(() => _signaturePhoto = path), isDarkMode),
          ],
        );
    }
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
            style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
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
                border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
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
    );
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
          color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
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
                  backgroundColor: Colors.black.withOpacity(0.6),
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
    );
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
          color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
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
                color: isDarkMode ? Colors.white.withOpacity(0.02) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
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
                          Icon(Icons.cloud_upload_outlined, size: 36, color: const Color(0xFF2563EB).withOpacity(0.8)),
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
            color: Colors.black.withOpacity(0.15),
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
                color: isDarkMode ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
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
                  color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
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
                          Icon(Icons.search_off_rounded, size: 48, color: const Color(0xFF64748B).withOpacity(0.5)),
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
                                    ? const Color(0xFF2563EB).withOpacity(isDarkMode ? 0.15 : 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB).withOpacity(0.3)
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
