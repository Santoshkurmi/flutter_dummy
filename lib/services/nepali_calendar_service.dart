import 'nepali_date_data.dart';

class NepaliCalendarService {
  static const List<String> nepaliMonths = [
    'Baisakh',
    'Jestha',
    'Ashadh',
    'Shrawan',
    'Bhadra',
    'Ashwin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  static const List<String> nepaliMonthsDevanagari = [
    'वैशाख',
    'जेठ',
    'असार',
    'साउन',
    'भदौ',
    'असोज',
    'कात्तिक',
    'मंसिर',
    'पुस',
    'माघ',
    'फागुन',
    'चैत',
  ];

  static const List<String> englishMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  static final DateTime refAdDate = DateTime(1943, 4, 14); // Baisakh 1, 2000 BS

  static bool isLeapYearAd(int year) {
    return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
  }

  static const List<int> adMonthsNormal = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  static const List<int> adMonthsLeap = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  /// Returns total days in a given BS year and month (1-indexed: 1 = Baisakh)
  static int getDaysInBsMonth(int yearBs, int monthBs) {
    if (yearBs < 2000 || yearBs > 2100 || monthBs < 1 || monthBs > 12) {
      return 30; // fallback
    }
    final yearRow = NepaliDateData.bsDateList[yearBs - 2000];
    return yearRow[monthBs];
  }

  /// Calculates BS date [year, month, day] for a given AD DateTime
  static List<int> adToBs(DateTime adDate) {
    final adUtc = DateTime.utc(adDate.year, adDate.month, adDate.day);
    final refUtc = DateTime.utc(1943, 4, 14);
    int diff = adUtc.difference(refUtc).inDays;

    if (diff < 0) {
      // Out of bounds (before BS 2000)
      return [2000, 1, 1];
    }

    int yearIdx = 0;
    while (yearIdx < NepaliDateData.bsDateList.length) {
      final yearRow = NepaliDateData.bsDateList[yearIdx];
      final year = yearRow[0];

      // Calculate total days in this BS year
      int daysInYear = 0;
      for (int m = 1; m <= 12; m++) {
        daysInYear += yearRow[m];
      }

      if (diff < daysInYear) {
        for (int m = 1; m <= 12; m++) {
          int daysInMonth = yearRow[m];
          if (diff < daysInMonth) {
            return [year, m, diff + 1];
          }
          diff -= daysInMonth;
        }
      }
      diff -= daysInYear;
      yearIdx++;
    }
    // Out of bounds (after BS 2100)
    return [2100, 12, 30];
  }

  /// Calculates AD DateTime for a given BS date [year, month, day]
  static DateTime bsToAd(int yearBs, int monthBs, int dayBs) {
    if (yearBs < 2000 || yearBs > 2100 || monthBs < 1 || monthBs > 12) {
      return refAdDate;
    }
    int daysPassed = 0;
    int k = 0;

    // Days for preceding years
    for (int i = 0; i < (yearBs - 2000); i++) {
      for (int j = 1; j <= 12; j++) {
        daysPassed += NepaliDateData.bsDateList[k][j];
      }
      k++;
    }

    // Days for preceding months in current year
    for (int j = 1; j < monthBs; j++) {
      daysPassed += NepaliDateData.bsDateList[k][j];
    }

    // Days in current month
    daysPassed += (dayBs - 1);

    // Compute in UTC first to prevent timezone offset shifts from altering the date
    final refAdUtc = DateTime.utc(1943, 4, 14);
    final adUtc = refAdUtc.add(Duration(days: daysPassed));

    // Return as a local DateTime representing midnight
    return DateTime(adUtc.year, adUtc.month, adUtc.day);
  }

  /// Get starting weekday index of a BS month (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
  static int getStartingWeekdayOfBsMonth(int yearBs, int monthBs) {
    // Baisakh 1 of yearBs
    final adDate = bsToAd(yearBs, monthBs, 1);
    // adDate.weekday returns: 1 = Mon, 2 = Tue, ..., 7 = Sun
    // We want: 0 = Sun, 1 = Mon, ..., 6 = Sat
    return adDate.weekday % 7;
  }
}
