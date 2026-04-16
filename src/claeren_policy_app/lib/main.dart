import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/constants/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Activeer Firebase initialisatie als FCM geconfigureerd is
  // if (Env.fcmSenderId.isNotEmpty) await Firebase.initializeApp(...);

  debugPrint('Omgeving: ${Env.isProduction ? "productie" : "development"}');
  debugPrint('API: ${Env.apiBaseUrl}');

  runApp(const ProviderScope(child: ClaerenApp()));
}
