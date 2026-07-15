import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../schedule/domain/travel_model.dart';
import '../../schedule/data/travel_repository.dart';

// ── API 통신과 UI 상태 관리를 하나로 통합한 Notifier ──
class TravelListNotifier extends StateNotifier<AsyncValue<List<TravelModel>>> {
  final TravelRepository _repository;

  TravelListNotifier(this._repository) : super(const AsyncLoading()) {
    loadTravels(); // 시작 시 자동 로드
  }

  // 1. 여행 목록 로드
  Future<void> loadTravels() async {
    try {
      state = const AsyncLoading();
      final travels = await _repository.getTravels();
      state = AsyncData(travels);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // 2. 새 여행 생성 (POST)
  Future<void> addTravel(TravelModel travel) async {
    try {
      await _repository.createTravel(travel);
      await loadTravels(); // 성공 시 서버에서 최신 목록을 다시 불러와 화면 갱신
    } catch (e) {
      print('🚨 여행 생성 실패: $e');
      rethrow;
    }
  }

  // 3. 여행 삭제 (DELETE)
  Future<void> removeTravel(String travelId) async {
    try {
      await _repository.deleteTravel(travelId);
      // 서버에서 지워졌다면 UI 리스트에서도 즉시 제거 (자연스러운 UX)
      if (state is AsyncData) {
        final currentList = state.value!;
        state = AsyncData(
            currentList.where((t) => t.travel_id != travelId).toList());
      }
    } catch (e) {
      print('🚨 여행 삭제 실패: $e');
      rethrow;
    }
  }
}

// ── UI에서 접근할 통합 Provider ──
final travelListProvider =
    StateNotifierProvider<TravelListNotifier, AsyncValue<List<TravelModel>>>(
        (ref) {
  return TravelListNotifier(ref.watch(travelRepositoryProvider));
});

// ── 홈 화면 상단을 위한 '가장 가까운 다가오는 여행' Provider ──
// travelListProvider의 상태를 지켜보다가 데이터가 있으면 알아서 필터링해 줍니다.
final nextTripProvider = Provider<AsyncValue<TravelModel?>>((ref) {
  final travelsAsync = ref.watch(travelListProvider);

  return travelsAsync.when(
    data: (travels) {
      // 다가오는 여행만 필터링
      final upcoming =
          travels.where((t) => t.status == TripStatus.upcoming).toList();
      if (upcoming.isEmpty) return const AsyncData(null);

      // 시작일 기준 오름차순 정렬하여 가장 가까운 여행 1개 선택
      upcoming.sort((a, b) => a.start_date.compareTo(b.start_date));
      return AsyncData(upcoming.first);
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});
