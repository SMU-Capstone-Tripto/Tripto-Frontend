import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

import 'src/routing/app_router.dart';
import 'src/constants/app_theme.dart';
import 'src/core/auth_storage.dart';
import 'src/core/network/token_storage.dart';

import 'src/features/home/domain/notification_model.dart';
import 'src/features/home/presentation/notification_provider.dart';
import 'package:firebase_core/firebase_core.dart';

void initFCMListener(WidgetRef ref) {
  // 포그라운드 상태에서 FCM 메시지를 수신할 때 실행
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data.isNotEmpty) {
      try {
        // 서버에서 전달된 데이터 payload를 NotificationModel로 변환
        final newNoti = NotificationModel.fromJson(message.data);

        // 실시간 알림 리스트 맨 위에 추가 및 뱃지 갱신
        ref
            .read(notificationProvider.notifier)
            .addRealtimeNotification(newNoti);
      } catch (e) {
        print('FCM 알림 파싱 에러: $e');
      }
    }
  });
}

void initWebSocketListener(WebSocketChannel channel, WidgetRef ref) {
  channel.stream.listen(
    (message) {
      try {
        // 수신한 문자열 데이터를 JSON으로 디코딩
        final Map<String, dynamic> data = jsonDecode(message);

        // 알림 데이터 형식인지 확인 후 모델로 변환
        final newNoti = NotificationModel.fromJson(data);

        // 실시간 알림 리스트 맨 위에 추가 및 뱃지 갱신
        ref
            .read(notificationProvider.notifier)
            .addRealtimeNotification(newNoti);
      } catch (e) {
        print('웹소켓 알림 데이터 파싱 에러: $e');
      }
    },
    onError: (error) {
      print('웹소켓 연결 에러: $error');
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // await Firebase.initializeApp();

  // 🎯 [토큰 자동 복구 로직]: 디스크에 저장된 최신 토큰을 읽어서 AuthStorage 메모리에 수혈
  try {
    final savedAccessToken = await TokenStorage.getAccessToken();
    final savedRefreshToken = await TokenStorage.getRefreshToken();

    if (savedAccessToken != null && savedAccessToken.isNotEmpty) {
      AuthStorage.accessToken = savedAccessToken;
      AuthStorage.refreshToken = savedRefreshToken;
      debugPrint('🟢 [앱 시작] 저장된 토큰 AuthStorage 동기화 성공!');
    }
  } catch (e) {
    debugPrint('⚠️ [앱 시작] 토큰 초기화 실패: $e');
  }

  // 네이버 지도 SDK 초기화
  await NaverMapSdk.instance.initialize(
    clientId: dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '',
    onAuthFailed: (ex) => print('네이버 지도 인증 오류: $ex'),
  );

  // 카카오 로그인 SDK 공식 초기화
  KakaoSdk.init(
    javaScriptAppKey: dotenv.env['KAKAO_JS_KEY'] ?? '',
  );

  runApp(const ProviderScope(child: TriptoApp()));
}

// 1. ConsumerWidget을 ConsumerStatefulWidget으로 변경하여 initState 사용 가능하게 수정
class TriptoApp extends ConsumerStatefulWidget {
  const TriptoApp({super.key});

  @override
  ConsumerState<TriptoApp> createState() => _TriptoAppState();
}

class _TriptoAppState extends ConsumerState<TriptoApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🟢 푸시 알림 권한 허용됨');
      }

      // 포그라운드 메시지 수신 리스너 실행
      initFCMListener(ref);
    } catch (e) {
      debugPrint('⚠️ FCM 초기화 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Tripto App',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      locale: const Locale('ko', 'KR'),
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
