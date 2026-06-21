import 'package:flutter/material.dart';
import 'skeleton_widget.dart';

/// 친구 목록 로딩 스켈레톤
class FriendListSkeleton extends StatelessWidget {
  final int count;
  const FriendListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const _FriendItemSkeleton()),
    );
  }
}

class _FriendItemSkeleton extends StatelessWidget {
  const _FriendItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // 아바타
          const SkeletonBox(width: 46, height: 46, borderRadius: 23),
          const SizedBox(width: 12),
          // 이름 + 상태
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                    width: MediaQuery.of(context).size.width * 0.3, height: 14),
                const SizedBox(height: 6),
                SkeletonBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
