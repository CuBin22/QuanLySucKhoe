import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/legacy_app.dart';
import '../support/app_database.dart';
import '../support/demo_seed.dart';

import '../notifications/fake_notification_port.dart';
import 'test_host.dart';

void main() {
  sqfliteFfiInit();
  testWidgets(
    'render actual Flutter layouts with labelled demo data for report evidence',
    (tester) async {
      final db = (await tester.runAsync(
        () => openAppDatabase(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      addTearDown(db.close);
      await tester.runAsync(() => seedDemoData(db));
      final boundary = GlobalKey();
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: HealthApp(
            database: db,
            notifications: FakeNotificationPort(),
            demoMode: true,
          ),
        ),
      );
      await pumpDatabase(tester);
      Future<void> capture(String name) async {
        await tester.pump();
        expect(tester.takeException(), isNull);
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final length = await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 1.5);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          image.dispose();
          await Directory('docs/evidence').create(recursive: true);
          await File('docs/evidence/$name.png').writeAsBytes(bytes);
          return bytes.length;
        });
        expect(length, greaterThan(10000));
      }

      await capture('desktop_overview');
      await tester.tap(find.text('Chỉ số').last);
      await pumpDatabase(tester);
      await capture('desktop_health');
      tester.view.physicalSize = const Size(360, 900);
      await pumpDatabase(tester);
      await capture('mobile_health');
      await tester.tap(find.text('Lịch chăm sóc').last);
      await pumpDatabase(tester);
      await capture('mobile_care');
      tester.view.physicalSize = const Size(1280, 900);
      await pumpDatabase(tester);
      await capture('desktop_care');
    },
  );
}
