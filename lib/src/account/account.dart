// The Excel to KML account in the app: sign in or create an account (with the 6-digit code the
// website emails), sign in through the browser (Google and saved passwords work there), and the
// calculations kept in the account.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../state/store.dart';
import 'api.dart';

class AccountUser {
  const AccountUser({required this.id, required this.email, required this.name});
  final String id;
  final String email;
  final String name;

  static AccountUser? from(Object? j) {
    if (j is! Map<String, Object?>) return null;
    final id = j['id'], email = j['email'];
    if (id is! String || email is! String) return null;
    return AccountUser(id: id, email: email.toLowerCase(), name: (j['name'] as String?) ?? '');
  }

  Map<String, Object?> toJson() => {'id': id, 'email': email, 'name': name};
  String get display => name.isNotEmpty ? name : email;
}

/// The website wants the emailed code before the account can be used
class EmailCode {
  const EmailCode(this.challenge, this.sentTo);
  final String challenge;
  final String sentTo;
}

/// A saved calculation, as the website keeps it
class SavedCalculation {
  const SavedCalculation({
    required this.id,
    required this.name,
    required this.data,
    required this.summary,
    required this.updated,
  });
  final String id;
  final String name;
  final Map<String, Object?> data;
  final Map<String, Object?> summary;
  final String updated;

  static SavedCalculation? from(Object? j) {
    if (j is! Map<String, Object?>) return null;
    final id = j['id'], name = j['name'], data = j['data'];
    if (id is! String || name is! String || data is! Map<String, Object?>) return null;
    final summary = j['summary'];
    return SavedCalculation(
      id: id,
      name: name,
      data: data,
      summary: summary is Map<String, Object?> ? summary : const {},
      updated: (j['updated_at'] as String?) ?? '',
    );
  }
}

/// A browser sign-in in progress: the code to confirm at [url]
class BrowserSignIn {
  const BrowserSignIn({required this.code, required this.url, required this.poll});
  final String code;
  final String url;
  final String poll;
}

class Account extends ChangeNotifier {
  Account(this.api, this._store) {
    final j = _store.readJson(_key);
    api.token = j?['token'] as String?;
    _user = AccountUser.from(j?['user']);
  }

  final Api api;
  final Store _store;
  static const _key = 'account';

  AccountUser? _user;
  AccountUser? get user => _user;
  bool get signedIn => _user != null;

  List<SavedCalculation> _saved = const [];
  List<SavedCalculation> get saved => _saved;
  bool loading = false;
  String? problem;

  void _remember() =>
      _store.writeJson(_key, {if (api.token != null) 'token': api.token, if (_user != null) 'user': _user!.toJson()});

  void _signedIn(Map<String, Object?> j) {
    final user = AccountUser.from(j['user']);
    if (user == null) throw ApiError('The website answered without an account. Please try again.');
    if (j['token'] is String) api.token = j['token'] as String;
    _user = user;
    _remember();
    notifyListeners();
    unawaited(refresh());
  }

  /// On start: is the remembered (or, on the web, the website's) sign-in still good?
  Future<void> restore() async {
    try {
      final j = await api.call('GET', '/api/auth/me');
      final user = AccountUser.from(j['user']);
      if (user == null) {
        if (_user != null) {
          _forget();
        }
        return;
      }
      _user = user;
      _remember();
      notifyListeners();
      await refresh();
    } on ApiError catch (e) {
      // offline: keep the remembered account; refused: sign out
      if (e.status == 401) _forget();
    }
  }

  /// Signs in; returns the code challenge when the email still has to be confirmed
  Future<EmailCode?> signIn(String email, String password) async {
    try {
      _signedIn(await api.call('POST', '/api/auth/login', {'email': email.trim().toLowerCase(), 'password': password}));
      return null;
    } on ApiError catch (e) {
      if (!e.needsEmailCode) rethrow;
      return EmailCode(e.data['challenge']! as String, (e.data['sentTo'] as String?) ?? 'your email');
    }
  }

