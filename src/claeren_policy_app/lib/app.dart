import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_router.dart';
import 'core/theme/app_theme.dart';

class ClaerenApp extends ConsumerWidget {
  const ClaerenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Claeren',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      locale: const Locale('nl'),
      supportedLocales: const [Locale('nl'), Locale('en')],
    );
  }
}
