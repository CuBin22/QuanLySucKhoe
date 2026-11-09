abstract class NotificationStore {
  Future<List<Map<String, Object?>>> cancellations();
  Future<List<Map<String, Object?>>> future(DateTime nowUtc);
  Future<bool> isPending(int id);
  Future<bool> markScheduled(int id);
  Future<void> markCancelled(int id);
  Future<void> cancelFailed(int id);
  Future<void> failure(int id, String code);
  Future<bool> hasWarnings(DateTime nowUtc);
}
