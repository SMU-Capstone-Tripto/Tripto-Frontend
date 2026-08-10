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
      // ❌ [테스트용 주석 처리] 실제 서버 통신 끄기
      // final items = await repository.getSchedules(travelId);
      // final itemsWithMemos = await Future.wait(...);

      // ✅ [테스트용] 실제 부산 핫플레이스 위도/경도가 들어간 완벽한 더미 데이터
      state = [
        const ScheduleModel(
          schedule_id: '9991',
          title: '광안리 바다 구경',
          start_time: '10:00:00',
          category: ScheduleType.activity, // 관광(초록색 뱃지/나침반)
          day_number: 1,
          place_name: '광안리 해수욕장',
          place_address: '부산광역시 수영구 광안해변로 219',
          latitude: 35.1531696, // ✅ 실제 광안리 해수욕장 위도
          longitude: 129.118666, // ✅ 실제 광안리 해수욕장 경도
          cost: 0,
          memos: null,
          memo_id: null,
          memo_content: '밤에 드론쇼 명당 자리 미리 확인해두기',
        ),
        const ScheduleModel(
          schedule_id: '9992',
          title: '해운대 유명 소갈비 점심',
          start_time: '13:00:00',
          category: ScheduleType.eat, // 식사(주황색 뱃지/포크나이프)
          day_number: 1,
          place_name: '해운대암소갈비집',
          place_address: '부산광역시 해운대구 중동2로10번길 32-10',
          latitude: 35.163351, // ✅ 실제 식당 위도
          longitude: 129.166609, // ✅ 실제 식당 경도
          cost: 52000,
          memos: null,
          memo_id: null,
          memo_content: '웨이팅이 길 수 있으니 캐치테이블로 미리 확인!',
        ),
        const ScheduleModel(
          schedule_id: '9993',
          title: '호텔 체크인 및 휴식',
          start_time: '16:00:00',
          category: ScheduleType.stay, // 숙소(파란색 뱃지/침대)
          day_number: 1,
          place_name: '파라다이스 호텔 부산',
          place_address: '부산광역시 해운대구 해운대해변로 296',
          latitude: 35.160032, // ✅ 실제 호텔 위도
          longitude: 129.163084, // ✅ 실제 호텔 경도
          cost: 350000,
          memos: null,
          memo_id: null,
          memo_content: '체크인할 때 오션뷰 객실로 배정해달라고 요청하기',
        ),
      ];

      return; // 더미 데이터만 넣고 함수 종료
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

  // 카테고리 로컬 업데이트 함수
  void updateCategoryLocally(String scheduleId, ScheduleType newCategory) {
    state = state.map((item) {
      if (item.schedule_id.toString() == scheduleId.toString()) {
        return item.copyWith(category: newCategory);
      }
      return item;
    }).toList();
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

  // 스케줄 시간 업데이트 (로컬 상태만)
  void updateTimeLocally(String scheduleId, String newTime) {
    state = state.map((item) {
      if (item.schedule_id.toString() == scheduleId.toString()) {
        return item.copyWith(start_time: newTime);
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
