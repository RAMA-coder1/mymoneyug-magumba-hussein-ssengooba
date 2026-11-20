import 'package:flutter/material.dart';
import '../lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/services.dart';
import '../widgets/async_view.dart';
import '../widgets/format.dart';
import '../widgets/theme.dart';

/// Accounts list. The API supports create + list + per-account balance only,
/// so there is no edit/delete here.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  int _tick = 0;

  /// Accounts plus each account's current balance (GET /accounts/{id}/balance).
  Future<List<(Account, AccountBalance?)>> _load(Services s) async {
    final accounts = await s.accounts.list();
    return Future.wait(accounts.map((a) async {
      try {
        return (a, await s.accounts.balance(a.id));
      } on ApiException catch (e) {
        if (e.isNetwork) rethrow;
        return (a, null);
      }
    }));
  }

  Future<void> _add(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddAccountSheet(),
    );
    if (created == true) {
      if (context.mounted) showMessage(context, 'Account added.');
      setState(() => _tick++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return AsyncView<List<(Account, AccountBalance?)>>(
      key: ValueKey(_tick),
      load: () => _load(services),
      isEmpty: (_) => false,
      emptyIcon: LucideIcons.wallet,
      emptyMessage:
          'No accounts yet.\nAdd Cash, Mobile Money or Bank to start tracking.',
      builder: (context, items, reload) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _add(context),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Add account'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() => _tick++);
          },
          child: items.isEmpty
              ? ListView(children: const [
                  SizedBox(
                    height: 320,
                    child: EmptyState(
                      icon: LucideIcons.wallet,
                      message:
                          'No accounts yet.\nAdd Cash, Mobile Money or Bank to start tracking.',
                    ),
                  ),
                ])
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final (a, b) = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.paleBlue,
                    child: Icon(Account.iconFor(a.accountType),
                        color: AppColors.text),
                  ),
                  title: Text(a.name),
                  subtitle: Text(Account.typeLabel(a.accountType)),
                  trailing: Text(
                    b == null ? 'UGX —' : ugx(b.currentBalance),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AccountDetailScreen(account: a)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Account detail: opening balance, income, expenses and current balance.
class AccountDetailScreen extends StatelessWidget {
  final Account account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: AsyncView<AccountBalance>(
        load: () => services.accounts.balance(account.id),
        builder: (context, b, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Account.typeLabel(account.accountType),
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    const Text('Current balance',
                        style: TextStyle(color: Colors.white70)),
                    Text(ugx(b.currentBalance),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(children: [
                  _row('Opening balance', ugx(b.openingBalance), null),
                  const Divider(height: 1),
                  _row('Total income', ugx(b.totalIncome), AppColors.income),
                  const Divider(height: 1),
                  _row('Total expenses', ugx(b.totalExpenses), AppColors.expense),
                ]),
              ),
              const SizedBox(height: 12),
              const Text(
                'Balance = opening balance + income − expenses, based on what you have recorded.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color? color) => ListTile(
        title: Text(label),
        trailing: Text(value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      );
}

/// Add account: name, type (cash / mobile money / bank), opening balance (>= 0).
class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _opening = TextEditingController(text: '0');
  String _type = Account.types.first;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    try {
      await context.read<Services>().accounts.create(
            _name.text.trim(),
            _type,
            double.parse(_opening.text.trim()),
          );
      nav.pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add account',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Account name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a name, e.g. MTN MoMo.' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final t in Account.types)
                    DropdownMenuItem(value: t, child: Text(Account.typeLabel(t))),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _opening,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                    labelText: 'Opening balance (UGX)', prefixText: 'UGX '),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null) return 'Enter an amount (0 if none).';
                  if (n < 0) return 'Opening balance cannot be negative.';
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
