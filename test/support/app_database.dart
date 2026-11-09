import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart' as desktop;
import 'package:sqflite_common/sqlite_api.dart';

import 'schema.dart';

Future<Database> openAppDatabase({
  DatabaseFactory? factory,
  String? path,
}) async {
  if (factory == null) {
    desktop.sqfliteFfiInit();
    factory = desktop.databaseFactoryFfi;
  }
  path ??= p.join(
    (await getApplicationSupportDirectory()).path,
    'personal_health.db',
  );
  if (path != inMemoryDatabasePath) {
    await Directory(p.dirname(path)).create(recursive: true);
  }
  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        for (final statement in schemaStatements) {
          await db.execute(statement);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        throw StateError(
          'Phiên bản dữ liệu chưa được hỗ trợ. Dữ liệu cũ được giữ nguyên.',
        );
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        throw StateError('Cần bản ứng dụng mới hơn để mở dữ liệu này.');
      },
    ),
  );
}
