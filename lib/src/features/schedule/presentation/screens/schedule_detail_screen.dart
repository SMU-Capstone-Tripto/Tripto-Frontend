import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/schedule_detail_provider.dart';
import '../../presentation/widgets/timeline_item_card.dart';
import '../../presentation/widgets/schedule_item_detail_sheet.dart';
import '../../../schedule/domain/travel_model.dart';

class ScheduleDetailScreen extends ConsumerStatefulWidget {
  final TravelModel schedule;
  const ScheduleDetailScreen({super.key, required this.schedule});

  @override
  ConsumerState<ScheduleDetailScreen> createState() =>
      _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends ConsumerState<ScheduleDetailScreen> {
  // 상단 뷰 모드
  bool _isMapView = false;

  // ✅ 화면이 처음 열릴 때 한 번만 실행되는 initState 추가
  @override
  void initState() {
    super.initState();

    // Flutter의 첫 화면 렌더링이 끝난 직후에 API를 안전하게 호출하도록 예약합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // widget.schedule에서 travel_id를 가져와 String으로 변환 후 넘겨줍니다.
      ref
          .read(scheduleProvider.notifier)
          .fetchSchedules(widget.schedule.travel_id.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dayItems = ref.watch(dayItemsProvider);

    // 여행 총 일수
    final totalDays =
        widget.schedule.end_date.difference(widget.schedule.start_date).inDays +
            1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3FF),
      body: Column(
        children: [
          // ── 헤더 ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 뒤로가기
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios,
                          size: 14, color: Color(0xFF9993C4)),
                      Text('목록으로',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF9993C4))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.schedule.title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2939))),
                Text('${widget.schedule.dateRangeLabel} ($totalDays일)',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9993C4))),
                const SizedBox(height: 12),

                // 일정 / 지도 탭
                Row(
                  children: [
                    _ViewTab(
                        label: '일정',
                        icon: Icons.access_time_outlined,
                        active: !_isMapView,
                        onTap: () => setState(() => _isMapView = false)),
                    const SizedBox(width: 8),
                    _ViewTab(
                        label: '지도',
                        icon: Icons.map_outlined,
                        active: _isMapView,
                        onTap: () => setState(() => _isMapView = true)),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // ── 일정 뷰 ──
          if (!_isMapView) ...[
            // Day 선택 바
            Container(
              color: Colors.white,
              child: SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: totalDays,
                  itemBuilder: (_, i) {
                    final day = i + 1;
                    final date =
                        widget.schedule.start_date.add(Duration(days: i));
                    final isSelected = day == selectedDay;
                    return GestureDetector(
                      onTap: () =>
                          ref.read(selectedDayProvider.notifier).state = day,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6144B0)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Day $day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF9993C4),
                                )),
                            Text(
                              '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white.withOpacity(.75)
                                    : const Color(0xFFC0BBDE),
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

            // 타임라인 리스트
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: dayItems.length,
                itemBuilder: (_, i) => TimelineItemCard(
                  item: dayItems[i],
                  isLast: i == dayItems.length - 1,
                  onTap: () => showScheduleItemDetail(context, dayItems[i]),
                ),
              ),
            ),
          ],

          // ── 지도 뷰 ──
          if (_isMapView)
            Expanded(
              child: _MapView(
                schedule: widget.schedule,
                totalDays: totalDays,
              ),
            ),
        ],
      ),
    );
  }
}

// 지도 뷰 (Google Maps)
class _MapView extends ConsumerWidget {
  final TravelModel schedule;
  final int totalDays;
  const _MapView({required this.schedule, required this.totalDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dayItems = ref.watch(dayItemsProvider);

    return Column(
      children: [
        // Day 필터
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: totalDays,
            itemBuilder: (_, i) {
              final day = i + 1;
              final isSelected = day == selectedDay;
              return GestureDetector(
                onTap: () => ref.read(selectedDayProvider.notifier).state = day,
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6144B0)
                        : const Color(0xFFF4F3FF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Day $day',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF9993C4))),
                ),
              );
            },
          ),
        ),

        // Google Maps (실제 구현)
        Expanded(
          child: Container(
            // TODO: GoogleMap 위젯으로 교체
            // GoogleMap(
            //   initialCameraPosition: ...,
            //   polylines: { /* 장소 연결선 */ },
            //   markers: { /* 각 일정 마커 */ },
            // ),
            color: const Color(0xFFE8E4F5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 40, color: Color(0xFF9993C4)),
                  SizedBox(height: 8),
                  Text('Google Maps API',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6144B0))),
                  Text('실제 앱에서 지도가 표시됩니다',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9993C4))),
                ],
              ),
            ),
          ),
        ),

        // 하단 장소 카드
        if (dayItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x146144B0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayItems.first.place_name ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2939))),
                Text(dayItems.first.place_address ?? '',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9993C4))),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.navigation_outlined,
                        size: 14, color: Color(0xFF6144B0)),
                    SizedBox(width: 4),
                    Text('길찾기',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6144B0))),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ViewTab(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6144B0) : const Color(0xFFF4F3FF),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: active ? Colors.white : const Color(0xFF9993C4)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF9993C4))),
          ],
        ),
      ),
    );
  }
}
