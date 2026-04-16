import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase Messaging is uitgecommentarieerd omdat het google-services.json / GoogleService-Info.plist
// vereist. Activeer door:
// 1. firebase_messaging toe te voegen aan pubspec.yaml
// 2. google-services.json (Android) en GoogleService-Info.plist (iOS) te plaatsen
// 3. De onderstaande imports te activeren

// import 'package:firebase_messaging/firebase_messaging.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  // FCM token voor deze installatie — stuur naar de BFF zodat die
  // push notificaties kan versturen bij events vanuit CCS Level 7.
  Future<String?> getFcmToken() async {
    // return await FirebaseMessaging.instance.getToken();
    return null; // activeer na Firebase setup
  }

  Future<void> initialize(BuildContext context) async {
    // FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // Foreground berichten tonen als snackbar
    // FirebaseMessaging.onMessage.listen((message) {
    //   if (context.mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text(message.notification?.body ?? 'Nieuw bericht')),
    //     );
    //   }
    // });

    // App openen vanuit notificatie — navigeer naar het juiste scherm
    // FirebaseMessaging.onMessageOpenedApp.listen((message) {
    //   _handleNavigation(message.data);
    // });
  }

  // Registreer FCM token bij de BFF zodat de server kan pushen
  Future<void> registerToken(String fcmToken, String authToken) async {
    // await apiClient.post('/api/notifications/register', data: {'fcmToken': fcmToken});
  }

  // Notificatie type bepaalt naar welk scherm de app navigeert
  void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    // ignore: unused_local_variable
    final referentieId = data['referentieId'] as String?;

    switch (type) {
      case 'NieuwDocument':
        // navigeer naar documenten tab van de betreffende polis
        break;
      case 'NaverrekenUitvraag':
        // navigeer naar naverrrekening scherm
        break;
      case 'OfferteOndertekenen':
      case 'SluitverklaringInvullen':
        // navigeer naar taken scherm (fase 4)
        break;
      case 'ClaimUpdate':
        // navigeer naar claims scherm
        break;
    }
  }
}
