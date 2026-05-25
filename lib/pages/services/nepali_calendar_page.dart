import 'package:flutter/material.dart';

class NepaliMonthConfig {
  final String name;
  final int days;
  final int startDayOfWeek; // 0 = Sunday, 1 = Monday, etc.
  final String engMonthStart; // e.g. "April 14"
  final int engYearStart; // 2026
  final String engMonthRange; // "Apr - May"
  final String? holidayDescription;

  const NepaliMonthConfig({
    required this.name,
    required this.days,
    required this.startDayOfWeek,
    required this.engMonthStart,
    required this.engYearStart,
    required this.engMonthRange,
    this.holidayDescription,
  });
}

class NepaliCalendarPage extends StatefulWidget {
  const NepaliCalendarPage({super.key});

  @override
  State<NepaliCalendarPage> createState() => _NepaliCalendarPageState();
}

class _NepaliCalendarPageState extends State<NepaliCalendarPage> {
  int _activeMonthIdx = 1; // Default to Jestha (Index 1)
  final String _currentYear = '2083';

  // Realistic Bikram Sambat 2083 Month Configs
  final List<NepaliMonthConfig> _nepaliMonths = const [
    NepaliMonthConfig(
      name: 'Baisakh',
      days: 31,
      startDayOfWeek: 2,
      engMonthStart: 'April 14',
      engYearStart: 2026,
      engMonthRange: 'Apr - May',
      holidayDescription: 'Baisakh 01: Nepali New Year 2083',
    ),
    NepaliMonthConfig(
      name: 'Jestha',
      days: 32,
      startDayOfWeek: 5,
      engMonthStart: 'May 15',
      engYearStart: 2026,
      engMonthRange: 'May - Jun',
      holidayDescription: 'Jestha 15: Republic Day',
    ),
    NepaliMonthConfig(
      name: 'Ashadh',
      days: 31,
      startDayOfWeek: 2,
      engMonthStart: 'June 16',
      engYearStart: 2026,
      engMonthRange: 'Jun - Jul',
      holidayDescription: 'Ashadh 15: National Paddy Day (Dahi Chiura)',
    ),
    NepaliMonthConfig(
      name: 'Shrawan',
      days: 32,
      startDayOfWeek: 5,
      engMonthStart: 'July 17',
      engYearStart: 2026,
      engMonthRange: 'Jul - Aug',
      holidayDescription: 'Shrawan 15: Kheer Khane Din',
    ),
    NepaliMonthConfig(
      name: 'Bhadra',
      days: 31,
      startDayOfWeek: 2,
      engMonthStart: 'August 18',
      engYearStart: 2026,
      engMonthRange: 'Aug - Sep',
      holidayDescription: 'Bhadra 12: Gai Jatra festival',
    ),
    NepaliMonthConfig(
      name: 'Ashwin',
      days: 30,
      startDayOfWeek: 5,
      engMonthStart: 'September 18',
      engYearStart: 2026,
      engMonthRange: 'Sep - Oct',
      holidayDescription: 'Ashwin 25: Dashain festival begins',
    ),
    NepaliMonthConfig(
      name: 'Kartik',
      days: 30,
      startDayOfWeek: 0,
      engMonthStart: 'October 18',
      engYearStart: 2026,
      engMonthRange: 'Oct - Nov',
      holidayDescription: 'Kartik 22: Tihar/Laxmi Puja festival',
    ),
    NepaliMonthConfig(
      name: 'Mangsir',
      days: 29,
      startDayOfWeek: 2,
      engMonthStart: 'November 17',
      engYearStart: 2026,
      engMonthRange: 'Nov - Dec',
      holidayDescription: 'Mangsir 25: Udhauli Parva',
    ),
    NepaliMonthConfig(
      name: 'Poush',
      days: 30,
      startDayOfWeek: 3,
      engMonthStart: 'December 16',
      engYearStart: 2026,
      engMonthRange: 'Dec - Jan',
      holidayDescription: 'Poush 15: Tamu Lhosar',
    ),
    NepaliMonthConfig(
      name: 'Magh',
      days: 29,
      startDayOfWeek: 5,
      engMonthStart: 'January 15',
      engYearStart: 2027,
      engMonthRange: 'Jan - Feb',
      holidayDescription: 'Magh 01: Maghe Sankranti parva',
    ),
    NepaliMonthConfig(
      name: 'Falgun',
      days: 30,
      startDayOfWeek: 6,
      engMonthStart: 'February 13',
      engYearStart: 2027,
      engMonthRange: 'Feb - Mar',
      holidayDescription: 'Falgun 23: Maha Shivaratri',
    ),
    NepaliMonthConfig(
      name: 'Chaitra',
      days: 30,
      startDayOfWeek: 1,
      engMonthStart: 'March 15',
      engYearStart: 2027,
      engMonthRange: 'Mar - Apr',
      holidayDescription: 'Chaitra 27: Ghode Jatra',
    ),
  ];

