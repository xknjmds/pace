import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/first_visit_hint.dart';
import '../../../core/platform/platform_features.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/widgets/pace_page.dart';
import '../../../core/widgets/pace_tile.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/section_header.dart';
import '../../../routes.dart';
import '../../blocking/application/gate_providers.dart';
import '../../finance/application/finance_providers.dart';
import '../../finance/domain/money.dart';
import '../../journey/application/journey_providers.dart';
import '../../rewards/application/rewards_providers.dart';
import '../../notes/application/notes_providers.dart';
import '../../onboarding/application/getting_started_providers.dart';
import '../../onboarding/domain/getting_started.dart';
import '../../shell/home_shell.dart';
import '../../shell/shell_tabs.dart';
import '../../review/application/review_providers.dart';
import '../../schedule/application/schedule_providers.dart';

/// Everything beyond the four daily tabs, as soft tiles that each say one
/// useful thing at a glance. Screens this device cannot use are left out.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(platformFeaturesProvider);
    final routineDays = ref.watch(weeklySummaryProvider).routineDays;
    final classes = ref.watch(classBlocksProvider).value?.length ?? 0;
    final notes = ref.watch(notesSearchProvider('')).value?.length ?? 0;
    final spent = ref.watch(budgetSummaryProvider).spentMinor;
    final code = ref.watch(settingsProvider).value?.currencyCode ?? '';
    final paused = features.appBlocking
        ? ref.watch(blockedAppsProvider).value?.length ?? 0
        : 0;

    final journeyDays = ref.watch(journeyProvider).value?.daysDone ?? 0;
    final ready = (ref.watch(rewardsProvider).value ?? const [])
        .where((v) => v.progress.earned && !v.progress.claimed)
        .length;

    String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

    final settings = ref.watch(settingsProvider).value;
    // Hidden by hand but otherwise still due: offer it back.
    final canReopenGuide =
        settings?.gettingStartedClosedAt != null &&
        showGettingStarted(
          onboardedAt: settings!.onboardedAt,
          closedAt: null,
          now: ref.watch(clockProvider)(),
          steps: ref.watch(gettingStartedStepsProvider),
          lowEnergy: ref.watch(lowEnergyProvider),
        );

    _Hub review() => _Hub(
      icon: Icons.insights_rounded,
      kind: PastelKind.morning,
      title: 'Review',
      status: routineDays == 0
          ? 'How your week went'
          : 'Routine done on ${count(routineDays, 'day', 'days')}',
      route: Routes.review,
    );

    final groups = <(String, List<_Hub>)>[
      (
        'Your week',
        [
          review(),
          _Hub(
            icon: Icons.school_rounded,
            kind: PastelKind.leave,
            title: 'Classes',
            status: classes == 0
                ? 'Add your timetable'
                : '${count(classes, 'class', 'classes')} a week',
            route: Routes.schedule,
          ),
          if (features.appBlocking)
            _Hub(
              icon: Icons.do_not_disturb_on_rounded,
              kind: PastelKind.evening,
              title: 'App gate',
              status: paused == 0
                  ? 'Pause distracting apps at set times'
                  : '${count(paused, 'app', 'apps')} paused',
              route: Routes.gate,
            ),
          if (features.calendarSync)
            const _Hub(
              icon: Icons.event_rounded,
              kind: PastelKind.focus,
              title: 'Calendar',
              status: 'Google, read-only',
              route: Routes.calendar,
            ),
        ],
      ),
      (
        'Keep track',
        [
          _Hub(
            icon: Icons.sticky_note_2_rounded,
            kind: PastelKind.deadline,
            title: 'Notes',
            status: notes == 0
                ? 'Write anything down'
                : count(notes, 'note', 'notes'),
            route: Routes.notes,
          ),
          _Hub(
            icon: Icons.account_balance_wallet_rounded,
            kind: PastelKind.calm,
            title: 'Money',
            status: spent == 0
                ? 'Spending and a budget'
                : '${formatMoney(spent, code)} this period',
            route: Routes.money,
          ),
        ],
      ),
      (
        'Keep going',
        [
          _Hub(
            icon: Icons.route_rounded,
            kind: PastelKind.leave,
            title: 'Journey',
            status: journeyDays == 0
                ? 'Tuck walks a step for each day done'
                : '${count(journeyDays, 'day', 'days')} along',
            route: Routes.journey,
          ),
          _Hub(
            icon: Icons.redeem_rounded,
            kind: PastelKind.morning,
            title: 'Rewards',
            status: ready == 0
                ? 'Treats you promise yourself'
                : '$ready ready to enjoy',
            route: Routes.rewards,
          ),
        ],
      ),
    ];

    return PacePage(
      title: 'More',
      subtitle: 'Everything else, one tap away.',
      children: [
        const FirstVisitHint(
          id: HintIds.more,
          text:
              'Everything else lives here, in three groups. Each tile says '
              'what it is for.',
        ),
        for (final (i, (header, tiles)) in groups.indexed) ...[
          if (i > 0) const SizedBox(height: PaceSpace.s),
          SectionHeader(header),
          LayoutBuilder(
            builder: (context, box) {
              const gap = PaceSpace.m;
              final columns = box.maxWidth >= 560 ? 3 : 2;
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final t in tiles) SizedBox(width: width, child: t),
                ],
              );
            },
          ),
        ],
        const SectionHeader('App'),
        PaceGroup(
          children: [
            if (canReopenGuide)
              PaceTile(
                key: const ValueKey('more-getting-started'),
                icon: Icons.flag_rounded,
                title: 'Getting started',
                subtitle: 'Show the first steps on Today again',
                chevron: true,
                onTap: () async {
                  await ref
                      .read(appDatabaseProvider)
                      .settingsDao
                      .setGettingStartedClosed(false);
                  if (context.mounted) HomeShell.open(context, ShellTab.today);
                },
              ),
            PaceTile(
              key: const ValueKey('more-settings'),
              icon: Icons.tune_rounded,
              title: 'Settings',
              subtitle: 'Your week, mornings and evenings',
              chevron: true,
              onTap: () => Navigator.of(context).pushNamed(Routes.settings),
            ),
            PaceTile(
              key: const ValueKey('more-support'),
              icon: Icons.favorite_outline_rounded,
              kind: PastelKind.evening,
              title: 'If you\'re struggling',
              subtitle: 'Kind words and people to call',
              chevron: true,
              onTap: () => Navigator.of(context).pushNamed(Routes.support),
            ),
            if (features.reminders)
              PaceTile(
                key: const ValueKey('more-reminders'),
                icon: Icons.notifications_none_rounded,
                title: 'Reminders',
                subtitle: 'Permissions and a test reminder',
                chevron: true,
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.notifications),
              ),
          ],
        ),
      ],
    );
  }
}

/// One soft hub tile: a pastel chip, the name and a one-line status.
class _Hub extends StatelessWidget {
  const _Hub({
    required this.icon,
    required this.kind,
    required this.title,
    required this.status,
    required this.route,
  });

  final IconData icon;
  final PastelKind kind;
  final String title;
  final String status;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pastel = PacePastels.of(context).forKind(kind);
    return MergeSemantics(
      child: PressScale(
        child: Material(
          key: ValueKey('hub-$route'),
          color: pastel.fill,
          borderRadius: PaceRadius.cardAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed(route),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 128),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // White chip on the pastel tile, icon in the tile's ink.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest
                            .withValues(alpha: .75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(icon, size: 22, color: pastel.ink),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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
