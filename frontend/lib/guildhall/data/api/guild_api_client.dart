import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Minimal JSON-over-HTTP client for the Guildhall endpoints.
///
/// Base URL can be overridden with `--dart-define=API_BASE_URL=http://host:port`.
/// Defaults to the host machine as seen from the Android emulator / iOS simulator.
class GuildApiClient {
  GuildApiClient({
    String? baseUrl,
    this.tokenProvider,
    this.timeout = const Duration(seconds: 10),
    HttpClient? httpClient,
  }) : baseUrl = baseUrl ?? defaultBaseUrl,
       _http = httpClient ?? HttpClient();

  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return Platform.isAndroid
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080';
  }

  final String baseUrl;

  /// Returns the JWT to send as `Authorization: Bearer …`, or null when signed out.
  final String? Function()? tokenProvider;
  final Duration timeout;
  final HttpClient _http;

  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final request = await _http.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final token = tokenProvider?.call();
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GuildApiException(
          response.statusCode,
          'GET $path failed (${response.statusCode})',
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw GuildApiException(
          response.statusCode,
          'GET $path returned unexpected JSON',
        );
      }
      return decoded;
    } on SocketException catch (e) {
      throw GuildApiException(null, 'Could not reach the server: ${e.message}');
    } on TimeoutException {
      throw GuildApiException(null, 'The server took too long to answer');
    } on FormatException catch (e) {
      throw GuildApiException(null, 'Invalid JSON from server: ${e.message}');
    }
  }

  void close() => _http.close(force: true);
}

class GuildApiException implements Exception {
  GuildApiException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}
