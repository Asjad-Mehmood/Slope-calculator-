import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:slope_calculator/src/account/account.dart';
import 'package:slope_calculator/src/account/api.dart';
import 'package:slope_calculator/src/app.dart';
import 'package:slope_calculator/src/state/store.dart';

/// A pretend exceltokml.com: the routes the app uses, with one account and its saved calculations.
class FakeSite {
  final jobs = <String, Map<String, Object?>>{};
  final requests = <http.Request>[];
  bool confirmed = false;
  bool approved = false;
  static const user = {'id': 'u1', 'email': 'sam@site.com', 'name': 'Sam Surveyor'};

  late final client = MockClient((r) async {
    requests.add(r);
    final body = r.body.isEmpty ? <String, Object?>{} : jsonDecode(r.body) as Map<String, Object?>;
    http.Response json(Object o, [int status = 200]) =>
        http.Response(jsonEncode(o), status, headers: {'content-type': 'application/json'});
    final signedIn = r.headers['Authorization'] == 'Bearer tok-1';
    switch ((r.method, r.url.path)) {
      case ('GET', '/api/auth/me'):
        return json({'user': signedIn ? user : null});
      case ('POST', '/api/auth/login'):
        if (body['password'] != 'right') return json({'error': 'Wrong email or password.'}, 401);
        if (!confirmed) {
          return json({
            'success': false,
            'verifyRequired': true,
            'challenge': 'ch-1',
            'sentTo': 's***@site.com',
            'error': 'Confirm your email',
          }, 403);
        }
        return json({'success': true, 'token': 'tok-1', 'user': user});
      case ('POST', '/api/auth/verify-email'):
        if (body['code'] != '123456') return json({'error': 'That code is not right.'}, 400);
        confirmed = true;
        return json({'success': true, 'token': 'tok-1', 'user': user});
      case ('POST', '/api/auth/device/start'):
        return json({'success': true, 'code': 'ABCD-EFGH', 'poll': 'poll-secret', 'url': '/link'});
      case ('POST', '/api/auth/device/poll'):
        return approved
            ? json({'success': true, 'token': 'tok-1', 'user': user})
            : json({'success': true, 'state': 'pending'});
      case ('POST', '/api/auth/logout'):
        return json({'success': true});
      case ('GET', '/api/slope/jobs'):
        if (!signedIn) return json({'error': 'Sign in'}, 401);
        return json({'success': true, 'jobs': jobs.values.toList()});
    }
    final id = r.url.pathSegments.length == 4 ? r.url.pathSegments.last : null;
    if (id != null && r.url.path.startsWith('/api/slope/jobs/')) {
      if (!signedIn) return json({'error': 'Sign in'}, 401);
      if (r.method == 'PUT') {
        jobs[id] = {
          'id': id,
          'name': body['name'],
          'data': body['data'],
          'summary': body['summary'],
          'updated_at': body['updated_at'],
        };
        return json({'success': true});
      }
      if (r.method == 'DELETE') {
        jobs.remove(id);
        return json({'success': true});
      }
    }
    return json({'error': 'Not found'}, 404);
  });

  Api api() => Api(base: 'https://site.test', client: client);
}

