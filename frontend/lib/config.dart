import 'package:flutter/foundation.dart';

/// API base URL is configurable so no host/secret is hardcoded (NFR-01, NFR-05).
///
/// Override at launch (e.g. a real phone on the same Wi-Fi):
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1
///
/// Defaults when not overridden:
///   Chrome / Edge / desktop  -> http://localhost:8000/api/v1
///   Android emulator         -> http://10.0.2.2:8000/api/v1
const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api/v1';
  }
  return 'http://localhost:8000/api/v1';
}

const Duration apiTimeout = Duration(seconds: 10);
