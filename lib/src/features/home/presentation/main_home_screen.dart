import 'package:flutter/material.dart';
import '../../chat/presentation/chat_list_screen.dart'; // 기존 채팅 화면 임포트
import 'home_screen.dart'; // 🛠️ 방금 백엔드와 연동한 진짜 HomeScreen 임포트 추가!

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  // 현재 어떤 탭이 선택되었는지 인덱스 저장 (0: 홈, 1: 채팅, 2: 일정, 3: 프로필)
  int _selectedIndex = 0; 

  // 하단 탭을 누를 때마다 화면을 전환하기 위한 리스트
  late final List<Widget> _screens = [
    const HomeScreen(), // 🛠️ 준비 중이던 더미 텍스트를 진짜 HomeScreen으로 교체!
    const ChatListScreen(), // ★ 우리가 한 땀 한 땀 만든 채팅 리스트 화면 연결!
    const Center(child: Text('일정 화면 (준비 중)', style: TextStyle(fontSize: 16, color: Colors.grey))),
    const Center(child: Text('프로필 화면 (준비 중)', style: TextStyle(fontSize: 16, color: Colors.grey))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 선택된 인덱스의 화면을 본문에 그려줍니다.
      body: _screens[_selectedIndex],
      
      // 와이어프레임 디자인을 반영한 하단 내비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 탭이 4개일 때 스타일이 깨지는 것을 방지
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF7145D0), // TRIPTO 시그니처 보라색
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: const TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 12),
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