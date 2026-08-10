import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:share_plus/share_plus.dart';

// 💡 실제 프로젝트의 ScheduleModel 경로로 맞춰주세요.
import '../../../schedule/domain/travel_model.dart';
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
  late TextEditingController _memoController;
  bool _isEditingMemo = false;

  // ✅ 바텀 시트가 열려있는 동안 현재 메모 ID를 기억할 변수 추가
  int? _currentMemoId;

  @override
  void initState() {
    super.initState();
    _memoController =
        TextEditingController(text: widget.item.memo_content ?? '');
    _currentMemoId = widget.item.memo_id; // 열릴 때 기존 메모 ID 장전
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

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

  // 메모 저장 기능 (API 연동)
  void _saveMemo() async {
    final newMemo = _memoController.text;

    if (newMemo.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메모 내용을 입력해 주세요.')),
      );
      return;
    }

    try {
      final repository = ref.read(scheduleRepositoryProvider);
      final int safeScheduleId = int.parse(widget.item.schedule_id.toString());

      if (_currentMemoId == null) {
        // 1) 메모가 없었다면 생성 (POST)
        final newId = await repository.createMemo(safeScheduleId, newMemo);
        _currentMemoId = newId; // 백엔드가 만들어준 새 메모 ID를 기억함!
      } else {
        // 2) 메모가 이미 있다면 수정 (PATCH)
        await repository.updateMemo(_currentMemoId!, newMemo);
      }

      // ✅ 3) 저장이 성공하면 화면(Provider) 상태도 최신으로 갈아끼움
      ref.read(scheduleProvider.notifier).updateMemoLocally(
          widget.item.schedule_id.toString(), _currentMemoId!, newMemo);

      setState(() {
        _isEditingMemo = false; // 완료 후 읽기 모드로 변경
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메모가 안전하게 저장되었습니다!')),
        );
      }
    } catch (e) {
      print('🚨 메모 저장/수정 중 터미널 에러: $e'); // 💡 VS Code 터미널에서 에러 확인용
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 오류: $e')),
        );
      }
    }
  }

  // ── 💡 바텀 시트 클래스 내부에 시간 수정 함수 추가 ──
  Future<void> _editTime() async {
    // 1. 기존 시간 불러오기 (로그를 보면 시간이 "06:13:53.853000" 형태로 올 수 있으므로 안전하게 앞의 시:분만 파싱)
    TimeOfDay initialTime = TimeOfDay.now();
    final timeString = widget.item.start_time;
    if (timeString.contains(':')) {
      final parts = timeString.split(':');
      initialTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    // 2. 플러터 기본 시간 선택기(Time Picker) 띄우기
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: '방문 예정 시간 선택',
    );

    // 3. 사용자가 취소하지 않고 시간을 골랐다면?
    if (picked != null) {
      // 24시간 형식의 "HH:mm:ss" 문자열로 변환
      final newTimeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';

      try {
        final repository = ref.read(scheduleRepositoryProvider);
        final safeScheduleId = int.parse(widget.item.schedule_id);

        // 백엔드 API에 시간 수정 요청
        // await repository.updateScheduleTime(safeScheduleId, newTimeStr);

        // 프론트 화면 즉시 업데이트
        ref
            .read(scheduleProvider.notifier)
            .updateTimeLocally(widget.item.schedule_id, newTimeStr);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('시간이 변경되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('시간 변경 오류: $e')),
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

    final String typeStr = widget.item.category.toString();
    Color primaryColor; // 글자 및 아이콘 색상
    Color bgColor; // 동그라미 및 뱃지 배경 색상

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
      primaryColor = const Color(0xFF4CAF50); // 관광/기타: 초록색 (기본)
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
                  // ── 💡 동그란 아이콘 영역 ──
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor, // 🎨 배경색 자동 적용
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
                      color: primaryColor, // 🎨 아이콘 색상 자동 적용
                    ),
                  ),
                  // ───────────────────────
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 💡 교체된 카테고리 드롭다운 뱃지 ──
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
                          switch (newValue) {
                            case '이동':
                              newType = ScheduleType.move;
                              break;
                            case '식사':
                              newType = ScheduleType.eat;
                              break;
                            case '숙소':
                              newType = ScheduleType.stay;
                              break;
                            default:
                              newType = ScheduleType.activity;
                              break;
                          }
                          try {
                            ref
                                .read(scheduleProvider.notifier)
                                .updateCategoryLocally(
                                    widget.item.schedule_id.toString(),
                                    newType);
                          } catch (e) {
                            print('카테고리 변경 오류: $e');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bgColor, // 🎨 뱃지 배경색 자동 적용
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
                                  color: primaryColor, // 🎨 뱃지 글자색 자동 적용
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down,
                                  size: 14,
                                  color: primaryColor), // 🎨 화살표 색상 자동 적용
                            ],
                          ),
                        ),
                      ),
                      // ─────────────────────────────────────
                      const SizedBox(height: 6),
                      // ⏰ 시간 표시 영역
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
                      // ── 💡 예상 비용 표시 영역 ──
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on_outlined,
                              size: 14, color: Color(0xFF9993C4)),
                          const SizedBox(width: 4),
                          Text(
                            '예상 비용: ${widget.item.cost ?? 0}원',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF9993C4)),
                          ),
                        ],
                      ),
                      // ────────────────────────────────
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 네이버 지도 렌더링 영역
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: NaverMap(
                  options: NaverMapViewOptions(
                    initialCameraPosition: NCameraPosition(
                      target: NLatLng(lat, lng),
                      zoom: 14,
                    ),
                    scrollGesturesEnable: false,
                    zoomGesturesEnable: false,
                  ),
                  onMapReady: (controller) {
                    final marker = NMarker(
                      id: widget.item.schedule_id.toString(),
                      position: NLatLng(lat, lng),
                      caption:
                          NOverlayCaption(text: widget.item.place_name ?? '장소'),
                    );
                    controller.addOverlay(marker);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 장소 상세 정보 카드
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
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.navigation_outlined,
                          size: 16, color: Color(0xFF6144B0)),
                      SizedBox(width: 4),
                      Text('길찾기',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6144B0))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 메모 기능 카드
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
                  const Text('메모',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9993C4))),
                  const SizedBox(height: 12),
                  if (_isEditingMemo) ...[
                    TextField(
                      controller: _memoController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '방문 시 주의사항, 예약 정보 등을 기록해보세요.',
                        hintStyle: const TextStyle(
                            color: Color(0xFFC0BBDE), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF4F3FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => _isEditingMemo = false),
                          child: const Text('취소',
                              style: TextStyle(
                                  color: Color(0xFF9993C4),
                                  fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          onPressed: _saveMemo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6144B0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('저장',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _memoController.text.isEmpty
                          ? '이곳에서 메모를 추가할 수 있습니다. 방문 시 주의사항, 예약 정보 등을 기록해보세요.'
                          : _memoController.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _memoController.text.isEmpty
                            ? const Color(0xFFC0BBDE)
                            : const Color(0xFF1E2939),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => setState(() => _isEditingMemo = true),
                      child: Row(
                        children: [
                          Icon(
                              _memoController.text.isEmpty
                                  ? Icons.add
                                  : Icons.edit,
                              size: 16,
                              color: const Color(0xFF6144B0)),
                          const SizedBox(width: 4),
                          Text(_memoController.text.isEmpty ? '메모 추가' : '메모 수정',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6144B0))),
                        ],
                      ),
                    ),
                  ],
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
