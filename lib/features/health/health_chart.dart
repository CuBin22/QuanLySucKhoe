import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/common.dart';
import '../../ui/metric_style.dart';
import '../../ui/motion.dart';
import 'health_record.dart';

class HealthChart extends StatefulWidget {
  const HealthChart({super.key, required this.records, required this.metric});
  final List<HealthRecord> records;
  final HealthMetric metric;
  @override
  State<HealthChart> createState() => _HealthChartState();
}

class _HealthChartState extends State<HealthChart> {
  int? _active;

  @override
  void didUpdateWidget(covariant HealthChart old) {
    super.didUpdateWidget(old);
    if (old.metric != widget.metric || old.records != widget.records) {
      _active = null;
    }
  }

  void _pick(Offset local, _Geo geo) {
    var best = 0;
    var distance = double.infinity;
    for (var i = 0; i < geo.records.length; i++) {
      final d = (geo.x(i) - local.dx).abs();
      if (d < distance) {
        distance = d;
        best = i;
      }
    }
    if (best != _active) setState(() => _active = best);
  }

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    final hue = metric.hue;
    final values = widget.records.where(metric.has).toList()
      ..sort((a, b) => a.measuredAtUtc.compareTo(b.measuredAtUtc));
    if (values.isEmpty) {
      return EmptyState(
        title: 'Chưa có dữ liệu trong khoảng này',
        message: 'Thêm chỉ số hoặc chọn khoảng ngày khác.',
        hue: hue,
      );
    }
    final latest = values.last;
    final unit = metric.unit;
    final number = metric.number(latest);
    final replay = ValueKey(
      '${metric.name}-${values.length}-${values.first.measuredAtUtc.millisecondsSinceEpoch}-${values.last.measuredAtUtc.millisecondsSinceEpoch}',
    );
    final secondary = Hue.mango.line;
    return AppPanel(
      hue: hue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HueBadge(icon: metric.icon, hue: hue, size: 36),
              const SizedBox(width: 10),
              Text(
                'Giá trị gần nhất',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: hue.strong),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CountUp(
            key: replay,
            builder: (context, t) => Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: metric.number(latest, t),
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontSize: 36),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '${values.length} lần đo · ${displayDate(latest.measuredAtUtc)} ${displayTime(latest.measuredAtUtc)}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Semantics(
            label:
                'Biểu đồ $unit với ${values.length} lần đo. Giá trị gần nhất $number $unit. Chi tiết trong danh sách bên dưới.',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final geo = _Geo(Size(c.maxWidth, 200), values);
                    return MouseRegion(
                      onHover: (e) => _pick(e.localPosition, geo),
                      onExit: (_) => setState(() => _active = null),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => _pick(d.localPosition, geo),
                        onHorizontalDragUpdate: (d) =>
                            _pick(d.localPosition, geo),
                        child: CountUp(
                          key: replay,
                          duration: const Duration(milliseconds: 1200),
                          builder: (context, t) => CustomPaint(
                            painter: _ChartPainter(
                              geo: geo,
                              metric: metric,
                              primary: hue.line,
                              secondary: secondary,
                              progress: t,
                              active: _active,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(displayDate(values.first.measuredAtUtc)),
                Text(displayDate(values.last.measuredAtUtc)),
                if (metric == HealthMetric.bloodPressure)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(color: hue.line, filled: true),
                      const SizedBox(width: 6),
                      const Text('Tâm thu'),
                      const SizedBox(width: 14),
                      _Dot(color: secondary, filled: false),
                      const SizedBox(width: 6),
                      const Text('Tâm trương'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled});
  final Color color;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? color : Colors.white,
      border: Border.all(color: color, width: 2.5),
    ),
  );
}

class _Geo {
  _Geo(this.size, this.records)
    : area = Rect.fromLTWH(
        44,
        16,
        math.max(1, size.width - 58),
        size.height - 34,
      ),
      _start = records.first.measuredAtUtc.millisecondsSinceEpoch,
      _end = records.last.measuredAtUtc.millisecondsSinceEpoch;
  final Size size;
  final List<HealthRecord> records;
  final Rect area;
  final int _start, _end;
  double x(int i) => _end == _start
      ? area.center.dx
      : area.left +
            (records[i].measuredAtUtc.millisecondsSinceEpoch - _start) /
                (_end - _start) *
                area.width;
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.geo,
    required this.metric,
    required this.primary,
    required this.secondary,
    required this.progress,
    required this.active,
  });
  final _Geo geo;
  final HealthMetric metric;
  final Color primary, secondary;
  final double progress;
  final int? active;

