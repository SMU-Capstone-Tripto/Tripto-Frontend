import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/features/home/domain/friend_model.dart';
import 'package:tripto/src/features/schedule/domain/travel_model.dart';
import 'package:tripto/src/features/schedule/data/travel_repository.dart';
import 'package:tripto/src/constants/app_theme.dart';

import '../../../schedule/presentation/screens/schedule_detail_screen.dart';

// 💡 더미 데이터(_pastTrips) 삭제 및 ConsumerWidget으로 변경
class FriendProfileScreen extends ConsumerWidget {
  final FriendModel friend;
  const FriendProfileScreen({super.key, required this.friend});

  (Color bg, Color text) _avatarColors() => switch (friend.avatarColor) {
        AvatarColor.purple => (
            AppColors.avatarPurple,
            AppColors.avatarPurpleText
          ),
        AvatarColor.pink => (AppColors.avatarPink, AppColors.avatarPinkText),
        AvatarColor.teal => (AppColors.avatarTeal, AppColors.avatarTealText),
        AvatarColor.amber => (AppColors.avatarAmber, AppColors.avatarAmberText),
        AvatarColor.blue => (AppColors.avatarBlue, AppColors.avatarBlueText),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (bg, text) = _avatarColors();

    // 💡 방금 만든 Provider로 실제 친구의 여행 데이터를 가져옵니다.
    final travelAsync = ref.watch(friendTravelsProvider(friend.friendId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          // 💡 현재 보고 있는 친구의 일정 데이터를 강제로 다시 서버에서 불러옵니다.
          await ref.refresh(friendTravelsProvider(friend.friendId).future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 새로고침을 위한 필수 속성
          slivers: [
            // ── 앱바 ──
            SliverAppBar(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textSecondary,
              elevation: 0,
              pinned: true,
              title: const Text('프로필',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2939))),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary),
                  onPressed: () {/* TODO: 삭제 메뉴 */},
                ),
              ],
            ),

            // ── 프로필 상단 ──
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    // 💡 여기에 프로필 이미지 분기 처리 추가!
                    Builder(builder: (context) {
                      // 모델의 프로필 이미지 변수명(profileImage)에 맞게 수정하세요.
                      final hasProfileImage = friend.profileImage != null &&
                          friend.profileImage!.isNotEmpty;

                      return CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            hasProfileImage ? Colors.grey.shade200 : bg,
                        backgroundImage: hasProfileImage
                            ? NetworkImage(friend.profileImage!)
                            : null,
                        child: hasProfileImage
                            ? null
                            : Text(
                                friend.nickname.isNotEmpty
                                    ? friend.nickname.substring(0, 1)
                                    : '',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: text),
                              ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Text(friend.nickname,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2939))),
                    const SizedBox(height: 4),
                    Text('"${friend.statusMessage}"',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),

            // ── 지난 일정 섹션 ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                            color: const Color(0xFF8777F2),
                            borderRadius: BorderRadius.circular(99))),
                    const SizedBox(width: 8),
                    const Text('지난 일정',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2939))),
                  ],
                ),
              ),
            ),

            // ── 💡 실제 여행 카드 목록 ──
            travelAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator()))),
              error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text('일정을 불러오지 못했습니다: $err'))),
              data: (travels) {
                if (travels.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                          child: Text('아직 등록된 일정이 없어요.',
                              style: TextStyle(color: Colors.grey))),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: travels.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PastTripCard(trip: travels[i]), // 실제 모델을 넘겨줌
                    ),
                  ),
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }
}

// 지난 여행 카드
class _PastTripCard extends StatelessWidget {
  final TravelModel trip;
  const _PastTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    // TravelModel에 있는 실제 필드명으로 변경해주세요. (아래는 예시입니다)
    final title = trip.title ?? '이름 없는 여행';
    final location = trip.destination ?? '위치 미상';
    final date = '${trip.start_date} - ${trip.end_date}';
    // final imageUrl = trip.imageUrl ?? 'https://images.unsplash.com/photo-1601042879364-f3947d3f9c16?w=400&q=80'; // 기본 이미지

    return InkWell(
      onTap: () {
        // 친구 여행 상세 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleDetailScreen(
              schedule: trip,
              isFriendFeed: true,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x146144B0)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF9CA3AF))),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 14,
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 4)
                            ])),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(location,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
