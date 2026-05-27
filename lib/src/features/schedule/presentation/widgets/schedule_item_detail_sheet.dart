import 'package:flutter/material.dart';
import '../../domain/schedule_model.dart';

/// 일정 아이템 클릭 시 나오는 바텀시트
void showScheduleItemDetail(BuildContext context, ScheduleModel item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF4F3FF),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _DetailSheet(item: item),
  );
}

class _DetailSheet extends StatefulWidget {
  final ScheduleModel item;
  const _DetailSheet({required this.item});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  final _memoController = TextEditingController();
  bool _editingMemo = false;

  @override
  void initState() {
    super.initState();
    _memoController.text = widget.item.memos ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        child: Column(
          children: [
            // 핸들
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2939))),
                  IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: Color(0xFF9993C4)),
                    onPressed: () {/* TODO: 공유 */},
                  ),
                ],
              ),
            ),

            // 일정 정보 카드
            _DetailCard(
              title: '일정 정보',
              child: Row(
                children: [
                  _TypeIcon(type: item.category),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeBadge(type: item.category),
                      const SizedBox(height: 4),
                      Text(item.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E2939))),
                      Row(children: [
                        const Icon(Icons.access_time,
                            size: 12, color: Color(0xFF9993C4)),
                        const SizedBox(width: 3),
                        Text(item.start_time,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9993C4))),
                      ]),
                    ],
                  ),
                ],
              ),
            ),

            // 지도 카드 (장소 있을 때만)
            if (item.place_address != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    children: [
                      // ── Google Maps 미니 지도 ──
                      // 실제 구현 시 GoogleMap 위젯으로 교체
                      // GeoCoding API로 address → LatLng 변환 후 마커 표시
                      Container(
                        height: 130,
                        color: const Color(0xFFE8E4F5),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // TODO: 실제 Google Maps
                            // GoogleMap(
                            //   initialCameraPosition: CameraPosition(target: latLng, zoom: 15),
                            //   markers: {Marker(markerId: MarkerId('place'), position: latLng)},
                            //   myLocationButtonEnabled: false,
                            //   zoomControlsEnabled: false,
                            // ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    color: Color(0xFF6144B0), size: 32),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 6)
                                    ],
                                  ),
                                  child: Text(item.place_name ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E2939))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 주소 + 길찾기
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.place_name ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E2939))),
                            Text(item.place_address!,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF9993C4))),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {/* TODO: 지도 앱 연동 */},
                              child: const Row(
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 메모 카드
            _DetailCard(
              title: '메모',
              child: _editingMemo
                  ? TextField(
                      controller: _memoController,
                      maxLines: 4,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '방문 시 주의사항, 예약 정보 등을 기록하세요',
                        hintStyle: const TextStyle(
                            fontSize: 12, color: Color(0xFFC0BBDE)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFEDE9FF))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF6144B0))),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                      onSubmitted: (v) => setState(() => _editingMemo = false),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.memos?.isNotEmpty == true)
                          Text(item.memos!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6A7282),
                                  height: 1.6)),
                        if (item.memos == null || item.memos!.isEmpty)
                          const Text(
                              '이곳에서 메모를 추가할 수 있습니다. 방문 시 주의사항, 예약 정보 등을 기록해보세요.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9993C4),
                                  height: 1.5)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _editingMemo = true),
                          child: const Row(
                            children: [
                              Icon(Icons.add,
                                  size: 14, color: Color(0xFF6144B0)),
                              Text('메모 추가',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6144B0))),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// 공통 카드 래퍼
class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x146144B0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9993C4),
                  letterSpacing: .5)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final ScheduleType type;
  const _TypeIcon({required this.type});
  @override
  Widget build(BuildContext context) {
    final (bg, color, icon) = switch (type) {
      ScheduleType.move => (
          const Color(0xFFEDE9FF),
          const Color(0xFF6144B0),
          Icons.directions_car_outlined
        ),
      ScheduleType.eat => (
          const Color(0xFFFFF0F0),
          const Color(0xFFD93030),
          Icons.restaurant_outlined
        ),
      ScheduleType.stay => (
          const Color(0xFFE6F1FB),
          const Color(0xFF185FA5),
          Icons.hotel_outlined
        ),
      ScheduleType.activity => (
          const Color(0xFFE1F5EE),
          const Color(0xFF0F6E56),
          Icons.explore_outlined
        ),
    };
    return CircleAvatar(
        radius: 20,
        backgroundColor: bg,
        child: Icon(icon, color: color, size: 20));
  }
}

class _TypeBadge extends StatelessWidget {
  final ScheduleType type;
  const _TypeBadge({required this.type});
  @override
  Widget build(BuildContext context) {
    final (bg, color) = switch (type) {
      ScheduleType.move => (const Color(0xFFEDE9FF), const Color(0xFF6144B0)),
      ScheduleType.eat => (const Color(0xFFFFF0F0), const Color(0xFFD93030)),
      ScheduleType.stay => (const Color(0xFFE6F1FB), const Color(0xFF185FA5)),
      ScheduleType.activity => (
          const Color(0xFFE1F5EE),
          const Color(0xFF0F6E56)
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(type.label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
