import 'package:flutter/material.dart';
import 'package:tripto/src/features/home/domain/friend_model.dart';
import 'package:tripto/src/constants/app_theme.dart';

class FriendProfileScreen extends StatelessWidget {
  final FriendModel friend;
  const FriendProfileScreen({super.key, required this.friend});

  // 더미 지난 일정 (추후 API로 교체)
  static const _pastTrips = [
    _PastTrip(
        title: '제주도 여름 휴가',
        date: '2025.08.12 – 08.15',
        location: '제주도',
        imageUrl:
            'https://images.unsplash.com/photo-1601042879364-f3947d3f9c16?w=400&q=80'),
    _PastTrip(
        title: '부산 바다 여행',
        date: '2025.05.03 – 05.05',
        location: '부산',
        imageUrl:
            'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=400&q=80'),
  ];

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
  Widget build(BuildContext context) {
    final (bg, text) = _avatarColors();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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
                icon:
                    const Icon(Icons.more_vert, color: AppColors.textSecondary),
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
                  // 아바타
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: bg,
                    child: Text(friend.avatarLabel,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: text)),
                  ),
                  const SizedBox(height: 12),
                  // 이름
                  Text(friend.nickname,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2939))),
                  const SizedBox(height: 4),
                  // 상태 메시지
                  Text('"${friend.statusMessage}"',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  // 채팅하기 버튼
                  ElevatedButton.icon(
                    onPressed: () {/* TODO: 채팅방으로 이동 */},
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('채팅하기',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
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

          // ── 여행 카드 목록 ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: _pastTrips.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PastTripCard(trip: _pastTrips[i]),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}

// 지난 여행 카드
class _PastTripCard extends StatelessWidget {
  final _PastTrip trip;
  const _PastTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x146144B0)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // 이미지
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(trip.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF9CA3AF))),
                // 그라데이션
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
                // 제목
                Positioned(
                  bottom: 10,
                  left: 14,
                  child: Text(trip.title,
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
          // 메타
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(trip.date,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(trip.location,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PastTrip {
  final String title, date, location, imageUrl;
  const _PastTrip(
      {required this.title,
      required this.date,
      required this.location,
      required this.imageUrl});
<<<<<<< HEAD
}
=======
}
>>>>>>> origin/chatting
