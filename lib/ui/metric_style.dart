import 'package:flutter/material.dart';

import '../features/health/health_record.dart';
import 'app_theme.dart';
import 'common.dart';

/// Nhận diện thị giác của từng chỉ số: mỗi chỉ số một màu trái cây.
extension HealthMetricStyle on HealthMetric {
  Hue get hue => switch (this) {
    HealthMetric.weight => Hue.mango,
    HealthMetric.bloodPressure => Hue.dragon,
    HealthMetric.heartRate => Hue.melon,
  };
  IconData get icon => switch (this) {
    HealthMetric.weight => Icons.monitor_weight_outlined,
    HealthMetric.bloodPressure => Icons.bloodtype_outlined,
    HealthMetric.heartRate => Icons.favorite_border,
  };
  String get label => switch (this) {
    HealthMetric.weight => 'Cân nặng',
    HealthMetric.bloodPressure => 'Huyết áp',
    HealthMetric.heartRate => 'Nhịp tim',
  };
  String get unit => switch (this) {
    HealthMetric.weight => 'kg',
    HealthMetric.bloodPressure => 'mmHg',
    HealthMetric.heartRate => 'nhịp/phút',
  };

  bool has(HealthRecord r) => switch (this) {
    HealthMetric.weight => r.weightKg != null,
    HealthMetric.bloodPressure => r.systolic != null && r.diastolic != null,
    HealthMetric.heartRate => r.heartRate != null,
  };

  /// Giá trị dùng để vẽ (huyết áp lấy tâm thu).
  double valueOf(HealthRecord r) => switch (this) {
    HealthMetric.weight => r.weightKg!,
    HealthMetric.bloodPressure => r.systolic!.toDouble(),
    HealthMetric.heartRate => r.heartRate!.toDouble(),
  };

  /// Số hiển thị; [t] từ 0 đến 1 để đếm lên, t = 1 cho đúng giá trị thật.
  String number(HealthRecord r, [double t = 1]) => switch (this) {
    HealthMetric.weight => displayNumber(r.weightKg! * t),
    HealthMetric.bloodPressure =>
      '${(r.systolic! * t).round()}/${(r.diastolic! * t).round()}',
    HealthMetric.heartRate => '${(r.heartRate! * t).round()}',
  };
}
