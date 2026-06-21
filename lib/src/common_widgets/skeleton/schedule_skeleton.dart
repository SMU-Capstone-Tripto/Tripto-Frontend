import 'package:flutter/material.dart';
import 'skeleton_widget.dart';

/// 일정 카드 로딩 스켈레톤
class ScheduleCardSkeleton extends StatelessWidget {
  const ScheduleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 상단 컬러 영역
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: const SkeletonBox.full(height: 100, borderRadius: 0),
          ),
          // 하단 액션 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(
                    width: MediaQuery.of(context).size.width * 0.3, height: 12),
                const SkeletonBox(width: 20, height: 20, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 일정 목록 스켈레톤 (여러 개)
class ScheduleListSkeleton extends StatelessWidget {
  final int count;
  const ScheduleListSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const ScheduleCardSkeleton()),
    );
  }
}
