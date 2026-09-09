// lib/src/features/profile/presentation/screens/friend_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/features/home/domain/friend_model.dart';
import 'package:tripto/src/constants/app_theme.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Builder(builder: (context) {
                    final hasProfileImage = friend.profileImage != null &&
                        friend.profileImage!.isNotEmpty;

                    return CircleAvatar(
                      radius: 44,
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
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: text),
                            ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Text(friend.nickname,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2939))),
                  const SizedBox(height: 6),
                  Text(
                    friend.statusMessage.isNotEmpty 
                        ? '"${friend.statusMessage}"' 
                        : '상태 메시지가 없습니다.',
                    style: TextStyle(
                        fontSize: 14, 
                        color: friend.statusMessage.isNotEmpty 
                            ? AppColors.textSecondary 
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          
          // 지난 일정이 빠진 만큼, 하단에 여백을 조금 주어 UI가 답답하지 않게 처리합니다.
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}