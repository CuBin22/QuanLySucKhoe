import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Người dùng bật "giảm chuyển động" trong hệ thống: bỏ hiệu ứng, hiện ngay.
bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Hiện dần và trượt nhẹ lên khi xuất hiện. [index] tạo độ trễ lần lượt.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final CurvedAnimation _t;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = 55 * widget.index.clamp(0, 8);
    const base = 520;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: base + delay),
    );
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay / (base + delay), 1, curve: Curves.easeOutExpo),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _t.value.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - _t.value)),
        child: child,
      ),
    ),
  );
}

/// Chạy t từ 0 đến 1 một lần khi hiện ra (đếm số, vẽ biểu đồ...).
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
  });
  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;
  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return builder(context, 1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, t, _) => builder(context, t),
    );
  }
}

/// Khung xương nhấp nháy nhẹ khi đang tải.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 96, this.radius = 22});
  final double height, radius;
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!reduceMotion(context)) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đang tải',
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            Hue.leaf.tint,
            AppColors.border,
            0.35 + 0.5 * _c.value,
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    ),
  );
}

/// Danh sách khung xương cho trạng thái đang tải của một trang.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3, this.height = 96});
  final int count;
  final double height;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < count; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : 12),
          child: Skeleton(height: height),
        ),
    ],
  );
}
