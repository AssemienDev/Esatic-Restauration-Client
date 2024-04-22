import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService{
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();


  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettings = const AndroidInitializationSettings('resto_logo');

    var initializationSettingsIos = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? playload) async {});

    var initializationSettings2 = InitializationSettings(
      android: initializationSettings, iOS: initializationSettingsIos
    );

    await notificationsPlugin.initialize(initializationSettings2,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {});

  }

  Future showNotif({int id=0, String? title, String? body, String? playload}) async{
    return notificationsPlugin.show(id, title, body,await notificationDetails());
  }

  notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails('channelId', 'channelName', importance: Importance.max), iOS: DarwinNotificationDetails()
    );
  }

}