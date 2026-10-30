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
    this.waiting = false,
  });
  final String id;
  final String name;
  final Map<String, Object?> data;
  final Map<String, Object?> summary;
  final String updated;

  /// Saved offline: kept on this device until the website can be reached
  final bool waiting;

  SavedCalculation waitingToSend() =>
      SavedCalculation(id: id, name: name, data: data, summary: summary, updated: updated, waiting: true);

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
    if (_user != null) _showKept();
    // signed in on this device before: the app opens at once (offline too) while the website is
    // asked. The web app may be signed in through the website: ask before showing the sign-in.
    checking = _user == null && (api.token != null || api.platform == 'web');
  }

  /// Still asking the website whether there is a sign-in (only when nobody is remembered here)
  bool checking = false;

  /// The list from the last refresh, kept on this device, with what is waiting
  void _showKept() {
    final kept = _store.readJson(_listKey)?['jobs'];
    _showList([if (kept is List) ...kept.map(SavedCalculation.from).whereType<SavedCalculation>()]);
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
    _showKept();
    notifyListeners();
    unawaited(refresh());
  }

  /// On start: is the remembered (or, on the web, the website's) sign-in still good?
  Future<void> restore() async {
    if (!checking && _user == null) return;
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
      // offline: keep the remembered account and its kept list; refused: sign out
      if (e.status == 401) {
        _forget();
      } else if (e.status == null && signedIn) {
        offline = true;
        notifyListeners();
      }
    } finally {
      if (checking) {
        checking = false;
        notifyListeners();
      }
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
    _onSite = const {};
    offline = false;
    _store.remove(_key);
    notifyListeners();
  }

  // ------------------------------------------------------------ saved calculations
  //
  // Saving and deleting work offline: what can't reach the website waits on this device (per
  // account) and is sent the next time the list is refreshed, a calculation is saved, the app
  // starts or comes back to the front, or "Send now" is pressed. The list from the last refresh is
  // kept too, so the Saved page still shows it without a connection.

  String get _waitingKey => 'waiting.${_user?.id}';
  String get _listKey => 'saved.${_user?.id}';

  List<Map<String, Object?>> _readWaiting() {
    final ops = _user == null ? null : _store.readJson(_waitingKey)?['ops'];
    return [if (ops is List) ...ops.whereType<Map<String, Object?>>()];
  }

  void _writeWaiting(List<Map<String, Object?>> ops) =>
      ops.isEmpty ? _store.remove(_waitingKey) : _store.writeJson(_waitingKey, {'ops': ops});

  /// Saves and deletes made offline, not yet sent to the website
  int get waiting => _readWaiting().length;

  /// The last refresh couldn't reach the website: the list is the one kept on this device
  bool offline = false;

  bool _sending = false;

  /// Why the website refused a waiting change, by change, for the save that is waiting on it
  final _refused = <String, String>{};

  /// The calculations the website had at the last refresh
  Set<String> _onSite = const {};

  static String _opKey(Map<String, Object?> op) => '${op['op']} ${op['id']} ${op['updated_at']}';

  /// Sends what is waiting, oldest first; stops at the first one that can't reach the website.
  /// A change the website refuses (too big, too many) is dropped and its reason shown.
  Future<void> sendWaiting() async {
    if (!signedIn || _sending) return;
    _sending = true;
    try {
      var ops = _readWaiting();
      while (ops.isNotEmpty) {
        final op = ops.first;
        final id = op['id']! as String;
        try {
          if (op['op'] == 'delete') {
            await api.call('DELETE', '/api/slope/jobs/$id');
          } else {
            await api.call('PUT', '/api/slope/jobs/$id', {
              'name': op['name'],
              'data': op['data'],
              'summary': op['summary'],
              'updated_at': op['updated_at'],
            });
          }
        } on ApiError catch (e) {
          if (e.status == null) {
            offline = true;
            return;
          }
          if (e.status == 401) {
            _forget();
            return;
          }
          _refused[_opKey(op)] = e.message;
          problem = '"${op['name'] ?? 'A calculation'}" was not sent: ${e.message}';
        }
        // read again: something may have been added while this one was sending
        ops = _readWaiting()..removeWhere((o) => _opKey(o) == _opKey(op));
        _writeWaiting(ops);
      }
    } finally {
      _sending = false;
    }
  }

  /// The website's list with what is waiting laid over it
  void _showList(List<SavedCalculation> fromSite) {
    _onSite = {for (final s in fromSite) s.id};
    final list = [...fromSite];
    for (final op in _readWaiting()) {
      final id = op['id'];
      list.removeWhere((s) => s.id == id);
      if (op['op'] == 'save') {
        final s = SavedCalculation.from(op);
        if (s != null) list.add(s.waitingToSend());
      }
    }
    list.sort((a, b) => b.updated.compareTo(a.updated));
    _saved = list;
  }

  Future<void> refresh() async {
    if (!signedIn) return;
    loading = true;
    problem = null;
    notifyListeners();
    try {
      await sendWaiting();
      if (!signedIn) return;
      final j = await api.call('GET', '/api/slope/jobs');
      final list = j['jobs'];
      final fromSite = [if (list is List) ...list.map(SavedCalculation.from).whereType<SavedCalculation>()];
      _store.writeJson(_listKey, {'jobs': list is List ? list : const []});
      offline = false;
      _showList(fromSite);
    } on ApiError catch (e) {
      if (e.status == 401) {
        _forget();
      } else if (e.status == null) {
        offline = true;
        _showKept();
      } else {
        problem = e.message;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Saves (or, with the same [id], replaces) a calculation in the account. True when the website
  /// has it; false when there was no connection and it waits on this device to be sent.
  Future<bool> save({
    String? id,
    required String name,
    required Map<String, Object?> data,
    Map<String, Object?> summary = const {},
  }) => _change({
    'op': 'save',
    'id': id ?? newId(),
    'name': name,
    'data': data,
    'summary': summary,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  });

  /// Deletes a calculation; offline, it is hidden now and deleted on the website later
  Future<bool> delete(String id) {
    final waiting = _readWaiting();
    final unsent = waiting.where((o) => o['id'] == id).toList();
    if (unsent.isNotEmpty && !_onSite.contains(id)) {
      // never reached the website: forget it here
      _writeWaiting(waiting..removeWhere((o) => o['id'] == id));
      _saved = [
        for (final s in _saved)
          if (s.id != id) s,
      ];
      notifyListeners();
      return Future.value(true);
    }
    return _change({'op': 'delete', 'id': id, 'updated_at': DateTime.now().toUtc().toIso8601String()});
  }

  Future<bool> _change(Map<String, Object?> op) async {
    if (!signedIn) throw ApiError('Sign in to keep calculations in your account.');
    final ops = _readWaiting()
      // a newer change to the same calculation replaces one still waiting
      ..removeWhere((o) => o['id'] == op['id'])
      ..add(op);
    _writeWaiting(ops);
    await refresh();
    final refused = _refused.remove(_opKey(op));
    if (refused != null) {
      problem = null;
      notifyListeners();
      throw ApiError(refused);
    }
    return !_readWaiting().any((o) => _opKey(o) == _opKey(op));
  }

  static String newId() {
    final r = math.Random.secure();
    return List.generate(20, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[r.nextInt(36)]).join();
  }
}
