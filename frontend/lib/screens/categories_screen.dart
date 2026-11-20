import 'package:flutter/material.dart';
import '../lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/services.dart';
import '../widgets/async_view.dart';
import '../widgets/theme.dart';

/// Categories grouped into income and expense (done in the app).
/// The API supports create + list only, so there is no edit/delete here.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _tick = 0;

  Future<void> _add(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddCategorySheet(),
    );
    if (created == true) {
      if (context.mounted) showMessage(context, 'Category added.');
      setState(() => _tick++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return AsyncView<List<Category>>(
      key: ValueKey(_tick),
      load: services.categories.list,
      isEmpty: (_) => false,
      emptyIcon: LucideIcons.tag,
      emptyMessage:
          'No categories yet.\nAdd ones like Food, Transport or Data bundles.',
      builder: (context, cats, reload) {
        final expense = cats.where((c) => c.isExpense).toList();
        final income = cats.where((c) => !c.isExpense).toList();
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _add(context),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add category'),
          ),
          body: RefreshIndicator(
            onRefresh: () async => setState(() => _tick++),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _section(context, 'Expense categories', expense,
                    AppColors.expense, LucideIcons.arrowUp),
                const SizedBox(height: 16),
                _section(context, 'Income categories', income,
                    AppColors.income, LucideIcons.arrowDown),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(BuildContext context, String title, List<Category> items,
      Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('None yet.')
        else
          Card(
            child: Column(
              children: [
                for (final c in items)
                  ListTile(
                    leading: Icon(icon, color: color, size: 20),
                    title: Text(c.name),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _type = 'expense';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
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
      await context.read<Services>().categories.create(_name.text.trim(), _type);
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
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add category',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Category name'),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Enter a name, e.g. Transport.'
                    : null,
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
                    : const Text('Save category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
