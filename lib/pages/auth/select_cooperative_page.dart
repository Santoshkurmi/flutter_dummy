import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import 'status_check_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  String? _errorMessage;

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

  Future<void> _loadCooperatives({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final list = await ApiService().fetchCooperatives(forceRefresh: forceRefresh);
      final List<Map<String, dynamic>> modifiedList = List<Map<String, dynamic>>.from(list);
      if (dotenv.env['IS_DEBUG'] == 'yes') {
        final currentUrl = AuthStore().customApiUrl ?? dotenv.env['API_URL'] ?? 'http://192.168.1.253:8000';
        modifiedList.add({
          'id': 99999,
          'name': 'Development Mode',
          'address': dotenv.env['API_URL'] ?? 'http://192.168.1.253:8000',
          'url': currentUrl,
          'api_url': currentUrl,
          'gradient': 'bg-rose-600',
          'logoUrl': '',
          'isDevMode': true,
        });
      }
      if (mounted) {
        setState(() {
          _cooperatives = modifiedList;
          _filteredCooperatives = modifiedList;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final List<Map<String, dynamic>> fallbackList = [];
        if (dotenv.env['IS_DEBUG'] == 'yes') {
          final currentUrl = AuthStore().customApiUrl ?? dotenv.env['API_URL'] ?? 'http://192.168.1.253:8000';
          fallbackList.add({
            'id': 99999,
            'name': 'Development Mode',
            'address': dotenv.env['API_URL'] ?? 'http://192.168.1.253:8000',
            'url': currentUrl,
            'api_url': currentUrl,
            'gradient': 'bg-rose-600',
            'logoUrl': '',
            'isDevMode': true,
          });
        }
        setState(() {
          _cooperatives = fallbackList;
          _filteredCooperatives = fallbackList;
          _isLoading = false;
          _errorMessage = fallbackList.isEmpty ? e.toString().replaceFirst('Exception: ', '') : null;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCooperatives = _cooperatives.where((coop) {
        final name = (coop['name'] as String? ?? '').toLowerCase();
        final address = (coop['address'] as String? ?? '').toLowerCase();
        return name.contains(query) || address.contains(query);
      }).toList();
    });
  }

  void _showApiUrlDialog(BuildContext context) {
    final String initialUrl = AuthStore().customApiUrl ?? dotenv.env['API_URL'] ?? 'http://192.168.1.253:8000/api/mobile-banking/v1';
    
    String initialScheme = 'http';
    String initialHost = '192.168.1.253';
    String initialPort = '8000';
    String initialPath = '/api/mobile-banking/v1';

    try {
      final uri = Uri.parse(initialUrl);
      if (uri.hasScheme) {
        initialScheme = uri.scheme;
      }
      initialHost = uri.host;
      if (uri.hasPort) {
        initialPort = uri.port.toString();
      } else {
        initialPort = '';
      }
      initialPath = uri.path;
    } catch (_) {
      // Fallback defaults
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String dialogScheme = initialScheme;
        final hostController = TextEditingController(text: initialHost);
        final portController = TextEditingController(text: initialPort);
        final pathController = TextEditingController(text: initialPath);

        String getAssembledUrl(String scheme, String host, String port, String path) {
          final cleanHost = host.trim();
          final cleanPort = port.trim();
          var cleanPath = path.trim();
          if (cleanPath.isNotEmpty && !cleanPath.startsWith('/')) {
            cleanPath = '/$cleanPath';
          }
          if (cleanHost.isEmpty) return '';
          final portPart = cleanPort.isNotEmpty ? ':$cleanPort' : '';
          return '$scheme://$cleanHost$portPart$cleanPath';
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final assembledUrl = getAssembledUrl(
              dialogScheme,
              hostController.text,
              portController.text,
              pathController.text,
            );

            return Dialog(
              backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Row(
                        children: [
                          const Icon(Icons.developer_board_rounded, color: Color(0xFF2563EB)),
                          const SizedBox(width: 10),
                          const Text(
                            'Developer Gateway',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Body/Description
                      const Text(
                        'Configure your API URL gateway endpoint below. Changes will persist across app restarts.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      
                      // Protocol selection
                      const Text(
                        'Protocol',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  dialogScheme = 'http';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: dialogScheme == 'http'
                                      ? const Color(0xFF2563EB)
                                      : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                  border: Border.all(
                                    color: dialogScheme == 'http'
                                        ? const Color(0xFF2563EB)
                                        : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'HTTP',
                                    style: TextStyle(
                                      color: dialogScheme == 'http' ? Colors.white : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  dialogScheme = 'https';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: dialogScheme == 'https'
                                      ? const Color(0xFF2563EB)
                                      : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                                  border: Border.all(
                                    color: dialogScheme == 'https'
                                        ? const Color(0xFF2563EB)
                                        : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'HTTPS',
                                    style: TextStyle(
                                      color: dialogScheme == 'https' ? Colors.white : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Host Input
                      TextField(
                        controller: hostController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Host / IP Address',
                          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          hintText: 'e.g. 192.168.1.253',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          filled: true,
                          fillColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Port & Path Inputs
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: portController,
                              onChanged: (_) => setState(() {}),
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                labelText: 'Port',
                                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                hintText: '8000',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                filled: true,
                                fillColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: pathController,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                labelText: 'API Path',
                                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                hintText: '/api/mobile-banking/v1',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                filled: true,
                                fillColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Live assembled URL preview (Multi-line / Wrapping)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Assembled API URL:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              assembledUrl.isNotEmpty ? assembledUrl : 'Invalid Host URL',
                              softWrap: true,
                              maxLines: null,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: assembledUrl.isNotEmpty
                                    ? (isDarkMode ? Colors.greenAccent : const Color(0xFF16A34A))
                                    : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                          TextButton(
                            onPressed: () async {
                              await AuthStore().setCustomApiUrl(null);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('API Gateway reset successfully!'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
                            child: const Text('Reset', style: TextStyle(color: Color(0xFFEF4444))),
                          ),
                          TextButton(
                            onPressed: () async {
                              final url = assembledUrl;
                              if (url.isNotEmpty) {
                                final navigator = Navigator.of(context);
                                await AuthStore().setCustomApiUrl(url);
                                await AuthStore().setSelectedCooperative({
                                  'id': 99999,
                                  'name': 'Development Mode',
                                  'address': dotenv.env['API_URL'] ?? 'http://192.168.1.253:8000',
                                  'url': url,
                                  'api_url': url,
                                  'gradient': 'bg-rose-600',
                                  'logoUrl': '',
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  navigator.push(
                                    MaterialPageRoute(
                                      builder: (_) => const StatusCheckPage(showBackButton: true),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Save Endpoint', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDevModeDialog(BuildContext context, Map<String, dynamic> coop) {
    final String currentUrl = AuthStore().customApiUrl ?? dotenv.env['API_URL'] ?? 'http://192.168.1.253:8000';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.bug_report_rounded, color: Color(0xFFE11D48)),
              const SizedBox(width: 8),
              Text(
                'Development Mode'.tr,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to proceed with the current API URL or configure/change it?'.tr,
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  currentUrl,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel'.tr,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showApiUrlDialog(context);
              },
              child: Text(
                'Change'.tr,
                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final navigator = Navigator.of(context);
                await AuthStore().setSelectedCooperative({
                  'id': 99999,
                  'name': 'Development Mode',
                  'address': dotenv.env['API_URL'] ?? 'http://192.168.1.253:8000',
                  'url': currentUrl,
                  'api_url': currentUrl,
                  'gradient': 'bg-rose-600',
                  'logoUrl': '',
                });
                navigator.push(
                  MaterialPageRoute(builder: (_) => const StatusCheckPage(showBackButton: true)),
                );
              },
              child: Text(
                'Proceed'.tr,
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

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

  Widget _buildInitialsAvatar(String letter, LinearGradient gradient) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
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
                  : _errorMessage != null && _cooperatives.isEmpty
                      ? RefreshIndicator(
                          color: const Color(0xFF2563EB),
                          onRefresh: () => _loadCooperatives(forceRefresh: true),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cloud_off_rounded,
                                      size: 64,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Failed to Load'.tr,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage ?? 'Please refresh again.'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    onPressed: () => _loadCooperatives(forceRefresh: true),
                                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                    label: Text(
                                      'Refresh Again'.tr,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : _filteredCooperatives.isEmpty
                          ? Center(
                              child: Text(
                                'No cooperatives found.'.tr,
                                style: TextStyle(color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 16),
                              ),
                            )
                      : RefreshIndicator(
                          color: const Color(0xFF2563EB),
                          onRefresh: () => _loadCooperatives(forceRefresh: true),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                            itemCount: _filteredCooperatives.length,
                            itemBuilder: (context, index) {
                              final coop = _filteredCooperatives[index];
                              final gradient = _getGradient(coop['gradient'] ?? 'bg-blue-600');
                              final String coopName = coop['name'] ?? '';
                              final initialLetter = coopName.isNotEmpty ? coopName.substring(0, 1) : 'S';
                              final logoUrl = coop['logoUrl'];
                              final bool hasLogo = logoUrl != null && logoUrl.toString().isNotEmpty;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: InkWell(
                                  onTap: () async {
                                    if (coop['isDevMode'] == true) {
                                      _showDevModeDialog(context, coop);
                                    } else {
                                      final navigator = Navigator.of(context);
                                      await AuthStore().setSelectedCooperative(coop);
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (_) => const StatusCheckPage(showBackButton: true),
                                        ),
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
                                        // Visual Icon with dynamic gradient or Image
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                            border: Border.all(
                                              color: _isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: hasLogo
                                              ? ClipOval(
                                                  child: Image.network(
                                                    logoUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(initialLetter, gradient),
                                                  ),
                                                )
                                              : _buildInitialsAvatar(initialLetter, gradient),
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
                                                  coopName,
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
            ),
          ],
        ),
      ),
    );
  }
}
