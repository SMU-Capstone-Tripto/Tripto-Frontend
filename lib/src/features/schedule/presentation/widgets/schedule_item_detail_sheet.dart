import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/schedule_repository.dart';
import '../../domain/schedule_model.dart';
import '../schedule_detail_provider.dart';

void showScheduleItemDetail(BuildContext context, dynamic item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ScheduleItemDetailSheet(item: item),
      );
    },
  );
}

class ScheduleItemDetailSheet extends ConsumerStatefulWidget {
  final dynamic item;

  const ScheduleItemDetailSheet({super.key, required this.item});

  @override
  ConsumerState<ScheduleItemDetailSheet> createState() =>
      _ScheduleItemDetailSheetState();
}

class _ScheduleItemDetailSheetState
    extends ConsumerState<ScheduleItemDetailSheet> {

  void _sharePlace() {
    final placeName = widget.item.place_name ?? '이름 없는 장소';
    final address = widget.item.place_address ?? '주소 정보 없음';

    final String shareText = '''
[Tripto 장소 추천]
📍 장소: $placeName
🗺️ 주소: $address
''';

    Share.share(shareText, subject: 'Tripto 장소 공유');
  }

  Future<void> _editTime() async {
    TimeOfDay initialTime = TimeOfDay.now();
    final timeString = widget.item.start_time;
    if (timeString != null && timeString.contains(':')) {
      final parts = timeString.split(':');
      initialTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: '방문 예정 시간 선택',
    );

    if (picked != null) {
      final newTimeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      final scheduleIdInt = int.tryParse(widget.item.schedule_id.toString());

      try {
        if (scheduleIdInt != null) {
          await ref
              .read(scheduleRepositoryProvider)
              .updateScheduleTime(scheduleIdInt, newTimeStr);
        }

        ref
            .read(scheduleProvider.notifier)
            .updateTimeLocally(widget.item.schedule_id.toString(), newTimeStr);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('시간이 변경되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('시간 변경 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double lat = widget.item.latitude ?? 38.1913;
    double lng = widget.item.longitude ?? 128.6035;

    if (lat == -90.0 || lng == -180.0) {
      lat = 38.1913;
      lng = 128.6035;
    }

    // 💡 채팅 UI 기준 통일 색상
    final String typeStr = widget.item.category.toString();
    Color primaryColor;
    Color bgColor;

    if (typeStr == 'ScheduleType.eat') {
      primaryColor = const Color(0xFF38BFA7);
      bgColor = const Color(0xFFF0FDF4);
    } else if (typeStr == 'ScheduleType.stay') {
      primaryColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFECFDF5);
    } else if (typeStr == 'ScheduleType.move') {
      primaryColor = const Color(0xFF367BC3);
      bgColor = const Color(0xFFEFF6FF);
    } else {
      primaryColor = const Color(0xFF524582);
      bgColor = const Color(0xFFFAF5FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: Color(0xFF64748B), size: 20),
                  onPressed: _sharePlace,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 일정 정보 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Icon(
                      () {
                        if (typeStr == 'ScheduleType.move') return Icons.directions_car_rounded;
                        if (typeStr == 'ScheduleType.eat') return Icons.restaurant_rounded;
                        if (typeStr == 'ScheduleType.stay') return Icons.hotel_rounded;
                        return Icons.place_rounded;
                      }(),
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PopupMenuButton<String>(
                        position: PopupMenuPosition.under,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: '관광', child: Text('관광')),
                          const PopupMenuItem(value: '식사', child: Text('식사')),
                          const PopupMenuItem(value: '숙소', child: Text('숙소')),
                          const PopupMenuItem(value: '이동', child: Text('이동')),
                        ],
                        onSelected: (String newValue) async {
                          ScheduleType newType;
                          String categoryServerStr;

                          switch (newValue) {
                            case '이동':
                              newType = ScheduleType.move;
                              categoryServerStr = 'move';
                              break;
                            case '식사':
                              newType = ScheduleType.eat;
                              categoryServerStr = 'eat';
                              break;
                            case '숙소':
                              newType = ScheduleType.stay;
                              categoryServerStr = 'stay';
                              break;
                            default:
                              newType = ScheduleType.activity;
                              categoryServerStr = 'activity';
                              break;
                          }

                          final scheduleIdInt =
                              int.tryParse(widget.item.schedule_id.toString());

                          try {
                            if (scheduleIdInt != null) {
                              await ref
                                  .read(scheduleRepositoryProvider)
                                  .updateScheduleCategory(
                                      scheduleIdInt, categoryServerStr);
                            }

                            ref
                                .read(scheduleProvider.notifier)
                                .updateCategoryLocally(
                                    widget.item.schedule_id.toString(),
                                    newType);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('카테고리가 변경되었습니다.')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('카테고리 변경 실패: $e')),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                () {
                                  if (typeStr == 'ScheduleType.move') return '이동';
                                  if (typeStr == 'ScheduleType.eat') return '식사';
                                  if (typeStr == 'ScheduleType.stay') return '숙소';
                                  return '일정';
                                }(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down_rounded,
                                  size: 16, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _editTime,
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: Color(0xFF524582)),
                            const SizedBox(width: 4),
                            Text(
                              widget.item.start_time ?? '시간 미정',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF524582),
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_rounded,
                                size: 12, color: Color(0xFF524582)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on_outlined,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            '예상 비용: ${widget.item.cost ?? 0}원',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 구글 지도 영역
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(widget.item.schedule_id.toString()),
                      position: LatLng(lat, lng),
                      infoWindow:
                          InfoWindow(title: widget.item.place_name ?? '장소'),
                    ),
                  },
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 장소 상세 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.place_name ?? '장소 이름',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.place_address ?? '주소 정보가 없습니다.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}