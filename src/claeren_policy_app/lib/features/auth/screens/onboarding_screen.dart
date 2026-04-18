import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../repository/auth_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final String sessionToken;

  const OnboardingScreen({super.key, required this.sessionToken});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _geboortedatumCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();
  final _huisnummerCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _geboortedatumCtrl.dispose();
    _postcodeCtrl.dispose();
    _huisnummerCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final result = await ref.read(authRepositoryProvider).completeOnboarding(
        sessionToken: widget.sessionToken,
        geboortedatum: _geboortedatumCtrl.text.trim(),
        postcode: _postcodeCtrl.text.trim().toUpperCase(),
        huisnummer: _huisnummerCtrl.text.trim(),
      );

      if (!mounted) return;

      if (!result.success || result.token == null) {
        setState(() => _error = result.errorMessage ?? 'Gegevens komen niet overeen.');
        return;
      }

      await ref.read(authRepositoryProvider).saveToken(result.token!);
      context.go('/entiteiten');
    } catch (e) {
      setState(() => _error = 'Er is een fout opgetreden. Probeer opnieuw.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account activeren')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.person_add_outlined, size: 56, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Welkom! Activeer uw account',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vul uw gegevens in ter verificatie. Dit is eenmalig.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _geboortedatumCtrl,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Geboortedatum',
                  hintText: 'dd-MM-yyyy',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Verplicht veld' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _postcodeCtrl,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Postcode',
                  hintText: '1234AB',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Verplicht veld';
                  if (!RegExp(r'^\d{4}[A-Za-z]{2}$').hasMatch(v.trim())) {
                    return 'Voer een geldige postcode in (bijv. 5611AZ)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _huisnummerCtrl,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Huisnummer',
                  hintText: '1A',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Verplicht veld' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _complete,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Activeren'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
