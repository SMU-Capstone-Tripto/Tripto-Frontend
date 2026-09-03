import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

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
      floatingActionButton: (!_isMapView && !widget.isFriendFeed)
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
                20, MediaQuery.of(context).padding.top + 8, 20, 0),
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
                const SizedBox(height: 12),

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
                const SizedBox(height: 12),
              ],
            ),
          ),

          // 일정 뷰
          if (!_isMapView) ...[
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

          // 지도 뷰
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

class _MapView extends ConsumerStatefulWidget {
  final TravelModel schedule;
  final int totalDays;
  const _MapView({required this.schedule, required this.totalDays});

  @override
  ConsumerState<_MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<_MapView> {
  String? _selectedScheduleId;

  @override
  Widget build(BuildContext context) {
    final travelIdStr = widget.schedule.travel_id.toString();
    final mapPinsAsync = ref.watch(mapPinsProvider(travelIdStr));
    final selectedDay = ref.watch(selectedDayProvider);
    final dayItems = ref.watch(dayItemsProvider);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.totalDays,
              itemBuilder: (_, i) {
                final day = i + 1;
                final isSelected = day == selectedDay;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedScheduleId = null);
                    ref.read(selectedDayProvider.notifier).state = day;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF524582) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Center(
                      child: Text('Day $day',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                              fontFamily: 'Pretendard')),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        Expanded(
          child: mapPinsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF524582))),
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
                    color: const Color(0xFF524582),
                    width: 4,
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              );
            },
          ),
        ),

        if (dayItems.isNotEmpty)
          () {
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
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activeItem.place_name ?? '장소 이름 없음',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          fontFamily: 'Pretendard')),
                  const SizedBox(height: 2),
                  Text(activeItem.place_address ?? '주소 정보 없음',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontFamily: 'Pretendard')),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF524582) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 13.5,
                color: active ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF64748B),
                    fontFamily: 'Pretendard')),
          ],
        ),
      ),
    );
  }
}