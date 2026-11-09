// shortcut: test_api internals provide socket-free execution in restricted Windows;
// replace this runner with flutter test when local loopback becomes available.
// ignore_for_file: avoid_print, implementation_imports
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_api/src/backend/declarer.dart';
import 'package:test_api/src/backend/group.dart';
import 'package:test_api/src/backend/invoker.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/suite.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_api/src/backend/test.dart' as backend;

Future<Never> runNativeTests(List<void Function()> entries) async {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();
  final declarer = Declarer();
  declarer.declare(() {
    for (var index = 0; index < entries.length; index++) {
      group('suite $index', entries[index]);
    }
  });
  final suite = Suite(declarer.build(), SuitePlatform(Runtime.vm));
  var passed = 0;
  var failed = 0;
  Future<void> runGroup(Group group, List<Group> parents) async {
    final groups = [...parents, group];
    for (final entry in group.entries) {
      if (entry is Group) {
        await runGroup(entry, groups);
      } else if (entry is backend.Test) {
        final live = entry.load(suite, groups: groups);
        await live.run();
        if (live.errors.isEmpty) {
          passed++;
          print('PASS ${entry.name}');
        } else {
          failed++;
          for (final error in live.errors) {
            print('FAIL ${entry.name}: $error');
          }
        }
        await live.close();
      }
    }
  }

  await Invoker.guard(() => runGroup(suite.group, []));
  print('NATIVE_TEST_RESULT passed=$passed failed=$failed');
  exit(failed == 0 && passed > 0 ? 0 : 1);
}
