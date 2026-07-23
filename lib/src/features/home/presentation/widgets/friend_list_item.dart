// lib/src/features/home/presentation/widgets/friend_list_item.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../home/domain/friend_model.dart';
import '../../../../constants/app_theme.dart';

class FriendListItem extends StatelessWidget {
  final FriendModel friend;
  // 💡 1. 단순 실행(VoidCallback)이 아니라 성공 여부를 기다리는 Future<bool>로 변경합니다.
  final Future<bool> Function()? onDelete;

  const FriendListItem({super.key, required this.friend, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(friend.friendshipId.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),

      confirmDismiss: (direction) async {
        // 1. 팝업을 띄워서 사용자의 선택을 기다립니다.
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('친구 삭제'),
            content: Text('${friend.nickname}님을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        // 💡 2. 사용자가 '삭제'를 눌렀다면, 서버에서 완전히 지워질 때까지 기다렸다가 스와이프를 승인합니다.
        if (confirm == true && onDelete != null) {
          return await onDelete!();
        }
        return false; // 취소했으면 스와이프 원상복구
      },

      // ── 기존 UI ──
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/home/friend-profile', extra: friend),
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
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// _FriendAvatar 부분은 기존 코드와 동일합니다.
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
    final hasProfileImage =
        friend.profileImage != null && friend.profileImage!.isNotEmpty;

    // 💡 2. 프로필 이미지가 등록된 경우: 실제 이미지를 보여줍니다.
    if (hasProfileImage) {
      return CircleAvatar(
        radius: 23,
        backgroundColor: Colors.grey.shade200, // 이미지 로딩 전 또는 에러 시 임시 배경색
        backgroundImage: NetworkImage(friend.profileImage!),
      );
    }

    final (bg, text) = _colors();
    final label =
        friend.nickname.isNotEmpty ? friend.nickname.substring(0, 1) : '';

    return Stack(
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: bg,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: text)),
        ),
      ],
    );
  }
}
