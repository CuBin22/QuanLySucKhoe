// shortcut: fixed UTC+7 matches the approved Vietnam-only timezone;
// use a timezone database if user-selectable regions are introduced.
const vietnamOffset = Duration(hours: 7);
DateTime vietnamWallTime(DateTime utc) => utc.toUtc().add(vietnamOffset);
DateTime vietnamWallToUtc(DateTime wall) => DateTime.utc(
  wall.year,
  wall.month,
  wall.day,
  wall.hour,
  wall.minute,
  wall.second,
).subtract(vietnamOffset);
String dateKey(DateTime wall) =>
    '${wall.year.toString().padLeft(4, '0')}-${wall.month.toString().padLeft(2, '0')}-${wall.day.toString().padLeft(2, '0')}';
DateTime parseDateKey(String key) {
  final parsed = DateTime.tryParse(key);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key) ||
      parsed == null ||
      dateKey(parsed) != key) {
    throw const FormatException('Ngày không hợp lệ.');
  }
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

DateTime vietnamDayStart(DateTime utc) {
  final wall = vietnamWallTime(utc);
  return DateTime.utc(wall.year, wall.month, wall.day).subtract(vietnamOffset);
}
