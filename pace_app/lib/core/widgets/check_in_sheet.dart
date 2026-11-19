import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../check_in/check_in_outcome.dart';
import '../check_in/check_in_rules.dart';
import '../theme/pace_tokens.dart';
import '../time/local_time.dart';
import 'press_scale.dart';
import 'time_button.dart';

/// What the check-in sheet is about: a routine step or a deadline. Only the
/// words change.
enum CheckInSubject { routine, deadline }

/// What the owner said in the sheet.
sealed class CheckInSheetResult {
  const CheckInSheetResult();
}

/// Saved: how it went, when (null for "didn't happen") and an optional note.
class CheckInSaved extends CheckInSheetResult {
  const CheckInSaved({required this.outcome, this.at, this.reason});

  final CheckInOutcome outcome;
  final DateTime? at;
  final String? reason;
}

/// "Start over": the existing check-in is removed.
class CheckInCleared extends CheckInSheetResult {
  const CheckInCleared();
}

/// A previous check-in, to edit.
typedef CheckInInitial = ({
  CheckInOutcome outcome,
  DateTime? at,
  String? reason,
});

/// Asks how a step or deadline went: on time, a bit later (at a picked
/// time), or didn't happen, with an optional short note. Calm words only;
/// nothing here is a failure state.
///
/// [planned] (when known) preselects "a bit later" once now is past it by
/// more than [graceMinutes]. With [initial], the sheet edits that check-in
/// and offers "Start over".
Future<CheckInSheetResult?> showCheckInSheet(
  BuildContext context, {
  required String title,
  required CheckInSubject subject,
  required DateTime now,
  LocalTime? planned,
  DateTime? dueAt,
  int graceMinutes = 20,
  CheckInInitial? initial,
  bool lowEnergy = false,
}) => showModalBottomSheet<CheckInSheetResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => CheckInSheet(
    title: title,
    subject: subject,
    now: now,
    planned: planned,
    dueAt: dueAt,
    graceMinutes: graceMinutes,
    initial: initial,
    lowEnergy: lowEnergy,
  ),
);

class CheckInSheet extends StatefulWidget {
  const CheckInSheet({
    super.key,
    required this.title,
    required this.subject,
    required this.now,
    this.planned,
    this.dueAt,
    this.graceMinutes = 20,
    this.initial,
    this.lowEnergy = false,
  });

  final String title;
  final CheckInSubject subject;
  final DateTime now;
  final LocalTime? planned;
  final DateTime? dueAt;
  final int graceMinutes;
  final CheckInInitial? initial;
  final bool lowEnergy;

  static const maxReasonLength = 80;

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  late CheckInOutcome _outcome = widget.initial?.outcome ?? _suggested();
  late LocalTime _at = LocalTime.of(
    (widget.initial?.at ?? widget.now).toLocal().hour,
    (widget.initial?.at ?? widget.now).toLocal().minute,
  );
  late final _reason = TextEditingController(text: widget.initial?.reason);
  late bool _noteOpen = !widget.lowEnergy || (widget.initial?.reason != null);

  bool get _deadline => widget.subject == CheckInSubject.deadline;

  CheckInOutcome _suggested() {
    final due = widget.dueAt;
    if (due != null) {
      return widget.now.isAfter(due)
          ? CheckInOutcome.later
          : CheckInOutcome.onTime;
    }
    return suggestOutcome(
      planned: widget.planned,
      actual: LocalTime.of(widget.now.hour, widget.now.minute),
      graceMinutes: widget.graceMinutes,
    );
  }

  List<String> get _quickReasons => _deadline
      ? const ['Ran out of time', 'Portal trouble', 'Not feeling well']
      : const ['Overslept', 'Traffic', 'Not feeling well', 'Plans changed'];

  String _label(CheckInOutcome o) => switch ((o, _deadline)) {
    (CheckInOutcome.onTime, false) => 'Done on time',
    (CheckInOutcome.later, false) => 'Done, a bit later',
    (CheckInOutcome.didntHappen, false) => 'Didn\'t happen today',
    (CheckInOutcome.onTime, true) => 'Submitted',
    (CheckInOutcome.later, true) => 'Submitted after the due time',
    (CheckInOutcome.didntHappen, true) => 'Couldn\'t submit, let it go',
  };

  IconData _icon(CheckInOutcome o) => switch (o) {
    CheckInOutcome.onTime => Icons.check_circle_outline_rounded,
    CheckInOutcome.later => Icons.schedule_rounded,
    CheckInOutcome.didntHappen => Icons.cloud_outlined,
  };

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    final reason = _reason.text.trim();
    Navigator.of(context).pop(
      CheckInSaved(
        outcome: _outcome,
        at: switch (_outcome) {
          CheckInOutcome.onTime => widget.now,
          CheckInOutcome.later => resolvePickedTime(widget.now, _at),
          CheckInOutcome.didntHappen => null,
        },
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = PaceMotion.of(context);
    final grow = motion.reduced ? Duration.zero : PaceMotion.standard;
    final subtitle = widget.dueAt != null
        ? 'Due ${LocalTime.of(widget.dueAt!.toLocal().hour, widget.dueAt!.toLocal().minute).format24()}'
        : widget.planned != null
        ? 'Planned for ${widget.planned!.format24()}'
        : null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (final o in CheckInOutcome.values) ...[
                _OutcomeOption(
                  key: ValueKey('check-in-${o.name}'),
                  icon: _icon(o),
                  label: _label(o),
                  selected: _outcome == o,
                  onTap: () => setState(() => _outcome = o),
                ),
                const SizedBox(height: 8),
              ],
              AnimatedSize(
                duration: grow,
                curve: PaceMotion.easeOut,
                alignment: Alignment.topCenter,
                child: _outcome == CheckInOutcome.later
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _deadline ? 'Submitted at' : 'Done at',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            TimeButton(
                              key: const ValueKey('check-in-time'),
                              minutes: _at.minutesSinceMidnight,
                              onChanged: (m) =>
                                  setState(() => _at = LocalTime(m)),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 4),
              AnimatedSize(
                duration: grow,
                curve: PaceMotion.easeOut,
                alignment: Alignment.topCenter,
                child: _noteOpen
                    ? _note(theme)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _noteOpen = true),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Add a note'),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              PressScale(
                child: FilledButton(
                  key: const ValueKey('check-in-save'),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
              if (widget.initial != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  key: const ValueKey('check-in-clear'),
                  onPressed: () =>
                      Navigator.of(context).pop(const CheckInCleared()),
                  child: Text(_deadline ? 'Reopen it' : 'Start this step over'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _note(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final r in _quickReasons)
            FilterChip(
              label: Text(r),
              selected: _reason.text.trim() == r,
              onSelected: (on) => setState(() {
                _reason.text = on ? r : '';
              }),
            ),
        ],
      ),
      const SizedBox(height: 10),
      TextField(
        key: const ValueKey('check-in-reason'),
        controller: _reason,
        maxLength: CheckInSheet.maxReasonLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Anything to note? (optional)',
          counterText: '',
        ),
        onChanged: (_) => setState(() {}),
      ),
    ],
  );
}

/// One choice in the sheet. The chosen one fills and carries a check, so
/// it is never marked by colour alone.
class _OutcomeOption extends StatelessWidget {
  const _OutcomeOption({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return PressScale(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(PaceRadius.m),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(icon, color: fg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(color: fg),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: PaceMotion.press,
                      child: selected
                          ? Icon(
                              Icons.check_rounded,
                              key: const ValueKey('on'),
                              color: fg,
                            )
                          : const SizedBox(key: ValueKey('off'), width: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
