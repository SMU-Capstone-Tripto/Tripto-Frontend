import 'package:flutter/material.dart';
import 'package:tripto/src/core/fcm_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

import 'src/routing/app_router.dart';
import 'src/constants/app_theme.dart';
import 'src/core/auth_storage.dart';
import 'src/core/network/token_storage.dart';

import 'src/features/home/domain/notification_model.dart';
import 'src/features/home/presentation/notification_provider.dart';

// 💡 포그라운드 상태에서 FCM 메시지를 수신할 때 실행
void initFCMListener(WidgetRef ref) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data.isNotEmpty) {
      try {
        final newNoti = NotificationModel.fromJson(message.data);
        ref
            .read(notificationProvider.notifier)
            .addRealtimeNotification(newNoti);
      } catch (e) {
        debugPrint('FCM 알림 파싱 에러: $e');
      }
    }
  });
}

void initWebSocketListener(WebSocketChannel channel, WidgetRef ref) {
  channel.stream.listen(
    (message) {
      try {
        final Map<String, dynamic> data = jsonDecode(message);
        final newNoti = NotificationModel.fromJson(data);

        // 기존 상태 업데이트 코드는 유지합니다.
        ref
            .read(notificationProvider.notifier)
            .addRealtimeNotification(newNoti);

        // 💡 추가된 부분: 웹소켓 메시지 타입이 봇 상태나 에러일 때 로컬 알림을 띄웁니다.
        if (data['type'] == 'bot_error' || data['type'] == 'bot_status') {
          final String title =
              data['type'] == 'bot_error' ? '⚠️ 에이전트 오류' : 'Tripto 에이전트';
          final String body = data['content'] ?? '상태가 업데이트되었습니다.';

          FCMService.showLocalNotification(
            title: title,
            body: body,
          );
        }
      } catch (e) {
        debugPrint('웹소켓 알림 데이터 파싱 에러: $e');
      }
    },
    onError: (error) {
      debugPrint('웹소켓 연결 에러: $error');
    },
  );
}

void main() async {
  // 1. Flutter 엔진 초기화 보장 (가장 먼저 실행)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 환경 변수(.env) 로드
  await dotenv.load(fileName: '.env');

  // 3. 푸시 알림 및 Firebase 초기화 (FCMService 내부에 Firebase.initializeApp() 포함됨)
  await FCMService.initialize();

  // 4. [토큰 자동 복구 로직]: 디스크에 저장된 최신 토큰을 읽어서 AuthStorage 메모리에 수혈
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

  // 5. 카카오 로그인 SDK 공식 초기화
  KakaoSdk.init(
    javaScriptAppKey: dotenv.env['KAKAO_JS_KEY'] ?? '',
  );

  await dotenv.load(fileName: ".env");
  
  // 6. 단 한 번의 runApp 호출 (여기서부터 UI를 그림)
  runApp(const ProviderScope(child: TriptoApp()));
}

class TriptoApp extends ConsumerStatefulWidget {
  const TriptoApp({super.key});

  @override
  ConsumerState<TriptoApp> createState() => _TriptoAppState();
}

class _TriptoAppState extends ConsumerState<TriptoApp> {
  @override
  void initState() {
    super.initState();
    // 💡 권한 요청은 FCMService에서 이미 처리했으므로, 여기서는 리스너만 연결해 줍니다.
    initFCMListener(ref);
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
