import 'package:intl/intl.dart';

class DateFormatter {
  // Format date as 'MM/dd/yyyy'
  static String formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }
  
  // Format date as 'yyyy-MM-dd'
  static String formatDateForDatabase(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  // Format date and time as 'MM/dd/yyyy hh:mm a'
  static String formatDateTime(DateTime date) {
    return DateFormat('MM/dd/yyyy hh:mm a').format(date);
  }
  
  // Format time as 'hh:mm a'
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
  
  // Parse date from string in format 'yyyy-MM-dd'
  static DateTime parseDate(String dateString) {
    return DateFormat('yyyy-MM-dd').parse(dateString);
  }
  
  // Parse date and time from string in format 'yyyy-MM-dd HH:mm:ss'
  static DateTime parseDateTime(String dateTimeString) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTimeString);
  }
  
  // Get current date as DateTime
  static DateTime getCurrentDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  // Get current date and time as DateTime
  static DateTime getCurrentDateTime() {
    return DateTime.now();
  }
  
  // Add days to a date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }
  
  // Format date as relative to now (today, yesterday, etc.)
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCompare = DateTime(date.year, date.month, date.day);
    
    if (dateToCompare == today) {
      return 'Today';
    } else if (dateToCompare == yesterday) {
      return 'Yesterday';
    } else {
      return formatDate(date);
    }
  }
  
  // Format date for reporting purposes (e.g., "Jan 2023")
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }
  
  // Format date as week range (e.g., "Jan 1 - Jan 7, 2023")
  static String formatWeekRange(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    if (startOfWeek.month == endOfWeek.month && startOfWeek.year == endOfWeek.year) {
      return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('d, yyyy').format(endOfWeek)}';
    } else if (startOfWeek.year == endOfWeek.year) {
      return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}';
    } else {
      return '${DateFormat('MMM d, yyyy').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}';
    }
  }
  
  // Get the start of the week for a given date
  static DateTime getStartOfWeek(DateTime date) {
    final difference = date.weekday - 1; // Monday is the first day of the week (1)
    return DateTime(date.year, date.month, date.day - difference);
  }
  
  // Get the start of the month for a given date
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  // Get the end of the month for a given date
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}
