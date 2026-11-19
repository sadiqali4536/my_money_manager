import 'package:intl/intl.dart';

class CurrencyHelper {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrCompactFormatter = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static final NumberFormat _inrIntegerFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Formats amount in paise (cents) to INR string e.g. 2500000 -> ₹25,000.00
  static String formatPaise(int paise, {bool compact = false, bool hideDecimals = false}) {
    final double rupees = paise / 100.0;
    return formatRupees(rupees, compact: compact, hideDecimals: hideDecimals);
  }

  /// Formats amount in rupees
  static String formatRupees(double rupees, {bool compact = false, bool hideDecimals = false}) {
    if (compact && (rupees.abs() >= 100000)) {
      return _inrCompactFormatter.format(rupees);
    }
    if (hideDecimals || rupees == rupees.roundToDouble()) {
      return _inrIntegerFormatter.format(rupees);
    }
    return _inrFormatter.format(rupees);
  }

  /// Formats amount in paise for PDF reports with safe ASCII/standard representation (e.g. "Rs. 25,000.00")
  /// to avoid character encoding / missing glyph box ('X') issues with standard PDF fonts.
  static String formatPaiseForPdf(int paise, {bool hideDecimals = false}) {
    final double rupees = paise / 100.0;
    final formatter = hideDecimals || rupees == rupees.roundToDouble()
        ? NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0)
        : NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
    return formatter.format(rupees);
  }

  /// Convert Rupee double to integer Paise safely
  static int rupeesToPaise(double rupees) {
    return (rupees * 100).round();
  }

  /// Convert Paise integer to Rupee double
  static double paiseToRupees(int paise) {
    return paise / 100.0;
  }
}

class DateHelper {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonthFormat = DateFormat('MMM');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEE, dd MMM');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatShortMonth(DateTime date) => _shortMonthFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatDayOfWeek(DateTime date) => _dayOfWeekFormat.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(targetDate).inDays;
    if (diffDays == 0) return 'Today, ${_timeFormat.format(date)}';
    if (diffDays == 1) return 'Yesterday, ${_timeFormat.format(date)}';
    return '${_dateFormat.format(date)}, ${_timeFormat.format(date)}';
  }

  static String getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}

