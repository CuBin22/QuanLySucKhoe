import 'package:sqflite_common/sqlite_api.dart';
import 'package:suc_khoe_ca_nhan/notifications/notification_sync.dart' as app;
import 'package:suc_khoe_ca_nhan/notifications/notification_port.dart';

import 'sqlite_notification_store.dart';

class NotificationSync extends app.NotificationSync {
  NotificationSync(Database db, NotificationPort port, {super.utcNow})
    : super(SqliteNotificationStore(db), port);
}
