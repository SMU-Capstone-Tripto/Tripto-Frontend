import 'package:flutter/material.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'package:tripto/src/features/home/domain/friend_model.dart';

/// 친구 목록 개별 아이템 위젯
/// Atomic Design 기준 Molecule 레벨
class FriendListItem extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback? onMoreTap;

  const FriendListItem({
    super.key,
    required this.friend,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: _AvatarWidget(friend: friend),
        title: Text(
          friend.nikname,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          friend.statusMessage,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: IconButton(
          onPressed: onMoreTap,
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.textSecondary,
            size: 18,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.background,
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }
}

/// 아바타 위젯 (이름 두 글자 + 온라인 dot)
class _AvatarWidget extends StatelessWidget {
  final FriendModel friend;
  const _AvatarWidget({required this.friend});

  /// AvatarColor → 배경/텍스트 색상 반환
  (Color bg, Color text) _colors() {
    return switch (friend.avatarColor) {
      AvatarColor.purple => (
          AppColors.avatarPurple,
          AppColors.avatarPurpleText
        ),
      AvatarColor.pink => (AppColors.avatarPink, AppColors.avatarPinkText),
      AvatarColor.teal => (AppColors.avatarTeal, AppColors.avatarTealText),
      AvatarColor.amber => (AppColors.avatarAmber, AppColors.avatarAmberText),
      AvatarColor.blue => (AppColors.avatarBlue, AppColors.avatarBlueText),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _colors();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 아바타 원
        CircleAvatar(
          radius: 21,
          backgroundColor: bg,
          child: Text(
            friend.avatarLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ),
        // 온라인 표시 dot
        if (friend.isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
