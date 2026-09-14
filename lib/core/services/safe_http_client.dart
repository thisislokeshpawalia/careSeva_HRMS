import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SafeHttpClient {
  static const int maxRetries = 3;
  static const Duration timeoutDuration = Duration(seconds: 15);

  /// Executes an HTTP GET request with retries and DoH DNS fallback
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    return _sendWithRetry(
      () => http.get(uri, headers: headers).timeout(timeoutDuration),
      uri,
      headers: headers,
      method: 'GET',
    );
  }

  /// Executes an HTTP POST request with retries and DoH DNS fallback
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _sendWithRetry(
      () => http.post(uri, headers: headers, body: body, encoding: encoding).timeout(timeoutDuration),
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
      method: 'POST',
    );
  }

  /// Executes an HTTP PATCH request with retries and DoH DNS fallback
  static Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _sendWithRetry(
      () => http.patch(uri, headers: headers, body: body, encoding: encoding).timeout(timeoutDuration),
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
      method: 'PATCH',
    );
  }

  /// Executes an HTTP PUT request with retries and DoH DNS fallback
  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _sendWithRetry(
      () => http.put(uri, headers: headers, body: body, encoding: encoding).timeout(timeoutDuration),
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
      method: 'PUT',
    );
  }

  /// Executes an HTTP DELETE request with retries and DoH DNS fallback
  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _sendWithRetry(
      () => http.delete(uri, headers: headers, body: body, encoding: encoding).timeout(timeoutDuration),
      uri,
      headers: headers,
      body: body,
      encoding: encoding,
      method: 'DELETE',
    );
  }

  static Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() requestFn,
    Uri originalUri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    String method = 'GET',
  }) async {
    Object? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await requestFn();
      } catch (e) {
        lastException = e;

        // If DNS host lookup fails on device, try resolving via Google DNS Over HTTPS (DoH)
        if (e is SocketException || e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
          final dohIp = await _resolveDoH(originalUri.host);
          if (dohIp != null && dohIp.isNotEmpty) {
            try {
              final fallbackUri = originalUri.replace(host: dohIp);
              final fallbackHeaders = Map<String, String>.from(headers ?? {});
              fallbackHeaders['Host'] = originalUri.host;

              if (method == 'POST') {
                return await http.post(fallbackUri, headers: fallbackHeaders, body: body, encoding: encoding).timeout(timeoutDuration);
              } else if (method == 'GET') {
                return await http.get(fallbackUri, headers: fallbackHeaders).timeout(timeoutDuration);
              } else if (method == 'PATCH') {
                return await http.patch(fallbackUri, headers: fallbackHeaders, body: body, encoding: encoding).timeout(timeoutDuration);
              } else if (method == 'PUT') {
                return await http.put(fallbackUri, headers: fallbackHeaders, body: body, encoding: encoding).timeout(timeoutDuration);
              } else if (method == 'DELETE') {
                return await http.delete(fallbackUri, headers: fallbackHeaders, body: body, encoding: encoding).timeout(timeoutDuration);
              }
            } catch (_) {
              // Ignore fallback attempt errors and proceed to delay retry
            }
          }
        }

        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    throw lastException ?? Exception('Network connection failed');
  }

  /// Resolves hostname using Google DNS Over HTTPS (DoH)
  static Future<String?> _resolveDoH(String hostname) async {
    try {
      final dohUri = Uri.parse('https://dns.google/resolve?name=${Uri.encodeComponent(hostname)}');
      final res = await http.get(dohUri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final answers = data['Answer'] as List<dynamic>?;
        if (answers != null && answers.isNotEmpty) {
          for (final a in answers) {
            if (a['type'] == 1 && a['data'] != null) { // Type 1 = A record (IPv4)
              return a['data'].toString();
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Utility to format exceptions into human-friendly messages
  static String formatErrorMessage(Object e) {
    final str = e.toString();
    if (str.contains('Failed host lookup') || str.contains('SocketException')) {
      return 'Unable to connect to CareSeva server. Please check your internet connection or network settings and try again.';
    }
    if (str.contains('TimeoutException') || str.contains('timed out')) {
      return 'Connection timed out. Please check your internet speed and try again.';
    }
    if (str.contains('HandshakeException') || str.contains('CERTIFICATE_VERIFY_FAILED')) {
      return 'Secure connection failed. Please verify device date & time settings.';
    }
    return 'Network connection error. Please try again.';
  }
}
