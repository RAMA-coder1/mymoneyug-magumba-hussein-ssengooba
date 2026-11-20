// Models follow the real API (MyMoneyUG_API_Flutter_Plan.xlsx).
//
// The plan lists endpoints and rules but not exact JSON key names, so the
// parsers below accept the most likely variants (e.g. `account_id` or `id`,
// `total_expense` or `total_expenses`). If your OpenAPI at /docs shows other
// names, only this file needs changing.

import 'package:flutter/widgets.dart' show IconData;
import '../lucide_icons.dart' show LucideIcons;

dynamic _pick(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) return j[k];
  }
  return null;
}

/// DECIMAL may be serialised as a JSON string or number; accept both.
double _num(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class AppUser {
  final String name;
  final String email;
  const AppUser({required this.name, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        name: (_pick(j, ['name', 'full_name']) ?? '').toString(),
        email: (j['email'] ?? '').toString(),
      );
}

class Account {
  final int id;
  final String name;
  final String accountType; // cash | mobile_money | bank
  final double openingBalance;

  const Account({
    required this.id,
    required this.name,
    required this.accountType,
    required this.openingBalance,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: _int(_pick(j, ['account_id', 'id'])),
        name: j['account_name'] as String,
        accountType: j['account_type'] as String,
        openingBalance: _num(j['opening_balance']),
      );

  /// POST /accounts/ body. Opening balance defaults to 0 and cannot be negative.
  static Map<String, dynamic> createBody(
          String name, String type, double openingBalance) =>
      {'account_name': name, 'account_type': type, 'opening_balance': openingBalance};

  static const types = ['cash', 'mobile_money', 'bank'];

  static String typeLabel(String t) {
    switch (t) {
      case 'cash':
        return 'Cash';
      case 'mobile_money':
        return 'Mobile Money';
      case 'bank':
        return 'Bank';
      default:
        return t;
    }
  }

  static IconData iconFor(String t) {
    switch (t) {
      case 'cash':
        return LucideIcons.banknote;
      case 'mobile_money':
        return LucideIcons.smartphone;
      case 'bank':
        return LucideIcons.building2;
      default:
        return LucideIcons.wallet;
    }
  }
}

/// GET /accounts/{id}/balance
class AccountBalance {
  final double openingBalance;
  final double totalIncome;
  final double totalExpenses;
  final double currentBalance;

  const AccountBalance({
    required this.openingBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentBalance,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> j) => AccountBalance(
        openingBalance: _num(j['opening_balance']),
        totalIncome: _num(_pick(j, ['total_income', 'income'])),
        totalExpenses:
            _num(_pick(j, ['total_expenses', 'total_expense', 'expenses'])),
        currentBalance: _num(_pick(j, ['current_balance', 'balance'])),
      );
}

class Category {
  final int id;
  final String name;
  final String type; // income | expense

  const Category({required this.id, required this.name, required this.type});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: _int(_pick(j, ['category_id', 'id'])),
        name: j['category_name'] as String,
        type: j['category_type'] as String,
      );

  bool get isExpense => type == 'expense';
}

class MoneyTransaction {
  final int id;
  final int accountId;
  final int categoryId;
  final String type; // income | expense
  final double amount;
  final String? description;
  final DateTime date;

  const MoneyTransaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
  });

  factory MoneyTransaction.fromJson(Map<String, dynamic> j) => MoneyTransaction(
        id: _int(_pick(j, ['transaction_id', 'id'])),
        accountId: _int(j['account_id']),
        categoryId: _int(j['category_id']),
        type: j['transaction_type'] as String,
        amount: _num(j['amount']),
        description: j['description'] as String?,
        date: DateTime.parse(
            (_pick(j, ['transaction_date', 'date'])).toString().substring(0, 10)),
      );

  bool get isExpense => type == 'expense';
}

/// Body for POST /transactions/ and PUT /transactions/{id}.
/// PUT replaces the record, so every field is always sent.
class TransactionInput {
  final int accountId;
  final int categoryId;
  final String type;
  final double amount;
  final DateTime date;
  final String? description;

  const TransactionInput({
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'account_id': accountId,
        'category_id': categoryId,
        'transaction_type': type,
        'amount': amount,
        'transaction_date': isoDate(date),
        'description': (description == null || description!.isEmpty)
            ? null
            : description,
      };
}

/// GET /dashboard/summary
class DashboardSummary {
  final double totalBalance;
  final double totalIncome;
  final double totalExpenses;
  final int accountCount;
  final int transactionCount;

  const DashboardSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.accountCount,
    required this.transactionCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
        totalBalance: _num(_pick(j, ['total_balance', 'balance'])),
        totalIncome: _num(_pick(j, ['total_income', 'income'])),
        totalExpenses:
            _num(_pick(j, ['total_expenses', 'total_expense', 'expenses'])),
        accountCount: _int(_pick(j, ['account_count', 'accounts_count'])),
        transactionCount:
            _int(_pick(j, ['transaction_count', 'transactions_count'])),
      );
}

/// GET /dashboard/monthly-summary?year=&month=
class MonthlySummary {
  final double income;
  final double expenses;
  final double netSavings;
  final int transactionCount;

  const MonthlySummary({
    required this.income,
    required this.expenses,
    required this.netSavings,
    required this.transactionCount,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> j) {
    final inc = _num(_pick(j, ['total_income', 'income']));
    final exp = _num(_pick(j, ['total_expenses', 'total_expense', 'expenses']));
    final net = _pick(j, ['net_savings', 'net']);
    return MonthlySummary(
      income: inc,
      expenses: exp,
      netSavings: net == null ? inc - exp : _num(net),
      transactionCount:
          _int(_pick(j, ['transaction_count', 'transactions_count'])),
    );
  }
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
