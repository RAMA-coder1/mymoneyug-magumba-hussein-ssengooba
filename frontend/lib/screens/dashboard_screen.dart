import 'package:flutter/material.dart';
import '../lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../widgets/async_view.dart';
import '../widgets/format.dart';
import '../widgets/theme.dart';
import '../widgets/transaction_tile.dart';
import 'monthly_summary_screen.dart';
import 'transaction_form_screen.dart';

class _DashData {
  final DashboardSummary summary;
  final List<MoneyTransaction> transactions;
  final Map<int, Category> categories;
  final Map<int, Account> accounts;
  _DashData(this.summary, this.transactions, this.categories, this.accounts);
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback onSeeAll;
  const DashboardScreen({super.key, required this.onSeeAll});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tick = 0;

  Future<_DashData> _load(Services s) async {
    final r = await Future.wait([
      s.dashboard.summary(),
      s.transactions.list(),
      s.categories.list(),
      s.accounts.list(),
    ]);
    return _DashData(
      r[0] as DashboardSummary,
      r[1] as List<MoneyTransaction>,
      {for (final c in r[2] as List<Category>) c.id: c},
      {for (final a in r[3] as List<Account>) a.id: a},
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return AsyncView<_DashData>(
      key: ValueKey(_tick),
      load: () => _load(services),
      builder: (context, d, reload) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final saved = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
            );
            if (saved == true) setState(() => _tick++);
          },
          icon: const Icon(LucideIcons.plus),
          label: const Text('Add transaction'),
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() => _tick++),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _BalanceCard(summary: d.summary),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _StatCard(
                        label: 'Income',
                        value: d.summary.totalIncome,
                        color: AppColors.income,
                        icon: LucideIcons.arrowDown)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Expenses',
                        value: d.summary.totalExpenses,
                        color: AppColors.expense,
                        icon: LucideIcons.arrowUp)),
              ]),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlySummaryScreen()),
                ),
                icon: const Icon(LucideIcons.calendarDays),
                label: const Text('Monthly summary'),
              ),
              const SizedBox(height: 24),
              Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (d.accounts.isEmpty)
                const Text('No accounts yet. Add one from the Accounts tab.')
              else
                SizedBox(
                  height: 84,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final a in d.accounts.values)
                        Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.paleBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Account.iconFor(a.accountType),
                                  color: AppColors.text),
                              const SizedBox(height: 6),
                              Text(a.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(Account.typeLabel(a.accountType),
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              _SpendingByCategory(
                  transactions: d.transactions, categories: d.categories),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text('Recent transactions',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton(onPressed: widget.onSeeAll, child: const Text('See all')),
                ],
              ),
              if (d.transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: EmptyState(
                      icon: LucideIcons.receipt,
                      message:
                          'No transactions yet.\nTap “Add transaction” to record your first one.'),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (final t in d.transactions.take(5))
                        TransactionTile(
                          txn: t,
                          categoryName: d.categories[t.categoryId]?.name ?? '—',
                          accountName: d.accounts[t.accountId]?.name ?? '—',
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final DashboardSummary summary;
  const _BalanceCard({required this.summary});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total balance',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              ugx(summary.totalBalance),
              style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Based on the transactions you have recorded',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label),
              ]),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(ugx(value),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
            ],
          ),
        ),
      );
}

/// ST-10: spending in UGX by category (e.g. transport, food, data bundles).
class _SpendingByCategory extends StatelessWidget {
  final List<MoneyTransaction> transactions;
  final Map<int, Category> categories;
  const _SpendingByCategory(
      {required this.transactions, required this.categories});

  @override
  Widget build(BuildContext context) {
    final totals = <int, double>{};
    for (final t in transactions.where((t) => t.isExpense)) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
    final rows = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = rows.isEmpty ? 1.0 : rows.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spending by category',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Text('No expenses recorded yet.')
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (final e in rows.take(6))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(categories[e.key]?.name ?? '—'),
                              Text(ugx(e.value)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: e.value / max,
                              minHeight: 8,
                               color: AppColors.primary,
                              backgroundColor: AppColors.paleBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
