// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Reads the JWT that the HTML login form stored in window.__claeren_jwt.
/// Returns null if no token is present.
Future<String?> getWebInitialToken() async {
  final dynamic jwt = html.window.context['__claeren_jwt'];
  if (jwt == null) return null;
  final value = jwt.toString();
  return value.isEmpty ? null : value;
}

/// Clears window.__claeren_jwt after Flutter has safely stored the token.
void clearWebInitialToken() {
  html.window.context['__claeren_jwt'] = null;
}
