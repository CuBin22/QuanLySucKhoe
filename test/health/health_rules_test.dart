import 'package:flutter_test/flutter_test.dart';
import 'package:suc_khoe_ca_nhan/features/health/health_record.dart';
import 'package:suc_khoe_ca_nhan/features/health/health_rules.dart';

void main() {
  test('decimal input accepts Vietnamese comma and rejects ambiguous or non-finite values', () {
    expect(parsePositiveDecimal('65,5'), 65.5);
    expect(parsePositiveDecimal(' 65.5 '), 65.5);
    for (final text in [
      '1,2.3',
      'NaN',
      'Infinity',
      '-5',
      '0',
      '',
      '1,000,000',
    ]) {
      expect(
        () => parsePositiveDecimal(text),
        throwsFormatException,
        reason: text,
      );
    }
  });
  test('record requires a group, a complete blood-pressure pair and nonfuture date', () {
    final now = DateTime.utc(2026, 10, 31, 3);
    expect(
      validateHealthRecord(HealthRecord(measuredAtUtc: now), nowUtc: now),
      contains('values'),
    );
    expect(
      validateHealthRecord(
        HealthRecord(measuredAtUtc: now, systolic: 120),
        nowUtc: now,
      ),
      contains('diastolic'),
    );
    expect(
      validateHealthRecord(
        HealthRecord(measuredAtUtc: now, systolic: 80, diastolic: 90),
        nowUtc: now,
      ),
      contains('systolic'),
    );
    expect(
      validateHealthRecord(
        HealthRecord(
          measuredAtUtc: now.add(const Duration(seconds: 1)),
          heartRate: 72,
        ),
        nowUtc: now,
      ),
      contains('measured_at_utc'),
    );
    expect(
      validateHealthRecord(
        HealthRecord(measuredAtUtc: now, heartRate: 72),
        nowUtc: now,
      ),
      isEmpty,
    );
  });
}
