import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../domain/app_time.dart';
import '../../ui/app_theme.dart';
import '../../ui/common.dart';
import '../../ui/metric_style.dart';
import '../../ui/motion.dart';
import '../../ui/sparkline.dart';
import '../care/care_reminder.dart';
import '../care/reminder_occurrence.dart';
import '../health/health_record.dart';

typedef _Today = (List<ReminderOccurrence>, Map<int, CareReminder>);

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    required this.services,
    this.onOpenReminder,
  });
  final AppServices services;
  final void Function(int)? onOpenReminder;
  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late int _revision;
  late Future<Map<HealthMetric, HealthRecord>> _latest;
  late Future<List<HealthRecord>> _trend;
  late Future<_Today> _today;

  @override
  void initState() {
    super.initState();
    _revision = widget.services.revision;
    _load();
  }

  @override
  void didUpdateWidget(covariant OverviewScreen old) {
    super.didUpdateWidget(old);
    if (_revision != widget.services.revision ||
        old.services != widget.services) {
      _revision = widget.services.revision;
      _load();
    }
  }

  void _load() {
    final services = widget.services;
    _latest = services.health.latestByMetric();
    final dayStart = vietnamDayStart(DateTime.now().toUtc());
    _trend = services.health.list(
      fromUtc: dayStart.subtract(const Duration(days: 29)),
      toUtc: dayStart.add(const Duration(days: 1)),
    );
    _today = () async {
      final slots = await services.care.occurrencesBetween(
        fromUtc: dayStart,
        toUtc: dayStart.add(const Duration(days: 1)),
      );
      final plans = await services.care.list(includeArchived: true);
      return (slots, {for (final p in plans) p.id!: p});
    }();
  }

  List<double> _series(List<HealthRecord> rows, HealthMetric m) {
    final list = rows.where(m.has).toList()
      ..sort((a, b) => a.measuredAtUtc.compareTo(b.measuredAtUtc));
    final tail = list.length > 14 ? list.sublist(list.length - 14) : list;
    return [for (final r in tail) m.valueOf(r)];
  }

  @override
  Widget build(BuildContext context) => PageList(
    key: const ValueKey('overview-page'),
    children: [
      PageHeader(
        title: 'Chào ${widget.services.profile?.fullName ?? 'bạn'},',
        subtitle: 'Sức khỏe hôm nay bắt đầu từ việc quan tâm đến bản thân.',
      ),
      Reveal(
        index: 1,
        child: Text(
          'Lần ghi nhận gần nhất',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      const SizedBox(height: 14),
      FutureBuilder<Map<HealthMetric, HealthRecord>>(
        future: _latest,
        builder: (context, s) {
          if (s.hasError) {
            return const InlineNotice(
              text: 'Chưa tải được chỉ số. Hãy chuyển lại màn hình để thử lại.',
              error: true,
            );
          }
          if (!s.hasData) return const SkeletonList(count: 1, height: 170);
          if (s.data!.isEmpty) {
            return const EmptyState(
              title: 'Bắt đầu theo dõi sức khỏe',
              message: 'Mở mục Chỉ số để ghi lần đo đầu tiên. Dữ liệu sẽ được lưu cho những lần xem sau.',
            );
          }
          return LayoutBuilder(
            builder: (context, c) {
              final width = c.maxWidth >= 800
                  ? (c.maxWidth - 32) / 3
                  : c.maxWidth >= 500
                  ? (c.maxWidth - 16) / 2
                  : c.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final (i, metric) in HealthMetric.values.indexed)
                    SizedBox(
                      width: width,
                      child: Reveal(
                        index: 2 + i,
                        child: _MetricCard(
                          metric: metric,
                          record: s.data![metric],
                          trend: _trend,
                          series: _series,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      const SizedBox(height: 32),
      Reveal(
        index: 5,
        child: Text(
          'Lịch hôm nay',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      const SizedBox(height: 14),
      FutureBuilder<_Today>(
        future: _today,
        builder: (context, s) {
          if (s.hasError) {
            return const InlineNotice(
              text: 'Chưa tải được lịch hôm nay. Hãy thử làm mới.',
              error: true,
            );
          }
          if (!s.hasData) return const SkeletonList(count: 2, height: 84);
          if (s.data!.$1.isEmpty) {
            return const EmptyState(
              title: 'Hôm nay chưa có lịch',
              message:
                  'Mở mục Lịch chăm sóc để tạo lịch uống thuốc hoặc tái khám.',
              icon: Icons.event_available_outlined,
              hue: Hue.lime,
            );
          }
          final slots = s.data!.$1.take(50).toList();
          final plans = s.data!.$2;
          final done = slots
              .where((i) => i.status == OccurrenceStatus.completed)
              .length;
          return Column(
            children: [
              Reveal(
                index: 6,
                child: _DayProgress(slots: slots, done: done),
              ),
              const SizedBox(height: 14),
              for (final (i, item) in slots.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Reveal(
                    index: 7 + i,
                    child: _OccurrenceRow(
                      item: item,
                      title: plans[item.reminderId]?.title ?? 'Lịch đã lưu trữ',
                      onOpen: widget.onOpenReminder == null
                          ? null
                          : () => widget.onOpenReminder!(item.reminderId),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
      const InlineNotice(
        text: 'Các chỉ số giúp ghi nhận và theo dõi, không thay thế việc thăm khám hoặc chẩn đoán.',
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.metric,
    required this.record,
    required this.trend,
    required this.series,
  });
  final HealthMetric metric;
  final HealthRecord? record;
  final Future<List<HealthRecord>> trend;
  final List<double> Function(List<HealthRecord>, HealthMetric) series;

  @override
  Widget build(BuildContext context) {
    final hue = metric.hue;
    final r = record;
    final theme = Theme.of(context).textTheme;
    return AppPanel(
      hue: hue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HueBadge(icon: metric.icon, hue: hue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  metric.label,
                  style: theme.titleSmall?.copyWith(color: hue.strong),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (r == null)
            Text(
              'Chưa ghi nhận',
              style: theme.titleMedium?.copyWith(color: AppColors.muted),
            )
          else ...[
            CountUp(
              builder: (context, t) => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: metric.number(r, t),
                      style: theme.headlineMedium?.copyWith(
                        fontSize: 34,
                        color: AppColors.ink,
                      ),
                    ),
                    TextSpan(
                      text: ' ${metric.unit}',
                      style: theme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${displayDate(r.measuredAtUtc)} · ${displayTime(r.measuredAtUtc)}',
              style: theme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<HealthRecord>>(
              future: trend,
              builder: (context, s) {
                final values = s.hasData ? series(s.data!, metric) : <double>[];
                if (values.length < 2) return const SizedBox(height: 44);
                return Sparkline(values: values, color: hue.line);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DayProgress extends StatelessWidget {
  const _DayProgress({required this.slots, required this.done});
  final List<ReminderOccurrence> slots;
  final int done;

  Color _color(ReminderOccurrence i) => switch (i.status) {
    OccurrenceStatus.completed => Hue.lime.line,
    OccurrenceStatus.pending => Hue.lime.glow.withValues(alpha: 0.35),
    _ => AppColors.border,
  };

  @override
  Widget build(BuildContext context) => AppPanel(
    hue: Hue.lime,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          done == slots.length
              ? 'Đã xong tất cả ${slots.length} lần nhắc hôm nay'
              : 'Đã xong $done trên ${slots.length} lần nhắc',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: Hue.lime.strong),
        ),
        const SizedBox(height: 12),
        CountUp(
          duration: const Duration(milliseconds: 1000),
          builder: (context, t) => Row(
            children: [
              for (final (i, item) in slots.indexed)
                Expanded(
                  child: Container(
                    height: 10,
                    margin: EdgeInsets.only(
                      right: i == slots.length - 1 ? 0 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: _color(item),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    // Các đoạn lần lượt đầy lên theo t.
                    foregroundDecoration: BoxDecoration(
                      color: Hue.lime.tint.withValues(
                        alpha: (1 - ((t * slots.length) - i).clamp(0.0, 1.0)),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OccurrenceRow extends StatelessWidget {
  const _OccurrenceRow({
    required this.item,
    required this.title,
    required this.onOpen,
  });
  final ReminderOccurrence item;
  final String title;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final overdue =
        item.status == OccurrenceStatus.pending &&
        !item.scheduledAtUtc.isAfter(DateTime.now().toUtc());
    final hue = switch (item.status) {
      OccurrenceStatus.completed => Hue.lime,
      OccurrenceStatus.pending => overdue ? Hue.melon : Hue.leaf,
      _ => Hue.leaf,
    };
    final label = switch (item.status) {
      OccurrenceStatus.completed => 'Đã hoàn thành',
      OccurrenceStatus.skipped => 'Đã bỏ qua',
      OccurrenceStatus.cancelled => 'Đã hủy',
      OccurrenceStatus.pending => overdue ? 'Quá hạn' : 'Sắp đến',
    };
    final muted =
        item.status == OccurrenceStatus.skipped ||
        item.status == OccurrenceStatus.cancelled;
    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HueBadge(
            icon: item.status == OccurrenceStatus.completed
                ? Icons.check_circle_outline
                : Icons.schedule_outlined,
            hue: muted
                ? const Hue(
                    strong: AppColors.muted,
                    line: AppColors.muted,
                    tint: AppColors.border,
                    glow: AppColors.border,
                  )
                : hue,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${displayTime(item.scheduledAtUtc)} · $title',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: muted ? AppColors.muted : hue.strong,
                  ),
                ),
                TextButton(onPressed: onOpen, child: const Text('Xem lịch')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
