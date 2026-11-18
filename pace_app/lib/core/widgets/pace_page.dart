import 'package:flutter/material.dart';

import '../theme/pace_tokens.dart';

/// A screen in PACE's own shape: a quiet top bar (back and actions only)
/// and a large title that opens the scrolling content. Once the title has
/// scrolled away, a small copy fades into the bar so you still know where
/// you are.
class PacePage extends StatefulWidget {
  const PacePage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.floatingActionButton,
    this.padding = PaceSpace.screen,
  });

  final String title;
  final String? subtitle;

  /// Beside the title: Tuck or a pastel icon chip.
  final Widget? leading;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? floatingActionButton;
  final EdgeInsets padding;

  @override
  State<PacePage> createState() => _PacePageState();
}

class _PacePageState extends State<PacePage> {
  bool _titleAway = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final away = n.metrics.pixels > 56;
    if (away != _titleAway) setState(() => _titleAway = away);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: AnimatedOpacity(
          opacity: _titleAway ? 1 : 0,
          duration: PaceMotion.quick,
          child: Text(widget.title),
        ),
        actions: [...widget.actions, const SizedBox(width: 8)],
      ),
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        top: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: ListView(
            padding: widget.padding,
            children: [
              PacePageHeader(
                title: widget.title,
                subtitle: widget.subtitle,
                leading: widget.leading,
              ),
              ...widget.children,
            ],
          ),
        ),
      ),
    );
  }
}

/// The large title at the top of a screen's content.
class PacePageHeader extends StatelessWidget {
  const PacePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineMedium),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (leading != null) ...[const SizedBox(width: 12), leading!],
        ],
      ),
    );
  }
}
