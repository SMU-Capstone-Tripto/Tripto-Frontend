import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// 💡 백그라운드(앱이 꺼져있을 때)에서 알림을 수신하는 핸들러 (반드시 최상단 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("백그라운드 메시지 수신: ${message.messageId}");
}

class FCMService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Firebase 초기화
    await Firebase.initializeApp();

    // 2. 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. 알림 권한 요청 (안드로이드 13 이상 필수)
    NotificationSettings notificationSettings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('푸시 권한 상태: ${notificationSettings.authorizationStatus}');

    // 4. 안드로이드 포그라운드(앱이 켜져있을 때) 알림을 위한 채널 설정
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      '중요 알림', // name
      description: '앱이 켜져 있을 때 표시되는 중요 알림입니다.',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 로컬 알림 초기화 세팅
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    // 🛠️ 에러 완벽 해결: 정확한 파라미터명인 'settings'를 사용합니다.
    await _localNotificationsPlugin.initialize(
      settings: initSettings,
    );

    // 앱이 포그라운드에 있을 때 푸시 알림이 오면 시스템 알림(헤드업)으로 띄워줌
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. 앱이 켜져있을 때 알림 수신 이벤트
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('포그라운드 메시지 수신: ${message.notification?.title}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 6. FCM 기기 고유 토큰 발급
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint("====================================");
    debugPrint("📱 내 FCM 기기 토큰: $fcmToken");
    debugPrint("====================================");
  }

  // 💡 새롭게 추가된 수동 로컬 알림 함수
  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      '중요 알림',
      channelDescription: '앱 내부 동작에 의한 알림입니다.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}

