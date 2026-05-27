
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'package:tripto/src/features/home/presentation/home_provider.dart';
import 'package:tripto/src/features/home/presentation/widgets/trip_card_widget.dart';
import 'package:tripto/src/features/home/presentation/widgets/friend_list_item.dart';

/// 홈 화면 (메인 탭 #1)
/// - ConsumerWidget: Riverpod Provider 구독
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(nextTripProvider);
    final friends = ref.watch(friendListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── 상단 헤더 (단색 배경) ──
          SliverToBoxAdapter(
            child: _HomeHeader(trip: trip),
          ),

          // ── 친구 섹션 타이틀 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좌측 보라 라인 + 타이틀
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
                  // 친구 추가 버튼
                  _AddFriendButton(onTap: () {
                    // TODO: 친구 추가 화면으로 이동
                  }),
                ],
              ),
            ),
          ),

          // ── 친구 목록 ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) => FriendListItem(
                friend: friends[index],
                onMoreTap: () {
                  // TODO: 친구 더보기 바텀시트
                },
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}

/// 홈 상단 헤더 (단색 보라 + 여행 카드)
class _HomeHeader extends StatelessWidget {
  final dynamic trip; // ScheduleModel?

  const _HomeHeader({this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16, // 상태바 여백
        20,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 브랜드 + 알림 아이콘
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
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '안녕하세요, 여행자님!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              // 알림 버튼
              IconButton(
                onPressed: () {
                  // TODO: 알림 화면
                },
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 섹션 라벨
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

          // 여행 카드 (trip 없으면 빈 상태)
          if (trip != null)
            TripCardWidget(
              trip: trip,
              onScheduleTap: () {
                // TODO: go_router로 일정 상세 이동
                // context.push('/schedule/${trip.id}');
              },
            )
          else
            const _EmptyTripCard(),
        ],
      ),
    );
  }
}

/// 여행 없을 때 표시하는 빈 상태 카드
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

/// 친구 추가 버튼 (원형)
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
