import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'services.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Holds login state. Logout simply clears the stored token (FR-03, ST-11).
class AuthController extends ChangeNotifier {
  final Services services;
  final TokenStorage tokens;
  AuthStatus status = AuthStatus.unknown;

  AuthController(this.services, this.tokens) {
    services.api.onUnauthorized = _handleUnauthorized;
  }

  Future<void> restore() async {
    // Splash / session check: validate any stored token with GET /auth/me.
    String? t;
    try {
      t = await tokens.read();
    } catch (_) {
      t = null;
    }
    if (t == null || t.isEmpty) {
      status = AuthStatus.signedOut;
    } else {
      try {
        await services.auth.me();
        status = AuthStatus.signedIn;
      } on ApiException catch (e) {
        if (e.isNetwork) {
          // Server unreachable: keep the session; screens show retry (NFR-03).
          status = AuthStatus.signedIn;
        } else {
          // Expired (60 min JWT) or invalid token.
          await tokens.clear();
          status = AuthStatus.signedOut;
        }
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final token = await services.auth.login(email.trim().toLowerCase(), password);
    await tokens.write(token);
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  /// Registers then signs in straight away.
  Future<void> register(String name, String email, String password) async {
    final e = email.trim().toLowerCase();
    await services.auth.register(name.trim(), e, password);
    await login(e, password);
  }

  Future<void> logout() async {
    await tokens.clear();
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (status == AuthStatus.signedIn) logout();
  }
}
