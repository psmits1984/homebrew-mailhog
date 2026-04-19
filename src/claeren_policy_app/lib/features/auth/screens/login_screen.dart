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
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _usernameError = _usernameCtrl.text.trim().isEmpty ? 'Vul uw e-mailadres in' : null;
      _passwordError = _passwordCtrl.text.isEmpty ? 'Vul uw wachtwoord in' : null;
    });
    return _usernameError == null && _passwordError == null;
  }

  Future<void> _login() async {
    if (!_validate()) return;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Inloggen', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Voer uw gegevens in om verder te gaan.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 32),
                      _buildInputField(
                        controller: _usernameCtrl,
                        focusNode: _usernameFocus,
                        hint: 'E-mailadres',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        errorText: _usernameError,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        hint: 'Wachtwoord',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        errorText: _passwordError,
                        prefixIcon: Icons.lock_outlined,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ],
                      const SizedBox(height: 32),
                      _buildLoginButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    bool obscureText = false,
    String? errorText,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: errorText != null ? AppColors.error : const Color(0xFFD1D5DB),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  const SizedBox(width: 12),
                  Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    onSubmitted: onSubmitted,
                    obscureText: obscureText,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (suffix != null) suffix,
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _loading ? null : _login,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _loading ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Inloggen',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Verzekeringen & Advies',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      );
}