  static const List<String> _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String _toDevanagariDigits(int num) {
    const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return num.toString().split('').map((char) {
      final val = int.tryParse(char);
      return val != null ? devanagariDigits[val] : char;
    }).join('');
  }

  String _getEnglishDateForDay(NepaliMonthConfig month, int dayNum) {
    final parts = month.engMonthStart.split(' ');
    final monthName = parts[0];
    final startDay = int.parse(parts[1]);

    int currentDay = startDay + (dayNum - 1);
    
    const monthsDaysMap = {
      'April': 30, 'May': 31, 'June': 30, 'July': 31, 'August': 31, 
      'September': 30, 'October': 31, 'November': 30, 'December': 31,
      'January': 31, 'February': 28, 'March': 31
    };

    final maxDays = monthsDaysMap[monthName] ?? 30;
    if (currentDay > maxDays) {
      currentDay = currentDay - maxDays;
    }
    return currentDay.toString();
  }

  void _prevMonth() {
    setState(() {
      _activeMonthIdx = _activeMonthIdx == 0 ? 11 : _activeMonthIdx - 1;
    });
  }

  void _nextMonth() {
    setState(() {
      _activeMonthIdx = _activeMonthIdx == 11 ? 0 : _activeMonthIdx + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeMonth = _nepaliMonths[_activeMonthIdx];

    // Build grid cells
    final List<Widget> gridCells = [];

    // Empty cells before start day of month
    for (int i = 0; i < activeMonth.startDayOfWeek; i++) {
      gridCells.add(const SizedBox.shrink());
    }

    // Days of the month
    for (int d = 1; d <= activeMonth.days; d++) {
      final isWeekend = (activeMonth.startDayOfWeek + d - 1) % 7 == 6; // Saturday is weekend in Nepal
      final isTodayHighlight = activeMonth.name == 'Jestha' && d == 7;
      final engDay = _getEnglishDateForDay(activeMonth, d);
      final hasDotHighlight = activeMonth.name == 'Jestha' && (d == 12 || d == 18);

      gridCells.add(
        Container(
          decoration: BoxDecoration(
            color: isTodayHighlight
                ? const Color(0xFF2563EB)
                : isWeekend
                    ? const Color(0xFFEF4444).withValues(alpha: isDarkMode ? 0.08 : 0.04)
                    : isDarkMode
                        ? Colors.white.withValues(alpha: 0.02)
                        : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTodayHighlight
                  ? const Color(0xFF2563EB)
                  : isWeekend
                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                      : isDarkMode
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFE2E8F0),
            ),
          ),
          child: Stack(
            children: [
              if (hasDotHighlight && !isTodayHighlight)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _toDevanagariDigits(d),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isTodayHighlight
                            ? Colors.white
                            : isWeekend
                                ? const Color(0xFFEF4444)
                                : isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      engDay,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: isTodayHighlight
                            ? Colors.blue[100]
                            : isDarkMode
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: Text(
          'Nepali Calendar',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          children: [
            // Month Switcher Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                    style: IconButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'BIKRAM SAMBAT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeMonth.name} $_currentYear',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activeMonth.engMonthRange} ${activeMonth.engYearStart} AD',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                    style: IconButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Calendar Grid Container
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  // Weekday Header
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 7,
                    childAspectRatio: 1.5,
                    children: List.generate(7, (idx) {
                      final day = _weekdays[idx];
                      final isSat = idx == 6;
                      return Center(
                        child: Text(
                          day.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isSat ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                      );
                    }),
                  ),
                  const Divider(height: 16),
                  
                  // Days Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    children: gridCells,
                  ),
                ],
              ),
            ),

            // Holiday Description Card
            if (activeMonth.holidayDescription != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HOLIDAY EVENTS BS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF59E0B),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeMonth.holidayDescription!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Month Events Timelines
            const SizedBox(height: 24),
            _buildSectionTitle('Month Events & Highlights', isDarkMode),
            const SizedBox(height: 12),

            _buildEventCard(
              title: 'Interest Calculation Run',
              desc: 'Quarterly capitalization calculation run for active savings accounts',
              dateBadge: '${activeMonth.name} २८',
              isDarkMode: isDarkMode,
            ),
            _buildEventCard(
              title: 'Cooperative AGM Board Meeting',
              desc: 'Discussion of annual dividend rates and core equity capitalization metrics',
              dateBadge: '${activeMonth.name} १२',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String desc,
    required String dateBadge,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16.0),
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
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              dateBadge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
