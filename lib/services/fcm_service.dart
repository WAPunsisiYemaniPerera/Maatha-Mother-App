import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // get the device token for push notifications
    String? token = await _messaging.getToken();
    
    // copy the token to clipboard or send it to your server for testing
    print("========= DEVICE TOKEN =========");
    print(token);
    print("================================");
  }
}