void main() {
  group('signing in', () {
    test('an unconfirmed email asks for the code, then signs in with a token', () async {
      final site = FakeSite();
      final a = Account(site.api(), Store.memory());
      final code = await a.signIn('Sam@Site.com ', 'right');
      expect(code, isNotNull);
      expect(code!.sentTo, 's***@site.com');
      expect(a.signedIn, isFalse);
      await expectLater(a.confirmEmail(code, '000000'), throwsA(isA<ApiError>()));
      await a.confirmEmail(code, '123456');
      expect(a.signedIn, isTrue);
      expect(a.user!.display, 'Sam Surveyor');
      expect(a.api.token, 'tok-1');
      expect(
        jsonDecode(site.requests.firstWhere((r) => r.url.path == '/api/auth/login').body)['email'],
        'sam@site.com',
      );
    });

    test('a wrong password says so', () async {
      final a = Account(FakeSite().api(), Store.memory());
      await expectLater(
        a.signIn('sam@site.com', 'wrong'),
        throwsA(predicate((e) => '$e' == 'Wrong email or password.')),
      );
    });

    test('remembered between starts, and checked with the website', () async {
      final site = FakeSite()..confirmed = true;
      final store = Store.memory();
      await Account(site.api(), store).signIn('sam@site.com', 'right');
      final again = Account(site.api(), store);
      expect(again.signedIn, isTrue);
      await again.restore();
      expect(again.signedIn, isTrue);
      expect(site.requests.last.headers['Authorization'], 'Bearer tok-1');
    });

    test('sent with the app name, platform and version', () async {
      final site = FakeSite()..confirmed = true;
      await Account(site.api(), Store.memory()).signIn('sam@site.com', 'right');
      final h = site.requests.first.headers;
      expect(h['X-App-Name'], 'slope');
      expect(h['X-App-Platform'], 'windows');
      expect(h['X-App-Version'], isNotEmpty);
    });

    test('through the browser: a code to confirm, then signed in', () async {
      final site = FakeSite();
      final a = Account(site.api(), Store.memory());
      final s = await a.startBrowserSignIn();
      expect(s.code, 'ABCD-EFGH');
      expect(s.url, 'https://site.test/link?code=ABCD-EFGH');
      expect(await a.checkBrowserSignIn(s), isFalse);
      site.approved = true;
      expect(await a.checkBrowserSignIn(s), isTrue);
      expect(a.signedIn, isTrue);
    });

    test('offline: the remembered account stays', () async {
      final store = Store.memory()..writeJson('account', {'token': 'tok-1', 'user': FakeSite.user});
      final offline = Api(
        base: 'https://site.test',
        client: MockClient((_) async => throw http.ClientException('no network')),
      );
      final a = Account(offline, store);
      await a.restore();
      expect(a.signedIn, isTrue);
    });

    test('a token the website refuses signs out', () async {
      final store = Store.memory()..writeJson('account', {'token': 'old', 'user': FakeSite.user});
      final a = Account(FakeSite().api(), store);
      await a.restore();
      expect(a.signedIn, isFalse);
      expect(store.readJson('account'), isNull);
    });

    test('sign out forgets the token', () async {
      final store = Store.memory();
      final a = Account((FakeSite()..confirmed = true).api(), store);
      await a.signIn('sam@site.com', 'right');
      await a.signOut();
      expect(a.signedIn, isFalse);
      expect(a.api.token, isNull);
      expect(store.readJson('account'), isNull);
    });
  });

  test('save, list and delete calculations', () async {
    final site = FakeSite()..confirmed = true;
    final a = Account(site.api(), Store.memory());
    await a.signIn('sam@site.com', 'right');
    await a.save(
      name: 'Ring Road',
      data: {
        'calculation': {'y1': '1'},
      },
      summary: {'percent': -1.5},
    );
    expect(a.saved.single.name, 'Ring Road');
    expect(a.saved.single.summary['percent'], -1.5);
    expect(RegExp(r'^[a-z0-9]{20}$').hasMatch(a.saved.single.id), isTrue);
    await a.delete(a.saved.single.id);
    expect(a.saved, isEmpty);
    expect(site.jobs, isEmpty);
  });

  testWidgets('the Saved page: sign in, save the calculation, open it again', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final site = FakeSite()..confirmed = true;
    await tester.pumpWidget(SlopeCalculatorApp(store: Store.memory(), api: site.api()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in').first);
    await tester.pumpAndSettle();
    expect(find.text('YOUR EXCEL TO KML ACCOUNT'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'sam@site.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'right');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Sam Surveyor'), findsWidgets);

    await tester.tap(find.text('Save the current calculation'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Test line');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Test line'), findsOneWidget);
    expect((site.jobs.values.single['data']! as Map)['calculation'], containsPair('y1', '102.500'));

    // change the calculator, then open the saved one: the boxes come back
    site.jobs.values.single['data'] = {
      'calculation': {'y1': '50', 'y2': '51', 'x1': '0', 'x2': '100', 'interval': '20', 'decimals': 3},
      'plate': {'project': 'Opened job'},
    };
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('ENTER YOUR DATA'), findsOneWidget);
    expect(find.text('+1.000 %'), findsOneWidget);
    expect(find.text('Opened job'), findsOneWidget);
  });
}
