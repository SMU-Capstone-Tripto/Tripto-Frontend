import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../schedule/domain/travel_model.dart';

enum SortOrder { newest, oldest, longest, shortest }

extension SortOrderLabel on SortOrder {
  String get label => switch (this) {
        SortOrder.newest => '최신순',
        SortOrder.oldest => '오래된순',
        SortOrder.longest => '기간 긴순',
        SortOrder.shortest => '기간 짧은순',
      };
}

// ── 전체 일정을 관리하는 단일 Notifier ──
// 홈, 일정 탭 양쪽에서 이 Provider를 바라봄
class ScheduleNotifier extends StateNotifier<List<TravelModel>> {
  ScheduleNotifier()
      : super([
          TravelModel(
            travel_id: 's1',
            title: '제주도 여행',
            destination: '제주도',
            start_date: DateTime(2026, 2, 16),
            end_date: DateTime(2026, 2, 19),
            status: TripStatus.upcoming,
          ),
          TravelModel(
            travel_id: 's2',
            title: '부산 바다 여행',
            destination: '부산',
            start_date: DateTime(2026, 2, 1),
            end_date: DateTime(2026, 2, 3),
            status: TripStatus.past,
          ),
          TravelModel(
            travel_id: 's3',
            title: '강릉 겨울 바다 여행',
            destination: '강릉',
            start_date: DateTime(2025, 12, 14),
            end_date: DateTime(2025, 12, 16),
            status: TripStatus.past,
          ),
          TravelModel(
            travel_id: 's4',
            title: '전주 한옥마을 여행',
            destination: '전주',
            start_date: DateTime(2025, 10, 5),
            end_date: DateTime(2025, 10, 7),
            status: TripStatus.past,
          ),
        ]);

  // 지난 일정 삭제
  void removePast(String id) {
    state = state.where((s) => s.travel_id != id).toList();
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, List<TravelModel>>(
  (ref) => ScheduleNotifier(),
);

// 정렬 기준
final sortOrderProvider = StateProvider<SortOrder>((ref) => SortOrder.newest);

// 예정된 여행 — 홈 화면에서도 참조
final upcomingSchedulesProvider = Provider<List<TravelModel>>((ref) {
  return ref
      .watch(scheduleNotifierProvider)
      .where((s) => s.status == TripStatus.upcoming)
      .toList();
});

// 가장 가까운 예정 여행 1개 — 홈 카드에 표시
final nextTripProvider = Provider<TravelModel?>((ref) {
  final list = ref.watch(upcomingSchedulesProvider);
  if (list.isEmpty) return null;
  list.sort((a, b) => a.start_date.compareTo(b.start_date));
  return list.first;
});

// 지난 여행 — 정렬 반영
final pastSchedulesProvider = Provider<List<TravelModel>>((ref) {
  final order = ref.watch(sortOrderProvider);
  final past = ref
      .watch(scheduleNotifierProvider)
      .where((s) => s.status == TripStatus.past)
      .toList();

  return past
    ..sort((a, b) => switch (order) {
          SortOrder.newest => b.start_date.compareTo(a.start_date),
          SortOrder.oldest => a.start_date.compareTo(b.start_date),
          SortOrder.longest => b.end_date
              .difference(b.start_date)
              .compareTo(a.end_date.difference(a.start_date)),
          SortOrder.shortest => a.end_date
              .difference(a.start_date)
              .compareTo(b.end_date.difference(b.start_date)),
        });
});
