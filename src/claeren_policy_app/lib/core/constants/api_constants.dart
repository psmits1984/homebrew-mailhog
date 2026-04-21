import 'env.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl => Env.apiBaseUrl;

  static const String login = '/api/auth/login';
  static const String twoFactor = '/api/auth/2fa/verify';
  static const String onboarding = '/api/auth/onboarding/complete';
  static const String entiteiten = '/api/entiteiten';

  static String polissen(String entityId) => '/api/entiteiten/$entityId/polissen';
  static String polisDetail(String entityId, String polisNummer) =>
      '/api/entiteiten/$entityId/polissen/$polisNummer';
  static String betalingen(String entityId) => '/api/entiteiten/$entityId/betalingen';
  static String claims(String entityId) => '/api/entiteiten/$entityId/claims';
  static String naverrrekening(String entityId) => '/api/entiteiten/$entityId/naverrrekening';
  static String navAntwoorden(String entityId, String uitvraagId) =>
      '/api/entiteiten/$entityId/naverrrekening/$uitvraagId/antwoorden';
  static const String machtigingen = '/api/machtigingen';

  // Offertes
  static String offertes(String entityId) =>
      '/api/entiteiten/$entityId/offertes';
  static String offerteDetail(String id) => '/api/offertes/$id';
  static String offerteAccorderen(String id) => '/api/offertes/$id/accorderen';
  static String offerteWeigeren(String id) => '/api/offertes/$id/weigeren';

  // Compliance / VNAB
  static const String complianceCheck = '/api/compliance/check';
  static const String complianceUbo = '/api/compliance/ubo';
  static String complianceStatus(String entityId) =>
      '/api/compliance/$entityId/status';

  // Slotverklaring
  static String slotverklaringOtp(String offerteId) =>
      '/api/slotverklaringen/$offerteId/otp';
  static String slotverklaringOndertekenen(String offerteId) =>
      '/api/slotverklaringen/$offerteId/ondertekenen';
}
