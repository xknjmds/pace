import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/pace_tokens.dart';
import '../../core/widgets/tuck.dart';
import '../../core/widgets/pace_wordmark.dart';
import '../../core/widgets/readable_width.dart';
import '../deadlines/ui/deadlines_screen.dart';
import '../focus/ui/focus_screen.dart';
import '../inbox/ui/inbox_screen.dart';
import '../today/ui/today_screen.dart';
import 'shell_tabs.dart';

/// Home: Today, Deadlines, Inbox and Focus one tap apart. A bottom bar on
/// phones, a side rail on wide windows. Tabs are built the first time
/// they are shown and then kept, so typed text and scroll stay put.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({
    super.key,
    this.initialTab = ShellTab.today,
    this.startCapturing = false,
  });

  final ShellTab initialTab;

  /// Opened from the widget's "Write it down": Inbox with the field focused.
  final bool startCapturing;

  /// Shows [tab] from inside the shell. Returns false when no shell is
  /// mounted (a screen pumped on its own), so callers can push instead.
  static bool open(
    BuildContext context,
    ShellTab tab, {
    bool capture = false,
    String? taskId,
  }) {
    final state = context.findAncestorStateOfType<_HomeShellState>();
    if (state == null) return false;
    state.ref
        .read(shellRequestProvider.notifier)
        .open(tab, capture: capture, taskId: taskId);
    return true;
  }

  static const wide = 840.0;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin {
  late ShellTab _tab = widget.initialTab;
  late final Set<ShellTab> _built = {_tab};
  late final _fade = AnimationController(
    vsync: this,
    duration: PaceMotion.quick,
    value: 1,
  );

  static const _destinations = [
    (Icons.wb_sunny_outlined, Icons.wb_sunny_rounded, 'Today'),
    (Icons.event_note_outlined, Icons.event_note_rounded, 'Deadlines'),
    (Icons.inbox_outlined, Icons.inbox_rounded, 'Inbox'),
    (Icons.timer_outlined, Icons.timer_rounded, 'Focus'),
  ];

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _select(ShellTab tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tab = tab;
      _built.add(tab);
    });
    // A short fade so the swap reads as a change of place, not a glitch.
    _fade.forward(from: .35);
  }

  Widget _screen(ShellTab tab) => switch (tab) {
    ShellTab.today => const TodayScreen(),
    ShellTab.deadlines => const DeadlinesScreen(),
    ShellTab.inbox => InboxScreen(startCapturing: _captureOnBuild),
    ShellTab.focus => const FocusScreen(),
  };

  /// The Inbox's first build focuses the field when that is why we came.
  bool get _captureOnBuild =>
      widget.startCapturing ||
      (ref.read(shellRequestProvider)?.capture ?? false);

  @override
  Widget build(BuildContext context) {
    ref.listen(shellRequestProvider, (_, next) {
      if (next != null) _select(next.tab);
    });
    final wide = MediaQuery.sizeOf(context).width >= HomeShell.wide;
    final stack = FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: PaceMotion.easeOut),
      child: IndexedStack(
        index: _tab.index,
        children: [
          for (final tab in ShellTab.values)
            _built.contains(tab)
                ? KeyedSubtree(
                    key: ValueKey(tab),
                    child: ReadableWidth(child: _screen(tab)),
                  )
                : const SizedBox.shrink(),
        ],
      ),
    );

    final body = wide
        ? Row(
            children: [
              _Rail(selected: _tab, onSelect: _select),
              const VerticalDivider(width: 1),
              Expanded(child: stack),
            ],
          )
        : stack;

    return PopScope(
      canPop: _tab == ShellTab.today,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(ShellTab.today);
      },
      child: Scaffold(
        body: body,
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _tab.index,
                onDestinationSelected: (i) => _select(ShellTab.values[i]),
                destinations: [
                  for (final (icon, selected, label) in _destinations)
                    NavigationDestination(
                      icon: Icon(icon),
                      selectedIcon: Icon(selected),
                      label: label,
                    ),
                ],
              ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.selected, required this.onSelect});

  final ShellTab selected;
  final ValueChanged<ShellTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NavigationRail(
      backgroundColor: scheme.surfaceContainerLow,
      selectedIndex: selected.index,
      onDestinationSelected: (i) => onSelect(ShellTab.values[i]),
      labelType: NavigationRailLabelType.all,
      indicatorColor: scheme.primaryContainer,
      minWidth: 96,
      leading: const Padding(
        padding: EdgeInsets.fromLTRB(0, 20, 0, 28),
        child: Column(
          children: [
            TuckMark(size: 44),
            SizedBox(height: 10),
            PaceWordmark(height: 11),
          ],
        ),
      ),
      destinations: [
        for (final (icon, sel, label) in _HomeShellState._destinations)
          NavigationRailDestination(
            icon: Icon(icon),
            selectedIcon: Icon(sel),
            label: Text(label),
          ),
      ],
    );
  }
}
