import 'package:flutter/material.dart';
import '../lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_controller.dart';
import 'register_screen.dart';

final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().login(_email.text, _password.text);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error =
            e.status == 401 ? 'Incorrect email or password.' : e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('MyMoney UG',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text('Track your money in UGX',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration:
                          const InputDecoration(labelText: 'Email address'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Enter your email address.';
                        if (!emailPattern.hasMatch(t)) {
                          return 'Enter a valid email, e.g. name@example.com.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _hide,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_hide
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password.'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Log in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
