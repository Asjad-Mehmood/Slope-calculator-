// The HTTP client: on the web it sends the website's sign-in cookie (the app is served from
// exceltokml.com), elsewhere a plain client with a Bearer token.
export 'http_client_io.dart' if (dart.library.js_interop) 'http_client_web.dart';
