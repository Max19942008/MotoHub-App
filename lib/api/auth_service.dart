import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'graphql_client.dart';

/// The logged-in member, read from the access token's payload (the backend
/// signs the member document into the JWT, minus the password).
class Member {
  Member({required this.id, required this.nick, this.phone, this.image, this.type, this.fullName});

  final String id;
  final String nick;
  final String? phone;
  final String? image;
  final String? type;
  final String? fullName;

  bool get isAgent => type == 'AGENT';
}

/// Holds the session: login / signup / logout, token storage in the platform
/// keystore, and silent refresh. Access tokens live an hour; refresh tokens
/// rotate (the presented one is spent), so a new pair is stored every refresh.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kAccess = 'accessToken';
  static const _kRefresh = 'refreshToken';

  final _storage = const FlutterSecureStorage();
  final _gql = GraphQLClient.instance;

  String? _accessToken;
  String? _refreshToken;
  Member? _member;
  Future<String?>? _refreshing;

  Member? get member => _member;
  bool get isLoggedIn => _member != null;

  /// Restore a saved session at app start.
  Future<void> init() async {
    _gql.tokenProvider = validAccessToken;
    try {
      _accessToken = await _storage.read(key: _kAccess);
      _refreshToken = await _storage.read(key: _kRefresh);
    } catch (_) {
      // Keystore can be unreadable after a backup restore; start logged out.
      await _clear();
    }
    _member = _accessToken == null ? null : _memberFromToken(_accessToken!);
    notifyListeners();
  }

  Future<void> login(String nick, String password) async {
    final data = await _gql.query(
      '''
      mutation (\$input: LoginInput!) { login(input: \$input) { accessToken refreshToken } }
      ''',
      variables: {
        'input': {'memberNick': nick.trim(), 'memberPassword': password},
      },
      authenticated: false,
    );
    await _saveTokens(data['login'] as Map<String, dynamic>);
  }

  Future<void> signup({
    required String nick,
    required String password,
    required String phone,
    required bool isAgent,
  }) async {
    final data = await _gql.query(
      '''
      mutation (\$input: MemberInput!) { signup(input: \$input) { accessToken refreshToken } }
      ''',
      variables: {
        'input': {
          'memberNick': nick.trim(),
          'memberPassword': password,
          'memberPhone': phone.trim(),
          'memberType': isAgent ? 'AGENT' : 'USER',
        },
      },
      authenticated: false,
    );
    await _saveTokens(data['signup'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refresh = _refreshToken;
    await _clear();
    notifyListeners();
    if (refresh != null) {
      // Best effort: revoke on the server too; the local session is already gone.
      unawaited(_gql
          .query(
            r'mutation ($t: String!) { logout(refreshToken: $t) }',
            variables: {'t': refresh},
            authenticated: false,
          )
          .catchError((_) => <String, dynamic>{}));
    }
  }

  /// Permanently deletes the account (same as on the website: the backend
  /// soft-deletes the member, revokes every session and retires their listings).
  Future<void> deleteAccount() async {
    final id = _member?.id;
    if (id == null) return;
    await _gql.query(
      r'mutation ($input: MemberUpdate!) { updateMember(input: $input) { _id memberStatus } }',
      variables: {
        'input': {'_id': id, 'memberStatus': 'DELETE'},
      },
    );
    // Server already revoked the refresh token; just drop the local session.
    await _clear();
    notifyListeners();
  }

  /// Access token for an API call, refreshed first if it expires within a minute.
  /// Returns null for guests, and logs out if the refresh token was rejected.
  Future<String?> validAccessToken() async {
    final token = _accessToken;
    if (token == null) return null;
    final exp = _expiry(token);
    if (exp == null || DateTime.now().isBefore(exp.subtract(const Duration(seconds: 60)))) return token;
    // One refresh at a time: the refresh token is single-use.
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh() async {
    final refresh = _refreshToken;
    if (refresh == null) {
      await logout();
      return null;
    }
    try {
      final data = await _gql.query(
        r'mutation ($t: String!) { refreshToken(refreshToken: $t) { accessToken refreshToken } }',
        variables: {'t': refresh},
        authenticated: false,
      );
      await _saveTokens(data['refreshToken'] as Map<String, dynamic>);
      return _accessToken;
    } on ApiException catch (e) {
      // Network trouble: keep the session and let the call go out as-is.
      if (e.isNetwork) return _accessToken;
      await logout(); // revoked / expired / reused
      return null;
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> pair) async {
    final access = pair['accessToken'] as String?;
    if (access == null || access.isEmpty) throw ApiException('Kirish amalga oshmadi.');
    _accessToken = access;
    _refreshToken = pair['refreshToken'] as String? ?? _refreshToken;
    _member = _memberFromToken(access);
    await _storage.write(key: _kAccess, value: _accessToken);
    if (_refreshToken != null) await _storage.write(key: _kRefresh, value: _refreshToken);
    notifyListeners();
  }

  Future<void> _clear() async {
    _accessToken = null;
    _refreshToken = null;
    _member = null;
    try {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
    } catch (_) {}
  }

  static Map<String, dynamic>? _payload(String token) {
    try {
      final part = token.split('.')[1];
      return jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(part)))) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _expiry(String token) {
    final exp = _payload(token)?['exp'];
    return exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000) : null;
  }

  static Member? _memberFromToken(String token) {
    final p = _payload(token);
    if (p == null || p['_id'] == null) return null;
    return Member(
      id: '${p['_id']}',
      nick: '${p['memberNick'] ?? ''}',
      phone: p['memberPhone'] as String?,
      image: p['memberImage'] as String?,
      type: p['memberType'] as String?,
      fullName: p['memberFullName'] as String?,
    );
  }
}
