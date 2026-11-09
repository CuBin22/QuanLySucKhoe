import 'package:suc_khoe_ca_nhan/features/profile/profile_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'package:suc_khoe_ca_nhan/features/profile/profile.dart';

class SqliteProfileRepository implements ProfileRepository {
  SqliteProfileRepository(this.db);
  final Database db;
  @override
  Future<Profile?> load() async {
    final rows = await db.query('profiles', where: 'id = ?', whereArgs: [1]);
    return rows.isEmpty ? null : Profile.fromMap(rows.single);
  }

  @override
  Future<void> save(Profile profile) async {
    if (profile.fullName.trim().isEmpty ||
        !profile.heightCm.isFinite ||
        profile.heightCm <= 0 ||
        (profile.targetWeightKg != null &&
            (!profile.targetWeightKg!.isFinite ||
                profile.targetWeightKg! <= 0))) {
      throw const FormatException('Nhập họ tên và các số đo lớn hơn 0.');
    }
    if (profile.birthDate != null) {
      final date = DateTime.tryParse(profile.birthDate!);
      final today = DateTime.now().toUtc().add(const Duration(hours: 7));
      if (date == null ||
          date.toIso8601String().substring(0, 10) != profile.birthDate ||
          date.isAfter(DateTime(today.year, today.month, today.day))) {
        throw const FormatException('Ngày sinh không hợp lệ hoặc ở tương lai.');
      }
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    // UPDATE then INSERT works on SQLite shipped with older Android versions.
    // Keep the row identity and created_at_utc; REPLACE would delete the row.
    await db.transaction((txn) async {
      final values = <String, Object?>{
        'full_name': profile.fullName.trim(),
        'birth_date': profile.birthDate,
        'height_cm': profile.heightCm,
        'target_weight_kg': profile.targetWeightKg,
        'updated_at_utc': now,
      };
      final changed = await txn.update(
        'profiles',
        values,
        where: 'id = ?',
        whereArgs: [1],
      );
      if (changed == 0) {
        await txn.insert('profiles', {
          'id': 1,
          ...values,
          'created_at_utc': now,
        });
      }
    });
  }
}
