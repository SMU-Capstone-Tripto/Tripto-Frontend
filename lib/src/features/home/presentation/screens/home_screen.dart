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

/// 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(nextTripProvider);
    final friendsAsync = ref.watch(friendListProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── 상단 헤더 (여행 정보) ──
          SliverToBoxAdapter(
            child: _HomeHeader(
              trip: trip,
              unreadCount: unreadCount,
              onNotifTap: () => context.push('/home/notification'),
              onScheduleTap: () =>
                  context.push('/schedule/detail', extra: trip!),
            ),
          ),

          // ── 친구 섹션 타이틀 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '친구',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FriendListItem(
                          friend: friends[i],
                          onDelete: () => ref
                              .read(friendListProvider.notifier)
                              .removeFriend(friends[i].uniqueId),
                        ),
                      ),
                    ),
                  ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
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
      color: const Color(0xFF4E48AF),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        28,
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
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '안녕하세요, 여행자님!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontFamily: 'Pretendard',
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
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      shape: const CircleBorder(),
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
                          color: Color(0xFFD93030),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 다가오는 여행 라벨 ──
          Text(
            '다가오는 여행',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

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

/// 헤더 로딩 플레이스홀더 (헤더 높이 유지)
class _HeaderLoadingPlaceholder extends StatelessWidget {
  const _HeaderLoadingPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4E48AF),
      height: 200,
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
      color: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          '여행 정보를 불러오지 못했습니다.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.flight_takeoff_outlined, color: Colors.white54, size: 32),
          SizedBox(height: 8),
          Text(
            '예정된 여행이 없어요',
            style: TextStyle(color: Colors.white70, fontSize: 13),
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
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_add_outlined,
          size: 16,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
