import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// Error shown to the user (FR-12, FR-13, NFR-03). Never crashes the app.
class ApiException implements Exception {
  final int? status;
  final String message;

  /// True when the backend could not be reached (offline / timeout).
  final bool isNetwork;

  const ApiException(this.message, {this.status, this.isNetwork = false});

  @override
  String toString() => message;
}

/// Bearer token kept in secure device storage; cleared on logout (FR-03).
class TokenStorage {
  static const _key = 'access_token';
  final FlutterSecureStorage _s = const FlutterSecureStorage();

  Future<String?> read() => _s.read(key: _key);
  Future<void> write(String t) => _s.write(key: _key, value: t);
  Future<void> clear() => _s.delete(key: _key);
}

class ApiClient {
  final TokenStorage tokens;
  final String baseUrl;

  /// Called on any 401 from a protected endpoint so the app returns to login.
  void Function()? onUnauthorized;

  ApiClient({required this.tokens, String? baseUrl})
      : baseUrl = baseUrl ?? apiBaseUrl;

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body,
          {bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);
  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final req = http.Request(method, Uri.parse('$baseUrl$path'));
    req.headers['Accept'] = 'application/json';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    if (auth) {
      final t = await tokens.read();
      if (t != null) req.headers['Authorization'] = 'Bearer $t';
    }

    http.Response res;
    try {
      res = await http.Response.fromStream(
          await req.send().timeout(apiTimeout));
    } on TimeoutException {
      throw const ApiException(
          'The server took too long to respond. Check your connection and try again.',
          isNetwork: true);
    } on SocketException {
      throw const ApiException(
          'Cannot reach the server. Check your internet or that the backend is running.',
          isNetwork: true);
    } on http.ClientException {
      throw const ApiException(
          'Cannot reach the server. Check your internet or that the backend is running.',
          isNetwork: true);
    }

    if (res.statusCode == 204) return null;

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    if (res.statusCode == 401 && auth) onUnauthorized?.call();
    throw ApiException(_messageFor(res.statusCode, data), status: res.statusCode);
  }

  /// Turns FastAPI error bodies into readable correction messages (FR-12).
  /// `detail` is either a string (400/401/404/409) or a list of
  /// {loc, msg} objects (422 schema validation).
  String _messageFor(int status, dynamic data) {
    if (data is Map && data['detail'] != null) {
      final d = data['detail'];
      if (d is String) return d;
      if (d is List) {
        final msgs = d.map((e) {
          if (e is Map) {
            final loc = (e['loc'] as List?)?.where((x) => x != 'body').join(' ');
            final msg = e['msg']?.toString() ?? 'Invalid value';
            return (loc == null || loc.isEmpty) ? msg : '$loc: $msg';
          }
          return e.toString();
        });
        return msgs.join('\n');
      }
    }
    switch (status) {
      case 400:
      case 422:
        return 'Some details are invalid. Please check and try again.';
      case 401:
        return 'Your session has expired or your login details are wrong.';
      case 404:
        return 'That record could not be found.';
      case 409:
        return 'This item is in use or already exists, so the action was refused.';
      default:
        return 'Something went wrong on the server (code $status). Please try again.';
    }
  }
}
