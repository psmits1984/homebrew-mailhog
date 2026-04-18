import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/constants/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  debugPrint('Omgeving: ${Env.isProduction ? "productie" : "development"}');
  debugPrint('API: ${Env.apiBaseUrl}');

  runApp(const ProviderScope(child: ClaerenApp()));
}
