import 'package:flutter/material.dart';
import '../../auth/presentation/login_screen.dart';

/// 앱 구동 시 노출되는 시작 화면 위젯.
class SplashScreen extends StatefulWidget {
  /// [SplashScreen] 생성자.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// SplashScreen 상태 및 전역 타이머 관리 클래스.
class _SplashScreenState extends State<SplashScreen> {
  /// 초기화 시 3초 대기 후 로그인 화면으로 전환 제어.
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  /// 스플래시 화면 인터페이스 빌드.
  ///
  /// - [context]: 빌드 컨텍스트 메타데이터.
  /// - 반환값: 그라데이션 및 로고가 포함된 [Scaffold] 위젯.
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
              Image.asset(
                'assets/images/paperplane.png',
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.send, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 2),
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