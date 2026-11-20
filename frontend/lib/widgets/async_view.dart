import 'package:flutter/material.dart';
import '../lucide_icons.dart';

import '../services/api_client.dart';
import 'theme.dart';

/// The "Error / Loading" screen from the sketches, as a reusable widget.
/// Covers FR-13 (loading, empty, server-unavailable) and NFR-03 (retry, no crash).
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext, T data, Future<void> Function() reload)
      builder;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;
  final IconData emptyIcon;

  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.emptyMessage = 'Nothing here yet.',
    this.emptyIcon = LucideIcons.inbox,
  });

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> _reload() async {
    final f = widget.load();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {
      // Error is rendered by the FutureBuilder below.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingState();
        }
        if (snap.hasError) {
          final e = snap.error;
          return ErrorState(
            message: e is ApiException ? e.message : 'Something went wrong.',
            offline: e is ApiException && e.isNetwork,
            onRetry: _reload,
          );
        }
        final data = snap.data as T;
        if (widget.isEmpty?.call(data) ?? false) {
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(children: [
              SizedBox(
                height: 360,
                child: EmptyState(
                    icon: widget.emptyIcon, message: widget.emptyMessage),
              ),
            ]),
          );
        }
        return widget.builder(context, data, _reload);
      },
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading…'),
          ],
        ),
      );
}

class ErrorState extends StatelessWidget {
  final String message;
  final bool offline;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.offline = false,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(offline ? LucideIcons.cloudOff : LucideIcons.alertCircle,
                  size: 56, color: AppColors.navy),
              const SizedBox(height: 16),
              Text(offline ? 'No internet / server off' : 'Something went wrong',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.black38),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

void showMessage(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.expense : null,
    ));
}

Future<bool> confirm(BuildContext context, String title, String body,
    {String action = 'Delete'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(action)),
      ],
    ),
  );
  return r ?? false;
}
