import 'package:flutter/material.dart';
import 'login_screen.dart';

/// 앱 구동 시 가장 먼저 노출되는 시작 화면 위젯.
class SplashScreen extends StatefulWidget {
  /// [SplashScreen] 위젯의 생성자.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// [SplashScreen]의 상태 및 화면 전환 로직을 관리하는 클래스.
class _SplashScreenState extends State<SplashScreen> {
  /// 위젯 초기화 시 타이머를 설정하여 일정 시간 후 화면을 전환함.
  /// 
  /// - 목적: 3초 대기 후 [LoginScreen]으로 자동 이동.
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      // 위젯이 트리에서 제거되지 않았을 때만 화면 전환 실행
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  /// 스플래시 화면의 시각적 레이아웃을 빌드함.
  /// 
  /// - [context]: 위젯 트리의 빌드 컨텍스트.
  /// - 반환값: 그라데이션 배경과 로고가 포함된 [Scaffold].
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 서비스의 상징적 아이콘 노출
              Image.asset(
                'assets/images/paperplane.png',
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.send, size: 80, color: Colors.white),
              ),
              
              const SizedBox(height: 2),
              
              // 메인 브랜드 로고 텍스트
              const Text(
                'TRIPTO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 1),
              
              // 서비스 핵심 가치를 담은 슬로건
              const Text(
                '당신의 여행 파트너',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}