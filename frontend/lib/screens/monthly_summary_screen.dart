import 'package:flutter/material.dart';
import '../lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../widgets/async_view.dart';
import '../widgets/format.dart';
import '../widgets/theme.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

/// GET /dashboard/monthly-summary?year=&month=
/// Month 1-12, year 2000-2100 (API rule), so the picker is clamped to that.
class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _shift(int delta) {
    final d = DateTime(_year, _month + delta);
    if (d.year < 2000 || d.year > 2100) return;
    setState(() {
      _year = d.year;
      _month = d.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly summary')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    tooltip: 'Previous month',
                    onPressed: () => _shift(-1),
                    icon: const Icon(LucideIcons.chevronLeft)),
                SizedBox(
                  width: 180,
                  child: Text('${_monthNames[_month - 1]} $_year',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                    tooltip: 'Next month',
                    onPressed: () => _shift(1),
                    icon: const Icon(LucideIcons.chevronRight)),
              ],
            ),
          ),
          Expanded(
            // A new key per month forces a fresh request when the month changes.
            child: AsyncView<MonthlySummary>(
              key: ValueKey('$_year-$_month'),
              load: () => services.dashboard.monthly(_year, _month),
              builder: (context, m, reload) => RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.text,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Net savings',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          Text(ugx(m.netSavings),
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
                        ListTile(
                          title: const Text('Income'),
                          trailing: Text(ugx(m.income),
                              style: const TextStyle(
                                  color: AppColors.income,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Expenses'),
                          trailing: Text(ugx(m.expenses),
                              style: const TextStyle(
                                  color: AppColors.expense,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Transactions'),
                          trailing: Text('${m.transactionCount}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
