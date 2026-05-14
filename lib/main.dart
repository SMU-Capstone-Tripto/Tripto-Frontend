import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'splash_screen.dart';

/// 애플리케이션의 진입점.
///
/// [TriptoApp] 위젯을 실행하여 전체 애플리케이션 인터페이스를 초기화함.
void main() {
  runApp(const TriptoApp());
}

/// 애플리케이션의 최상위 루트 위젯.
///
/// 테마 설정, 다국어 처리(Localization), 초기 화면 지정 등 전역 설정을 관리함.
class TriptoApp extends StatelessWidget {
  /// [TriptoApp] 위젯의 생성자.
  const TriptoApp({super.key});

  /// 애플리케이션의 구성 및 디자인 프레임워크를 빌드함.
  ///
  /// - [context]: 위젯 트리에 대한 위치 및 메타데이터 정보.
  /// - 반환값: 전역 설정이 포함된 [MaterialApp] 위젯.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 디버그 모드에서 우측 상단 배너 표시 여부 제어
      debugShowCheckedModeBanner: false,
      
      // 운영체제 작업 관리자 등에서 표시될 앱 이름
      title: 'Tripto App',

      // 다국어 지원을 위한 델리게이트 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 앱에서 지원할 언어 및 국가 목록 정의
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],

      // 앱의 기본 로케일을 한국어로 고정 설정
      locale: const Locale('ko', 'KR'),

      // 앱 전역 테마 정의 (기본 색상 및 폰트 포함)
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Pretendard',
      ),

      // 애플리케이션 구동 시 가장 먼저 실행될 시작 위젯 지정
      home: const SplashScreen(),
    );
  }
}