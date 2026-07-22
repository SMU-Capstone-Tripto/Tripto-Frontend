import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'src/routing/app_router.dart';
import 'src/constants/app_theme.dart';

// 🎯 [핵심 추가]: 앱 시작 시 저장된 토큰을 읽어와 메모리에 올리기 위한 import
import 'src/core/auth_storage.dart';
import 'src/core/network/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

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
    clientId: '여기에_복사한_CLIENT_ID를_넣어주세요',
    onAuthFailed: (ex) => print('네이버 지도 인증 오류: $ex'),
  );

  // 카카오 로그인 SDK 공식 초기화
  KakaoSdk.init(
    // 만약 팀원이 JavaScript 키로 구현해 두었다면 아래 줄을 활성화하세요.
    javaScriptAppKey: dotenv.env['KAKAO_JS_KEY'] ?? '',
  );

  runApp(const ProviderScope(child: TriptoApp()));
}

class TriptoApp extends ConsumerWidget {
  const TriptoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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