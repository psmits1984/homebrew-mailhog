// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;

Future<String?> getWebInitialToken() async {
  final jwt = js.context['__claeren_jwt'];
  if (jwt == null) return null;
  final value = jwt.toString();
  return value.isEmpty ? null : value;
}

void clearWebInitialToken() {
  js.context['__claeren_jwt'] = null;
}

void openUrl(String url) {
  js.context.callMethod('open', [url, '_blank']);
}
