import 'package:suc_khoe_ca_nhan/features/health/health_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'package:suc_khoe_ca_nhan/features/health/health_record.dart';
import 'package:suc_khoe_ca_nhan/features/health/health_rules.dart';

class SqliteHealthRepository implements HealthRepository {
  SqliteHealthRepository(this.db, {DateTime Function()? utcNow})
    : _utcNow = utcNow ?? (() => DateTime.now().toUtc());
  final Database db;
  final DateTime Function() _utcNow;
  @override
  Future<int> save(HealthRecord record) async {
    final now = _utcNow();
    final errors = validateHealthRecord(record, nowUtc: now);
    if (errors.isNotEmpty) throw FormatException(errors.values.first);
    return db.transaction((txn) async {
      Map<String, Object?>? previous;
      if (record.id != null) {
        final rows = await txn.query(
          'health_records',
          where: 'id = ?',
          whereArgs: [record.id],
        );
        if (rows.isEmpty) throw StateError('Bản ghi không còn tồn tại.');
        previous = rows.single;
      }
      double? snapshot;
      if (record.weightKg != null) {
        snapshot = (previous?['height_cm_snapshot'] as num?)?.toDouble();
        if (snapshot == null) {
          final profiles = await txn.query(
            'profiles',
            columns: ['height_cm'],
            where: 'id = ?',
            whereArgs: [1],
          );
          if (profiles.isEmpty) throw StateError('Hãy thiết lập hồ sơ trước.');
          snapshot = (profiles.single['height_cm'] as num).toDouble();
        }
      }
      final values = <String, Object?>{
        'profile_id': 1,
        'measured_at_utc': record.measuredAtUtc.toUtc().millisecondsSinceEpoch,
        'weight_kg': record.weightKg,
        'height_cm_snapshot': snapshot,
        'systolic': record.systolic,
        'diastolic': record.diastolic,
        'heart_rate': record.heartRate,
        'note': record.note.trim(),
        'updated_at_utc': now.millisecondsSinceEpoch,
      };
      if (record.id == null) {
        values['created_at_utc'] = now.millisecondsSinceEpoch;
        return txn.insert('health_records', values);
      }
      await txn.update(
        'health_records',
        values,
        where: 'id = ?',
        whereArgs: [record.id],
      );
      return record.id!;
    });
  }

  @override
  Future<void> delete(int id) async {
    if (await db.delete('health_records', where: 'id = ?', whereArgs: [id]) ==
        0) {
      throw StateError('Bản ghi không còn tồn tại.');
    }
  }

  @override
  Future<List<HealthRecord>> list({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final rows = await db.query(
      'health_records',
      where: 'measured_at_utc >= ? AND measured_at_utc < ?',
      whereArgs: [fromUtc.millisecondsSinceEpoch, toUtc.millisecondsSinceEpoch],
      orderBy: 'measured_at_utc DESC, id DESC',
    );
    return rows.map(HealthRecord.fromMap).toList();
  }

  @override
  Future<Map<HealthMetric, HealthRecord>> latestByMetric() async {
    final result = <HealthMetric, HealthRecord>{};
    const columns = {
      HealthMetric.weight: 'weight_kg',
      HealthMetric.bloodPressure: 'systolic',
      HealthMetric.heartRate: 'heart_rate',
    };
    for (final entry in columns.entries) {
      final rows = await db.query(
        'health_records',
        where: '${entry.value} IS NOT NULL',
        orderBy: 'measured_at_utc DESC, id DESC',
        limit: 1,
      );
      if (rows.isNotEmpty) {
        result[entry.key] = HealthRecord.fromMap(rows.single);
      }
    }
    return result;
  }
}
