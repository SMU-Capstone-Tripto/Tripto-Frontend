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
final travelsProvider = FutureProvider<List<TravelModel>>((ref) async {
  // ✅ 실제 서버 API 연동
  return ref.watch(travelRepositoryProvider).getTravels();

  /*
  // ❌ [테스트용 더미데이터 주석 처리]
  return [
    TravelModel(
      travel_id: 999,
      owner_id: 1,
      title: '부산 먹방 & 호캉스 여행',
      destination: '부산',
      start_date: DateTime.now(),
      end_date: DateTime.now().add(const Duration(days: 2)),
      status: TripStatus.upcoming,
    ),
    TravelModel(
      travel_id: 1000,
      owner_id: 1,
      title: '제주도 힐링 여행 (빈 일정)',
      destination: '제주도',
      start_date: DateTime.now().add(const Duration(days: 10)),
      end_date: DateTime.now().add(const Duration(days: 14)),
      status: TripStatus.upcoming,
    ),
  ];
  */
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
  final list = upcomingAsync.value;
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
    ref.invalidate(travelsProvider);
  };
});