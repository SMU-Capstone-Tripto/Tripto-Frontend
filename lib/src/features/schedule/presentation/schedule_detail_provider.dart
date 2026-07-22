import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/schedule_model.dart';
import '../data/schedule_repository.dart';

// 선택된 Day
final selectedDayProvider = StateProvider<int>((ref) => 1);

// 1. Repository를 주입받도록 Provider 수정
final scheduleProvider =
    StateNotifierProvider<ScheduleItemsNotifier, List<ScheduleModel>>(
  (ref) {
    final repository = ref.watch(scheduleRepositoryProvider);
    return ScheduleItemsNotifier(repository);
  },
);

class ScheduleItemsNotifier extends StateNotifier<List<ScheduleModel>> {
  final ScheduleRepository repository;

  // 2. 초기 상태는 빈 배열([])로 시작합니다. 더미 데이터를 모두 지웠습니다.
  ScheduleItemsNotifier(this.repository) : super([]);

  // 3. API에서 실제 스케줄 데이터를 불러와 상태를 갱신하는 함수 추가
  Future<void> fetchSchedules(String travelId) async {
    try {
      // API 호출
      final items = await repository.getSchedules(travelId);

      // 💡 만약 서버에 데이터가 하나도 없어서 UI 테스트가 안 된다면 임시로 아래 주석을 푸세요!
      /*
      if (items.isEmpty) {
        state = [
          ScheduleModel(schedule_id: '1', title: '테스트 일정 1', start_time: '10:00', category: ScheduleType.move, day_number: 1, place_name: '제주공항', place_address: ''),
        ];
        return;
      }
      */

      // 받아온 실제 데이터로 화면(상태) 업데이트
      state = items;
    } catch (e) {
      print('스케줄 불러오기 실패: $e');
      // 필요하다면 에러 처리 로직 추가
    }
  }

  // ── 💡 새로 추가: 친구 피드용 스케줄 불러오기 ──
  Future<void> fetchFriendSchedules(String travelId) async {
    try {
      // repository에 새로 만들 getFriendSchedules를 호출합니다.
      final items = await repository.getFriendSchedules(travelId);
      state = items;
    } catch (e) {
      print('친구 스케줄 불러오기 실패: $e');
    }
  }

  // 메모 업데이트 (기존 유지)
  void updateMemo(String id, String memo) {
    state = state
        .map(
            (item) => item.schedule_id == id ? item.copyWith(memo: memo) : item)
        .toList();
  }
}

// 선택된 Day의 아이템만 필터 (기존 유지)
final dayItemsProvider = Provider<List<ScheduleModel>>((ref) {
  final day = ref.watch(selectedDayProvider);
  final items = ref.watch(scheduleProvider);
  return items.where((i) => i.day_number == day).toList()
    ..sort((a, b) => a.start_time.compareTo(b.start_time));
});
