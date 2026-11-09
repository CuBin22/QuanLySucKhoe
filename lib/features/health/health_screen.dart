import 'package:flutter/material.dart';

import '../../domain/app_time.dart';
import '../../ui/app_theme.dart';
import '../../ui/common.dart';
import '../../ui/metric_style.dart';
import '../../ui/motion.dart';
import 'health_record.dart';
import 'health_repository.dart';
import 'health_form.dart';
import 'health_chart.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({
    super.key,
    required this.repository,
    required this.onChanged,
    this.revision = 0,
  });
  final HealthRepository repository;
  final Future<void> Function() onChanged;
  final int revision;
  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int _days = 30, _visible = 50;
  HealthMetric _metric = HealthMetric.weight;
  DateTimeRange? _custom;
  late Future<List<HealthRecord>> _data;
  @override
  void initState() {
    super.initState();
    _query();
  }

  @override
  void didUpdateWidget(covariant HealthScreen old) {
    super.didUpdateWidget(old);
    if (old.revision != widget.revision) _query();
  }

  void _query() {
    final today = vietnamDayStart(DateTime.now().toUtc());
    final from = _custom == null
        ? today.subtract(Duration(days: _days - 1))
        : vietnamWallToUtc(_custom!.start);
    final to = _custom == null
        ? today.add(const Duration(days: 1))
        : vietnamWallToUtc(_custom!.end.add(const Duration(days: 1)));
    _data = widget.repository.list(fromUtc: from, toUtc: to);
  }

  Future<void> _edit([HealthRecord? initial]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            HealthForm(repository: widget.repository, initial: initial),
      ),
    );
    if (saved == true) {
      await widget.onChanged();
      if (mounted) {
        setState(_query);
        showFeedback(context, 'Đã lưu chỉ số.');
      }
    }
  }

  Future<void> _remove(HealthRecord record) async {
    if (!await confirmRemoval(
      context,
      title: 'Xóa bản ghi?',
      message:
          'Bản ghi ngày ${displayDate(record.measuredAtUtc)} sẽ bị xóa khỏi cơ sở dữ liệu trên máy chủ.',
    )) {
      return;
    }
    try {
      await widget.repository.delete(record.id!);
      await widget.onChanged();
      if (mounted) {
        setState(_query);
        showFeedback(context, 'Đã xóa bản ghi.');
      }
    } catch (_) {
      if (mounted) {
        showFeedback(context, 'Không xóa được bản ghi. Hãy thử lại.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageList(
    children: [
      PageHeader(
        title: 'Nhật ký chỉ số',
        subtitle: 'Nhìn lại những thay đổi qua từng lần đo.',
        action: FilledButton.icon(
          key: const ValueKey('add-health'),
          onPressed: _edit,
          icon: const Icon(Icons.add),
          label: const Text('Thêm chỉ số'),
        ),
      ),
      Reveal(
        index: 1,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in HealthMetric.values)
              Theme(
                data: themeWithHue(Theme.of(context), m.hue),
                child: ChoiceChip(
                  avatar: Icon(
                    m.icon,
                    size: 18,
                    color: _metric == m ? m.hue.strong : AppColors.muted,
                  ),
                  label: Text(m.label),
                  showCheckmark: false,
                  selected: _metric == m,
                  side: BorderSide(
                    color: _metric == m ? m.hue.glow : AppColors.border,
                    width: _metric == m ? 1.5 : 1,
                  ),
                  onSelected: (_) => setState(() => _metric = m),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Reveal(
        index: 2,
        child: AnimatedTheme(
          data: themeWithHue(Theme.of(context), _metric.hue),
          duration: reduceMotion(context)
              ? Duration.zero
              : const Duration(milliseconds: 350),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final d in [7, 30, 90])
                ChoiceChip(
                  label: Text('$d ngày'),
                  showCheckmark: false,
                  selected: _custom == null && _days == d,
                  onSelected: (_) => setState(() {
                    _days = d;
                    _custom = null;
                    _visible = 50;
                    _query();
                  }),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_outlined),
                label: const Text('Chọn ngày'),
                onPressed: () async {
                  final wall = vietnamWallTime(DateTime.now());
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(wall.year, wall.month, wall.day),
                  );
                  if (range != null && context.mounted && mounted) {
                    if (range.end.difference(range.start).inDays > 89) {
                      showFeedback(context, 'Chọn tối đa 90 ngày mỗi lần.');
                      return;
                    }
                    setState(() {
                      _custom = range;
                      _visible = 50;
                      _query();
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      FutureBuilder<List<HealthRecord>>(
        future: _data,
        builder: (context, s) {
          if (s.hasError) {
            return EmptyState(
              title: 'Chưa tải được chỉ số',
              message: 'Dữ liệu được giữ nguyên. Hãy thử lại.',
              action: OutlinedButton(
                onPressed: () => setState(_query),
                child: const Text('Thử lại'),
              ),
            );
          }
          if (!s.hasData) {
            return const Column(
              children: [
                Skeleton(height: 330),
                SizedBox(height: 12),
                SkeletonList(count: 2, height: 84),
              ],
            );
          }
          final rows = s.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Reveal(
                index: 3,
                child: HealthChart(records: rows, metric: _metric),
              ),
              const SizedBox(height: 28),
              Text(
                'Lịch sử · ${rows.length} bản ghi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Text('Chưa có bản ghi. Chọn “Thêm chỉ số” để bắt đầu.'),
              for (final (i, r) in rows.take(_visible).indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Reveal(
                    index: 4 + i,
                    child: AppPanel(
                      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${displayDate(r.measuredAtUtc)} · ${displayTime(r.measuredAtUtc)}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: AppColors.muted),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (r.weightKg != null)
                                      HuePill(
                                        text:
                                            '${displayNumber(r.weightKg!)} kg',
                                        hue: HealthMetric.weight.hue,
                                      ),
                                    if (r.systolic != null)
                                      HuePill(
                                        text:
                                            '${r.systolic}/${r.diastolic} mmHg',
                                        hue: HealthMetric.bloodPressure.hue,
                                      ),
                                    if (r.heartRate != null)
                                      HuePill(
                                        text: '${r.heartRate} nhịp/phút',
                                        hue: HealthMetric.heartRate.hue,
                                      ),
                                  ],
                                ),
                                if (r.note.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(r.note),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Thao tác bản ghi',
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (v) {
                              if (v == 'edit') {
                                _edit(r);
                              } else {
                                _remove(r);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Chỉnh sửa'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Xóa bản ghi'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (rows.length > _visible)
                OutlinedButton(
                  onPressed: () => setState(() => _visible += 50),
                  child: Text('Xem thêm · đã hiện $_visible/${rows.length}'),
                ),
            ],
          );
        },
      ),
    ],
  );
}
