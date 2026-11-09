import 'health_record.dart';

double parsePositiveDecimal(String text) {
  final normalized = text.trim();
  if (!RegExp(r'^(?:\d+(?:[.,]\d+)?|[.,]\d+)$').hasMatch(normalized)) {
    throw const FormatException('Nhập một số lớn hơn 0, ví dụ 65,5.');
  }
  final value = double.tryParse(normalized.replaceAll(',', '.'));
  if (value == null || !value.isFinite || value <= 0) {
    throw const FormatException('Giá trị phải là số hữu hạn lớn hơn 0.');
  }
  return value;
}

Map<String, String> validateHealthRecord(
  HealthRecord record, {
  required DateTime nowUtc,
}) {
  final errors = <String, String>{};
  if (record.measuredAtUtc.isAfter(nowUtc)) {
    errors['measured_at_utc'] = 'Thời điểm đo không được ở tương lai.';
  }
  if (record.weightKg == null &&
      record.systolic == null &&
      record.diastolic == null &&
      record.heartRate == null) {
    errors['values'] = 'Nhập ít nhất một nhóm chỉ số.';
  }
  if (record.weightKg != null &&
      (!record.weightKg!.isFinite || record.weightKg! <= 0)) {
    errors['weight_kg'] = 'Cân nặng phải lớn hơn 0.';
  }
  if (record.systolic != null || record.diastolic != null) {
    if (record.diastolic == null || record.diastolic! <= 0) {
      errors['diastolic'] = 'Nhập huyết áp tâm trương lớn hơn 0.';
    }
    if (record.systolic == null ||
        record.systolic! <= 0 ||
        (record.diastolic != null && record.systolic! <= record.diastolic!)) {
      errors['systolic'] = 'Tâm thu phải lớn hơn tâm trương.';
    }
  }
  if (record.heartRate != null && record.heartRate! <= 0) {
    errors['heart_rate'] = 'Nhịp tim phải lớn hơn 0.';
  }
  return errors;
}