  /// Creates the account; the website then emails a code (returned) to confirm it
  Future<EmailCode?> register({
    required String name,
    required String email,
    required String password,
    String? company,
  }) async {
    try {
      _signedIn(
        await api.call('POST', '/api/auth/register', {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          if (company != null && company.trim().isNotEmpty) 'organization': company.trim(),
        }),
      );
      return null;
    } on ApiError catch (e) {
      if (!e.needsEmailCode) rethrow;
      return EmailCode(e.data['challenge']! as String, (e.data['sentTo'] as String?) ?? 'your email');
    }
  }

  Future<void> confirmEmail(EmailCode c, String code) async =>
      _signedIn(await api.call('POST', '/api/auth/verify-email', {'challenge': c.challenge, 'code': code.trim()}));

  Future<EmailCode> resendCode(EmailCode c) async {
    final j = await api.call('POST', '/api/auth/resend-verify', {'challenge': c.challenge});
    return EmailCode((j['challenge'] as String?) ?? c.challenge, (j['sentTo'] as String?) ?? c.sentTo);
  }

  Future<void> forgotPassword(String email) =>
      api.call('POST', '/api/auth/forgot-password', {'email': email.trim().toLowerCase()});

  /// Starts a sign-in to confirm in the browser (where Google sign-in works)
  Future<BrowserSignIn> startBrowserSignIn() async {
    final j = await api.call('POST', '/api/auth/device/start', {'app': 'Slope Calculator'});
    final code = j['code'], poll = j['poll'];
    if (code is! String || poll is! String) throw ApiError('The website could not start a sign-in. Please try again.');
    final url = (j['url'] as String?) ?? '/link';
    return BrowserSignIn(code: code, poll: poll, url: url.startsWith('http') ? url : '${api.base}$url?code=$code');
  }

  /// Asks once whether the browser sign-in was confirmed: true when signed in, false to ask again,
  /// an [ApiError] when the code expired
  Future<bool> checkBrowserSignIn(BrowserSignIn s) async {
    final j = await api.call('POST', '/api/auth/device/poll', {'poll': s.poll});
    if (j['user'] != null) {
      _signedIn(j);
      return true;
    }
    if (j['state'] == 'expired' || j['state'] == 'denied') {
      throw ApiError('The sign-in code ran out. Start again.');
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      await api.call('POST', '/api/auth/logout');
    } on ApiError {
      // signed out on this device anyway
    }
    _forget();
  }

  void _forget() {
    api.token = null;
    _user = null;
    _saved = const [];
    _store.remove(_key);
    notifyListeners();
  }

  // ------------------------------------------------------------ saved calculations

  Future<void> refresh() async {
    if (!signedIn) return;
    loading = true;
    problem = null;
    notifyListeners();
    try {
      final j = await api.call('GET', '/api/slope/jobs');
      final list = j['jobs'];
      _saved = [if (list is List) ...list.map(SavedCalculation.from).whereType<SavedCalculation>()];
    } on ApiError catch (e) {
      problem = e.message;
      if (e.status == 401) _forget();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Saves (or, with the same [id], replaces) a calculation in the account
  Future<void> save({
    String? id,
    required String name,
    required Map<String, Object?> data,
    Map<String, Object?> summary = const {},
  }) async {
    final key = id ?? newId();
    await api.call('PUT', '/api/slope/jobs/$key', {
      'name': name,
      'data': data,
      'summary': summary,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    await refresh();
  }

  Future<void> delete(String id) async {
    await api.call('DELETE', '/api/slope/jobs/$id');
    _saved = [
      for (final s in _saved)
        if (s.id != id) s,
    ];
    notifyListeners();
  }

  static String newId() {
    final r = math.Random.secure();
    return List.generate(20, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[r.nextInt(36)]).join();
  }
}
