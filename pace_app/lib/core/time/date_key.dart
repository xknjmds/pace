/// `yyyy-MM-dd` for the local calendar day of [day]. Key of `daily_logs`
/// and `reminder_mutes`.
String dateKey(DateTime day) {
  final l = day.isUtc ? day.toLocal() : day;
  return '${l.year.toString().padLeft(4, '0')}-'
      '${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}';
}

/// Local midnight of [day], with any time of day removed.
DateTime dateOnly(DateTime day) {
  final l = day.isUtc ? day.toLocal() : day;
  return DateTime(l.year, l.month, l.day);
}
