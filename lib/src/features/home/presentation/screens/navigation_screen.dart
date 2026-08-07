import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainHomeScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainHomeScreen({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,

      // 💡 사진 느낌을 살리기 위해 NavigationBar(Material 3)로 교체
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEDE9FF), // 선택된 탭의 연한 보라색 배경
        surfaceTintColor: Colors.transparent, // 스크롤 시 색상 변함 방지
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.home, color: Color(0xFF7145D0)),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.grey),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF7145D0)),
            label: '채팅',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF7145D0)),
            label: '일정',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.grey),
            selectedIcon: Icon(Icons.person, color: Color(0xFF7145D0)),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
