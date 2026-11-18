import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/db/settings_provider.dart';
import '../../../core/theme/pace_pastels.dart';
import '../../../core/theme/pace_tokens.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/undo_snack.dart';
import '../application/finance_providers.dart';
import '../domain/budget_summary.dart';
import '../domain/money.dart';

/// Spending in plain totals: this period, by category, and what is left
/// of the budget. Going over is said neutrally (CLAUDE.md rule 12).
class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  bool _showLists = false;

  Future<void> _addExpense() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ExpenseSheet(),
    );
  }

  Future<void> _editBudget(Budget? current, String code) async {
    final amount = TextEditingController(
      text: current == null ? '' : formatMoney(current.amountMinor),
    );
    var period = current?.period ?? BudgetPeriod.weekly;
    final result = await showDialog<(BudgetPeriod, int)?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<BudgetPeriod>(
                segments: const [
                  ButtonSegment(
                    value: BudgetPeriod.weekly,
                    label: Text('Week'),
                  ),
                  ButtonSegment(
                    value: BudgetPeriod.monthly,
                    label: Text('Month'),
                  ),
                ],
                selected: {period},
                onSelectionChanged: (s) => setState(() => period = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixText: code.isEmpty ? null : code,
                ),
              ),
            ],
          ),
          actions: [
            if (current != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop((period, 0)),
                child: const Text('No budget'),
              ),
            FilledButton(
              onPressed: () {
                final m = parseAmount(amount.text);
                if (m != null) Navigator.of(context).pop((period, m));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    if (result == null) return;
    await ref
        .read(appDatabaseProvider)
        .financeDao
        .setBudget(result.$2 == 0 ? null : result.$1, result.$2);
  }

  Future<void> _editCurrency(String current) async {
    final c = TextEditingController(text: current);
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency'),
        content: TextField(
          controller: c,
          textCapitalization: TextCapitalization.characters,
          maxLength: 3,
          decoration: const InputDecoration(
            labelText: 'Code, like PHP or USD (optional)',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    if (code == null) return;
    await ref
        .read(appDatabaseProvider)
        .settingsDao
        .updateSettings((s) => s.copyWith(currencyCode: code.toUpperCase()));
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(budgetSummaryProvider);
    final budget = ref.watch(budgetProvider).value;
    final expenses = ref.watch(expensesProvider).value ?? const <Expense>[];
    final code = ref.watch(settingsProvider).value?.currencyCode ?? '';
    final lowEnergy = ref.watch(lowEnergyProvider);
    final now = ref.watch(clockProvider)();
    String money(int m) => formatMoney(m, code);
    final theme = Theme.of(context);
    final pastels = PacePastels.of(context);
    final period = ref.watch(budgetPeriodProvider);
    final recent = [
      for (final e in expenses)
        if (!e.spentAt.toLocal().isBefore(summary.from)) e,
    ];
    final listsVisible = !lowEnergy || _showLists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money'),
        actions: [
          IconButton(
            tooltip: 'Currency',
            icon: const Icon(Icons.currency_exchange_rounded),
            onPressed: () => _editCurrency(code),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-expense'),
        onPressed: _addExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Spent'),
      ),
      body: ListView(
        padding: PaceSpace.screen,
        children: [
          Card(
            color: pastels.calm.fill,
            child: InkWell(
              onTap: () => _editBudget(budget, code),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period == Period.weekly ? 'This week' : 'This month',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      money(summary.spentMinor),
                      key: const ValueKey('spent-total'),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      describeBudget(summary, money),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (summary.budgetMinor != null &&
                        summary.budgetMinor! > 0) ...[
                      const SizedBox(height: 10),
                      // Fills up to the budget and stops; never turns red.
                      LinearProgressIndicator(
                        value: (summary.spentMinor / summary.budgetMinor!)
                            .clamp(0, 1)
                            .toDouble(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      budget == null ? 'Tap to set a budget' : 'Tap to change',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!listsVisible)
            TextButton(
              onPressed: () => setState(() => _showLists = true),
              child: const Text('Show categories and spending'),
            )
          else ...[
            if (summary.byCategory.isNotEmpty) ...[
              const SectionHeader('By category'),
              Card(
                child: Column(
                  children: [
                    for (final c in summary.byCategory)
                      ListTile(
                        title: Text(c.category),
                        trailing: Text(money(c.amountMinor)),
                      ),
                  ],
                ),
              ),
            ],
            const SectionHeader('Spent this period'),
            if (recent.isEmpty)
              const Card(child: ListTile(title: Text('Nothing logged yet')))
            else
              Card(
                child: Column(
                  children: [
                    for (final e in recent)
                      ListTile(
                        key: ValueKey('expense-${e.id}'),
                        title: Text(
                          e.note.isEmpty
                              ? e.category
                              : '${e.category} · ${e.note}',
                        ),
                        subtitle: Text(_when(e.spentAt.toLocal(), now)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(money(e.amountMinor)),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () async {
                                final dao = ref
                                    .read(appDatabaseProvider)
                                    .financeDao;
                                await dao.removeExpense(e.id);
                                if (!context.mounted) return;
                                showUndo(
                                  context,
                                  message:
                                      'Removed ${money(e.amountMinor)} · '
                                      '${e.category}.',
                                  onUndo: () => dao.restoreExpense(e.id),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _when(DateTime t, DateTime now) {
    final d = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${t.day}/${t.month}';
  }
}

class _ExpenseSheet extends ConsumerStatefulWidget {
  const _ExpenseSheet();

  @override
  ConsumerState<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<_ExpenseSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = expenseCategories.first;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(settingsProvider).value?.currencyCode ?? '';
    final minor = parseAmount(_amount.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('expense-amount'),
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: InputDecoration(
              labelText: 'How much',
              suffixText: code.isEmpty ? null : code,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in expenseCategories)
                ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('save-expense'),
            onPressed: minor == null
                ? null
                : () async {
                    await ref
                        .read(appDatabaseProvider)
                        .financeDao
                        .addExpense(
                          amountMinor: minor,
                          category: _category,
                          note: _note.text.trim(),
                          spentAt: ref.read(clockProvider)(),
                        );
                    if (context.mounted) Navigator.of(context).pop();
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
