import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/error_state_view.dart';

class CooperativeDetailsPage extends StatefulWidget {
  const CooperativeDetailsPage({super.key});

  @override
  State<CooperativeDetailsPage> createState() => _CooperativeDetailsPageState();
}

class _CooperativeDetailsPageState extends State<CooperativeDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _coopData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCooperativeDetails();
  }

  Future<void> _fetchCooperativeDetails() async {
    try {
      final response = await ApiService().getCooperativeDetails();
      if (mounted) {
        setState(() {
          _coopData = response['data'];
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
          'Cooperative Details'.tr,
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
                      await _fetchCooperativeDetails();
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    children: [
                      if (_coopData?['logo_url'] != null && _coopData!['logo_url'].toString().isNotEmpty)
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor),
                            ),
                            child: ClipOval(
                              child: CachedImage(
                                imageUrl: _coopData!['logo_url'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.account_balance_rounded,
                                    size: 48,
                                    color: Color(0xFF2563EB),
                                  );
                                },
                                placeholder: const Icon(
                                  Icons.account_balance_rounded,
                                  size: 48,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Text(
                        currentLang == 'ne'
                            ? (_coopData?['name_nepali'] ?? _coopData?['name'] ?? 'Cooperative Name'.tr)
                            : (_coopData?['name'] ?? 'Cooperative Name'.tr),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(
                        title: 'Registration & Legality'.tr,
                        isDarkMode: isDarkMode,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        items: [
                          _buildInfoRow(Icons.calendar_month_rounded, 'Establish Date'.tr, _coopData?['org_estd'], _coopData?['org_estd_nepali'], primaryTextColor, secondaryTextColor, isNumeric: true),
                          _buildInfoRow(Icons.app_registration_rounded, 'Registration No.'.tr, _coopData?['reg_no'], _coopData?['reg_no_nepali'], primaryTextColor, secondaryTextColor, isNumeric: true),
                          _buildInfoRow(Icons.credit_card_rounded, 'PAN Number'.tr, _coopData?['pan_no'], _coopData?['pan_no_nepali'], primaryTextColor, secondaryTextColor, isNumeric: true),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoSection(
                        title: 'Contact Information'.tr,
                        isDarkMode: isDarkMode,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        items: [
                          _buildInfoRow(Icons.place_rounded, 'Address'.tr, _coopData?['address'], _coopData?['address_nepali'], primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.phone_rounded, 'Phone Number'.tr, _coopData?['phone_no'], _coopData?['phone_no_nepali'], primaryTextColor, secondaryTextColor, isNumeric: true),
                          _buildInfoRow(Icons.email_rounded, 'Email Address'.tr, _coopData?['email'], null, primaryTextColor, secondaryTextColor),
                          _buildInfoRow(Icons.language_rounded, 'Website'.tr, _coopData?['website'], null, primaryTextColor, secondaryTextColor),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required bool isDarkMode,
    required Color borderColor,
    required Color cardBgColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required List<Widget> items,
  }) {
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
    String? englishValue,
    String? nepaliValue,
    Color primaryTextColor,
    Color secondaryTextColor, {
    bool isNumeric = false,
  }) {
    final String currentLang = AuthStore().language;
    String displayValue = '-';
    
    if (currentLang == 'ne') {
      displayValue = (nepaliValue != null && nepaliValue.isNotEmpty) 
          ? nepaliValue 
          : (englishValue ?? '-');
      if (isNumeric && displayValue != '-') {
        displayValue = displayValue.trd;
      }
    } else {
      displayValue = englishValue ?? '-';
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
