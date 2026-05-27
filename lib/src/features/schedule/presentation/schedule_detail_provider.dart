import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/schedule_model.dart';

// 선택된 Day
final selectedDayProvider = StateProvider<int>((ref) => 1);

// 일정 아이템 목록 (더미 - 추후 API 교체)
final scheduleProvider =
    StateNotifierProvider<ScheduleItemsNotifier, List<ScheduleModel>>(
  (ref) => ScheduleItemsNotifier(),
);

class ScheduleItemsNotifier extends StateNotifier<List<ScheduleModel>> {
  ScheduleItemsNotifier()
      : super(const [
          // Day 1
          ScheduleModel(
              schedule_id: 'i1',
              title: '김포공항 도착',
              start_time: '08:00',
              category: ScheduleType.move,
              day_number: 1,
              place_name: '김포국제공항',
              place_address: '서울특별시 강서구 하늘길 38'),
          ScheduleModel(
              schedule_id: 'i2',
              title: '제주공항 도착',
              start_time: '10:00',
              category: ScheduleType.move,
              day_number: 1,
              place_name: '제주국제공항',
              place_address: '제주특별자치도 제주시 공항로 2'),
          ScheduleModel(
              schedule_id: 'i3',
              title: '렌터카 픽업',
              start_time: '11:00',
              category: ScheduleType.move,
              day_number: 1,
              place_name: '제주공항',
              place_address: '제주특별자치도 제주시 공항로 2'),
          ScheduleModel(
              schedule_id: 'i4',
              title: '점심식사',
              start_time: '12:00',
              category: ScheduleType.eat,
              day_number: 1,
              place_name: '올레국수',
              place_address: '제주특별자치도 제주시 노형동 925'),
          ScheduleModel(
              schedule_id: 'i5',
              title: '한라산 등반',
              start_time: '14:00',
              category: ScheduleType.activity,
              day_number: 1,
              place_name: '한라산국립공원',
              place_address: '제주특별자치도 제주시 1100로 2070-61'),
          ScheduleModel(
              schedule_id: 'i6',
              title: '숙소 체크인',
              start_time: '18:00',
              category: ScheduleType.stay,
              day_number: 1,
              place_name: '제주 신라호텔',
              place_address: '제주특별자치도 서귀포시 중문관광로72번길 75'),
          // Day_number 2
          ScheduleModel(
              schedule_id: 'i7',
              title: '성산일출봉',
              start_time: '09:00',
              category: ScheduleType.activity,
              day_number: 2,
              place_name: '성산일출봉',
              place_address: '제주특별자치도 서귀포시 성산읍 일출로 284-12'),
          ScheduleModel(
              schedule_id: 'i8',
              title: '점심 해산물',
              start_time: '12:00',
              category: ScheduleType.eat,
              day_number: 2,
              place_name: '성산항 횟집',
              place_address: '제주특별자치도 서귀포시 성산읍'),
        ]);

  // 메모 업데이트
  void updateMemo(String id, String memo) {
    state = state
        .map(
            (item) => item.schedule_id == id ? item.copyWith(memo: memo) : item)
        .toList();
  }
}

// 선택된 Day의 아이템만 필터
final dayItemsProvider = Provider<List<ScheduleModel>>((ref) {
  final day = ref.watch(selectedDayProvider);
  final items = ref.watch(scheduleProvider);
  return items.where((i) => i.day_number == day).toList()
    ..sort((a, b) => a.start_time.compareTo(b.start_time));
});
