import 'health_record.dart';

abstract class HealthRepository {
  Future<int> save(HealthRecord record);
  Future<void> delete(int id);
  Future<List<HealthRecord>> list({
    required DateTime fromUtc,
    required DateTime toUtc,
  });
  Future<Map<HealthMetric, HealthRecord>> latestByMetric();
}
