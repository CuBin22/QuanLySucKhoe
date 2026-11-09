import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../ui/common.dart';
import '../../ui/motion.dart';
import '../../ui/app_theme.dart';
import 'care_reminder.dart';
import 'reminder_occurrence.dart';
import 'care_form.dart';

class CareDetailScreen extends StatefulWidget {
  const CareDetailScreen({
    super.key,
    required this.services,
    required this.reminderId,
  });
  final AppServices services;
  final int reminderId;
  @override
  State<CareDetailScreen> createState() => _CareDetailScreenState();
}

class _CareDetailScreenState extends State<CareDetailScreen> {
  late Future<(CareReminder?, List<ReminderOccurrence>)> _data;
  bool _busy = false;
  int _visible = 50;
  @override
  void initState() {
    super.initState();
    _query();
  }

  void _query() {
    _data = () async {
      return (
        await widget.services.care.find(widget.reminderId),
        await widget.services.care.occurrencesFor(widget.reminderId),
      );
    }();
  }

  Future<void> _refresh() async {
    await widget.services.sync.reconcile();
    await widget.services.refresh();
    if (mounted) setState(_query);
  }

  Future<void> _resolve(
    ReminderOccurrence item,
    OccurrenceStatus result,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.services.care.resolve(
        item.id,
        result,
        nowUtc: DateTime.now().toUtc(),
      );
      await _refresh();
    } catch (_) {
      if (mounted) {
        showFeedback(
          context,
          'Chưa xác nhận được lần nhắc. Hãy làm mới và thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(CareReminder plan) async {
    if (!await confirmRemoval(
      context,
      title: 'Xóa lịch?',
      message:
          '“${plan.title}” sẽ được lưu trữ ẩn. Các lần chưa hoàn thành sẽ được hủy; lịch sử đã xác nhận được giữ lại.',
    )) {
      return;
    }
    try {
      await widget.services.care.archive(
        plan.id!,
        nowUtc: DateTime.now().toUtc(),
      );
      await _refresh();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showFeedback(context, 'Chưa xóa được lịch. Hãy thử lại.');
    }
  }

  String _status(ReminderOccurrence item) {
    return switch (item.status) {
      OccurrenceStatus.completed => 'Đã hoàn thành',
      OccurrenceStatus.skipped => 'Đã bỏ qua',
      OccurrenceStatus.cancelled => 'Đã hủy',
      OccurrenceStatus.pending =>
        item.scheduledAtUtc.isAfter(DateTime.now().toUtc())
            ? 'Sắp đến'
            : 'Quá hạn',
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chi tiết lịch'),
      actions: [
        IconButton(
          key: const ValueKey('care-refresh'),
          tooltip: 'Làm mới lịch',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<(CareReminder?, List<ReminderOccurrence>)>(
      future: _data,
      builder: (context, s) {
        if (s.hasError) {
          return EmptyState(
            title: 'Chưa tải được lịch',
            message: 'Dữ liệu được giữ nguyên.',
            action: OutlinedButton(
              onPressed: () => setState(_query),
              child: const Text('Thử lại'),
            ),
          );
        }
        if (!s.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: SkeletonList(count: 3, height: 110),
          );
        }
        final p = s.data!.$1;
        final items = s.data!.$2;
        if (p == null) {
          return const EmptyState(
            title: 'Không tìm thấy lịch',
            message: 'Lịch không còn tồn tại trên máy chủ.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeader(
              title: p.title,
              subtitle:
                  '${p.type == ReminderType.medication ? 'Uống thuốc' : 'Tái khám'} · ${p.localTime} · UTC+7',
            ),
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hiệu lực: ${p.startDate.split('-').reversed.join('/')} — ${p.endDate.split('-').reversed.join('/')}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.isArchived
                        ? 'Lịch đã lưu trữ; lịch sử được giữ lại.'
                        : p.isEnabled
                        ? 'Lịch đang bật.'
                        : 'Lịch đã tắt.',
                  ),
                  if (p.note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(p.note),
                  ],
                  if (!p.isArchived) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final saved = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => CareForm(
                                      services: widget.services,
                                      initial: p,
                                    ),
                                  ),
                                );
                            if (saved == true) await _refresh();
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Chỉnh sửa lịch'),
                        ),
                        TextButton.icon(
                          onPressed: () => _remove(p),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Xóa lịch'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (items.any((i) => i.notificationError != null)) ...[
              const InlineNotice(
                text: 'Một số thông báo chưa được cập nhật. Lịch vẫn được lưu; bạn có thể bật quyền hoặc thử lại ở mục Lịch chăm sóc.',
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Các lần thực hiện · ${items.length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final item in items.take(_visible))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text(
                            '${displayDate(item.scheduledAtUtc)} · ${displayTime(item.scheduledAtUtc)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            _status(item),
                            style: TextStyle(
                              color: item.status == OccurrenceStatus.completed
                                  ? AppColors.secondary
                                  : AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (item.resolvedAtUtc != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Xác nhận lúc ${displayTime(item.resolvedAtUtc!)} · ${displayDate(item.resolvedAtUtc!)}',
                        ),
                      ],
                      if (item.status == OccurrenceStatus.pending) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              key: ValueKey('complete-${item.id}'),
                              onPressed:
                                  _busy ||
                                      item.scheduledAtUtc.isAfter(
                                        DateTime.now().toUtc(),
                                      )
                                  ? null
                                  : () => _resolve(
                                      item,
                                      OccurrenceStatus.completed,
                                    ),
                              icon: const Icon(Icons.check),
                              label: const Text('Hoàn thành'),
                            ),
                            TextButton(
                              onPressed:
                                  _busy ||
                                      item.scheduledAtUtc.isAfter(
                                        DateTime.now().toUtc(),
                                      )
                                  ? null
                                  : () => _resolve(
                                      item,
                                      OccurrenceStatus.skipped,
                                    ),
                              child: const Text('Bỏ qua'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (items.length > _visible)
              OutlinedButton(
                onPressed: () => setState(() => _visible += 50),
                child: const Text('Xem thêm lịch sử'),
              ),
          ],
        );
      },
    ),
  );
}
