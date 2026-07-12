import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 1. 카카오 로그인 전용 패키지 불러오기
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'src/routing/app_router.dart';
import 'src/constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // 2. 카카오 로그인 SDK 공식 초기화 (AuthRepository 삭제)
  KakaoSdk.init(
    // 모바일 앱(Android/iOS)은 주로 Native App Key를 사용합니다.
    // nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '',

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