import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// 공통 빈 상태 위젯
/// 친구 없을 때, 일정 없을 때 등 재사용
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? description;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.iconBg = AppColors.primaryLight,
    this.iconColor = AppColors.primary,
    this.description,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 16),

            // 제목
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2939)),
                textAlign: TextAlign.center),

            // 설명
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description!,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6),
                  textAlign: TextAlign.center),
            ],

            // 버튼
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onButtonTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(buttonLabel!,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 자주 쓰는 빈 상태 프리셋 ──

/// 친구 없을 때
class EmptyFriendsWidget extends StatelessWidget {
  final VoidCallback? onAddFriend;
  const EmptyFriendsWidget({super.key, this.onAddFriend});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.group_outlined,
      title: '아직 친구가 없어요',
      description: '아이디 검색으로\n친구를 추가해보세요',
      buttonLabel: '친구 추가하기',
      onButtonTap: onAddFriend,
    );
  }
}

/// 예정 일정 없을 때
class EmptyUpcomingTripWidget extends StatelessWidget {
  final VoidCallback? onCreateTrip;
  const EmptyUpcomingTripWidget({super.key, this.onCreateTrip});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.flight_takeoff_outlined,
      title: '예정된 여행이 없어요',
      description: '새로운 여행을\n계획해보세요',
      buttonLabel: '여행 만들기',
      onButtonTap: onCreateTrip,
    );
  }
}

/// 지난 일정 없을 때
class EmptyPastTripWidget extends StatelessWidget {
  const EmptyPastTripWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.calendar_month_outlined,
      iconBg: const Color(0xFFF3F4F6),
      iconColor: AppColors.textSecondary,
      title: '지난 여행이 없어요',
    );
  }
}

/// 채팅방 없을 때
class EmptyChatsWidget extends StatelessWidget {
  const EmptyChatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: '채팅방이 없어요',
      description: '그룹 채팅방을 만들거나\nAI와 대화를 시작해보세요',
    );
  }
}
