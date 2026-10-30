import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client makeClient() => BrowserClient()..withCredentials = true;

/// On exceltokml.com the API is on the same site; anywhere else (testing) the live site
String defaultApiBase() {
  const fixed = String.fromEnvironment('API_BASE');
  if (fixed.isNotEmpty) return fixed;
  final here = Uri.base;
  return here.host.endsWith('exceltokml.com') ? here.origin : 'https://www.exceltokml.com';
}
