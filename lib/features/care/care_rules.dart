import 'care_reminder.dart';
import '../../domain/app_time.dart';

List<DateTime> generateOccurrenceTimes(
  CareReminder reminder, {
  required DateTime nowUtc,
  required bool creating,
}) {
  if (reminder.title.trim().isEmpty) {
    throw const FormatException('Nhập tên lịch chăm sóc.');
  }
  final start = parseDateKey(reminder.startDate);
  final end = parseDateKey(reminder.endDate);
  final duration = end.difference(start).inDays;
  if (duration < 0 || duration > 29) {
    throw const FormatException('Khoảng lịch phải từ 1 đến 30 ngày.');
  }
  if (!RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(reminder.localTime)) {
    throw const FormatException('Giờ không hợp lệ.');
  }
  if ((reminder.type == ReminderType.appointment &&
          reminder.repeatRule != RepeatRule.none) ||
      (reminder.repeatRule == RepeatRule.none && duration != 0)) {
    throw const FormatException(
      'Lịch một lần phải có cùng ngày bắt đầu và kết thúc.',
    );
  }
  final today = parseDateKey(dateKey(vietnamWallTime(nowUtc)));
  if (creating && start.isBefore(today)) {
    throw const FormatException('Ngày bắt đầu không được trước hôm nay.');
  }
  final parts = reminder.localTime.split(':').map(int.parse).toList();
  final result = <DateTime>[];
  for (var index = 0; index <= duration; index++) {
    final day = start.add(Duration(days: index));
    final time = DateTime.utc(
      day.year,
      day.month,
      day.day,
      parts[0],
      parts[1],
    ).subtract(vietnamOffset);
    if (time.isAfter(nowUtc)) result.add(time);
  }
  if (result.isEmpty) {
    throw const FormatException(
      'Lịch không còn lần nhắc ở tương lai. Hãy đổi ngày hoặc giờ.',
    );
  }
  return result;
}
