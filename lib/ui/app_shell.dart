import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.pages, this.beforeChange});
  final List<Widget> pages;
  final Future<bool> Function(int from, int to)? beforeChange;
  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _selected = 0;
  bool _changing = false;
  late final AnimationController _page = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> select(int index) async {
    if (index == _selected || _changing) return;
    _changing = true;
    try {
      if (await widget.beforeChange?.call(_selected, index) ?? true) {
        if (!mounted) return;
        setState(() => _selected = index);
        if (!reduceMotion(context)) _page.forward(from: 0);
      }
    } finally {
      _changing = false;
    }
  }

  static const labels = ['Tổng quan', 'Chỉ số', 'Lịch chăm sóc', 'Hồ sơ'];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.monitor_heart_outlined,
    Icons.event_note_outlined,
    Icons.person_outline,
  ];
  static const selectedIcons = [
    Icons.space_dashboard,
    Icons.monitor_heart,
    Icons.event_note,
    Icons.person,
  ];

  /// Mỗi mục một màu trái cây: màu loang vào khung khi chuyển mục.
  static const hues = [Hue.leaf, Hue.dragon, Hue.lime, Hue.mango];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth >= 600;
      final extended = c.maxWidth >= 1050;
      final hue = hues[_selected];
      final quick = reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 450);
      return AnimatedTheme(
        data: themeWithHue(Theme.of(context), hue),
        duration: quick,
        curve: Curves.easeOutCubic,
        child: Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (wide) ...[
                  NavigationRail(
                    selectedIndex: _selected,
                    onDestinationSelected: select,
                    extended: extended,
                    minExtendedWidth: 220,
                    labelType: extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: _Brand(extended: extended),
                    ),
                    destinations: [
                      for (var i = 0; i < labels.length; i++)
                        NavigationRailDestination(
                          icon: Icon(icons[i]),
                          selectedIcon: Icon(selectedIcons[i]),
                          label: Text(labels[i], textAlign: TextAlign.center),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                ],
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 300,
                        child: IgnorePointer(
                          child: TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: hue.tint),
                            duration: quick,
                            curve: Curves.easeOutCubic,
                            builder: (context, color, _) => DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    color ?? hue.tint,
                                    AppColors.background.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _page,
                          child: IndexedStack(
                            index: _selected,
                            children: widget.pages,
                          ),
                          builder: (context, child) {
                            final t = Curves.easeOutExpo.transform(_page.value);
                            return Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - t)),
                                child: child,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _selected,
                  onDestinationSelected: select,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (var i = 0; i < labels.length; i++)
                      NavigationDestination(
                        icon: Icon(icons[i]),
                        selectedIcon: Icon(selectedIcons[i]),
                        label: labels[i],
                      ),
                  ],
                ),
        ),
      );
    },
  );
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended});
  final bool extended;
  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Hue.leaf.strong,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Hue.leaf.strong.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.health_and_safety, color: Colors.white, size: 26),
    );
    if (!extended) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        const Text(
          'Sổ sức khỏe',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ],
    );
  }
}
