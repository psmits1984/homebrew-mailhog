class LoginResponse {
  final bool requiresTwoFactor;
  final bool requiresOnboarding;
  final String? token;
  final String? twoFactorSessionToken;

  const LoginResponse({
    required this.requiresTwoFactor,
    required this.requiresOnboarding,
    this.token,
    this.twoFactorSessionToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        requiresTwoFactor: json['requiresTwoFactor'] as bool,
        requiresOnboarding: json['requiresOnboarding'] as bool,
        token: json['token'] as String?,
        twoFactorSessionToken: json['twoFactorSessionToken'] as String?,
      );
}

class OnboardingResponse {
  final bool success;
  final String? token;
  final String? errorMessage;

  const OnboardingResponse({
    required this.success,
    this.token,
    this.errorMessage,
  });

  factory OnboardingResponse.fromJson(Map<String, dynamic> json) => OnboardingResponse(
        success: json['success'] as bool,
        token: json['token'] as String?,
        errorMessage: json['errorMessage'] as String?,
      );
}
