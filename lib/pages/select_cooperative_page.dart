import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../store/auth_store.dart';
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
      backgroundColor: const Color(0xFF0F172A),
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
                              color: Colors.white.withOpacity(0.08),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      const Text(
                        'Select Cooperative',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B)),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    hintText: 'Search cooperative or location...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
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
                      ? const Center(
                          child: Text(
                            'No cooperatives found.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const StatusCheckPage(),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.06),
                                    ),
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
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_rounded,
                                                  size: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    coop['address'] ?? '',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF64748B),
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
