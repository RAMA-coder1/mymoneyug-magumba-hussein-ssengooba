import 'package:flutter/material.dart';
import '../lucide_icons.dart';

import '../models/models.dart';
import 'format.dart';
import 'theme.dart';

class TransactionTile extends StatelessWidget {
  final MoneyTransaction txn;
  final String categoryName;
  final String accountName;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.txn,
    required this.categoryName,
    required this.accountName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = txn.isExpense ? AppColors.expense : AppColors.income;
    final sign = txn.isExpense ? '-' : '+';
    final note = (txn.description ?? '').trim();
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.paleBlue,
        child: Icon(
          txn.isExpense ? LucideIcons.arrowUp : LucideIcons.arrowDown,
          color: color,
          size: 20,
        ),
      ),
      title: Text(categoryName),
      subtitle: Text(
        [shortDate(txn.date), accountName, if (note.isNotEmpty) note].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$sign${ugx(txn.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
