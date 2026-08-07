import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/common_widgets/error_state_widget.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/network/auth_storage.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../home/presentation/home_provider.dart';

import '../../domain/profile_model.dart';
import '../screens/saved_schedule_screen.dart';
import '../profile_provider.dart';
import '../screens/saved_places_screen.dart';
import '../screens/app_info_screen.dart';
import '../screens/notification_setting_screen.dart';
import '../screens/profile_edit_screen.dart';
import '../../../../core/network/token_storage.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      // 💡 트렌디한 연한 배경색 적용
      backgroundColor: const Color(0xFFF6F5FA),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (profile) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ProfileHeader(profile: profile)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                // 💡 기존의 요소 배치(틀)는 모두 그대로 유지됩니다.
                delegate: SliverChildListDelegate([
                  const _SectionLabel('여행 기록'),
                  const SizedBox(height: 6),
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.calendar_month_outlined,
                      label: '저장한 일정',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SavedSchedulesScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.favorite_outline,
                      iconBg: const Color(0xFFFFF0F0),
                      iconColor: const Color(0xFFD93030),
                      label: '저장한 장소',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SavedPlacesScreen())),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const _SectionLabel('설정'),
                  const SizedBox(height: 6),
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.person_outline,
                      label: '프로필 수정',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileEditScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: '알림 설정',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const NotificationSettingScreen())),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const _SectionLabel('지원'),
                  const SizedBox(height: 6),
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.info_outline,
                      iconBg: const Color(0xFFF3F4F6),
                      iconColor: const Color(0xFF6A7282),
                      label: '앱정보',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AppInfoScreen())),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  _LogoutButton(onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        // 💡 팝업 모서리 둥글게 보정
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        title: const Text('로그아웃',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        content: const Text('정말 로그아웃 하시겠습니까?',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('로그아웃',
                                style: TextStyle(color: Color(0xFFD93030))),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        await TokenStorage.clearTokens();
                        AuthStorage.accessToken = null;
                        AuthStorage.refreshToken = null;

                        ref.invalidate(profileProvider);
                        ref.invalidate(friendListProvider);

                        final cookieManager = WebViewCookieManager();
                        await cookieManager.clearCookies();

                        if (context.mounted) {
                          context.go('/login');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('로그아웃 실패: $e')),
                          );
                        }
                      }
                    }
                  }),
                  const _AppVersion(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final ProfileModel profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUploadState = ref.watch(profileImageControllerProvider);
    final isUploading = imageUploadState.isLoading;

    final bool hasImage =
        profile.profileImage != null && profile.profileImage!.isNotEmpty;

    return Container(
      // 💡 기존 하얀색 배경 대신 그라데이션 및 부드러운 라운드 적용
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A6BFF), Color(0xFF6144B0)],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 32), // 하단 패딩 살짝 증가
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('프로필',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.8), // 💡 헤더에 맞춰 흰색으로
                  letterSpacing: 0.8)),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2), // 반투명하게
                    backgroundImage:
                        hasImage ? NetworkImage(profile.profileImage!) : null,
                    child: !hasImage
                        ? const Icon(Icons.person_outline,
                            size: 30, color: Colors.white)
                        : null,
                  ),
                  if (isUploading)
                    Positioned.fill(
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black.withOpacity(0.4),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: isUploading
                          ? null
                          : () {
                              ref
                                  .read(profileImageControllerProvider.notifier)
                                  .updateProfileImage();
                            },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white, // 흰색 카메라 버튼
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            size: 12, color: Color(0xFF6144B0)), // 진보라색 아이콘
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.nickname,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800, // 💡 굵기 조절
                          color: Colors.white)), // 💡 글자색 조절
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(profile.uniqueId,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8))),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: profile.uniqueId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('아이디가 복사되었습니다'),
                                duration: Duration(seconds: 1)),
                          );
                        },
                        child: Icon(Icons.copy_outlined,
                            size: 13, color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9993C4), // 💡 텍스트 컬러 통일 (연한 보라색 계열)
        letterSpacing: 0.6,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 💡 테두리(border)를 제거하고 은은한 그림자가 들어간 둥근 카드 패턴 적용
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6144B0).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Column(
            children: [
              item,
              if (!isLast)
                const Divider(
                    height: 1,
                    color: Color(0xFFF6F5FA),
                    indent: 16,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconBg = const Color(0xFFEDE9FF), // 💡 기본 보라색 대신 새 컬러 매핑
    this.iconColor = const Color(0xFF6144B0),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10), // 💡 8에서 10으로 살짝 더 둥글게
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600, // 💡 500에서 600으로 위계 조절
                  color: Color(0xFF1E2939),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, // 💡 둥근 아이콘
                size: 20,
                color: Color(0xFFC0BBDE)), // 💡 화살표 색상 연하게
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout_outlined, size: 17),
      label: const Text('로그아웃'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF9993C4), // 💡 로그아웃 글씨 컬러
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AppVersion extends StatelessWidget {
  const _AppVersion();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4, bottom: 12),
      child: Center(
        child: Column(
          children: [
            Text('Tripto v1.0.0',
                style: TextStyle(
                    fontSize: 11, color: Color(0xFFC0BBDE))), // 💡 텍스트 컬러 보정
            SizedBox(height: 2),
            Text('© 2026 Tripto. All rights reserved.',
                style: TextStyle(fontSize: 11, color: Color(0xFFC0BBDE))),
          ],
        ),
      ),
    );
  }
}
