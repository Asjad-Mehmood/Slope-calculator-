import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client makeClient() => BrowserClient()..withCredentials = true;

/// On exceltokml.com (or a copy of the website running on this computer) the API is on the same
/// site; anywhere else the live site
String defaultApiBase() {
  const fixed = String.fromEnvironment('API_BASE');
  if (fixed.isNotEmpty) return fixed;
  final here = Uri.base;
  final local = here.host == 'localhost' || here.host == '127.0.0.1';
  return here.host.endsWith('exceltokml.com') || local ? here.origin : 'https://www.exceltokml.com';
}
