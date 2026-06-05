import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/error_state_view.dart';

class MemberDetailsPage extends StatefulWidget {
  const MemberDetailsPage({super.key});

  @override
  State<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _memberData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  Future<void> _fetchMemberDetails() async {
    try {
      final response = await ApiService().getMemberDetails();
      if (mounted) {
        setState(() {
          _memberData = response['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AuthStore().isDarkMode;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBgColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0);
    final String currentLang = AuthStore().language;

    final m = _memberData?['member'] ?? {};
    final String name = currentLang == 'ne'
        ? (m['full_name_nepali'] ?? m['full_name'] ?? 'Sahakari Member')
        : (m['full_name'] ?? 'Sahakari Member');

    final profileImg = m['profile_image_url'];
    final bool hasProfileImg = profileImg != null && profileImg.toString().isNotEmpty;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Member Details'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
            : _errorMessage != null
                ? ErrorStateView(
                    errorMessage: _errorMessage,
                    isDarkMode: isDarkMode,
                    onRetry: () async {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      await _fetchMemberDetails();
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    children: [
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardBgColor,
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasProfileImg
                              ? ClipOval(
                                  child: CachedImage(
                                    imageUrl: profileImg,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildInitialsPlaceholder(name),
                                    placeholder: _buildInitialsPlaceholder(name),
                                  ),
                                )
                              : _buildInitialsPlaceholder(name),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 1. Membership Info
                      _buildInfoSection(
                        title: 'Membership Information'.tr,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                        items: [
                          _buildInfoRow(Icons.badge_rounded, 'Membership Number'.tr, _memberData?['membership_number'], primaryTextColor, secondaryTextColor, isNumeric: true),
                          _buildInfoRow(Icons.phone_iphone_rounded, 'Mobile Number'.tr, _memberData?['mobile_number'], primaryTextColor, secondaryTextColor, isNumeric: true),
                          _buildInfoRow(Icons.email_rounded, 'Email Address'.tr, _memberData?['email'], primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.calendar_month_rounded, 'Joined Date'.tr, currentLang == 'ne' ? m['joined_date_bs'] : m['joined_date_ad'], primaryTextColor, secondaryTextColor, isNumeric: true),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. Personal Info
                      _buildInfoSection(
                        title: 'Personal Specifications'.tr,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                        items: [
                          _buildInfoRow(Icons.transgender_rounded, 'Gender'.tr, m['gender']?.toString().tr, primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.cake_rounded, 'Date of Birth'.tr, currentLang == 'ne' ? m['date_of_birth_bs'] : m['date_of_birth_ad'], primaryTextColor, secondaryTextColor, isNumeric: true),
                          _buildInfoRow(Icons.flag_rounded, 'Nationality'.tr, m['nationality'], primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.bloodtype_rounded, 'Blood Group'.tr, m['blood_group'], primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.credit_card_rounded, 'PAN Number'.tr, m['pan_number'], primaryTextColor, secondaryTextColor, isNumeric: true),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 3. Address Info
                      _buildInfoSection(
                        title: 'Addresses'.tr,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                        items: [
                          _buildInfoRow(Icons.home_rounded, 'Permanent Address'.tr, currentLang == 'ne' ? (m['permanent_address_nepali'] ?? m['permanent_address']) : m['permanent_address'], primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.place_rounded, 'Temporary Address'.tr, currentLang == 'ne' ? (m['temporary_address_nepali'] ?? m['temporary_address']) : m['temporary_address'], primaryTextColor, secondaryTextColor),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 4. Family Info
                      _buildInfoSection(
                        title: 'Family & Kinship'.tr,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                        items: [
                          _buildInfoRow(Icons.person_rounded, 'Father\'s Name'.tr, currentLang == 'ne' ? (m['father_nepali_name'] ?? m['father_name']) : m['father_name'], primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.person_outline_rounded, 'Mother\'s Name'.tr, currentLang == 'ne' ? (m['mother_nepali_name'] ?? m['mother_name']) : m['mother_name'], primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.elderly_rounded, 'Grandfather\'s Name'.tr, currentLang == 'ne' ? (m['grandfather_nepali_name'] ?? m['grand_father_name']) : m['grand_father_name'], primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.favorite_rounded, 'Marital Status'.tr, m['marital_status']?.toString().tr, primaryTextColor, secondaryTextColor),
                          if (m['spouse_name'] != null && m['spouse_name'].toString().isNotEmpty)
                            _buildInfoRow(Icons.people_alt_rounded, 'Spouse\'s Name'.tr, currentLang == 'ne' ? (m['spouse_nepali_name'] ?? m['spouse_name']) : m['spouse_name'], primaryTextColor, secondaryTextColor),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 5. Nominee Info
                      _buildInfoSection(
                        title: 'Nominee details'.tr,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                        items: [
                          _buildInfoRow(Icons.assignment_ind_rounded, 'Nominee Name'.tr, m['nominee_name'], primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.family_restroom_rounded, 'Relation'.tr, m['nominee_relation']?.toString().tr, primaryTextColor, secondaryTextColor),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 6. Legal Identity
                      _buildInfoSection(
                        title: 'Legal Identities'.tr,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                        items: [
                          _buildInfoRow(Icons.assignment_rounded, 'Citizenship Number'.tr, m['citizenship_number'], primaryTextColor, secondaryTextColor, isNumeric: true),
                          _buildInfoRow(Icons.map_rounded, 'Citizenship District'.tr, m['citizenship_district'], primaryTextColor, secondaryTextColor),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }

  Widget _buildInitialsPlaceholder(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
      ),
      child: Center(
        child: Text(
          name.isEmpty ? 'S' : name.substring(0, 1),
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required Color borderColor,
    required Color cardBgColor,
    required List<Widget> items,
  }) {
    final isDarkMode = AuthStore().isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String? value,
    Color primaryTextColor,
    Color secondaryTextColor, {
    bool isNumeric = false,
  }) {
    final String currentLang = AuthStore().language;
    String displayValue = value ?? '-';
    
    if (currentLang == 'ne' && isNumeric && displayValue != '-') {
      displayValue = displayValue.trd;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AuthStore().isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Text(
              displayValue,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
