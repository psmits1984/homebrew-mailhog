import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/platform/web_init.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web: read JWT from HTML login form (stored in window.__claeren_jwt)
  final webToken = await getWebInitialToken();
  if (webToken != null) {
    await SecureStorage().saveToken(webToken);
    clearWebInitialToken();
  }

  runApp(const ProviderScope(child: ClaerenApp()));
}
