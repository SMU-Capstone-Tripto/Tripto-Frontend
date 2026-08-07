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
      // 전체 일정 목록을 먼저 가져옵니다. (여기엔 메모가 비어있음)
      final items = await repository.getSchedules(travelId);

      // 목록의 모든 일정에 대해 각각 단건 API를 동시에 찔러 메모를 가져옵니다.
      final itemsWithMemos = await Future.wait(
        items.map((item) async {
          // 아까 만들어둔 단건 메모 조회 함수 호출
          final memo =
              await repository.getScheduleMemo(item.schedule_id.toString());
          // 기존 아이템에 가져온 메모를 끼워 넣어서 반환
          return item.copyWith(memo: memo);
        }),
      );

      // 3. 메모까지 완벽하게 채워진 리스트로 화면(상태) 업데이트
      state = itemsWithMemos;
    } catch (e) {
      print('스케줄 불러오기 실패: $e');
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
    state = state.map((item) {
      // 💡 숫자(int)와 문자(String) 비교 실패를 막기 위해 양쪽 다 문자로 변환!
      if (item.schedule_id.toString() == id.toString()) {
        return item.copyWith(memo: memo);
      }
      return item;
    }).toList();
  }

  // 메모 ID와 내용을 함께 업데이트하는 함수
  void updateMemoLocally(String scheduleId, int newMemoId, String newContent) {
    state = state.map((item) {
      // 💡 숫자(int)와 문자(String) 비교 실패를 막기 위해 양쪽 다 문자로 변환!
      if (item.schedule_id.toString() == scheduleId.toString()) {
        return item.copyWith(memo_id: newMemoId, memo_content: newContent);
      }
      return item;
    }).toList();
  }

  // 단건 스케줄 메모만 서버에서 당겨와서 동기화
  Future<void> fetchAndSyncMemo(String scheduleId) async {
    try {
      final latestMemo = await repository.getScheduleMemo(scheduleId);

      // 기존에 만들어두신 updateMemo를 재활용해서 상태를 갱신합니다!
      updateMemo(scheduleId, latestMemo);
    } catch (e) {
      print('메모 동기화 실패: $e');
    }
  }
}

// 선택된 Day의 아이템만 필터 (기존 유지)
final dayItemsProvider = Provider<List<ScheduleModel>>((ref) {
  final day = ref.watch(selectedDayProvider);
  final items = ref.watch(scheduleProvider);
  return items.where((i) => i.day_number == day).toList()
    ..sort((a, b) => a.start_time.compareTo(b.start_time));
});

// 지도 핀(마커) 목록 조회 Provider
final mapPinsProvider =
    FutureProvider.family<List<ScheduleModel>, String>((ref, travelId) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getTravelMapPins(travelId);
});
