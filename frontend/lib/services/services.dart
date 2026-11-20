import '../models/models.dart';
import 'api_client.dart';

/// One thin service per module, mapped 1:1 to the "API Endpoints" sheet.
/// All routes live under /api/v1 (set in config.dart). Collection routes
/// end with a trailing slash, as listed in the plan.

class AuthService {
  final ApiClient api;
  AuthService(this.api);

  /// POST /auth/register  body: name (2-100), email, password (min 8)
  Future<void> register(String name, String email, String password) =>
      api.post(
        '/auth/register',
        {'name': name, 'email': email, 'password': password},
        auth: false,
      );

  /// POST /auth/login -> {access_token, token_type}; JWT lasts 60 minutes.
  Future<String> login(String email, String password) async {
    final r = await api.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;
    return r['access_token'] as String;
  }

  /// GET /auth/me - used on launch to validate a stored token.
  Future<AppUser> me() async =>
      AppUser.fromJson(await api.get('/auth/me') as Map<String, dynamic>);
}

/// The API only supports create + list for accounts (no PUT/DELETE).
class AccountService {
  final ApiClient api;
  AccountService(this.api);

  Future<List<Account>> list() async {
    final r = await api.get('/accounts/') as List;
    return r.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Account> create(String name, String type, double openingBalance) async =>
      Account.fromJson(await api.post(
              '/accounts/', Account.createBody(name, type, openingBalance))
          as Map<String, dynamic>);

  Future<AccountBalance> balance(int id) async => AccountBalance.fromJson(
      await api.get('/accounts/$id/balance') as Map<String, dynamic>);
}

/// The API only supports create + list for categories (no PUT/DELETE).
class CategoryService {
  final ApiClient api;
  CategoryService(this.api);

  Future<List<Category>> list() async {
    final r = await api.get('/categories/') as List;
    return r.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Category> create(String name, String type) async => Category.fromJson(
      await api.post('/categories/', {'category_name': name, 'category_type': type})
          as Map<String, dynamic>);
}

class TransactionService {
  final ApiClient api;
  TransactionService(this.api);

  /// No server-side filtering or pagination: load all, sort in the app.
  Future<List<MoneyTransaction>> list() async {
    final r = await api.get('/transactions/') as List;
    final items = r
        .map((e) => MoneyTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    items.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return items;
  }

  Future<MoneyTransaction> get(int id) async => MoneyTransaction.fromJson(
      await api.get('/transactions/$id') as Map<String, dynamic>);

  Future<void> create(TransactionInput t) =>
      api.post('/transactions/', t.toJson());

  Future<void> update(int id, TransactionInput t) =>
      api.put('/transactions/$id', t.toJson());

  /// Returns 204 with no body.
  Future<void> delete(int id) => api.delete('/transactions/$id');
}

class DashboardService {
  final ApiClient api;
  DashboardService(this.api);

  Future<DashboardSummary> summary() async => DashboardSummary.fromJson(
      await api.get('/dashboard/summary') as Map<String, dynamic>);

  Future<MonthlySummary> monthly(int year, int month) async =>
      MonthlySummary.fromJson(
          await api.get('/dashboard/monthly-summary?year=$year&month=$month')
              as Map<String, dynamic>);
}

/// Bundle handed to screens through Provider.
class Services {
  final ApiClient api;
  final AuthService auth;
  final AccountService accounts;
  final CategoryService categories;
  final TransactionService transactions;
  final DashboardService dashboard;

  Services(this.api)
      : auth = AuthService(api),
        accounts = AccountService(api),
        categories = CategoryService(api),
        transactions = TransactionService(api),
        dashboard = DashboardService(api);
}
