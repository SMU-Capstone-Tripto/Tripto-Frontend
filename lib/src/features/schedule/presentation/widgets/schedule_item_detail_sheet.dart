import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/schedule_model.dart';
import '../schedule_detail_provider.dart';

void showScheduleItemDetail(
  BuildContext context,
  ScheduleModel item, {
  required String travelId,
  required DateTime tripStartDate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ScheduleItemDetailSheet(
          item: item,
          travelId: travelId,
          tripStartDate: tripStartDate,
        ),
      );
    },
  );
}

void showAddScheduleSheet(
  BuildContext context, {
  required String travelId,
  required int dayNumber,
  required DateTime tripStartDate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddScheduleSheet(
          travelId: travelId,
          dayNumber: dayNumber,
          tripStartDate: tripStartDate,
        ),
      );
    },
  );
}

// 💡 3. 카테고리별 테마 컬러 및 아이콘 정의
class CategoryTheme {
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String label;

  const CategoryTheme(this.color, this.bgColor, this.icon, this.label);

  static const Map<ScheduleType, CategoryTheme> map = {
    ScheduleType.activity: CategoryTheme(
      Color(0xFF524582),
      Color(0xFFFAF5FF),
      Icons.place_rounded,
      '관광/일정',
    ),
    ScheduleType.eat: CategoryTheme(
      Color(0xFF38BFA7),
      Color(0xFFF0FDF4),
      Icons.restaurant_rounded,
      '식사',
    ),
    ScheduleType.stay: CategoryTheme(
      Color(0xFF10B981),
      Color(0xFFECFDF5),
      Icons.hotel_rounded,
      '숙소',
    ),
    ScheduleType.move: CategoryTheme(
      Color(0xFF367BC3),
      Color(0xFFEFF6FF),
      Icons.directions_car_rounded,
      '이동',
    ),
  };
}

class ScheduleItemDetailSheet extends ConsumerStatefulWidget {
  final ScheduleModel item;
  final String travelId;
  final DateTime tripStartDate;

  const ScheduleItemDetailSheet({
    super.key,
    required this.item,
    required this.travelId,
    required this.tripStartDate,
  });

  @override
  ConsumerState<ScheduleItemDetailSheet> createState() =>
      _ScheduleItemDetailSheetState();
}

