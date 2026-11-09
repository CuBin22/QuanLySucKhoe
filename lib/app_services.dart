import 'package:flutter/foundation.dart';

import 'features/profile/profile.dart';
import 'features/profile/profile_repository.dart';
import 'features/health/health_repository.dart';
import 'features/care/care_repository.dart';
import 'notifications/notification_port.dart';
import 'notifications/notification_sync.dart';
import 'data/api_client.dart';
import 'data/api_repositories.dart';

class AppServices extends ChangeNotifier {
  AppServices({
    required this.notifications,
    required this.profiles,
    required this.health,
    required this.care,
    required this.sync,
  });
  AppServices.remote(
    ApiClient api,
    this.notifications, {
    Future<void> Function()? beforeReconcile,
  }) : profiles = ApiProfileRepository(api),
       health = ApiHealthRepository(api),
       care = ApiCareRepository(api),
       sync = NotificationSync(
         ApiNotificationStore(api),
         notifications,
         beforeReconcile: beforeReconcile,
       );
  final NotificationPort notifications;
  final ProfileRepository profiles;
  final HealthRepository health;
  final CareRepository care;
  final NotificationSync sync;
  Profile? profile;
  int revision = 0;
  bool _disposed = false;
  Future<void> refresh() async {
    profile = await profiles.load();
    revision++;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
