import 'package:flutter/material.dart';
import '../lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/services.dart';
import '../widgets/async_view.dart';
import '../widgets/format.dart';

/// Add Transaction (POST) and Edit Transaction (GET one, then PUT).
/// Pass [transactionId] to edit. PUT replaces the whole record, so the form
/// is pre-filled from the existing one and every field is sent back.
class TransactionFormScreen extends StatelessWidget {
  final int? transactionId;
  const TransactionFormScreen({super.key, this.transactionId});

  bool get _editing => transactionId != null;

  Future<_FormRefs> _load(Services s) async {
    final r = await Future.wait([
      s.accounts.list(),
      s.categories.list(),
      if (_editing) s.transactions.get(transactionId!),
    ]);
    return _FormRefs(
      r[0] as List<Account>,
      r[1] as List<Category>,
      _editing ? r[2] as MoneyTransaction : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return Scaffold(
      appBar: AppBar(
          title: Text(_editing ? 'Edit Transaction' : 'Add Transaction')),
      body: AsyncView<_FormRefs>(
        load: () => _load(services),
        builder: (context, refs, _) => _TransactionForm(refs: refs),
      ),
    );
  }
}

class _FormRefs {
  final List<Account> accounts;
  final List<Category> categories;
  final MoneyTransaction? existing;
  _FormRefs(this.accounts, this.categories, this.existing);
}

class _TransactionForm extends StatefulWidget {
  final _FormRefs refs;
  const _TransactionForm({required this.refs});

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();

  String _type = 'expense';
  int? _accountId;
  int? _categoryId;
  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _error;

  MoneyTransaction? get _existing => widget.refs.existing;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    if (e != null) {
      // Pre-fill from the existing record.
      _type = e.type;
      _accountId = e.accountId;
      _categoryId = e.categoryId;
      _date = e.date;
      _amount.text = e.amount == e.amount.roundToDouble()
          ? e.amount.round().toString()
          : e.amount.toString();
      _description.text = e.description ?? '';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Only categories whose type matches the chosen transaction type.
  List<Category> get _categoryChoices =>
      widget.refs.categories.where((c) => c.type == _type).toList();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final input = TransactionInput(
      accountId: _accountId!,
      categoryId: _categoryId!,
      type: _type,
      amount: double.parse(_amount.text.trim()),
      date: _date,
      description: _description.text.trim(),
    );
    final nav = Navigator.of(context);
    final svc = context.read<Services>().transactions;
    try {
      if (_existing == null) {
        await svc.create(input);
      } else {
        await svc.update(_existing!.id, input);
      }
      nav.pop(true); // tells the previous screen to refresh
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noAccounts = widget.refs.accounts.isEmpty;
    final choices = _categoryChoices;
    final noCategories = choices.isEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  // The old category may not match the new type any more.
                  if (!_categoryChoices.any((c) => c.id == _categoryId)) {
                    _categoryId = null;
                  }
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                    labelText: 'Amount (UGX)', prefixText: 'UGX '),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null) return 'Enter an amount, e.g. 5000.';
                  if (n <= 0) return 'Amount must be more than 0.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _accountId,
                decoration: InputDecoration(
                  labelText: 'Account',
                  helperText: noAccounts
                      ? 'Add an account first (Accounts tab).'
                      : null,
                ),
                items: [
                  for (final a in widget.refs.accounts)
                    DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.name} · ${Account.typeLabel(a.accountType)}')),
                ],
                onChanged: noAccounts ? null : (v) => setState(() => _accountId = v),
                validator: (v) => v == null ? 'Choose an account.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: ValueKey('cat-$_type'),
                initialValue: _categoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  helperText: noCategories
                      ? 'No $_type categories yet. Add one in the Categories tab.'
                      : null,
                ),
                items: [
                  for (final c in choices)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged:
                    noCategories ? null : (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Choose a category.' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(LucideIcons.calendar),
                  ),
                  child: Text(shortDate(_date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLength: 255,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: (_busy || noAccounts || noCategories) ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_existing == null ? 'Save transaction' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
