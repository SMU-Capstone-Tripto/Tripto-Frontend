import 'package:flutter/material.dart';

/// 회원 가입 및 정보 설정 수집 절차 완료 후 최종 착륙 대시보드 화면.
class MainHomeScreen extends StatelessWidget {
  /// [MainHomeScreen] 생성자.
  const MainHomeScreen({super.key});

  /// 홈 코어 정보 레이아웃 가공 조립 빌드.
  ///
  /// - [context]: 위젯 트리 빌드 컨텍스트 메타데이터.
  /// - 반환값: 중앙 텍스트 컨테이너 정렬 포함 [Scaffold] 위젯.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4D48AF), Color(0xFFB287FD)],
          ),
        ),
        child: const Center(
          child: Text(
            'TRIPTO 메인 화면',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}