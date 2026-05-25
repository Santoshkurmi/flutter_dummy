import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import 'status_check_page.dart';

class SelectCooperativePage extends StatefulWidget {
  const SelectCooperativePage({super.key});

  @override
  State<SelectCooperativePage> createState() => _SelectCooperativePageState();
}

class _SelectCooperativePageState extends State<SelectCooperativePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _cooperatives = [];
  List<Map<String, dynamic>> _filteredCooperatives = [];
  bool _isLoading = true;

  bool get _isDarkMode => AuthStore().isDarkMode;

  @override
  void initState() {
    super.initState();
    _loadCooperatives();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCooperatives() async {
    try {
      final list = await ApiService().fetchCooperatives();
      setState(() {
        _cooperatives = list;
        _filteredCooperatives = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCooperatives = _cooperatives.where((coop) {
        final name = (coop['name'] as String).toLowerCase();
        final address = (coop['address'] as String).toLowerCase();
        return name.contains(query) || address.contains(query);
      }).toList();
    });
  }

  // Maps CSS Tailwind classes to premium linear gradients in Flutter
  LinearGradient _getGradient(String gradientClass) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                              size: 16,
                            ),
                          ),
                        ),
                      Text(
                        'Select Cooperative'.tr,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                  ),
                  boxShadow: _isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    hintText: 'Search Cooperative...'.tr,
                    hintStyle: TextStyle(color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Cooperative List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    )
                  : _filteredCooperatives.isEmpty
                      ? Center(
                          child: Text(
                            'No cooperatives found.',
                            style: TextStyle(color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: _filteredCooperatives.length,
                          itemBuilder: (context, index) {
                            final coop = _filteredCooperatives[index];
                            final gradient = _getGradient(coop['gradient'] ?? 'bg-blue-600');
                            final initialLetter = (coop['name'] as String).substring(0, 1);
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: () async {
                                  await AuthStore().setSelectedCooperative(coop);
                                  if (mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const StatusCheckPage(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                                    ),
                                    boxShadow: _isDarkMode
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.02),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            )
                                          ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Visual Icon with dynamic gradient
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: gradient,
                                        ),
                                        child: Center(
                                          child: Text(
                                            initialLetter,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Name and Address
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              physics: const BouncingScrollPhysics(),
                                              child: Text(
                                                coop['name'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_rounded,
                                                  size: 14,
                                                  color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    coop['address'] ?? '',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
