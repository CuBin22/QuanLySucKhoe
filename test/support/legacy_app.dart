import 'package:sqflite_common/sqlite_api.dart';
import 'package:suc_khoe_ca_nhan/app.dart' as app;
import 'package:suc_khoe_ca_nhan/app_services.dart';
import 'package:suc_khoe_ca_nhan/notifications/notification_port.dart';
import 'package:suc_khoe_ca_nhan/notifications/local_notification_service.dart';
import 'package:suc_khoe_ca_nhan/notifications/notification_sync.dart';

import 'sqlite_profile_repository.dart';
import 'sqlite_health_repository.dart';
import 'sqlite_care_repository.dart';
import 'sqlite_notification_store.dart';

AppServices localServices(Database db, NotificationPort port) => AppServices(
  notifications: port,
  profiles: SqliteProfileRepository(db),
  health: SqliteHealthRepository(db),
  care: SqliteCareRepository(db),
  sync: NotificationSync(SqliteNotificationStore(db), port),
);

class HealthApp extends app.HealthApp {
  HealthApp({
    super.key,
    required Database database,
    NotificationPort? notifications,
    super.demoMode,
  }) : super(
         services: localServices(
           database,
           notifications ?? LocalNotificationService(),
         ),
       );
}
