import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'package:tripto/src/features/home/presentation/home_provider.dart';
import 'package:tripto/src/features/home/presentation/notification_provider.dart';
import 'package:tripto/src/features/home/presentation/widgets/trip_card_widget.dart';
import 'package:tripto/src/features/home/presentation/widgets/friend_list_item.dart';
import 'package:tripto/src/features/schedule/domain/travel_model.dart';
import 'package:tripto/src/common_widgets/empty_state_widget.dart';
import 'package:tripto/src/common_widgets/error_state_widget.dart';
import 'package:tripto/src/common_widgets/skeleton/friend_skeleton.dart';

import '../../domain/notification_model.dart';

/// 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(nextTripProvider);
    final friendsAsync = ref.watch(friendListProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      // 💡 1. 전체 배경색을 트렌디한 연한 보라빛 회백색으로 변경
      backgroundColor: const Color(0xFFF6F5FA),
      body: CustomScrollView(
        slivers: [
          // ── 상단 그라데이션 헤더 (여행 정보) ──
          SliverToBoxAdapter(
            child: _HomeHeader(
              trip: trip,
              onNotifTap: () {
                context.push('/home/notification'); // 기존 알림 화면으로 이동
              },
              onScheduleTap: () =>
                  context.push('/schedule/detail', extra: trip!),
            ),
          ),

          // ── 친구 섹션 타이틀 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8A6BFF), // 💡 포인트 컬러
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '친구',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800, // 💡 제목은 w700 이상
                          color: Color(0xFF1E2939),
                        ),
                      ),
                    ],
                  ),
                  _AddFriendButton(
                    onTap: () => context.push('/home/add-friend'),
                  ),
                ],
              ),
            ),
          ),

          // ── 친구 목록 ──
          friendsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: FriendListSkeleton(count: 5),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorStateWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(friendListProvider),
              ),
            ),
            data: (friends) => friends.isEmpty
                ? SliverToBoxAdapter(
                    child: EmptyFriendsWidget(
                      onAddFriend: () => context.push('/home/add-friend'),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.builder(
                      itemCount: friends.length,
                      itemBuilder: (_, i) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 12), // 💡 카드 간격 조절
                        child: FriendListItem(
                          friend: friends[i],
                          onDelete: () async {
                            try {
                              await ref
                                  .read(friendListProvider.notifier)
                                  .removeFriend(friends[i].friendshipId);
                              return true;
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('삭제 실패: $e')));
                              }
                              return false;
                            }
                          },
                        ),
                      ),
                    ),
                  ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

/// 홈 상단 헤더
class _HomeHeader extends StatelessWidget {
  final TravelModel? trip;
  final VoidCallback? onScheduleTap;
  final VoidCallback? onNotifTap;
  final int unreadCount;

  const _HomeHeader({
    this.trip,
    this.onScheduleTap,
    this.onNotifTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 💡 2. 그라데이션 및 부드러운 라운드 처리 적용
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
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        32, // 하단 라운드를 위해 패딩을 약간 늘림
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 브랜드 + 알림 버튼 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tripto',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '안녕하세요, 여행자님!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400, // 💡 본문 느낌은 w400
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              // ── 알림 버튼 + 읽지 않은 빨간 점 ──
              Stack(
                children: [
                  IconButton(
                    onPressed: onNotifTap,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14), // 💡 투명한 둥근 버튼
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5252), // 더 화사한 빨간색
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── 다가오는 여행 라벨 ──
          Text(
            '다가오는 여행',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // ── 여행 카드 or 빈 상태 ──
          if (trip != null && onScheduleTap != null)
            TripCardWidget(
              trip: trip!,
              onScheduleTap: onScheduleTap!,
            )
          else
            const _EmptyTripCard(),
        ],
      ),
    );
  }
}

/// 헤더 로딩 플레이스홀더
class _HeaderLoadingPlaceholder extends StatelessWidget {
  const _HeaderLoadingPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A6BFF), Color(0xFF6144B0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

/// 헤더 에러 플레이스홀더
class _HeaderErrorPlaceholder extends StatelessWidget {
  final String message;
  const _HeaderErrorPlaceholder({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A6BFF), Color(0xFF6144B0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          '여행 정보를 불러오지 못했습니다.',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
      ),
    );
  }
}

/// 여행 없을 때 빈 상태 카드
class _EmptyTripCard extends StatelessWidget {
  const _EmptyTripCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // 💡 반투명 화이트 배경
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.flight_takeoff_outlined,
              color: Colors.white.withOpacity(0.8), size: 36),
          const SizedBox(height: 12),
          Text(
            '예정된 여행이 없어요',
            style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 친구 추가 버튼
class _AddFriendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFriendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FF), // 💡 연한 보라색 배경
          borderRadius: BorderRadius.circular(10), // 💡 둥근 사각형 느낌으로 변경
        ),
        child: const Icon(
          Icons.person_add_outlined,
          size: 18,
          color: Color(0xFF6144B0), // 진한 보라색 아이콘
        ),
      ),
    );
  }
}
