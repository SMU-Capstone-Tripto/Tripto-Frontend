import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'src/features/splash/presentation/splash_screen.dart';

/// 애플리케이션 진입점.
///
/// [TriptoApp] 위젯을 구동하여 시스템 인터페이스 초기화.
void main() {
  runApp(const TriptoApp());
}

/// 최상위 루트 위젯.
///
/// 전역 테마, 다국어 처리, 초기 시작 화면 설정 관리.
class TriptoApp extends StatelessWidget {
  /// [TriptoApp] 생성자.
  const TriptoApp({super.key});

  /// 글로벌 애플리케이션 구성 및 디자인 설정 빌드.
  ///
  /// - [context]: 빌드 컨텍스트 메타데이터.
  /// - 반환값: 전역 설정이 반영된 [MaterialApp] 위젯.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tripto App',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Pretendard',
      ),
      home: const SplashScreen(),
    );
  }
}