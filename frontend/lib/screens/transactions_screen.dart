import 'package:flutter/material.dart';
import '../lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/services.dart';
import '../widgets/async_view.dart';
import '../widgets/format.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';

/// Everything this screen needs, fetched together.
class _TxData {
  final List<MoneyTransaction> transactions;
  final Map<int, Category> categories;
  final Map<int, Account> accounts;
  _TxData(this.transactions, this.categories, this.accounts);
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // The API has no filtering, so filters live here and are applied in the app.
  String? _type; // null = all, otherwise 'income' / 'expense'
  int? _accountId;
  int? _categoryId;
  DateTimeRange? _range;
  int _tick = 0;

  bool get _hasFilter =>
      _type != null || _accountId != null || _categoryId != null || _range != null;

  Future<_TxData> _load(Services s) async {
    final r = await Future.wait([
      s.transactions.list(),
      s.categories.list(),
      s.accounts.list(),
    ]);
    return _TxData(
      r[0] as List<MoneyTransaction>,
      {for (final c in r[1] as List<Category>) c.id: c},
      {for (final a in r[2] as List<Account>) a.id: a},
    );
  }

  List<MoneyTransaction> _apply(List<MoneyTransaction> all) {
    return all.where((t) {
      if (_type != null && t.type != _type) return false;
      if (_accountId != null && t.accountId != _accountId) return false;
      if (_categoryId != null && t.categoryId != _categoryId) return false;
      if (_range != null) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        if (d.isBefore(_range!.start) || d.isAfter(_range!.end)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openForm(Future<void> Function() reload, {int? id}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => TransactionFormScreen(transactionId: id)),
    );
    if (saved == true) {
      setState(() => _tick++);
    }
  }

  Future<void> _delete(MoneyTransaction t, Future<void> Function() reload) async {
    final ok = await confirm(context, 'Delete transaction?',
        'This will remove ${ugx(t.amount)} and update your totals.');
    if (!ok || !mounted) return;
    try {
      await context.read<Services>().transactions.delete(t.id);
      if (!mounted) return;
      showMessage(context, 'Transaction deleted.');
      setState(() => _tick++);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  /// Tap an entry -> choose Edit or Delete (as in the sketch).
  void _actions(MoneyTransaction t, Future<void> Function() reload) {
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(c);
                _openForm(reload, id: t.id);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(c);
                _delete(t, reload);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return AsyncView<_TxData>(
      key: ValueKey(_tick),
      load: () => _load(services),
      builder: (context, d, reload) {
        final shown = _apply(d.transactions);
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(reload),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add transaction'),
          ),
          body: Column(
            children: [
              _filters(d),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: reload,
                  child: shown.isEmpty
                      ? ListView(children: [
                          SizedBox(
                            height: 320,
                            child: EmptyState(
                              icon: LucideIcons.receipt,
                              message: d.transactions.isEmpty
                                  ? 'No transactions yet.\nTap “Add transaction” to record one.'
                                  : 'No transactions match these filters.',
                            ),
                          ),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: shown.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final t = shown[i];
                            return TransactionTile(
                              txn: t,
                              categoryName: d.categories[t.categoryId]?.name ?? '—',
                              accountName: d.accounts[t.accountId]?.name ?? '—',
                              onTap: () => _actions(t, reload),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filters(_TxData d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in const [null, 'income', 'expense'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t == null ? 'All' : (t == 'income' ? 'Income' : 'Expense')),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
              ),
            _menuChip(
              label: _accountId == null
                  ? 'Account'
                  : (d.accounts[_accountId]?.name ?? 'Account'),
              active: _accountId != null,
              items: {for (final a in d.accounts.values) a.id: a.name},
              onPick: (v) => setState(() => _accountId = v),
            ),
            _menuChip(
              label: _categoryId == null
                  ? 'Category'
                  : (d.categories[_categoryId]?.name ?? 'Category'),
              active: _categoryId != null,
              items: {for (final c in d.categories.values) c.id: c.name},
              onPick: (v) => setState(() => _categoryId = v),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(LucideIcons.calendarDays, size: 18),
                label: Text(_range == null
                    ? 'Date'
                    : '${shortDate(_range!.start)} – ${shortDate(_range!.end)}'),
                onPressed: _pickRange,
              ),
            ),
            if (_hasFilter)
              TextButton(
                onPressed: () => setState(() {
                  _type = null;
                  _accountId = null;
                  _categoryId = null;
                  _range = null;
                }),
                child: const Text('Clear'),
              ),
          ],
        ),
      ),
    );
  }

  /// Filter chip with a popup list. Value 0 means "Any" (ids start at 1);
  /// PopupMenuButton does not call onSelected for a null value.
  Widget _menuChip({
    required String label,
    required bool active,
    required Map<int, String> items,
    required void Function(int?) onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<int>(
        onSelected: (v) => onPick(v == 0 ? null : v),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 0, child: Text('Any')),
          for (final e in items.entries)
            PopupMenuItem(value: e.key, child: Text(e.value)),
        ],
        child: Chip(
          label: Text(label),
          backgroundColor: active ? const Color(0xFFC8E4EC) : null,
        ),
      ),
    );
  }
}