  List<HealthRecord> get records => geo.records;

  @override
  void paint(Canvas canvas, Size size) {
    final a = [for (final r in records) metric.valueOf(r)];
    final b = metric == HealthMetric.bloodPressure
        ? [for (final r in records) r.diastolic!.toDouble()]
        : <double>[];
    final all = [...a, ...b];
    var low = all.reduce(math.min);
    var high = all.reduce(math.max);
    final padding = math.max((high - low) * 0.15, 1.0);
    low -= padding;
    high += padding;
    final area = geo.area;
    double yOf(double v) =>
        area.bottom - (v - low) / (high - low) * area.height;

    for (var i = 0; i < 3; i++) {
      final y = area.top + area.height * i / 2;
      canvas.drawLine(
        Offset(area.left, y),
        Offset(area.right, y),
        Paint()
          ..color = AppColors.border
          ..strokeWidth = 1,
      );
      final label = TextPainter(
        text: TextSpan(
          text: displayNumber(high - (high - low) * i / 2),
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 40);
      label.paint(canvas, Offset(0, y - 7));
    }

    final limit = area.left + area.width * progress.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, limit + 6, size.height));

    void series(List<double> values, Color color, {required bool filled}) {
      final pts = [
        for (var i = 0; i < values.length; i++)
          Offset(geo.x(i), yOf(values[i])),
      ];
      if (pts.length > 1) {
        final line = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts.skip(1)) {
          line.lineTo(p.dx, p.dy);
        }
        if (filled) {
          final fill = Path.from(line)
            ..lineTo(pts.last.dx, area.bottom)
            ..lineTo(pts.first.dx, area.bottom)
            ..close();
          canvas.drawPath(
            fill,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.28),
                  color.withValues(alpha: 0),
                ],
              ).createShader(area),
          );
        }
        canvas.drawPath(
          line,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
      for (final p in pts) {
        if (p.dx > limit) continue;
        if (filled) {
          canvas.drawCircle(p, 4, Paint()..color = color);
        } else {
          canvas.drawCircle(p, 4, Paint()..color = Colors.white);
          canvas.drawCircle(
            p,
            4,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        }
      }
    }

    if (b.isNotEmpty) series(b, secondary, filled: false);
    series(a, primary, filled: true);
    canvas.restore();

    final i = active;
    if (i != null && progress >= 0.999) {
      final x = geo.x(i);
      canvas.drawLine(
        Offset(x, area.top),
        Offset(x, area.bottom),
        Paint()
          ..color = primary.withValues(alpha: 0.45)
          ..strokeWidth = 1.5,
      );
      final p = Offset(x, yOf(a[i]));
      canvas.drawCircle(p, 8, Paint()..color = primary.withValues(alpha: 0.2));
      canvas.drawCircle(p, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 4, Paint()..color = primary);
      final r = records[i];
      final tip = TextPainter(
        text: TextSpan(
          text:
              '${metric.number(r)} ${metric.unit}\n${displayDate(r.measuredAtUtc)} ${displayTime(r.measuredAtUtc)}',
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final box = Size(tip.width + 20, tip.height + 14);
      final left = (x - box.width / 2).clamp(0.0, size.width - box.width);
      final top = math.max(0.0, p.dy - box.height - 14);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, box.width, box.height),
        const Radius.circular(10),
      );
      canvas.drawRRect(rect, Paint()..color = AppColors.ink);
      tip.paint(canvas, Offset(left + 10, top + 7));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.geo != geo ||
      old.metric != metric ||
      old.progress != progress ||
      old.active != active ||
      old.primary != primary;
}
