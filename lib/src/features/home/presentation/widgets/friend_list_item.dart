import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../home/domain/friend_model.dart';
import '../../../../constants/app_theme.dart';

class FriendListItem extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback? onDelete;

  const FriendListItem({super.key, required this.friend, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/home/friend-profile', extra: friend),
      onLongPress: () => _showDeleteDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _FriendAvatar(friend: friend),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.nickname,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(friend.statusMessage,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${friend.nickname}님을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  final FriendModel friend;
  const _FriendAvatar({required this.friend});

  (Color bg, Color text) _colors() => switch (friend.avatarColor) {
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
    final (bg, text) = _colors();
    return Stack(
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: bg,
          child: Text(friend.avatarLabel,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: text)),
        ),
      ],
    );
  }
}
