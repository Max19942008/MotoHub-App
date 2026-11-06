import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Tiny GraphQL-over-HTTP client. The backend is a NestJS Apollo server on
/// Render's free tier, which sleeps when idle and can take ~50 s to wake up,
/// hence the generous timeout.
class GraphQLClient {
  GraphQLClient._();
  static final GraphQLClient instance = GraphQLClient._();

  final http.Client _http = http.Client();

  Future<Map<String, dynamic>> query(
    String document, {
    Map<String, dynamic> variables = const {},
  }) async {
    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse(graphqlUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'query': document, 'variables': variables}),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw ApiException('Server javob bermadi. Keyinroq qayta urinib ko\'ring.');
    } on SocketException {
      throw ApiException('Internet aloqasi yo\'q.');
    } on http.ClientException {
      throw ApiException('Serverga ulanib bo\'lmadi.');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server xatosi (${response.statusCode}).');
    }

    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      throw ApiException(first is Map ? '${first['message']}' : 'Server xatosi.');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) throw ApiException('Server bo\'sh javob qaytardi.');
    return data;
  }
}
