import 'package:flutter/material.dart';

import '../domain/app_time.dart';
import 'app_theme.dart';
import 'motion.dart';

String displayDate(DateTime utc) {
  final w = vietnamWallTime(utc);
  return '${w.day.toString().padLeft(2, '0')}/${w.month.toString().padLeft(2, '0')}/${w.year}';
}

String displayTime(DateTime utc) {
  final w = vietnamWallTime(utc);
  return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
}

String displayNumber(num value) => value
    .toStringAsFixed(2)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

// Editable values must round-trip, including small numbers that Dart writes
// with an exponent but the decimal input parser deliberately does not accept.
String editNumber(num value) {
  final raw = value.toString().toLowerCase();
  if (!raw.contains('e')) return raw.replaceAll('.', ',');
  final parts = raw.split('e');
  final negative = parts.first.startsWith('-');
  final mantissa = negative ? parts.first.substring(1) : parts.first;
  final point =
      (mantissa.contains('.') ? mantissa.indexOf('.') : mantissa.length) +
      int.parse(parts.last);
  final digits = mantissa.replaceAll('.', '');
  final String decimal;
  if (point <= 0) {
    decimal = '0,${'0' * -point}$digits';
  } else if (point >= digits.length) {
    decimal = '$digits${'0' * (point - digits.length)}';
  } else {
    decimal = '${digits.substring(0, point)},${digits.substring(point)}';
  }
  return negative ? '-$decimal' : decimal;
}

void showFeedback(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> confirmRemoval(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Xóa',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Giữ lại'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    ) ??
    false;

/// Khung nội dung. Có [hue] thì nền tô nhạt theo màu dữ liệu; có [onTap]
/// thì nổi lên khi rê chuột và có hiệu ứng chạm.
class AppPanel extends StatefulWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.hue,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final Hue? hue;
  final VoidCallback? onTap;
  @override
  State<AppPanel> createState() => _AppPanelState();
}

class _AppPanelState extends State<AppPanel> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final hue = widget.hue;
    final interactive = widget.onTap != null;
    final lifted = _hover && interactive;
    final radius = BorderRadius.circular(22);
    final shadow = hue?.strong ?? AppColors.ink;
    final content = interactive
        ? Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.onTap,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          )
        : Padding(padding: widget.padding, child: widget.child);
    final box = AnimatedContainer(
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, lifted ? -3 : 0, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: hue?.tint ?? AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: hue == null
              ? AppColors.border
              : hue.glow.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: lifted ? 0.16 : 0.06),
            blurRadius: lifted ? 26 : 12,
            offset: Offset(0, lifted ? 12 : 4),
          ),
        ],
      ),
      child: content,
    );
    if (!interactive) return box;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: box,
    );
  }
}

/// Bọc nội dung trang: giới hạn bề rộng trên desktop, giữ cuộn toàn trang.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final side = c.maxWidth > 1120 ? (c.maxWidth - 1080) / 2 : 20.0;
      return ListView(
        padding: EdgeInsets.fromLTRB(side, 20, side, 40),
        children: children,
      );
    },
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Reveal(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: LayoutBuilder(
        builder: (context, c) => Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 16,
          spacing: 24,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: c.maxWidth > 720 ? c.maxWidth - 220 : c.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.insights_outlined,
    this.action,
    this.hue = Hue.leaf,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  final Hue hue;
  @override
  Widget build(BuildContext context) => AppPanel(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduceMotion(context) ? 1 : 0.4, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: HueBadge(icon: icon, hue: hue, size: 64),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    ),
  );
}

class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.text,
    this.error = false,
    this.action,
  });
  final String text;
  final bool error;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFDE8E6) : Hue.leaf.tint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          error ? Icons.error_outline : Icons.info_outline,
          size: 20,
          color: error ? AppColors.danger : Hue.leaf.strong,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: error ? AppColors.danger : AppColors.ink,
                ),
              ),
              ?action,
            ],
          ),
        ),
      ],
    ),
  );
}

/// Màn hình chờ lúc khởi động app.
class BootSplash extends StatelessWidget {
  const BootSplash({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CountUp(
            duration: const Duration(milliseconds: 700),
            builder: (context, t) => Transform.scale(
              scale: 0.7 + 0.3 * t,
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Hue.leaf.strong,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Hue.leaf.strong.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sức Khỏe Cá Nhân',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              minHeight: 4,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Biểu tượng tròn tô màu theo [hue].
class HueBadge extends StatelessWidget {
  const HueBadge({
    super.key,
    required this.icon,
    required this.hue,
    this.size = 40,
  });
  final IconData icon;
  final Hue hue;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: hue.glow.withValues(alpha: 0.28),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: size * 0.55, color: hue.strong),
  );
}

/// Viên thuốc nhỏ hiển thị một giá trị, tô màu theo [hue].
class HuePill extends StatelessWidget {
  const HuePill({super.key, required this.text, required this.hue});
  final String text;
  final Hue hue;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: hue.tint,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: hue.glow.withValues(alpha: 0.5)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: hue.strong,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}
