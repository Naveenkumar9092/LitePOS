import "package:intl/intl.dart";

class DateFormatter {
  static final DateFormat _dateTimeFormat = DateFormat("dd MMM yyyy, hh:mm a");
  static final DateFormat _dateFormat = DateFormat("dd MMM yyyy");
  static final DateFormat _timeFormat = DateFormat("hh:mm a");

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return "-";
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return "-";
    return _dateFormat.format(dateTime.toLocal());
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return "-";
    return _timeFormat.format(dateTime.toLocal());
  }

  static String formatIsoUtc(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  static DateTime? parseIsoUtc(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    return DateTime.tryParse(isoString)?.toUtc();
  }

  static String formatRelative(dynamic value) {
    if (value == null) return "-";
    DateTime? dt;
    if (value is DateTime) {
      dt = value.toLocal();
    } else if (value is String) {
      if (value.isEmpty) return "-";
      dt = DateTime.tryParse(value)?.toLocal();
    }
    if (dt == null) return "-";
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return _dateTimeFormat.format(dt);
  }
}

