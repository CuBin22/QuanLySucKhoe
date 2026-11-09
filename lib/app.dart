import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'notifications/notification_port.dart';
import 'notifications/local_notification_service.dart';
import 'data/remote_services.dart';
import 'data/api_client.dart';
import 'app_services.dart';
import 'ui/app_shell.dart';
import 'ui/app_theme.dart';
import 'ui/common.dart';
import 'features/profile/profile_screen.dart';
import 'features/health/health_screen.dart';
import 'features/overview/overview_screen.dart';
import 'features/care/care_screen.dart';
import 'features/care/care_detail_screen.dart';

class HealthApp extends StatefulWidget {
  const HealthApp({
    super.key,
    this.services,
    this.notifications,
    this.demoMode = false,
  });
  final AppServices? services;
  final NotificationPort? notifications;
  final bool demoMode;
  @override
  State<HealthApp> createState() => _HealthAppState();
}

class _HealthAppState extends State<HealthApp> with WidgetsBindingObserver {
  late Future<AppServices> _boot;
  AppServices? _services;
  final _navigator = GlobalKey<NavigatorState>();
  final _shell = GlobalKey<AppShellState>();
  final _profile = GlobalKey<ProfileScreenState>();
  StreamSubscription<int>? _selections;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot = _start();
  }

  Future<AppServices> _start() async {
    final service =
        widget.services ??
        await createRemoteServices(
          widget.notifications ?? LocalNotificationService(),
        );
    await service.refresh();
    _services = service;
    _selections = service.notifications.selections.listen(
      (id) => _openOccurrence(id),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final id = await service.notifications.getLaunchOccurrenceId();
      if (id != null) await _openOccurrence(id);
      await _sync();
    });
    return service;
  }

  Future<void> _sync() async {
    final service = _services;
    if (service == null || !mounted) return;
    try {
      await service.sync.reconcile();
      if (mounted) await service.refresh();
    } catch (_) {
      /* Existing records remain available for retry. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  Future<void> _openOccurrence(int id) async {
    final service = _services;
    if (service == null || service.profile == null || !mounted) return;
    int? reminderId;
    try {
      reminderId = await service.care.reminderIdForOccurrence(id);
    } catch (_) {
      if (mounted && _navigator.currentContext != null) {
        showFeedback(
          _navigator.currentContext!,
          'Chưa kết nối được API để mở lịch. Hãy thử lại.',
        );
      }
      return;
    }
    if (!mounted) return;
    if (reminderId == null) {
      await _shell.currentState?.select(2);
      if (mounted && _navigator.currentContext != null) {
        showFeedback(
          _navigator.currentContext!,
          'Lần nhắc không còn tồn tại. Hãy kiểm tra danh sách lịch.',
        );
      }
      return;
    }
    _showReminder(reminderId);
  }

  void _showReminder(int id) {
    final service = _services;
    if (service != null && mounted) {
      _navigator.currentState?.push<void>(
        MaterialPageRoute(
          builder: (_) => CareDetailScreen(services: service, reminderId: id),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selections?.cancel();
    _services?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sức Khỏe Cá Nhân',
    debugShowCheckedModeBanner: false,
    navigatorKey: _navigator,
    theme: buildAppTheme(),
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.demoMode)
          Material(
            color: const Color(0xFFFFF3CD),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Dữ liệu minh họa phục vụ demo · không phải hồ sơ sức khỏe thật',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        Expanded(child: child ?? const SizedBox.shrink()),
      ],
    ),
    home: FutureBuilder<AppServices>(
      future: _boot,
      builder: (context, s) {
        if (s.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  title: 'Chưa mở được dữ liệu',
                  message: s.error is ApiException
                      ? (s.error as ApiException).message
                      : 'Chưa kết nối được API SQL Server. Kiểm tra máy chủ và mạng rồi thử lại.',
                  action: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _boot = _start();
                      });
                    },
                    child: const Text('Thử lại'),
                  ),
                ),
              ),
            ),
          );
        }
        if (!s.hasData) {
          return const BootSplash();
        }
        final services = s.data!;
        return AnimatedBuilder(
          animation: services,
          builder: (context, _) => services.profile == null
              ? ProfileScreen(
                  key: _profile,
                  repository: services.profiles,
                  onSaved: services.refresh,
                )
              : AppShell(
                  key: _shell,
                  beforeChange: (from, to) async => from == 3
                      ? await _profile.currentState?.confirmLeave() ?? true
                      : true,
                  pages: [
                    OverviewScreen(
                      services: services,
                      onOpenReminder: _showReminder,
                    ),
                    HealthScreen(
                      repository: services.health,
                      onChanged: services.refresh,
                      revision: services.revision,
                    ),
                    CareScreen(services: services, revision: services.revision),
                    ProfileScreen(
                      key: _profile,
                      repository: services.profiles,
                      initial: services.profile,
                      onSaved: services.refresh,
                    ),
                  ],
                ),
        );
      },
    ),
  );
}
