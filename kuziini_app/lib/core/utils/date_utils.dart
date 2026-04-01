import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

abstract final class AppDateUtils {
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _shortDayFormat = DateFormat('EEE');
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _time24Format = DateFormat('HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _fullFormat = DateFormat('EEEE, MMM d, yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  static String formatDay(DateTime date) => _dayFormat.format(date);
  static String formatShortDay(DateTime date) => _shortDayFormat.format(date);
  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatTime24(DateTime date) => _time24Format.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatFull(DateTime date) => _fullFormat.format(date);
  static String formatIso(DateTime date) => _isoFormat.format(date);

  static String formatTimeAgo(DateTime date) => timeago.format(date);

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static bool isOverdue(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String getRelativeDateLabel(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    if (isYesterday(date)) return 'Yesterday';
    final diff = date.difference(DateTime.now()).inDays;
    if (diff > 0 && diff < 7) return formatDay(date);
    return formatDate(date);
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  static DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    return endOfDay(date.add(Duration(days: 7 - weekday)));
  }

  static List<DateTime> getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      last.day,
      (i) => DateTime(first.year, first.month, i + 1),
    );
  }

  static List<DateTime> getWeekDays(DateTime referenceDate) {
    final start = startOfWeek(referenceDate);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }
}
