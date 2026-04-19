import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../repository/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final result = await ref.read(authRepositoryProvider).login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;

      if (result.requiresTwoFactor && result.twoFactorSessionToken != null) {
        context.push('/auth/2fa', extra: {
          'sessionToken': result.twoFactorSessionToken,
          'requiresOnboarding': result.requiresOnboarding,
        });
      }
    } catch (e) {
      setState(() => _error = 'Ongeldige inloggegevens. Probeer opnieuw.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildLogo(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Inloggen',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Voer uw gegevens in om verder te gaan.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          height: 56,
                          color: Colors.red,
                          alignment: Alignment.center,
                          child: const Text('EMAIL VELD', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 56,
                          color: Colors.blue,
                          alignment: Alignment.center,
                          child: const Text('WACHTWOORD VELD', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          height: 52,
                          color: Colors.green,
                          alignment: Alignment.center,
                          child: const Text('INLOGGEN KNOP', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() => Column(
        children: [
          const Icon(Icons.shield_outlined, size: 64, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            'Claeren',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Verzekeringen & Advies',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white70),
          ),
        ],
      );
}
