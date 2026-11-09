import 'package:sqflite_common/sqlite_api.dart';

import 'package:suc_khoe_ca_nhan/domain/app_time.dart';
import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

import 'sqlite_profile_repository.dart';

import 'package:suc_khoe_ca_nhan/features/health/health_record.dart';

import 'sqlite_health_repository.dart';

import 'package:suc_khoe_ca_nhan/features/care/care_reminder.dart';

import 'sqlite_care_repository.dart';

Future<bool> seedDemoData(Database db) async {
  final profiles = SqliteProfileRepository(db);
  if (await profiles.load() != null) return false;
  await profiles.save(
    const Profile(
      fullName: 'Người dùng minh họa',
      heightCm: 170,
      targetWeightKg: 65,
    ),
  );
  final now = DateTime.now().toUtc();
  final health = SqliteHealthRepository(db);
  for (var day = 29; day >= 0; day--) {
    await health.save(
      HealthRecord(
        measuredAtUtc: now.subtract(Duration(days: day)),
        weightKg: 65.2 + day * 0.045 + (day % 3) * 0.1,
        systolic: 116 + day % 7,
        diastolic: 75 + day % 5,
        heartRate: 68 + day % 8,
        note: day == 0 ? 'Dữ liệu minh họa phục vụ demo' : '',
      ),
    );
  }
  final wall = vietnamWallTime(now);
  final start = parseDateKey(dateKey(wall));
  final care = SqliteCareRepository(db);
  await care.save(
    CareReminder(
      type: ReminderType.medication,
      title: 'Lịch thuốc minh họa',
      note: 'Chỉ là dữ liệu demo, không phải chỉ định dùng thuốc.',
      repeatRule: RepeatRule.daily,
      startDate: dateKey(start),
      endDate: dateKey(start.add(const Duration(days: 6))),
      localTime: '08:00',
    ),
    nowUtc: now,
  );
  final appointment = start.add(const Duration(days: 3));
  await care.save(
    CareReminder(
      type: ReminderType.appointment,
      title: 'Tái khám minh họa',
      note: 'Mang theo sổ theo dõi sức khỏe.',
      startDate: dateKey(appointment),
      endDate: dateKey(appointment),
      localTime: '14:00',
    ),
    nowUtc: now,
  );
  return true;
}
