import 'package:flutter_test/flutter_test.dart';
import 'package:suc_khoe_ca_nhan/features/care/care_reminder.dart';
import 'package:suc_khoe_ca_nhan/features/care/care_rules.dart';

CareReminder daily({
  String start = '2026-10-31',
  String end = '2026-11-01',
  String time = '08:00',
}) => CareReminder(
  type: ReminderType.medication,
  title: 'Lịch thử',
  repeatRule: RepeatRule.daily,
  startDate: start,
  endDate: end,
  localTime: time,
);

void main() {
  test('daily schedule skips elapsed hour today and includes the final day in Vietnam time', () {
    final times = generateOccurrenceTimes(
      daily(),
      nowUtc: DateTime.utc(2026, 10, 31, 2),
      creating: true,
    );
    expect(times, [DateTime.utc(2026, 11, 1, 1)]);
  });
  test('30 days is accepted and 31 days is rejected', () {
    final now = DateTime.utc(2026, 10, 30);
    expect(
      generateOccurrenceTimes(
        daily(start: '2026-11-01', end: '2026-11-30'),
        nowUtc: now,
        creating: true,
      ).length,
      30,
    );
    expect(
      () => generateOccurrenceTimes(
        daily(start: '2026-11-01', end: '2026-12-01'),
        nowUtc: now,
        creating: true,
      ),
      throwsFormatException,
    );
  });
  test('new schedule cannot start in the past while edits preserve past start but generate only future', () {
    final now = DateTime.utc(2026, 11, 1, 2);
    final plan = daily(end: '2026-11-02');
    expect(
      () => generateOccurrenceTimes(plan, nowUtc: now, creating: true),
      throwsFormatException,
    );
    expect(generateOccurrenceTimes(plan, nowUtc: now, creating: false), [
      DateTime.utc(2026, 11, 2, 1),
    ]);
    expect(
      () => generateOccurrenceTimes(
        daily(end: '2026-11-01'),
        nowUtc: now,
        creating: false,
      ),
      throwsFormatException,
    );
  });
  test('appointment must be one-time and a strictly future date', () {
    final now = DateTime.utc(2026, 10, 31, 1);
    final past = CareReminder(
      type: ReminderType.appointment,
      title: 'Khám',
      startDate: '2026-10-31',
      endDate: '2026-10-31',
      localTime: '08:00',
    );
    expect(
      () => generateOccurrenceTimes(past, nowUtc: now, creating: true),
      throwsFormatException,
    );
    final repeat = CareReminder(
      type: ReminderType.appointment,
      title: 'Khám',
      repeatRule: RepeatRule.daily,
      startDate: '2026-11-01',
      endDate: '2026-11-02',
      localTime: '08:00',
    );
    expect(
      () => generateOccurrenceTimes(repeat, nowUtc: now, creating: true),
      throwsFormatException,
    );
  });
}
