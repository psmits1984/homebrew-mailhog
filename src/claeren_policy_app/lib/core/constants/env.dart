// Geef de omgeving mee via --dart-define bij het builden:
// flutter run --dart-define=ENV=production --dart-define=API_URL=https://bff.claeren.nl
//
// Zonder --dart-define valt de app terug op development defaults.

class Env {
  Env._();

  static const String _env = String.fromEnvironment('ENV', defaultValue: 'development');
  static const String _apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000',
  );
  static const String _fcmSenderId = String.fromEnvironment('FCM_SENDER_ID', defaultValue: '');

  static bool get isProduction => _env == 'production';
  static bool get isDevelopment => _env == 'development';

  static String get apiBaseUrl => _apiUrl;
  static String get fcmSenderId => _fcmSenderId;
}
