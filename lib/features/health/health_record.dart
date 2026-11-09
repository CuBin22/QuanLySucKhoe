enum HealthMetric { weight, bloodPressure, heartRate }

class HealthRecord {
  const HealthRecord({
    this.id,
    required this.measuredAtUtc,
    this.weightKg,
    this.heightCmSnapshot,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.note = '',
  });
  final int? id;
  final DateTime measuredAtUtc;
  final double? weightKg;
  final double? heightCmSnapshot;
  final int? systolic;
  final int? diastolic;
  final int? heartRate;
  final String note;

  factory HealthRecord.fromMap(Map<String, Object?> row) => HealthRecord(
    id: row['id'] as int,
    measuredAtUtc: DateTime.fromMillisecondsSinceEpoch(
      row['measured_at_utc'] as int,
      isUtc: true,
    ),
    weightKg: (row['weight_kg'] as num?)?.toDouble(),
    heightCmSnapshot: (row['height_cm_snapshot'] as num?)?.toDouble(),
    systolic: row['systolic'] as int?,
    diastolic: row['diastolic'] as int?,
    heartRate: row['heart_rate'] as int?,
    note: row['note'] as String,
  );
}
