// ignore: depend_on_referenced_packages
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationServices {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: true,
      announcement: true,
      provisional: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User denied permission');
    }
  }

  Future<String> getDeviceToken() async {
    String? token = await messaging.getToken();
    return token ?? '';
  }

  void isTokenrefreshed() async {
    messaging.onTokenRefresh.listen((event) {
      event.toString();
    });
  }
}
