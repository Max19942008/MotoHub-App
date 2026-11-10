import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.isNetwork = false});
  final String message;

  /// True when the server was never reached (offline, timeout, waking up),
  /// as opposed to the server answering with an error.
  final bool isNetwork;

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

  /// Set by AuthService: returns a valid access token (refreshing it if needed) or null for guests.
  Future<String?> Function()? tokenProvider;

  Future<Map<String, dynamic>> query(
    String document, {
    Map<String, dynamic> variables = const {},
    bool authenticated = true,
  }) async {
    final token = authenticated ? await tokenProvider?.call() : null;
    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse(graphqlUrl),
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'query': document, 'variables': variables}),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw ApiException(
          'Server javob bermadi. Keyinroq qayta urinib ko\'ring.',
          isNetwork: true);
    } on SocketException {
      throw ApiException('Internet aloqasi yo\'q.', isNetwork: true);
    } on http.ClientException {
      throw ApiException('Serverga ulanib bo\'lmadi.', isNetwork: true);
    }

    Map<String, dynamic> body;
    try {
      body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      // Render answers with an HTML 502/503 page while the instance boots.
      throw ApiException('Server xatosi (${response.statusCode}).',
          isNetwork: response.statusCode >= 500);
    }

    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      final raw = first is Map ? first['message'] : null;
      // class-validator errors arrive as a list of messages.
      final message =
          raw is List ? raw.join('\n') : '${raw ?? 'Server xatosi.'}';
      throw ApiException(_translate(message));
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Server bo\'sh javob qaytardi.');
    }
    return data;
  }

  /// Uploads one image with the GraphQL multipart spec (same as the site's
  /// editor) and returns the stored path, e.g. "uploads/member/x.jpg".
  /// [target] is the upload folder: member, property, part, article.
  Future<String> uploadImage(String filePath, String target) async {
    final token = await tokenProvider?.call();
    final request = http.MultipartRequest('POST', Uri.parse(graphqlUrl))
      ..headers.addAll({
        'apollo-require-preflight': 'true',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      })
      ..fields['operations'] = jsonEncode({
        'query':
            r'mutation ($file: Upload!, $target: String!) { imageUploader(file: $file, target: $target) }',
        'variables': {'file': null, 'target': target},
      })
      ..fields['map'] = jsonEncode({
        '0': ['variables.file']
      })
      ..files.add(await http.MultipartFile.fromPath('0', filePath,
          contentType: _imageType(filePath)));
    final http.Response response;
    try {
      response = await http.Response.fromStream(
          await _http.send(request).timeout(const Duration(seconds: 90)));
    } on TimeoutException {
      throw ApiException('Rasm yuklanmadi: server javob bermadi.',
          isNetwork: true);
    } on SocketException {
      throw ApiException('Internet aloqasi yo\'q.', isNetwork: true);
    }
    Map<String, dynamic> body;
    try {
      body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Rasm yuklanmadi (${response.statusCode}).');
    }
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw ApiException(
          _translate('${(errors.first as Map)['message'] ?? 'Xato'}'));
    }
    final path = (body['data'] as Map?)?['imageUploader'];
    if (path is! String || path.isEmpty) {
      throw ApiException('Rasm yuklanmadi.');
    }
    return path;
  }

  static MediaType _imageType(String path) {
    final p = path.toLowerCase();
    // The backend accepts png / jpg / jpeg only; the picker re-encodes to jpeg.
    if (p.endsWith('.png')) return MediaType('image', 'png');
    return MediaType('image', 'jpeg');
  }

  /// Server messages are English; show the ones users hit most in Uzbek.
  static String _translate(String message) {
    const known = {
      'No member with that member nick!':
          'Bunday nikdagi foydalanuvchi topilmadi.',
      'Wrong password, try again!': "Parol noto'g'ri.",
      'Already used nick or phone':
          'Bu nik yoki telefon raqam allaqachon band.',
      'You have been blocked!': 'Hisobingiz bloklangan.',
      'This account signs in with Google!':
          'Bu hisob Google orqali kiradi — saytdan kiring.',
      'AI assistant is not configured': 'AI yordamchi hozircha sozlanmagan.',
      'Assistant is busy, please try again in a minute':
          "Yordamchi band, bir daqiqadan so'ng urinib ko'ring.",
      'Assistant is unavailable right now': 'Yordamchi hozir ishlamayapti.',
      'Too many questions — please wait a few minutes':
          "Juda ko'p savol — bir necha daqiqa kuting.",
    };
    return known[message] ?? message;
  }
}
