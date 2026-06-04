import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import '../../services/api_service.dart';
import '../../services/nepali_calendar_service.dart';
import 'date_conversion_page.dart';

class NepaliCalendarPage extends StatefulWidget {
  const NepaliCalendarPage({super.key});

  @override
  State<NepaliCalendarPage> createState() => _NepaliCalendarPageState();
}

class _NepaliCalendarPageState extends State<NepaliCalendarPage> {
  int _activeYear = 2083; // default fallback
  int _activeMonth = 1;  // default fallback (1 = Baisakh)

  List<dynamic> _calendarDays = [];
  bool _isEventsLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _selectedDayInfo;
  double _horizontalDragDistance = 0.0;

  StreamSubscription? _calendarSubscription;

  @override
  void dispose() {
    _calendarSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize based on today's BS date
    final todayBs = NepaliCalendarService.adToBs(DateTime.now());
    _activeYear = todayBs[0];
    _activeMonth = todayBs[1];
    _generateLocalCalendar(); // generate calendar grid instantly

    // Select today's date by default ONLY on initial page load
    final todayDayNum = todayBs[2];
    final initialMatches = _calendarDays.where((dayData) => dayData['day'] == todayDayNum);
    _selectedDayInfo = initialMatches.isNotEmpty ? initialMatches.first : null;

    // Fetch calendar data after page transition is fully completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        if (route.animation!.isCompleted) {
          _fetchCalendarData();
        } else {
          late final void Function(AnimationStatus) listener;
          listener = (status) {
            if (status == AnimationStatus.completed) {
              if (mounted) {
                _fetchCalendarData();
              }
              route.animation!.removeStatusListener(listener);
            }
          };
          route.animation!.addStatusListener(listener);
        }
      } else {
        _fetchCalendarData();
      }
    });
  }

  Future<void> _fetchCalendarData({bool forceRefresh = false}) async {
    _calendarSubscription?.cancel();
    final completer = Completer<void>();

    setState(() {
      _isEventsLoading = true;
    });

    _calendarSubscription = ApiService().getHolidaysStream(
      yearBs: _activeYear,
      monthBs: _activeMonth,
      forceRefresh: forceRefresh,
    ).listen((response) {
      if (mounted) {
        setState(() {
          _isEventsLoading = response.isLoading;
          _errorMessage = response.hasError ? response.error : null;
          if (response.data != null && response.data!['calendar'] != null) {
            _calendarDays = response.data!['calendar'];
            // Keep current selection but update its holiday information from API response
            if (_selectedDayInfo != null) {
              final selectedDayNum = _selectedDayInfo!['day'];
              final matches = _calendarDays.where((dayData) => dayData['day'] == selectedDayNum);
              _selectedDayInfo = matches.isNotEmpty ? matches.first : null;
            }
          }
        });
      }
    }, onError: (e) {
      debugPrint('Error fetching calendar from API: $e');
      if (mounted) {
        setState(() {
          _isEventsLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    }, onDone: () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    return completer.future;
  }

  void _generateLocalCalendar() {
    final daysInMonth = NepaliCalendarService.getDaysInBsMonth(_activeYear, _activeMonth);

    final generated = <Map<String, dynamic>>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final adDate = NepaliCalendarService.bsToAd(_activeYear, _activeMonth, day);
      final dayOfWeek = adDate.weekday % 7; // Sunday = 0, ..., Saturday = 6
      final isSaturday = dayOfWeek == 6;

      final monthStr = _activeMonth.toString().padLeft(2, '0');
      final dayStr = day.toString().padLeft(2, '0');
      final dateBs = '$_activeYear-$monthStr-$dayStr';
      final dateAd = '${adDate.year}-${adDate.month.toString().padLeft(2, '0')}-${adDate.day.toString().padLeft(2, '0')}';

      generated.add({
        'day': day,
        'date_bs': dateBs,
        'date_ad': dateAd,
        'day_of_week': dayOfWeek,
        'is_saturday': isSaturday,
        'is_holiday': isSaturday,
        'holiday_id': null,
        'holiday_name': isSaturday ? 'Saturday' : '',
        'is_db_holiday': false,
      });
    }

    setState(() {
      _calendarDays = generated;
    });
  }

  void _prevMonth() {
    if (_activeMonth == 1) {
      if (_activeYear > 2000) {
        setState(() {
          _activeMonth = 12;
          _activeYear--;
          _selectedDayInfo = null; // Clear selection on month change
          _generateLocalCalendar(); // instant update
        });
        _fetchCalendarData();
      }
    } else {
      setState(() {
        _activeMonth--;
        _selectedDayInfo = null; // Clear selection on month change
        _generateLocalCalendar(); // instant update
      });
      _fetchCalendarData();
    }
  }

  void _nextMonth() {
    if (_activeMonth == 12) {
      if (_activeYear < 2100) {
        setState(() {
          _activeMonth = 1;
          _activeYear++;
          _selectedDayInfo = null; // Clear selection on month change
          _generateLocalCalendar(); // instant update
        });
        _fetchCalendarData();
      }
    } else {
      setState(() {
        _activeMonth++;
        _selectedDayInfo = null; // Clear selection on month change
        _generateLocalCalendar(); // instant update
      });
      _fetchCalendarData();
    }
  }

  String _toDevanagariDigits(int num) {
    const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return num.toString().split('').map((char) {
      final val = int.tryParse(char);
      return val != null ? devanagariDigits[val] : char;
    }).join('');
  }

  String _getEnglishDayLabel(String dateAdStr) {
    try {
      final parts = dateAdStr.split('-');
      return int.parse(parts[2]).toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBgColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0);
    final monthName = NepaliCalendarService.nepaliMonths[_activeMonth - 1];
    final monthNameNe = NepaliCalendarService.nepaliMonthsDevanagari[_activeMonth - 1];

    // Determine start offset cells
    int startDayOfWeek = 0;
    if (_calendarDays.isNotEmpty) {
      startDayOfWeek = _calendarDays.first['day_of_week'] as int;
    } else {
      startDayOfWeek = NepaliCalendarService.getStartingWeekdayOfBsMonth(_activeYear, _activeMonth);
    }

    final todayBs = NepaliCalendarService.adToBs(DateTime.now());
    final isCurrentMonth = todayBs[0] == _activeYear && todayBs[1] == _activeMonth;
    final todayDayNum = todayBs[2];

    final List<Widget> gridCells = [];

    // Empty offset cells
    for (int i = 0; i < startDayOfWeek; i++) {
      gridCells.add(const SizedBox.shrink());
    }

    // Dynamic grid days
    for (final dayData in _calendarDays) {
      final int d = dayData['day'] as int;
      final bool isHoliday = dayData['is_holiday'] as bool;
      final bool isTodayHighlight = isCurrentMonth && d == todayDayNum;
      final String engDay = _getEnglishDayLabel(dayData['date_ad'] as String);
      final String holidayName = dayData['holiday_name'] ?? '';
      final bool hasEvent = holidayName.isNotEmpty && holidayName.toLowerCase() != 'saturday';
      final bool isSelected = _selectedDayInfo != null && _selectedDayInfo!['day'] == d;

      gridCells.add(
        InkWell(
          onTap: () {
            setState(() {
              _selectedDayInfo = dayData;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isTodayHighlight
                  ? const Color(0xFF2563EB)
                  : isHoliday
                      ? const Color(0xFFEF4444).withValues(alpha: isDarkMode ? 0.08 : 0.04)
                      : isDarkMode
                          ? Colors.white.withValues(alpha: 0.02)
                          : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected && !isTodayHighlight
                    ? (isDarkMode ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF94A3B8))
                    : isTodayHighlight
                        ? const Color(0xFF2563EB)
                        : isHoliday
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : isDarkMode
                                ? Colors.white.withValues(alpha: 0.04)
                                : const Color(0xFFE2E8F0),
                width: isSelected && !isTodayHighlight ? 1.5 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                if (hasEvent && !isTodayHighlight)
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
                              : isHoliday
                                  ? const Color(0xFFEF4444)
                                  : primaryTextColor,
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
        ),
      );
    }

    // Filter genuine holiday events
    final holidayEvents = _calendarDays.where((day) {
      final name = day['holiday_name'] ?? '';
      return name.isNotEmpty && name.toLowerCase() != 'saturday';
    }).toList();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: primaryTextColor,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Calendar'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
        actions: [
          // Month Selection Dropdown
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _activeMonth,
                dropdownColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontSize: 14,
                ),
                items: List.generate(12, (index) => index + 1).map((mIdx) {
                  final mName = NepaliCalendarService.nepaliMonths[mIdx - 1];
                  return DropdownMenuItem<int>(
                    value: mIdx,
                    child: Text(mName.tr),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _activeMonth = val;
                      _selectedDayInfo = null; // Clear selection on month change
                      _generateLocalCalendar(); // Update local instantly
                    });
                    _fetchCalendarData();
                  }
                },
              ),
            ),
          ),
          // Year Selection Dropdown (2000 to 2100)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _activeYear,
                dropdownColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontSize: 14,
                ),
                items: List.generate(101, (index) => 2000 + index).map((yr) {
                  return DropdownMenuItem<int>(
                    value: yr,
                    child: Text(_toDevanagariDigits(yr)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _activeYear = val;
                      _selectedDayInfo = null; // Clear selection on year change
                      _generateLocalCalendar(); // Update local instantly
                    });
                    _fetchCalendarData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _fetchCalendarData(forceRefresh: true),
          color: const Color(0xFF2563EB),
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          children: [
            // Month Navigation Row
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    style: IconButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'BIKRAM SAMBAT'.tr,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$monthNameNe (${monthName.tr}) ${_toDevanagariDigits(_activeYear)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    style: IconButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildInlineErrorBanner(_errorMessage!, isDarkMode),
            ],
            const SizedBox(height: 20),

            // Calendar Grid
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                _horizontalDragDistance = 0.0;
              },
              onHorizontalDragUpdate: (details) {
                _horizontalDragDistance += details.delta.dx;
              },
              onHorizontalDragEnd: (details) {
                if (_horizontalDragDistance.abs() > 40.0) {
                  if (_horizontalDragDistance > 0) {
                    _prevMonth();
                  } else {
                    _nextMonth();
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Column(
                  children: [
                    // Weekday labels
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 7,
                      childAspectRatio: 1.5,
                      children: List.generate(7, (idx) {
                        const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                        final label = labels[idx];
                        final isSat = idx == 6;
                        return Center(
                          child: Text(
                            label.tr.toUpperCase(),
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
                    // Days grid
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
            ),

            // Selected Day Event Detail Sheet/Card
            if (_selectedDayInfo != null) ...[
              const SizedBox(height: 18),
              _buildSelectedDayCard(isDarkMode, borderColor, primaryTextColor),
            ],

            const SizedBox(height: 24),
            // Month Events Section (Always visible)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Month Events'.tr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DateConversionPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.swap_horizontal_circle_outlined,
                    size: 22,
                    color: Color(0xFF2563EB),
                  ),
                  tooltip: 'Date Conversion & Difference'.tr,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Event Loading or Event Cards
            if (_isEventsLoading)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (holidayEvents.isEmpty)
              _buildNoEventsCard(cardBgColor, borderColor, primaryTextColor)
            else
              ...holidayEvents.map((dayData) {
                final int dayNum = dayData['day'] as int;
                final String evTitle = dayData['holiday_name'] ?? '';
                final isSat = dayData['is_saturday'] as bool;
                return _buildEventCard(
                  title: evTitle.tr,
                  desc: isSat ? 'Weekly Holiday'.tr : 'Official Event / Holiday'.tr,
                  dateBadge: '$monthNameNe ${_toDevanagariDigits(dayNum)}',
                  isDarkMode: isDarkMode,
                  cardBgColor: cardBgColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  isHolidayEvent: true,
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildNoEventsCard(Color cardBgColor, Color borderColor, Color primaryTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: Color(0xFF10B981),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All Clear!'.tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No holidays or special events are scheduled for this month. Have a productive time!'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayCard(bool isDarkMode, Color borderColor, Color primaryTextColor) {
    final int day = _selectedDayInfo!['day'] as int;
    final String dateBs = _selectedDayInfo!['date_bs'] as String;
    final String dateAd = _selectedDayInfo!['date_ad'] as String;
    final String holidayName = _selectedDayInfo!['holiday_name'] ?? '';
    final bool isHoliday = _selectedDayInfo!['is_holiday'] as bool;
    final bool isSaturday = _selectedDayInfo!['is_saturday'] as bool;

    final String eventTitle = holidayName.isNotEmpty
        ? holidayName
        : (isSaturday ? 'Saturday' : 'Regular Working Day');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isHoliday
            ? const Color(0xFFEF4444).withValues(alpha: 0.08)
            : const Color(0xFF2563EB).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHoliday
              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
              : const Color(0xFF2563EB).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHoliday ? Icons.event_busy_rounded : Icons.event_available_rounded,
            color: isHoliday ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'Day Detail'.tr} : ${_toDevanagariDigits(day)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isHoliday ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  eventTitle.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${'BS Date'.tr}: $dateBs | ${'AD Date'.tr}: $dateAd',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String desc,
    required String dateBadge,
    required bool isDarkMode,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    bool isHolidayEvent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
                    color: isHolidayEvent ? const Color(0xFFEF4444) : primaryTextColor,
                  ),
                ),
                if (!isHolidayEvent) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isHolidayEvent 
                  ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                  : const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              dateBadge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isHolidayEvent ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineErrorBanner(String error, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
