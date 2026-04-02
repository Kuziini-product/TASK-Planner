/// Romanian public holidays and weekend info.
class HolidaysService {
  HolidaysService._();

  /// Fixed Romanian public holidays (month, day) → name.
  static const _fixedHolidays = <String, String>{
    '01-01': 'Anul Nou',
    '01-02': 'Anul Nou',
    '01-06': 'Boboteaza',
    '01-07': 'Sf. Ioan',
    '01-24': 'Ziua Unirii',
    '05-01': 'Ziua Muncii',
    '06-01': 'Ziua Copilului',
    '08-15': 'Adormirea Maicii Domnului',
    '11-30': 'Sf. Andrei',
    '12-01': 'Ziua Națională',
    '12-25': 'Crăciun',
    '12-26': 'Crăciun',
  };

  /// Easter dates (Orthodox) for 2024-2030.
  /// Format: year → (month, day) of Easter Sunday.
  static const _easterDates = <int, (int, int)>{
    2024: (5, 5),
    2025: (4, 20),
    2026: (4, 12),
    2027: (5, 2),
    2028: (4, 16),
    2029: (4, 8),
    2030: (4, 28),
  };

  /// Get Easter-related holidays for a year.
  static Map<String, String> _easterHolidays(int year) {
    final easter = _easterDates[year];
    if (easter == null) return {};

    final easterDate = DateTime(year, easter.$1, easter.$2);
    final goodFriday = easterDate.subtract(const Duration(days: 2));
    final easterMonday = easterDate.add(const Duration(days: 1));
    // Rusalii = Easter + 49 days (Pentecost Sunday)
    final rusalii = easterDate.add(const Duration(days: 49));
    final rusaliiMonday = rusalii.add(const Duration(days: 1));

    String fmt(DateTime d) => '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
      fmt(goodFriday): 'Vinerea Mare',
      fmt(easterDate): 'Paștele',
      fmt(easterMonday): 'Paștele',
      fmt(rusalii): 'Rusalii',
      fmt(rusaliiMonday): 'Rusalii',
    };
  }

  /// Get all holidays for a given year.
  static Map<String, String> getHolidays(int year) {
    return {
      ..._fixedHolidays,
      ..._easterHolidays(year),
    };
  }

  /// Check if a date is a public holiday. Returns holiday name or null.
  static String? getHolidayName(DateTime date) {
    final key = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final holidays = getHolidays(date.year);
    return holidays[key];
  }

  /// Check if date is Saturday.
  static bool isSaturday(DateTime date) => date.weekday == 6;

  /// Check if date is Sunday.
  static bool isSunday(DateTime date) => date.weekday == 7;

  /// Check if date is weekend.
  static bool isWeekend(DateTime date) => date.weekday >= 6;

  /// Check if date is a free day (weekend or holiday).
  static bool isFreeDay(DateTime date) => isWeekend(date) || getHolidayName(date) != null;
}
