import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
        // 전체 요소를 화면 정중앙에 배치
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 세로 공간 차지
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. 종이비행기 아이콘
              Image.asset(
                'assets/images/paperplane.png',
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.send, size: 80, color: Colors.white),
              ),
              
              // 아이콘과 로고 사이 간격
              const SizedBox(height: 2),
              
              // 2. 앱 로고 텍스트
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
              
              // 로고와 서브 슬로건 사이 간격
              const SizedBox(height: 1),
              
              // 3. 서브 슬로건
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