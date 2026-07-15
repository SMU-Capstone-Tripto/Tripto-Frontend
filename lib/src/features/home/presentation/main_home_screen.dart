import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainHomeScreen extends StatelessWidget {
  // GoRouter에서 탭바를 관리하기 위해 넘겨주는 전용 객체입니다.
  final StatefulNavigationShell navigationShell;

  const MainHomeScreen({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index) {
    // 탭을 누르면 GoRouter가 알맞은 화면(홈, 채팅 등)으로 부드럽게 전환해줍니다.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 선택된 탭의 실제 화면(home_screen.dart 등)을 본문에 그려줍니다.
      body: navigationShell,

      // 🎨 원하시던 이전 파일의 하단 탭바 스타일을 그대로 적용했습니다!
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF7145D0), // TRIPTO 시그니처 보라색
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: '일정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}