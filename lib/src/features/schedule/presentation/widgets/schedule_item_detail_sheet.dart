import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/schedule_repository.dart';
import '../../domain/schedule_model.dart';
import '../schedule_detail_provider.dart';

// ── ✅ 바텀 시트를 띄워주는 함수 (에러 해결!) ──
void showScheduleItemDetail(BuildContext context, dynamic item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 바텀 시트 높이를 자유롭게 조절
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        // 메모 작성 시 키보드가 올라오면 바텀 시트도 위로 밀려올라가도록 설정
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ScheduleItemDetailSheet(item: item),
      );
    },
  );
}

// ── 바텀 시트 UI 본체 ──
class ScheduleItemDetailSheet extends ConsumerStatefulWidget {
  final dynamic item; // 모델 타입이 명확하다면 ScheduleModel 등으로 변경하세요.

  const ScheduleItemDetailSheet({super.key, required this.item});

  @override
  ConsumerState<ScheduleItemDetailSheet> createState() =>
      _ScheduleItemDetailSheetState();
}

class _ScheduleItemDetailSheetState
    extends ConsumerState<ScheduleItemDetailSheet> {
  // 🗑️ 메모 관련 변수, initState, dispose, _saveMemo 함수 모두 삭제 완료!

  // 장소 공유 기능
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

  // 시간 수정 기능 (서버 DB 반영 + 로컬 반영)
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
      final scheduleIdInt = int.parse(widget.item.schedule_id.toString());

      try {
        // 💡 1. 서버 DB에 시간 수정 요청 전송
        await ref
            .read(scheduleRepositoryProvider)
            .updateScheduleTime(scheduleIdInt, newTimeStr);

        // 2. 화면(로컬) 상태 즉시 갱신
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
    // 네이버 지도 좌표 방어 로직
    double lat = widget.item.latitude ?? 38.1913;
    double lng = widget.item.longitude ?? 128.6035;

    if (lat == -90.0 || lng == -180.0) {
      lat = 38.1913;
      lng = 128.6035;
    }

    // 카테고리별 테마 색상 결정 로직
    final String typeStr = widget.item.category.toString();
    Color primaryColor;
    Color bgColor;

    if (typeStr == 'ScheduleType.eat') {
      primaryColor = const Color(0xFFFF9800); // 식사: 주황색
      bgColor = const Color(0xFFFFF3E0);
    } else if (typeStr == 'ScheduleType.stay') {
      primaryColor = const Color(0xFF2196F3); // 숙소: 파란색
      bgColor = const Color(0xFFE3F2FD);
    } else if (typeStr == 'ScheduleType.move') {
      primaryColor = const Color(0xFF9C27B0); // 이동: 보라색
      bgColor = const Color(0xFFF3E5F5);
    } else {
      primaryColor = const Color(0xFF4CAF50); // 관광/기타: 초록색
      bgColor = const Color(0xFFE8F5E9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들 및 공유 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: Color(0xFF9993C4)),
                  onPressed: _sharePlace,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 일정 정보 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                        if (typeStr == 'ScheduleType.move')
                          return Icons.directions_car_outlined;
                        if (typeStr == 'ScheduleType.eat')
                          return Icons.restaurant_outlined;
                        if (typeStr == 'ScheduleType.stay')
                          return Icons.hotel_outlined;
                        return Icons.explore_outlined;
                      }(),
                      color: primaryColor,
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
                          const PopupMenuItem(value: '기타', child: Text('기타')),
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
                              int.parse(widget.item.schedule_id.toString());

                          try {
                            // 💡 1. 서버 DB에 카테고리 수정 요청 전송
                            await ref
                                .read(scheduleRepositoryProvider)
                                .updateScheduleCategory(
                                    scheduleIdInt, categoryServerStr);

                            // 2. 화면(로컬) 상태 즉시 갱신
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
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                () {
                                  if (typeStr == 'ScheduleType.move')
                                    return '이동';
                                  if (typeStr == 'ScheduleType.eat')
                                    return '식사';
                                  if (typeStr == 'ScheduleType.stay')
                                    return '숙소';
                                  return '일정';
                                }(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down,
                                  size: 14, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _editTime,
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: Color(0xFF6144B0)),
                            const SizedBox(width: 4),
                            Text(widget.item.start_time ?? '시간 미정',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6144B0))),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit,
                                size: 12, color: Color(0xFF6144B0)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on_outlined,
                              size: 14, color: Color(0xFF9993C4)),
                          const SizedBox(width: 4),
                          Text('예상 비용: ${widget.item.cost ?? 0}원',
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF9993C4))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 🗺️ 구글 지도 렌더링 영역
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
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

            // 🗑️ 길찾기 및 메모 삭제된 장소 상세 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.place_name ?? '장소 이름',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2939))),
                  const SizedBox(height: 4),
                  Text(widget.item.place_address ?? '주소 정보가 없습니다.',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF9993C4))),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
