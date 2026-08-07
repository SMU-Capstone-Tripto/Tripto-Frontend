import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:share_plus/share_plus.dart';

// 💡 실제 프로젝트의 ScheduleModel 경로로 맞춰주세요.
import '../../../schedule/domain/travel_model.dart';
import '../../data/schedule_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    // 네이버 지도 좌표 방어 로직
    double lat = widget.item.latitude ?? 38.1913;
    double lng = widget.item.longitude ?? 128.6035;

    if (lat == -90.0 || lng == -180.0) {
      lat = 38.1913;
      lng = 128.6035;
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
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Icon(Icons.explore_outlined,
                        color: Color(0xFF4CAF50)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.item.category?.toString() ?? '일정',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Color(0xFF9993C4)),
                          const SizedBox(width: 4),
                          Text(widget.item.start_time ?? '',
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
