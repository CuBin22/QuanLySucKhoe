import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../notifications/notification_port.dart';
import '../../ui/common.dart';
import '../../ui/app_theme.dart';
import '../../ui/motion.dart';
import 'care_reminder.dart';
import 'care_form.dart';
import 'care_detail_screen.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key, required this.services, this.revision = 0});
  final AppServices services;
  final int revision;
  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  ReminderType? _type;
  int _status = 0, _visible = 50;
  final _busy = <int>{};
  late Future<(List<CareReminder>, bool)> _data;
  @override
  void initState() {
    super.initState();
    _query();
  }

  @override
  void didUpdateWidget(covariant CareScreen old) {
    super.didUpdateWidget(old);
    if (old.revision != widget.revision) _query();
  }

  void _query() {
    _data = () async {
      var plans = await widget.services.care.list(
        type: _type,
        includeArchived: _status == 3,
      );
      plans = plans
          .where(
            (p) => switch (_status) {
              1 => p.isEnabled && !p.isArchived,
              2 => !p.isEnabled && !p.isArchived,
              3 => p.isArchived,
              _ => !p.isArchived,
            },
          )
          .toList();
      return (plans, await widget.services.sync.hasWarnings());
    }();
  }

  Future<void> _refresh() async {
    await widget.services.sync.reconcile();
    await widget.services.refresh();
    if (mounted) setState(_query);
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CareForm(services: widget.services)),
    );
    if (saved == true) {
      await _refresh();
      final warnings = await widget.services.sync.hasWarnings();
      if (mounted) {
        showFeedback(
          context,
          warnings
              ? 'Đã lưu lịch, chưa bật được thông báo. Bạn có thể thử lại.'
              : 'Đã lưu lịch chăm sóc.',
        );
      }
    }
  }

  Future<void> _permission() async {
    final state = await widget.services.notifications.requestPermission();
    await _refresh();
    if (mounted) {
      showFeedback(context, switch (state) {
        NotificationPermission.granted =>
          'Đã bật nhắc nhở cho các lịch còn hiệu lực.',
        NotificationPermission.denied => 'Chưa được cấp quyền thông báo. Bạn vẫn xem được lịch trong ứng dụng.',
        NotificationPermission.unavailable => 'Bản chạy này chưa bật được thông báo hệ thống. Xem hướng dẫn cài đặt.',
      });
    }
  }

  Future<void> _toggle(CareReminder plan, bool value) async {
    if (!value &&
        !await confirmRemoval(
          context,
          title: 'Tắt lịch?',
          message:
              'Các lần chưa hoàn thành của “${plan.title}” sẽ được hủy. Lịch sử đã xác nhận được giữ lại.',
          actionLabel: 'Tắt lịch',
        )) {
      return;
    }
    setState(() => _busy.add(plan.id!));
    try {
      await widget.services.care.setEnabled(
        plan.id!,
        value,
        nowUtc: DateTime.now().toUtc(),
      );
      await _refresh();
    } catch (error) {
      if (mounted) {
        showFeedback(
          context,
          error is FormatException
              ? error.message
              : 'Chưa cập nhật được lịch. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(plan.id));
    }
  }

  @override
  Widget build(BuildContext context) => PageList(
    children: [
      PageHeader(
        title: 'Lịch chăm sóc',
        subtitle: 'Một lịch rõ ràng cho những việc cần nhớ.',
        action: FilledButton.icon(
          key: const ValueKey('add-care'),
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Tạo lịch'),
        ),
      ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: _permission,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Bật nhắc nhở'),
          ),
          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại thông báo'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const Text('Giờ Việt Nam (UTC+7). Lịch lặp tối đa 30 ngày mỗi đợt.'),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Tất cả loại'),
            selected: _type == null,
            onSelected: (_) => setState(() {
              _type = null;
              _query();
            }),
          ),
          for (final type in ReminderType.values)
            ChoiceChip(
              label: Text(
                type == ReminderType.medication ? 'Uống thuốc' : 'Tái khám',
              ),
              selected: _type == type,
              onSelected: (_) => setState(() {
                _type = type;
                _query();
              }),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 4; i++)
            ChoiceChip(
              label: Text(
                ['Tất cả lịch', 'Đang bật', 'Đã tắt', 'Đã lưu trữ'][i],
              ),
              selected: _status == i,
              onSelected: (_) => setState(() {
                _status = i;
                _visible = 50;
                _query();
              }),
            ),
        ],
      ),
      const SizedBox(height: 20),
      FutureBuilder<(List<CareReminder>, bool)>(
        future: _data,
        builder: (context, s) {
          if (s.hasError) {
            return EmptyState(
              title: 'Chưa tải được lịch',
              message: 'Dữ liệu vẫn được giữ nguyên.',
              action: OutlinedButton(
                onPressed: () => setState(_query),
                child: const Text('Thử lại'),
              ),
            );
          }
          if (!s.hasData) {
            return const SkeletonList(count: 3, height: 130);
          }
          final plans = s.data!.$1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.data!.$2) ...[
                const InlineNotice(
                  text: 'Đã lưu lịch, chưa bật được thông báo cho một số lần nhắc. Chọn Bật nhắc nhở hoặc Thử lại thông báo.',
                ),
                const SizedBox(height: 16),
              ],
              if (plans.isEmpty)
                const EmptyState(
                  title: 'Chưa có lịch trong nhóm này',
                  message: 'Tạo lịch uống thuốc hoặc tái khám, hoặc chọn bộ lọc khác.',
                  icon: Icons.event_note_outlined,
                  hue: Hue.lime,
                ),
              for (final (i, p) in plans.take(_visible).indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Reveal(
                    index: i,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: p.isEnabled || p.isArchived ? 1 : 0.62,
                      child: AppPanel(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HueBadge(
                                  icon: p.type == ReminderType.medication
                                      ? Icons.medication_outlined
                                      : Icons.local_hospital_outlined,
                                  hue: Hue.lime,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    p.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                if (!p.isArchived)
                                  Switch(
                                    value: p.isEnabled,
                                    onChanged: _busy.contains(p.id)
                                        ? null
                                        : (v) => _toggle(p, v),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${p.localTime} · ${p.repeatRule == RepeatRule.daily ? 'Mỗi ngày' : 'Một lần'} · ${p.isArchived
                                  ? 'Đã lưu trữ'
                                  : p.isEnabled
                                  ? 'Đang bật'
                                  : 'Đã tắt'}',
                            ),
                            Text(
                              '${p.startDate.split('-').reversed.join('/')} — ${p.endDate.split('-').reversed.join('/')}',
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () async {
                                await Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) => CareDetailScreen(
                                      services: widget.services,
                                      reminderId: p.id!,
                                    ),
                                  ),
                                );
                                if (mounted) setState(_query);
                              },
                              child: const Text('Xem lịch và lịch sử'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (plans.length > _visible)
                OutlinedButton(
                  onPressed: () => setState(() => _visible += 50),
                  child: const Text('Xem thêm lịch'),
                ),
            ],
          );
        },
      ),
    ],
  );
}
