import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants/app_colors.dart';
import '../repository/auth_repository.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  final String sessionToken;
  final bool requiresOnboarding;

  const TwoFactorScreen({
    super.key,
    required this.sessionToken,
    required this.requiresOnboarding,
  });

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _verify(String code) async {
    if (code.length != 6) return;
    setState(() { _loading = true; _error = null; });

    try {
      final result = await ref.read(authRepositoryProvider).verifyTwoFactor(
        widget.sessionToken,
        code,
      );

      if (!mounted) return;

      if (result.requiresOnboarding && result.twoFactorSessionToken != null) {
        context.go('/auth/onboarding', extra: result.twoFactorSessionToken);
        return;
      }

      if (result.token != null) {
        await ref.read(authRepositoryProvider).saveToken(result.token!);
        context.go('/entiteiten');
      }
    } catch (e) {
      setState(() => _error = 'Ongeldige code. Probeer opnieuw.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verificatie')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.security, size: 56, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Tweestapsverificatie',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Voer de 6-cijferige code in vanuit uw authenticator-app.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Pinput(
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyDecorationWith(
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              onCompleted: _loading ? null : _verify,
              enabled: !_loading,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
