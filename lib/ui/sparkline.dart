import 'package:flutter/material.dart';

import 'motion.dart';

/// Đường xu hướng nhỏ, vẽ dần từ trái sang phải khi hiện ra.
/// [values] theo thứ tự thời gian cũ -> mới.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 44,
  });
  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CountUp(
        duration: const Duration(milliseconds: 1100),
        builder: (context, t) =>
            CustomPaint(painter: _SparkPainter(values, color, t)),
      ),
    ),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color, this.t);
  final List<double> values;
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final span = (high - low) == 0 ? 1.0 : (high - low);
    const pad = 5.0;
    final w = size.width - pad * 2, h = size.height - pad * 2;
    Offset at(int i) => Offset(
      values.length == 1 ? size.width / 2 : pad + w * i / (values.length - 1),
      pad + h - (values[i] - low) / span * h,
    );
    final limit = pad + w * t.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, limit + 4, size.height));
    if (values.length > 1) {
      final line = Path()..moveTo(at(0).dx, at(0).dy);
      for (var i = 1; i < values.length; i++) {
        line.lineTo(at(i).dx, at(i).dy);
      }
      final fill = Path.from(line)
        ..lineTo(at(values.length - 1).dx, size.height)
        ..lineTo(at(0).dx, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final last = at(values.length - 1);
    if (last.dx <= limit + 1) {
      canvas.drawCircle(last, 5, Paint()..color = Colors.white);
      canvas.drawCircle(last, 3.5, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.t != t || old.color != color || old.values != values;
}
