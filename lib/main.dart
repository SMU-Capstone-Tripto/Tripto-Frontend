import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/features/home/presentation/home_screen.dart';
import 'package:tripto/src/features/chat/presentation/chat_screen.dart';
import 'package:tripto/src/features/schedule/presentation/schedule_screen.dart';
import 'package:tripto/src/features/settings/presentation/profile_screen.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

// 어느 화면에서든 탭 전환 가능하도록 전역으로 관리
final currentTabProvider = StateProvider<int>((ref) => 0);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao Maps SDK 초기화
  // .env로 관리 권장 (flutter_dotenv)
  AuthRepository.initialize(appKey: 'YOUR_KAKAO_JAVASCRIPT_KEY');

  runApp(const ProviderScope(child: TriptoApp()));
}

class TriptoApp extends StatelessWidget {
  const TriptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tripto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _MainShell(),
    );
  }
}

/// 바텀 네비게이션 + 탭 전환 Shell
class _MainShell extends ConsumerWidget {  // ← StatefulWidget → ConsumerWidget
  const _MainShell();

  static const _screens = [
    HomeScreen(),
    ChatScreen(),
    ScheduleScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) =>
        ref.read(currentTabProvider.notifier).state = i,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),            label: '홈'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline),      label: '채팅'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined),  label: '일정'),
          NavigationDestination(icon: Icon(Icons.person_outline),           label: '프로필'),
        ],
      ),
    );
  }
}

/// 빈 탭 화면 (추후 구현 예정)
class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.black12),
            const SizedBox(height: 12),
            Text(
              '$label 탭 (준비 중)',
              style: const TextStyle(fontSize: 14, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}
