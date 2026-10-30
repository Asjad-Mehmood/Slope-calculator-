import 'package:http/http.dart' as http;

http.Client makeClient() => http.Client();

/// The website's address for this app
String defaultApiBase() => const String.fromEnvironment('API_BASE', defaultValue: 'https://www.exceltokml.com');
