import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_controller.dart';
import 'services/services.dart';
import 'widgets/theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStorage();
  final services = Services(ApiClient(tokens: tokens));
  final auth = AuthController(services, tokens)..restore();

  runApp(MultiProvider(
    providers: [
      Provider<Services>.value(value: services),
      ChangeNotifierProvider<AuthController>.value(value: auth),
    ],
    child: const MyMoneyApp(),
  ));
}

class MyMoneyApp extends StatelessWidget {
  const MyMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMoney UG',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _Root(),
    );
  }
}

/// Guests only see login/registration; everything else needs a token (FR-14).
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    switch (context.watch<AuthController>().status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedOut:
        // e.g. a 401 while a form is open: drop any pushed screens (FR-14, T11).
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => navigatorKey.currentState?.popUntil((r) => r.isFirst));
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const HomeShell();
    }
  }
}
