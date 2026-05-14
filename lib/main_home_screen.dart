import 'package:flutter/material.dart';

/// 
/// 로그인, 프로필 설정, 선호 스타일 조사를 마친 유저가 도달하는 최종 목적지임.
class MainHomeScreen extends StatelessWidget {
  /// [MainHomeScreen] 위젯의 생성자.
  const MainHomeScreen({super.key});

  /// 홈 화면의 인터페이스를 빌드함.
  /// 
  /// - [context]: 위젯 트리의 빌드 컨텍스트.
  /// - 반환값: 그라데이션 배경과 환영 메시지가 포함된 [Scaffold].
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