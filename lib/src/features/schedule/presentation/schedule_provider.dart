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
  // return ref.read(travelRepositoryProvider).getTravels();
  // ✅ [테스트용] 앱 첫 화면에 띄울 완벽한 가짜 여행 데이터
  return [
    TravelModel(
      travel_id: 999, // 💡 이 ID가 아까 만든 999번 부산 스케줄과 연결됩니다!
      owner_id: 1,
      title: '부산 먹방 & 호캉스 여행',
      destination: '부산',
      start_date: DateTime.now(), // 오늘부터
      end_date: DateTime.now().add(const Duration(days: 2)), // 2박 3일
      status: TripStatus.upcoming, // 예정된 여행 탭에 뜨도록 설정
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