class _ScheduleItemDetailSheetState
    extends ConsumerState<ScheduleItemDetailSheet> {
  late TextEditingController _placeNameController;
  late TextEditingController _addressController;
  late TextEditingController _costController;

  late ScheduleType _selectedCategory;
  late String _selectedTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 💡 4. 인풋 박스에서도 시간 표기를 완전히 분리하고 순수 장소명만 설정
    final rawPlace = widget.item.place_name ?? widget.item.title;
    final cleanPlace = ScheduleItemsNotifier.stripTimePrefix(rawPlace);

    _placeNameController = TextEditingController(text: cleanPlace);
    _addressController = TextEditingController(text: widget.item.place_address ?? '');
    _costController = TextEditingController(text: widget.item.cost != null ? widget.item.cost.toString() : '0');
    _selectedCategory = widget.item.category;
    _selectedTime = widget.item.start_time;
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _addressController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _sharePlace() {
    final placeName = _placeNameController.text.trim();
    final address = _addressController.text.trim();
    Share.share('[Tripto 장소]\n📍 장소: $placeName\n🗺️ 주소: $address');
  }

  // 💡 5. 편리한 쿠퍼티노 휠 타임피커 모달
  void _pickTimeWheel() {
    int hour = 10;
    int minute = 0;
    if (_selectedTime.contains(':')) {
      final parts = _selectedTime.split(':');
      hour = int.tryParse(parts[0]) ?? 10;
      minute = int.tryParse(parts[1]) ?? 0;
    }

    DateTime tempDateTime = DateTime(2026, 1, 1, hour, minute);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          height: 280,
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Pretendard')),
                    ),
                    const Text('방문 시간 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Pretendard')),
                    TextButton(
                      onPressed: () {
                        final formattedHour = tempDateTime.hour.toString().padLeft(2, '0');
                        final formattedMinute = tempDateTime.minute.toString().padLeft(2, '0');
                        setState(() {
                          _selectedTime = '$formattedHour:$formattedMinute:00';
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('확인', style: TextStyle(color: Color(0xFF524582), fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempDateTime,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final placeName = _placeNameController.text.trim();
    if (placeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장소 이름을 입력해 주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final parsedCost = int.tryParse(_costController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final updated = widget.item.copyWith(
      title: placeName,
      place_name: placeName,
      place_address: _addressController.text.trim(),
      category: _selectedCategory,
      start_time: _selectedTime,
      cost: parsedCost,
    );

    await ref.read(scheduleProvider.notifier).saveOrUpdateSchedule(
          updated,
          travelId: widget.travelId,
          tripStartDate: widget.tripStartDate,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정이 수정되었습니다.')),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일정 삭제', style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('이 일정을 삭제하시겠습니까?', style: TextStyle(fontFamily: 'Pretendard', fontSize: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(scheduleProvider.notifier).deleteScheduleItem(
          widget.item.schedule_id,
          travelId: widget.travelId,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정이 삭제되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double lat = widget.item.latitude ?? 35.1531;
    double lng = widget.item.longitude ?? 129.1186;
    if (lat == -90.0 || lng == -180.0) {
      lat = 35.1531;
      lng = 129.1186;
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
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  onPressed: _handleDelete,
                ),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B), size: 20),
                  onPressed: _sharePlace,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 💡 3. 카테고리별 고유 색상 칩
            Row(
              children: [
                _buildCategoryChip(ScheduleType.activity),
                const SizedBox(width: 8),
                _buildCategoryChip(ScheduleType.eat),
                const SizedBox(width: 8),
                _buildCategoryChip(ScheduleType.stay),
                const SizedBox(width: 8),
                _buildCategoryChip(ScheduleType.move),
              ],
            ),
            const SizedBox(height: 16),

            // 장소명 입력
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _placeNameController,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                decoration: const InputDecoration(
                  labelText: '장소 이름',
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 시간 & 예상 비용
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTimeWheel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('방문 시간', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Pretendard')),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF524582)),
                              const SizedBox(width: 6),
                              Text(
                                _selectedTime.length >= 5 ? _selectedTime.substring(0, 5) : _selectedTime,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Pretendard'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                      decoration: const InputDecoration(
                        labelText: '예상 비용 (원)',
                        border: InputBorder.none,
                        labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 주소 입력
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _addressController,
                style: const TextStyle(fontSize: 13, fontFamily: 'Pretendard'),
                decoration: const InputDecoration(
                  labelText: '주소 또는 상세 설명',
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 미니 지도
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 14),
                  markers: {
                    Marker(
                      markerId: MarkerId(widget.item.schedule_id),
                      position: LatLng(lat, lng),
                      infoWindow: InfoWindow(title: _placeNameController.text),
                    ),
                  },
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF524582),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('일정 수정 완료', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ScheduleType type) {
    final bool isSelected = (_selectedCategory == type);
    final theme = CategoryTheme.map[type]!;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? theme.color : const Color(0xFFE2E8F0)),
            boxShadow: isSelected
                ? [BoxShadow(color: theme.color.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            children: [
              Icon(theme.icon, size: 16, color: isSelected ? Colors.white : theme.color),
              const SizedBox(height: 4),
              Text(
                theme.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 💡 신규 일정 추가 모달
class _AddScheduleSheet extends ConsumerStatefulWidget {
  final String travelId;
  final int dayNumber;
  final DateTime tripStartDate;

  const _AddScheduleSheet({
    required this.travelId,
    required this.dayNumber,
    required this.tripStartDate,
  });

  @override
  ConsumerState<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends ConsumerState<_AddScheduleSheet> {
  final _placeController = TextEditingController();
  final _addressController = TextEditingController();
  final _costController = TextEditingController(text: '0');

  ScheduleType _selectedCategory = ScheduleType.activity;
  String _selectedTime = '12:00:00';
  bool _isSaving = false;

  void _pickTimeWheel() {
    int hour = 12;
    int minute = 0;
    if (_selectedTime.contains(':')) {
      final parts = _selectedTime.split(':');
      hour = int.tryParse(parts[0]) ?? 12;
      minute = int.tryParse(parts[1]) ?? 0;
    }

    DateTime tempDateTime = DateTime(2026, 1, 1, hour, minute);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          height: 280,
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Pretendard')),
                    ),
                    const Text('일정 시간 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Pretendard')),
                    TextButton(
                      onPressed: () {
                        final formattedHour = tempDateTime.hour.toString().padLeft(2, '0');
                        final formattedMinute = tempDateTime.minute.toString().padLeft(2, '0');
                        setState(() {
                          _selectedTime = '$formattedHour:$formattedMinute:00';
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('확인', style: TextStyle(color: Color(0xFF524582), fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempDateTime,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCreate() async {
    final place = _placeController.text.trim();
    if (place.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장소 이름을 입력해 주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final cost = int.tryParse(_costController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final newItem = ScheduleModel(
      schedule_id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      title: place,
      content: place,
      start_time: _selectedTime,
      category: _selectedCategory,
      day_number: widget.dayNumber,
      place_name: place,
      place_address: _addressController.text.trim(),
      cost: cost,
    );

    await ref.read(scheduleProvider.notifier).addScheduleDirectly(
          newItem,
          travelId: widget.travelId,
          tripStartDate: widget.tripStartDate,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 일정이 등록되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 14),
            Text(
              'Day ${widget.dayNumber} 새 일정 추가',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Pretendard'),
            ),
            const SizedBox(height: 14),

            // 💡 카테고리별 고유 색상 칩
            Row(
              children: [
                _buildCategoryChip(ScheduleType.activity),
                const SizedBox(width: 8),
                _buildCategoryChip(ScheduleType.eat),
                const SizedBox(width: 8),
                _buildCategoryChip(ScheduleType.stay),
                const SizedBox(width: 8),
                _buildCategoryChip(ScheduleType.move),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _placeController,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                decoration: const InputDecoration(
                  labelText: '장소 이름 (필수)',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTimeWheel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('방문 시간', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Pretendard')),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTime.substring(0, 5),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Pretendard'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '예상 비용 (원)',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '주소 (선택)',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF524582),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _handleCreate,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('일정 추가하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5, fontFamily: 'Pretendard')),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ScheduleType type) {
    final bool isSelected = (_selectedCategory == type);
    final theme = CategoryTheme.map[type]!;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? theme.color : const Color(0xFFE2E8F0)),
            boxShadow: isSelected
                ? [BoxShadow(color: theme.color.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Column(
            children: [
              Icon(theme.icon, size: 16, color: isSelected ? Colors.white : theme.color),
              const SizedBox(height: 4),
              Text(
                theme.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}