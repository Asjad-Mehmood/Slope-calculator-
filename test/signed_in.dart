import 'package:slope_calculator/src/state/store.dart';

/// A device where someone signed in before: the app opens straight to the calculator
Store signedInStore([Store? store]) => (store ?? Store.memory())
  ..writeJson('account', {
    'token': 'tok-test',
    'user': {'id': 'u-test', 'email': 'sam@site.com', 'name': 'Sam Surveyor'},
  });
