import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import '../../services/nepali_calendar_service.dart';

class DateConversionPage extends StatefulWidget {
  const DateConversionPage({super.key});

  @override
  State<DateConversionPage> createState() => _DateConversionPageState();
}

class _DateConversionPageState extends State<DateConversionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Convert Date State
  bool _isAdToBs = true;
  DateTime _selectedAdDate = DateTime.now();
  int _selectedBsYear = 2083;
  int _selectedBsMonth = 1;
  int _selectedBsDay = 1;

  // Date Difference State
  bool _diffInBs = true;
  DateTime _diffAdStart = DateTime.now();
  DateTime _diffAdEnd = DateTime.now().add(const Duration(days: 7));
  
  int _diffBsStartYear = 2083;
  int _diffBsStartMonth = 1;
  int _diffBsStartDay = 1;

  int _diffBsEndYear = 2083;
  int _diffBsEndMonth = 1;
  int _diffBsEndDay = 8;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize defaults based on today's BS date
    final todayBs = NepaliCalendarService.adToBs(DateTime.now());
    _selectedBsYear = todayBs[0];
    _selectedBsMonth = todayBs[1];
    _selectedBsDay = todayBs[2];

    _diffBsStartYear = todayBs[0];
    _diffBsStartMonth = todayBs[1];
    _diffBsStartDay = todayBs[2];

    // end date default +7 days
    final endBs = NepaliCalendarService.adToBs(DateTime.now().add(const Duration(days: 7)));
    _diffBsEndYear = endBs[0];
    _diffBsEndMonth = endBs[1];
    _diffBsEndDay = endBs[2];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _toDevanagariDigits(int num) {
    const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return num.toString().split('').map((char) {
      final val = int.tryParse(char);
      return val != null ? devanagariDigits[val] : char;
    }).join('');
  }

  String _formatBsDate(int y, int m, int d) {
    final mNameNe = NepaliCalendarService.nepaliMonthsDevanagari[m - 1];
    final mName = NepaliCalendarService.nepaliMonths[m - 1];
    // Check if Nepali language is active
    final isNepali = TranslationService.translate('Baisakh') == 'वैशाख';
    if (isNepali) {
      return '${_toDevanagariDigits(d)} $mNameNe ${_toDevanagariDigits(y)}';
    }
    return '$mName $d, $y';
  }

  String _formatAdDate(DateTime date) {
    final monthName = NepaliCalendarService.englishMonths[date.month - 1];
    return '$monthName ${date.day}, ${date.year}';
  }

  void _pickAdDate(bool isForConversion, bool isStart) async {
    final current = isForConversion 
        ? _selectedAdDate 
        : (isStart ? _diffAdStart : _diffAdEnd);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1943, 4, 14),
      lastDate: DateTime(2044, 4, 12),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isForConversion) {
          _selectedAdDate = picked;
        } else {
          if (isStart) {
            _diffAdStart = picked;
          } else {
            _diffAdEnd = picked;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBgColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Date Utility'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: secondaryTextColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'Date Converter'.tr),
            Tab(text: 'Date Difference'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Date Converter
          ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Direction Toggle Card
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isAdToBs = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isAdToBs ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'AD to BS'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isAdToBs ? Colors.white : secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isAdToBs = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isAdToBs ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'BS to AD'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isAdToBs ? Colors.white : secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_isAdToBs) ...[
                // Input AD Date
                _buildSectionHeader('SELECT AD DATE'.tr, isDarkMode),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickAdDate(true, true),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB)),
                            const SizedBox(width: 14),
                            Text(
                              _formatAdDate(_selectedAdDate),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.edit_calendar_rounded, color: Colors.blue.shade600),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Converted BS Result
                _buildResultCard(
                  title: 'Equivalent BS Date'.tr,
                  result: _formatBsDate(
                    NepaliCalendarService.adToBs(_selectedAdDate)[0],
                    NepaliCalendarService.adToBs(_selectedAdDate)[1],
                    NepaliCalendarService.adToBs(_selectedAdDate)[2],
                  ),
                  isDarkMode: isDarkMode,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
              ] else ...[
                // Input BS Date Dropdowns
                _buildSectionHeader('SELECT BS DATE'.tr, isDarkMode),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      // Year
                      Expanded(
                        child: _buildBsDropdown<int>(
                          label: 'Year'.tr,
                          value: _selectedBsYear,
                          items: List.generate(101, (idx) => 2000 + idx),
                          displayFormat: (yr) => _toDevanagariDigits(yr),
                          onChanged: (yr) {
                            if (yr != null) {
                              setState(() {
                                _selectedBsYear = yr;
                                // validate day bounds
                                final maxDays = NepaliCalendarService.getDaysInBsMonth(_selectedBsYear, _selectedBsMonth);
                                if (_selectedBsDay > maxDays) {
                                  _selectedBsDay = maxDays;
                                }
                              });
                            }
                          },
                          isDarkMode: isDarkMode,
                          primaryTextColor: primaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Month
                      Expanded(
                        child: _buildBsDropdown<int>(
                          label: 'Month'.tr,
                          value: _selectedBsMonth,
                          items: List.generate(12, (idx) => idx + 1),
                          displayFormat: (m) => NepaliCalendarService.nepaliMonths[m - 1].tr,
                          onChanged: (m) {
                            if (m != null) {
                              setState(() {
                                _selectedBsMonth = m;
                                // validate day bounds
                                final maxDays = NepaliCalendarService.getDaysInBsMonth(_selectedBsYear, _selectedBsMonth);
                                if (_selectedBsDay > maxDays) {
                                  _selectedBsDay = maxDays;
                                }
                              });
                            }
                          },
                          isDarkMode: isDarkMode,
                          primaryTextColor: primaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Day
                      Expanded(
                        child: _buildBsDropdown<int>(
                          label: 'Day'.tr,
                          value: _selectedBsDay,
                          items: List.generate(
                            NepaliCalendarService.getDaysInBsMonth(_selectedBsYear, _selectedBsMonth),
                            (idx) => idx + 1,
                          ),
                          displayFormat: (d) => _toDevanagariDigits(d),
                          onChanged: (d) {
                            if (d != null) {
                              setState(() => _selectedBsDay = d);
                            }
                          },
                          isDarkMode: isDarkMode,
                          primaryTextColor: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Converted AD Result
                _buildResultCard(
                  title: 'Equivalent AD Date'.tr,
                  result: _formatAdDate(
                    NepaliCalendarService.bsToAd(_selectedBsYear, _selectedBsMonth, _selectedBsDay),
                  ),
                  isDarkMode: isDarkMode,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
              ],
            ],
          ),

          // Tab 2: Date Difference Calculator
          ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Calendar Standard Toggle Card
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _diffInBs = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _diffInBs ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'BS Calendar'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _diffInBs ? Colors.white : secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _diffInBs = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_diffInBs ? const Color(0xFF2563EB) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'AD Calendar'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_diffInBs ? Colors.white : secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_diffInBs) ...[
                // BS Date Difference Selectors
                _buildSectionHeader('START DATE (BS)'.tr, isDarkMode),
                const SizedBox(height: 12),
                _buildBsDatePickerWidget(
                  yearVal: _diffBsStartYear,
                  monthVal: _diffBsStartMonth,
                  dayVal: _diffBsStartDay,
                  onYearChanged: (yr) {
                    if (yr != null) {
                      setState(() {
                        _diffBsStartYear = yr;
                        final max = NepaliCalendarService.getDaysInBsMonth(yr, _diffBsStartMonth);
                        if (_diffBsStartDay > max) _diffBsStartDay = max;
                      });
                    }
                  },
                  onMonthChanged: (m) {
                    if (m != null) {
                      setState(() {
                        _diffBsStartMonth = m;
                        final max = NepaliCalendarService.getDaysInBsMonth(_diffBsStartYear, m);
                        if (_diffBsStartDay > max) _diffBsStartDay = max;
                      });
                    }
                  },
                  onDayChanged: (d) {
                    if (d != null) setState(() => _diffBsStartDay = d);
                  },
                  isDarkMode: isDarkMode,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('END DATE (BS)'.tr, isDarkMode),
                const SizedBox(height: 12),
                _buildBsDatePickerWidget(
                  yearVal: _diffBsEndYear,
                  monthVal: _diffBsEndMonth,
                  dayVal: _diffBsEndDay,
                  onYearChanged: (yr) {
                    if (yr != null) {
                      setState(() {
                        _diffBsEndYear = yr;
                        final max = NepaliCalendarService.getDaysInBsMonth(yr, _diffBsEndMonth);
                        if (_diffBsEndDay > max) _diffBsEndDay = max;
                      });
                    }
                  },
                  onMonthChanged: (m) {
                    if (m != null) {
                      setState(() {
                        _diffBsEndMonth = m;
                        final max = NepaliCalendarService.getDaysInBsMonth(_diffBsEndYear, m);
                        if (_diffBsEndDay > max) _diffBsEndDay = max;
                      });
                    }
                  },
                  onDayChanged: (d) {
                    if (d != null) setState(() => _diffBsEndDay = d);
                  },
                  isDarkMode: isDarkMode,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
                const SizedBox(height: 24),

                // Converted BS Difference Result
                _buildDiffResultCard(
                  days: _calculateBsDiff(),
                  isDarkMode: isDarkMode,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
              ] else ...[
                // AD Date Difference selectors
                _buildSectionHeader('START DATE (AD)'.tr, isDarkMode),
                const SizedBox(height: 12),
                _buildAdDatePickerWidget(
                  date: _diffAdStart,
                  onTap: () => _pickAdDate(false, true),
                  isDarkMode: isDarkMode,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('END DATE (AD)'.tr, isDarkMode),
                const SizedBox(height: 12),
                _buildAdDatePickerWidget(
                  date: _diffAdEnd,
                  onTap: () => _pickAdDate(false, false),
                  isDarkMode: isDarkMode,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
                const SizedBox(height: 24),

                // Converted AD Difference Result
                _buildDiffResultCard(
                  days: _calculateAdDiff(),
                  isDarkMode: isDarkMode,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String result,
    required bool isDarkMode,
    required Color borderColor,
    required Color primaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDarkMode 
            ? [] 
            : [
                BoxShadow(
                  color: Colors.blue.shade600.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2563EB),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffResultCard({
    required int days,
    required bool isDarkMode,
    required Color borderColor,
    required Color primaryTextColor,
  }) {
    final absDays = days.abs();
    final isNepali = TranslationService.translate('Baisakh') == 'वैशाख';
    final daysLabel = isNepali ? '${_toDevanagariDigits(absDays)} दिन' : '$absDays Days';
    final suffix = days >= 0 
        ? (isNepali ? 'को फरक' : 'difference') 
        : (isNepali ? 'ऋणात्मक फरक' : 'negative difference');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL DURATION'.tr.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            daysLabel,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            suffix.tr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBsDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) displayFormat,
    required ValueChanged<T?> onChanged,
    required bool isDarkMode,
    required Color primaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFCBD5E1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
                fontSize: 14,
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(displayFormat(item)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBsDatePickerWidget({
    required int yearVal,
    required int monthVal,
    required int dayVal,
    required ValueChanged<int?> onYearChanged,
    required ValueChanged<int?> onMonthChanged,
    required ValueChanged<int?> onDayChanged,
    required bool isDarkMode,
    required Color borderColor,
    required Color primaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBsDropdown<int>(
              label: 'Year'.tr,
              value: yearVal,
              items: List.generate(101, (idx) => 2000 + idx),
              displayFormat: (yr) => _toDevanagariDigits(yr),
              onChanged: onYearChanged,
              isDarkMode: isDarkMode,
              primaryTextColor: primaryTextColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBsDropdown<int>(
              label: 'Month'.tr,
              value: monthVal,
              items: List.generate(12, (idx) => idx + 1),
              displayFormat: (m) => NepaliCalendarService.nepaliMonths[m - 1].tr,
              onChanged: onMonthChanged,
              isDarkMode: isDarkMode,
              primaryTextColor: primaryTextColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBsDropdown<int>(
              label: 'Day'.tr,
              value: dayVal,
              items: List.generate(
                NepaliCalendarService.getDaysInBsMonth(yearVal, monthVal),
                (idx) => idx + 1,
              ),
              displayFormat: (d) => _toDevanagariDigits(d),
              onChanged: onDayChanged,
              isDarkMode: isDarkMode,
              primaryTextColor: primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdDatePickerWidget({
    required DateTime date,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color borderColor,
    required Color primaryTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: 14),
                Text(
                  _formatAdDate(date),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
            Icon(Icons.edit_calendar_rounded, color: Colors.blue.shade600),
          ],
        ),
      ),
    );
  }

  int _calculateBsDiff() {
    final startAd = NepaliCalendarService.bsToAd(_diffBsStartYear, _diffBsStartMonth, _diffBsStartDay);
    final endAd = NepaliCalendarService.bsToAd(_diffBsEndYear, _diffBsEndMonth, _diffBsEndDay);
    final startOnly = DateTime(startAd.year, startAd.month, startAd.day);
    final endOnly = DateTime(endAd.year, endAd.month, endAd.day);
    return endOnly.difference(startOnly).inDays;
  }

  int _calculateAdDiff() {
    final startOnly = DateTime(_diffAdStart.year, _diffAdStart.month, _diffAdStart.day);
    final endOnly = DateTime(_diffAdEnd.year, _diffAdEnd.month, _diffAdEnd.day);
    return endOnly.difference(startOnly).inDays;
  }
}
