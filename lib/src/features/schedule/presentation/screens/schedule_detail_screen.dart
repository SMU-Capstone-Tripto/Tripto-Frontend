import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // 🗺️ 구글 지도 패키지
import 'package:share_plus/share_plus.dart'; // 공유 패키지

import '../../data/schedule_repository.dart';
import '../../presentation/schedule_detail_provider.dart';
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
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final travelId = widget.schedule.travel_id.toString();

      if (widget.isFriendFeed) {
        ref.read(scheduleProvider.notifier).fetchFriendSchedules(travelId);
      } else {
        ref.read(scheduleProvider.notifier).fetchSchedules(travelId);
      }
    });
  }

  // ── 공유 버튼 동작 함수 ──
  void _shareTravel() {
    final title = widget.schedule.title;
    final travelId = widget.schedule.travel_id;

    final String shareLink = 'https://tripto.app/travel/$travelId';

    // 링크와 함께 보낼 메시지 구성
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
                // 뒤로가기 & ✅ 공유 버튼 추가
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    GestureDetector(
                      onTap: _shareTravel,
                      child: const Icon(Icons.share_outlined,
                          size: 20, color: Color(0xFF9993C4)),
                    ),
                  ],
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

          // 일정 뷰
          if (!_isMapView) ...[
            Container(
              color: Colors.white,
              child: SizedBox(
                height: 90,
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
                  onTap: () async {
                    final targetId = dayItems[i].schedule_id.toString();

                    final realMemo = await ref
                        .read(scheduleRepositoryProvider)
                        .getScheduleMemo(targetId);

                    if (context.mounted) {
                      final forcedItem = dayItems[i].copyWith(memo: realMemo);
                      showScheduleItemDetail(context, forcedItem);
                    }
                  },
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

// 🗺️ 구글 지도 뷰 (Day별 필터링 + 마커 클릭 연동 하단 카드)
class _MapView extends ConsumerStatefulWidget {
  final TravelModel schedule;
  final int totalDays;
  const _MapView({required this.schedule, required this.totalDays});

  @override
  ConsumerState<_MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<_MapView> {
  // 사용자가 클릭한 마커의 스케줄 ID를 저장하는 상태 (없으면 해당 Day의 첫 번째 장소)
  String? _selectedScheduleId;

  @override
  Widget build(BuildContext context) {
    final travelIdStr = widget.schedule.travel_id.toString();
    final mapPinsAsync = ref.watch(mapPinsProvider(travelIdStr));
    final selectedDay = ref.watch(selectedDayProvider);
    final dayItems = ref.watch(dayItemsProvider);

    return Column(
      children: [
        // Day 필터
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: widget.totalDays,
            itemBuilder: (_, i) {
              final day = i + 1;
              final isSelected = day == selectedDay;
              return GestureDetector(
                onTap: () {
                  // Day가 바뀔 때 선택된 마커 초기화
                  setState(() => _selectedScheduleId = null);
                  ref.read(selectedDayProvider.notifier).state = day;
                },
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

        // ✅ 구글 지도 렌더링 영역
        Expanded(
          child: mapPinsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('지도 데이터를 불러오지 못했습니다: $err')),
            data: (allPins) {
              final currentDayPins = dayItems;

              double centerLat = 35.1531;
              double centerLng = 129.1186;

              final Set<Marker> markers = {};
              final List<LatLng> polylinePoints = [];

              for (var item in currentDayPins) {
                if (item.latitude != null &&
                    item.longitude != null &&
                    item.latitude != -90.0) {
                  final latLng = LatLng(item.latitude!, item.longitude!);
                  final scheduleIdStr = item.schedule_id.toString();

                  markers.add(
                    Marker(
                      markerId: MarkerId(scheduleIdStr),
                      position: latLng,
                      infoWindow: InfoWindow(title: item.place_name ?? '장소'),
                      onTap: () {
                        // 💡 마커를 클릭했을 때 하단 카드가 바뀌도록 상태 업데이트!
                        setState(() {
                          _selectedScheduleId = scheduleIdStr;
                        });
                      },
                    ),
                  );
                  polylinePoints.add(latLng);
                }
              }

              if (polylinePoints.isNotEmpty) {
                centerLat = polylinePoints.first.latitude;
                centerLng = polylinePoints.first.longitude;
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(centerLat, centerLng),
                  zoom: 14,
                ),
                markers: markers,
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('day_travel_path'),
                    points: polylinePoints,
                    color: const Color(0xFF6144B0),
                    width: 4,
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              );
            },
          ),
        ),

        // 💡 하단 장소 카드 (클릭한 마커 혹은 해당 Day의 첫 번째 장소 정보 표시)
        if (dayItems.isNotEmpty)
          () {
            // 사용자가 클릭한 마커가 있다면 그 아이템을 찾고, 없으면 첫 번째 아이템을 보여줌
            final activeItem = dayItems.firstWhere(
              (item) => item.schedule_id.toString() == _selectedScheduleId,
              orElse: () => dayItems.first,
            );

            return Container(
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
                  Text(activeItem.place_name ?? '장소 이름 없음',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2939))),
                  const SizedBox(height: 2),
                  Text(activeItem.place_address ?? '주소 정보 없음',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9993C4))),
                  const SizedBox(height: 6),
                  const Row(
                    children: [],
                  ),
                ],
              ),
            );
          }(),
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
