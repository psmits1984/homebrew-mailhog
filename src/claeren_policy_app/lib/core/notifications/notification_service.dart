import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  Future<String?> getFcmToken() async {
    // return await FirebaseMessaging.instance.getToken();
    return null;
  }

  Future<void> initialize(BuildContext context) async {
    // Activeer na Firebase setup:
    // FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    // FirebaseMessaging.onMessage.listen((message) { ... });
    // FirebaseMessaging.onMessageOpenedApp.listen((message) { ... });
  }

  Future<void> registerToken(String fcmToken, String authToken) async {
    // await apiClient.post('/api/notifications/register', data: {'fcmToken': fcmToken});
  }
}
