import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/common_widgets/error_state_widget.dart';
import 'package:tripto/src/constants/app_theme.dart';
import '../screens/saved_schedule_screen.dart';
import '../profile_provider.dart';
import '../screens/saved_places_screen.dart';
import '../screens/app_info_screen.dart';
import '../screens/notification_setting_screen.dart';
import '../screens/profile_edit_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 백엔드에서 프로필 데이터 가져오기
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (profile) => CustomScrollView(
          slivers: [
            // 💡 프로필 헤더에 profile 객체 전달
            SliverToBoxAdapter(child: _ProfileHeader(profile: profile)),

            // ── 메뉴 목록 (기존 그대로) ──
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 여행 기록
                  const _SectionLabel('여행 기록'),
                  const SizedBox(height: 6),
                  _MenuCard(items: [
                    _MenuItem(
                      icon: Icons.calendar_month_outlined,
                      label: '저장한 일정',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SavedSchedulesScreen())), // 일정 화면 연결
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

                  // 설정
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

                  // 지원
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

                  // 로그아웃
                  _LogoutButton(onTap: () {/* TODO */}),

                  // 버전 정보
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

// ── 상단 프로필 헤더 (ConsumerWidget으로 변경하여 Provider 직접 사용) ──
class _ProfileHeader extends ConsumerWidget {
  final dynamic profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 이미지 업로드 상태 구독 (로딩 스피너 표시용)
    final imageUploadState = ref.watch(profileImageControllerProvider);
    final isUploading = imageUploadState.isLoading;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('프로필',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8)),
          const SizedBox(height: 16),
          Row(
            children: [
              // ── 아바타 ──
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    // 💡 DB에 저장된 실제 이미지 URL을 불러옵니다.
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? const Icon(Icons.person_outline,
                            size: 30, color: AppColors.primary)
                        : null,
                  ),
                  // 업로드 중 로딩 표시
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
                  // 카메라 버튼
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      // 💡 버튼 클릭 시 Provider의 업로드 로직 실행!
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
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_outlined,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // ── 이름 + 아이디 ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.nikname,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2939))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(profile.unique_id,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: profile.unique_id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('아이디가 복사되었습니다'),
                                duration: Duration(seconds: 1)),
                          );
                        },
                        child: const Icon(Icons.copy_outlined,
                            size: 13, color: AppColors.textSecondary),
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

// ── 섹션 라벨 ──
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
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

// ── 메뉴 카드 (둥근 흰 박스) ──
class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Column(
            children: [
              item,
              if (!isLast)
                const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── 개별 메뉴 항목 ──
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
    this.iconBg = AppColors.primaryLight,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // 아이콘 배경 박스
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            // 메뉴 텍스트
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E2939),
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── 로그아웃 버튼 ──
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
        foregroundColor: AppColors.textSecondary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── 앱 버전 ──
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
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            SizedBox(height: 2),
            Text('© 2026 Tripto. All rights reserved.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
