import 'package:flutter/material.dart';
import '../lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_controller.dart';
import 'login_screen.dart' show emailPattern;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
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
    final nav = Navigator.of(context);
    try {
      await context
          .read<AuthController>()
          .register(_name.text, _email.text, _password.text);
      // Auth state flips to signed-in; drop back to the root which shows Home.
      nav.popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.status == 409
            ? 'That email is already registered. Try logging in instead.'
            : e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
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
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Enter your name.';
                        if (t.length > 100) return 'Name is too long (max 100).';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
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
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: 'At least 8 characters',
                        suffixIcon: IconButton(
                          icon: Icon(_hide
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Password must be at least 8 characters.'
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
                          : const Text('Create account'),
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
