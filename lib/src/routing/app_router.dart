import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/screens/home_screen.dart';
import '../features/settings/presentation/screens/saved_schedule_screen.dart';
import '../features/home/presentation/screens/add_friend_screen.dart';
import '../features/home/presentation/screens/friend_profile_screen.dart';
import '../features/home/presentation/screens/notification_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/schedule/presentation/screens/schedule_screen.dart';
import '../features/schedule/presentation/screens/schedule_detail_screen.dart';
import '../features/settings/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/screens/profile_edit_screen.dart';
import '../features/settings/presentation/screens/password_change_screen.dart';
import '../features/settings/presentation/screens/saved_places_screen.dart';
import '../features/settings/presentation/screens/notification_setting_screen.dart';
import '../features/settings/presentation/screens/app_info_screen.dart';
import '../features/schedule/domain/travel_model.dart';
import '../features/home/domain/friend_model.dart';

// ── 경로 상수 ──
// 문자열 오타 방지를 위해 상수로 관리
class AppRoutes {
  static const shell = '/';
  static const home = '/home';
  static const notification = '/notification';
  static const addFriend = '/add-friend';
  static const friendProfile = '/friend-profile';
  static const chat = '/chat';
  static const schedule = '/schedule';
  static const scheduleDetail = '/schedule/detail';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const passwordChange = '/profile/password';
  static const savedPlaces = '/profile/saved-places';
  static const savedSchedules = '/profile/saved-schedules';
  static const notifSetting = '/profile/notification-setting';
  static const appInfo = '/profile/app-info';
}

// ── 탭 인덱스 ──
const _tabs = [
  AppRoutes.home,
  AppRoutes.chat,
  AppRoutes.schedule,
  AppRoutes.profile,
];

// ── Router Provider ──
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // ── Shell Route: 바텀 네비가 있는 탭 화면들 ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ShellScreen(shell: shell),
        branches: [
          // 홈 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'notification',
                  builder: (_, __) => const NotificationScreen(),
                ),
                GoRoute(
                  path: 'add-friend',
                  builder: (_, __) => const AddFriendScreen(),
                ),
                GoRoute(
                  path: 'friend-profile',
                  builder: (_, state) => FriendProfileScreen(
                    friend: state.extra as FriendModel,
                  ),
                ),
              ],
            ),
          ]),

          // 채팅 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.chat,
              builder: (_, __) => const ChatScreen(),
            ),
          ]),

          // 일정 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.schedule,
              builder: (_, __) => const ScheduleScreen(),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder: (_, state) => ScheduleDetailScreen(
                    schedule: state.extra as TravelModel,
                  ),
                ),
              ],
            ),
          ]),

          // 프로필 탭
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, __) => const ProfileEditScreen(),
                  routes: [
                    GoRoute(
                      path: 'password',
                      builder: (_, __) => const PasswordChangeScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'saved-places',
                  builder: (_, __) => const SavedPlacesScreen(),
                ),
                GoRoute(
                  path: 'saved-schedules',
                  builder: (_, __) => const SavedSchedulesScreen(),
                ),
                GoRoute(
                  path: 'notification-setting',
                  builder: (_, __) => const NotificationSettingScreen(),
                ),
                GoRoute(
                  path: 'app-info',
                  builder: (_, __) => const AppInfoScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

// ── Shell 화면: 바텀 네비 포함 ──
class _ShellScreen extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _ShellScreen({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          // 같은 탭 누르면 루트로 이동
          initialLocation: i == shell.currentIndex,
        ),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEDE9FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_outlined, color: Color(0xFF6144B0)),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon:
                Icon(Icons.chat_bubble_outline, color: Color(0xFF6144B0)),
            label: '채팅',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon:
                Icon(Icons.calendar_today_outlined, color: Color(0xFF6144B0)),
            label: '일정',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_outline, color: Color(0xFF6144B0)),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
