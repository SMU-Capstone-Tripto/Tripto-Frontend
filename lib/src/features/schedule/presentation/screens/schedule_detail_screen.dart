// lib/src/features/schedule/presentation/screens/schedule_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/schedule_repository.dart';
import '../../presentation/schedule_detail_provider.dart'; // 프로젝트 상황에 맞게 경로 확인
import '../../presentation/widgets/timeline_item_card.dart';
import '../../presentation/widgets/schedule_item_detail_sheet.dart';
import '../../../schedule/domain/travel_model.dart';

class ScheduleDetailScreen extends ConsumerStatefulWidget {
  final TravelModel schedule;
  final bool isFriendFeed;

  const ScheduleDetailScreen({
    super.key,
    required this.schedule,
    this.isFriendFeed = false,
  });

  @override
  ConsumerState<ScheduleDetailScreen> createState() =>
      _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends ConsumerState<ScheduleDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final travelId = widget.schedule.travel_id.toString();

      // 💡 새로운 여행 상세 화면 진입 시 항상 Day 1로 초기화
      ref.read(selectedDayProvider.notifier).state = 1;

      if (widget.isFriendFeed) {
        ref.read(scheduleProvider.notifier).fetchFriendSchedules(travelId);
      } else {
        ref.read(scheduleProvider.notifier).fetchSchedules(travelId);
      }
    });
  }

  void _shareTravel() {
    final title = widget.schedule.title;
    final travelId = widget.schedule.travel_id;
    final String shareLink = 'https://tripto.app/travel/$travelId';
    Share.share('[$title] 여행 일정을 확인해보세요!\n👉 링크: $shareLink');
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dayItems = ref.watch(dayItemsProvider);

    final totalDays =
        widget.schedule.end_date.difference(widget.schedule.start_date).inDays +
            1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // 💡 맵 뷰가 사라졌으므로 조건도 간소화되었습니다.
      floatingActionButton: !widget.isFriendFeed
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF524582),
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: () {
                showAddScheduleSheet(
                  context,
                  travelId: widget.schedule.travel_id.toString(),
                  dayNumber: selectedDay,
                  tripStartDate: widget.schedule.start_date,
                );
              },
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
            )
          : null,
      body: Column(
        children: [
          // ── 헤더 ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded,
                              size: 14, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text('목록으로',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _shareTravel,
                      child: const Icon(Icons.share_outlined,
                          size: 19, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.schedule.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.schedule.dateRangeLabel} ($totalDays일간)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),

          // ── 일자(Day) 선택 가로 탭 ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: totalDays,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final date = widget.schedule.start_date.add(Duration(days: i));
                  final isSelected = day == selectedDay;
                  return GestureDetector(
                    onTap: () => ref.read(selectedDayProvider.notifier).state = day,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF524582) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF524582) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Day $day',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          Text(
                            '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isSelected ? Colors.white.withOpacity(.85) : const Color(0xFF94A3B8),
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 일정 목록 ──
          Expanded(
            child: dayItems.isEmpty
                ? Center(
                    child: Text(
                      'Day $selectedDay 에 등록된 일정이 없습니다.\n우측 하단의 연필 버튼을 눌러 새 일정을 추가해 보세요.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                        height: 1.5,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: dayItems.length,
                    itemBuilder: (_, i) => TimelineItemCard(
                      item: dayItems[i],
                      isLast: i == dayItems.length - 1,
                      onTap: () async {
                        final targetId = dayItems[i].schedule_id.toString();
                        final realMemo = await ref
                            .read(scheduleRepositoryProvider)
                            .getScheduleMemo(targetId);

                        if (context.mounted) {
                          final forcedItem = dayItems[i].copyWith(memo: realMemo);
                          showScheduleItemDetail(
                            context,
                            forcedItem,
                            travelId: widget.schedule.travel_id.toString(),
                            tripStartDate: widget.schedule.start_date,
                          );
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}