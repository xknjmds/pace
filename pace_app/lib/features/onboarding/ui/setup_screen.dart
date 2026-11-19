import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_features.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/time/local_time.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/time_button.dart';
import '../../../core/widgets/tuck.dart';
import '../../../routes.dart';
import '../../routine/ui/routine_settings_screen.dart' show weekdayNames;
import '../application/setup_providers.dart';
import '../domain/setup_plan.dart';

/// First run: a few calm questions that set up the mornings. Every step
/// has a sensible default, and "Skip for now" is always there.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

enum _Step { hello, classes, travel, sleep, bodyClock, summary }

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _index = 0;
  bool _forward = true;
  bool _saving = false;

  Set<int> _classDays = {1, 2, 3, 4, 5};
  int _firstClass = 8 * 60;
  int _commute = 30;
  int _prep = 30;
  int _usualWake = 6 * 60 + 30;
  int _sleep = 8 * 60;
  Chronotype _chronotype = Chronotype.inBetween;

  static const _commuteChoices = [10, 20, 30, 45, 60];
  static const _prepChoices = [15, 20, 30, 45];
  static const _sleepChoices = [420, 450, 480, 510, 540];

  SetupAnswers get _answers => SetupAnswers(
    classDays: _classDays,
    firstClass: LocalTime(_firstClass),
    commuteMinutes: _commute,
    prepMinutes: _prep,
    usualWake: LocalTime(_usualWake),
    sleepTargetMinutes: _sleep,
    chronotype: _chronotype,
  );

  void _go(int to) => setState(() {
    _forward = to > _index;
    _index = to;
  });

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(setupServiceProvider).apply(planFromAnswers(_answers));
    if (!mounted) return;
    _leave();
  }

  Future<void> _skip() async {
    await ref.read(setupServiceProvider).skip();
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  /// Done: on Android, one more short stop to make reminders reliable.
  void _leave() {
    final nav = Navigator.of(context);
    if (ref.read(platformFeaturesProvider).reminders) {
      nav.pushReplacementNamed(Routes.notifications);
    } else {
      nav.maybePop();
    }
  }

  static String _hours(int m) =>
      m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60} min';

  Widget _chips<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
    String keyPrefix = 'choice',
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        ChoiceChip(
          key: ValueKey('$keyPrefix-$v'),
          label: Text(label(v)),
          selected: v == selected,
          onSelected: (_) => setState(() => onSelected(v)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _Step.values;
    final step = steps[_index];
    final isFirst = _index == 0;
    final isLast = _index == steps.length - 1;
    final muted = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.45,
    );

    final body = switch (step) {
      _Step.hello => [
        const SizedBox(height: 12),
        const Center(child: Tuck(size: 132)),
        const SizedBox(height: 24),
        Text(
          'Hi, I\'m Tuck.',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'A few quick questions and your mornings will be planned for you. '
          'It takes about a minute, and you can change anything later.',
          style: muted,
          textAlign: TextAlign.center,
        ),
      ],
      _Step.classes => [
        _StepTitle(Icons.school_rounded, 'Your school days', PastelKind.leave),
        const SizedBox(height: 8),
        Text('Which days do you have class?', style: muted),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in weekdayNames.entries)
              FilterChip(
                key: ValueKey('day-${entry.key}'),
                label: Text(entry.value.substring(0, 3)),
                tooltip: entry.value,
                selected: _classDays.contains(entry.key),
                onSelected: (on) => setState(() {
                  _classDays = {..._classDays};
                  on ? _classDays.add(entry.key) : _classDays.remove(entry.key);
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('When does your first class usually start?', style: muted),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TimeButton(
            key: const ValueKey('first-class'),
            minutes: _firstClass,
            onChanged: (m) => setState(() => _firstClass = m),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Different times on different days? Adjust each day later in '
          'Settings, or import a photo of your class schedule.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      _Step.travel => [
        _StepTitle(
          Icons.directions_walk_rounded,
          'Getting there',
          PastelKind.leave,
        ),
        const SizedBox(height: 8),
        Text('How long is the trip to school?', style: muted),
        const SizedBox(height: 12),
        _chips(
          values: _commuteChoices,
          selected: _commute,
          label: (m) => '$m min',
          onSelected: (m) => _commute = m,
          keyPrefix: 'commute',
        ),
        const SizedBox(height: 20),
        Text('And to get ready (wash, dress, pack)?', style: muted),
        const SizedBox(height: 12),
        _chips(
          values: _prepChoices,
          selected: _prep,
          label: (m) => '$m min',
          onSelected: (m) => _prep = m,
          keyPrefix: 'prep',
        ),
      ],
      _Step.sleep => [
        _StepTitle(Icons.bedtime_rounded, 'Sleep', PastelKind.evening),
        const SizedBox(height: 8),
        Text('When do you usually wake up now?', style: muted),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TimeButton(
            key: const ValueKey('usual-wake'),
            minutes: _usualWake,
            onChanged: (m) => setState(() => _usualWake = m),
          ),
        ),
        const SizedBox(height: 20),
        Text('How much sleep feels good for you?', style: muted),
        const SizedBox(height: 12),
        _chips(
          values: _sleepChoices,
          selected: _sleep,
          label: _hours,
          onSelected: (m) => _sleep = m,
          keyPrefix: 'sleep',
        ),
      ],
      _Step.bodyClock => [
        _StepTitle(
          Icons.wb_twilight_rounded,
          'Your body clock',
          PastelKind.morning,
        ),
        const SizedBox(height: 8),
        Text(
          'There\'s no wrong answer. It only changes how gently your '
          'mornings move.',
          style: muted,
        ),
        const SizedBox(height: 12),
        RadioGroup<Chronotype>(
          groupValue: _chronotype,
          onChanged: (v) => setState(() => _chronotype = v!),
          child: Column(
            children: [
              for (final (c, title, sub) in const [
                (Chronotype.morning, 'Morning person', 'Mornings come easy'),
                (Chronotype.inBetween, 'Somewhere in between', 'It depends'),
                (Chronotype.night, 'Night person', 'Mornings are hard'),
              ])
                RadioListTile<Chronotype>(
                  key: ValueKey('chronotype-${c.name}'),
                  value: c,
                  title: Text(title),
                  subtitle: Text(sub),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ],
      _Step.summary => _summary(theme, muted),
    };

    final motion = PaceMotion.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: isFirst ? null : Text('Set up $_index of ${steps.length - 1}'),
        actions: [
          if (!isLast)
            TextButton(
              key: const ValueKey('setup-skip'),
              onPressed: _skip,
              child: const Text('Skip for now'),
            ),
          const SizedBox(width: 8),
        ],
        bottom: isFirst
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      for (var i = 1; i < steps.length; i++) ...[
                        if (i > 1) const SizedBox(width: 6),
                        Expanded(
                          child: AnimatedContainer(
                            duration: PaceMotion.standard,
                            curve: PaceMotion.easeOut,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= _index
                                  ? scheme.secondary
                                  : scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: PaceMotion.emphasized,
                switchInCurve: PaceMotion.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, a) {
                  final incoming = child.key == ValueKey(step);
                  final dx = motion.offset(.06) * (_forward ? 1 : -1);
                  return FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(incoming ? dx : -dx, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  );
                },
                child: ListView(
                  key: ValueKey(step),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  children: body,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  if (!isFirst)
                    TextButton(
                      onPressed: _saving ? null : () => _go(_index - 1),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  PressScale(
                    child: FilledButton.icon(
                      key: const ValueKey('setup-next'),
                      onPressed: _saving
                          ? null
                          : isLast
                          ? _finish
                          : () => _go(_index + 1),
                      icon: Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      iconAlignment: IconAlignment.end,
                      label: Text(
                        isFirst
                            ? 'Let\'s start'
                            : isLast
                            ? 'Looks good'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _summary(ThemeData theme, TextStyle? muted) {
    final plan = planFromAnswers(_answers);
    final wakeLine = switch (plan.wake) {
      WakeNow(:final minutes) => 'Wake up at ${LocalTime(minutes).format24()}.',
      WakeGradually(:final fromMinutes, :final goalMinutes, :final everyDays) =>
        'Start waking at ${LocalTime(fromMinutes).format24()}, then a little '
            'earlier every $everyDays days until '
            '${LocalTime(goalMinutes).format24()}. No sudden changes.',
    };
    final leave = plan.leaveBy;
    return [
      _StepTitle(Icons.check_circle_rounded, 'Your plan', PastelKind.calm),
      const SizedBox(height: 12),
      Text(
        wakeLine,
        key: const ValueKey('summary-wake'),
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 8),
      if (leave != null)
        Text(
          'Leave by ${leave.format24()} on school days.',
          key: const ValueKey('summary-leave'),
          style: theme.textTheme.bodyLarge,
        )
      else if (_classDays.isEmpty)
        Text('No school days for now.', style: theme.textTheme.bodyLarge)
      else
        Text(
          'That morning is very tight. You can adjust it in Settings.',
          style: theme.textTheme.bodyLarge,
        ),
      const SizedBox(height: 8),
      Text(
        'About ${_hours(plan.sleepTargetMinutes)} of sleep, '
        'with a little extra on weekends.',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 16),
      Text(
        'I\'ll remind you when it\'s time. Missing a day is fine; '
        'we just pick up again.',
        style: muted,
      ),
    ];
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.icon, this.text, this.kind);

  final IconData icon;
  final String text;
  final PastelKind kind;

  @override
  Widget build(BuildContext context) {
    final pastel = PacePastels.of(context).forKind(kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pastel.fill,
              borderRadius: BorderRadius.circular(PaceRadius.s),
            ),
            child: Icon(icon, color: pastel.ink),
          ),
          const SizedBox(height: 14),
          Text(text, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
