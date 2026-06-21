import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/travel_model.dart';
import '../data/travel_repository.dart';

enum SortOrder { newest, oldest, longest, shortest }

extension SortOrderLabel on SortOrder {
  String get label => switch (this) {
        SortOrder.newest => '최신순',
        SortOrder.oldest => '오래된순',
        SortOrder.longest => '기간 긴순',
        SortOrder.shortest => '기간 짧은순',
      };
}

// ── 전체 여행 목록 (API 연동) ──
// FutureProvider이므로 AsyncValue<List<TravelModel>> 반환
final travelsProvider = FutureProvider<List<TravelModel>>((ref) async {
  return ref.read(travelRepositoryProvider).getTravels();
});

// 정렬 기준
final sortOrderProvider = StateProvider<SortOrder>((ref) => SortOrder.newest);

// 예정된 여행
final upcomingSchedulesProvider =
    Provider<AsyncValue<List<TravelModel>>>((ref) {
  final travelsAsync = ref.watch(travelsProvider);
  return travelsAsync.whenData(
    (list) => list.where((t) => t.status == TripStatus.upcoming).toList(),
  );
});

// 가장 가까운 예정 여행 1개 — 홈 카드에 표시
final nextTripProvider = Provider<TravelModel?>((ref) {
  final upcomingAsync = ref.watch(upcomingSchedulesProvider);
  final list = upcomingAsync.value; // 로딩/에러 시 null
  if (list == null || list.isEmpty) return null;
  final sorted = [...list]
    ..sort((a, b) => a.start_date.compareTo(b.start_date));
  return sorted.first;
});

// 지난 여행 — 정렬 반영
final pastSchedulesProvider = Provider<AsyncValue<List<TravelModel>>>((ref) {
  final order = ref.watch(sortOrderProvider);
  final travelsAsync = ref.watch(travelsProvider);

  return travelsAsync.whenData((list) {
    final past = list.where((t) => t.status == TripStatus.past).toList();
    past.sort((a, b) => switch (order) {
          SortOrder.newest => b.start_date.compareTo(a.start_date),
          SortOrder.oldest => a.start_date.compareTo(b.start_date),
          SortOrder.longest => b.end_date
              .difference(b.start_date)
              .compareTo(a.end_date.difference(a.start_date)),
          SortOrder.shortest => a.end_date
              .difference(a.start_date)
              .compareTo(b.end_date.difference(b.start_date)),
        });
    return past;
  });
});

// 지난 일정 삭제 (API 호출 + 새로고침)
final deleteTravelProvider = Provider((ref) {
  return (String travelId) async {
    await ref.read(travelRepositoryProvider).deleteTravel(travelId);
    ref.invalidate(travelsProvider); // 삭제 후 목록 갱신
  };
});
