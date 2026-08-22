import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/schedule_model.dart';
import '../data/schedule_repository.dart';

// 선택된 Day
final selectedDayProvider = StateProvider<int>((ref) => 1);

final scheduleProvider =
    StateNotifierProvider<ScheduleItemsNotifier, List<ScheduleModel>>(
  (ref) {
    final repository = ref.watch(scheduleRepositoryProvider);
    return ScheduleItemsNotifier(repository);
  },
);

class ScheduleItemsNotifier extends StateNotifier<List<ScheduleModel>> {
  final ScheduleRepository repository;

  ScheduleItemsNotifier(this.repository) : super([]);

  // 💡 카테고리 자동 판별
  static ScheduleType _detectCategory(String text) {
    final lower = text.toLowerCase();
    if (text.contains('→') || text.contains('->') || lower.contains('이동') || lower.contains('탑승') || lower.contains('도착') || lower.contains('출발') || lower.contains('공항') || lower.contains('역')) {
      return ScheduleType.move;
    } else if (lower.contains('식사') || lower.contains('맛집') || lower.contains('점심') || lower.contains('저녁') || lower.contains('아침') || lower.contains('식당') || lower.contains('카페') || lower.contains('커피') || lower.contains('디저트') || lower.contains('브런치') || lower.contains('베이커리')) {
      return ScheduleType.eat;
    } else if (lower.contains('호텔') || lower.contains('숙소') || lower.contains('체크인') || lower.contains('체크아웃') || lower.contains('펜션') || lower.contains('리조트') || lower.contains('게스트하우스') || lower.contains('민박')) {
      return ScheduleType.stay;
    }
    return ScheduleType.activity;
  }

  // 💡 "1일차: 장소A, 장소B..." 형태의 통짜 데이터를 개별 타임라인 아이템으로 정밀 분해
  static List<ScheduleModel> _expandAndParseSchedules(List<ScheduleModel> rawItems) {
    final List<ScheduleModel> expanded = [];
    final List<String> defaultTimes = ['10:00:00', '12:30:00', '15:00:00', '17:30:00', '19:30:00', '21:00:00'];
    int globalCounter = 1;

    for (var item in rawItems) {
      String rawText = '';
      if (item.content != null && item.content!.trim().isNotEmpty) {
        rawText = item.content!.trim();
      } else if (item.memo_content != null && item.memo_content!.trim().isNotEmpty) {
        rawText = item.memo_content!.trim();
      } else {
        rawText = item.title.trim();
      }

      if (item.content != null && item.content!.trim().isNotEmpty && item.title.trim().isNotEmpty) {
        final isTitleJustHeader = RegExp(r'^\[?\s*\d+일차(\s*일정)?\]?$').hasMatch(item.title.trim());
        if (!isTitleJustHeader && !rawText.contains(item.title.trim())) {
          rawText = '${item.title.trim()}\n$rawText';
        }
      }

      // "1일차: ", "[1일차 - ...]" 등 접두사 제거
      String cleanText = rawText.replaceAll(RegExp(r'^\[?\s*\d+일차[^\n:\-\]]*[:\-\]]*\s*'), '').trim();

      // 줄바꿈 -> 화살표 -> 번호목록 -> 쉼표 순으로 분할
      List<String> chunks = [];
      if (cleanText.contains('\n')) {
        chunks = cleanText.split('\n');
      } else if (cleanText.contains('→') || cleanText.contains('->')) {
        chunks = cleanText.split(RegExp(r'→|->'));
      } else if (RegExp(r'\d+\.\s+').hasMatch(cleanText)) {
        chunks = cleanText.split(RegExp(r'(?=\d+\.\s+)')).map((s) => s.replaceAll(RegExp(r'^\d+\.\s*'), '')).toList();
      } else if (cleanText.contains(',')) {
        chunks = cleanText.split(',');
      } else {
        chunks = [cleanText];
      }

      int timeIdx = 0;
      int validChunksCount = 0;

      for (var chunk in chunks) {
        String trimmed = chunk.trim();
        if (trimmed.isEmpty) continue;

        trimmed = trimmed.replaceAll(RegExp(r'^[-•*#\d\.\)\s]+'), '').trim();
        if (trimmed.isEmpty) continue;

        if (RegExp(r'^\d+일차(\s*일정)?$').hasMatch(trimmed) || trimmed == '일정' || trimmed == '상세 일정') {
          continue;
        }

        final timeRegex = RegExp(r'^(\d{2}:\d{2}(?:\s*(?:~|-|→|->)\s*\d{2}:\d{2})?|\d{2}:\d{2})\s*(.*)');
        final match = timeRegex.firstMatch(trimmed);

        String time = defaultTimes[timeIdx % defaultTimes.length];
        String text = trimmed;

        if (match != null) {
          final rawTime = match.group(1) ?? '';
          time = rawTime.length == 5 ? '$rawTime:00' : rawTime;
          text = (match.group(2) ?? '').trim();
        }

        if (text.isEmpty) text = trimmed;

        String placeName = text;
        if (text.contains('(')) {
          placeName = text.split('(')[0].trim();
        } else if (text.contains(' - ')) {
          placeName = text.split(' - ')[0].trim();
        } else if (text.contains(' ')) {
          placeName = text.split(' ')[0].trim();
        }

        expanded.add(
          ScheduleModel(
            schedule_id: '${item.schedule_id}_${globalCounter++}',
            title: text,
            content: text,
            start_time: time,
            category: _detectCategory(text),
            day_number: item.day_number,
            place_name: placeName.isNotEmpty ? placeName : text,
            place_address: item.place_address ?? '',
            cost: item.cost,
            latitude: item.latitude,
            longitude: item.longitude,
            memo_id: item.memo_id,
            memo_content: item.memo_content,
          ),
        );

        timeIdx++;
        validChunksCount++;
      }

      // 세부 내용이 전혀 없는 경우 기본 일정 슬롯 4개 자동 생성
      if (validChunksCount == 0) {
        expanded.addAll([
          ScheduleModel(
            schedule_id: '${item.schedule_id}_${globalCounter++}',
            title: '${item.day_number}일차 오전 관광 및 이동',
            start_time: '10:00:00',
            category: ScheduleType.move,
            day_number: item.day_number,
            place_name: '현지 관광지',
            place_address: item.place_address ?? '',
          ),
          ScheduleModel(
            schedule_id: '${item.schedule_id}_${globalCounter++}',
            title: '현지 맛집 점심 식사',
            start_time: '12:30:00',
            category: ScheduleType.eat,
            day_number: item.day_number,
            place_name: '추천 맛집',
            place_address: item.place_address ?? '',
          ),
          ScheduleModel(
            schedule_id: '${item.schedule_id}_${globalCounter++}',
            title: '오후 주요 명소 탐방',
            start_time: '15:00:00',
            category: ScheduleType.activity,
            day_number: item.day_number,
            place_name: '인기 명소',
            place_address: item.place_address ?? '',
          ),
          ScheduleModel(
            schedule_id: '${item.schedule_id}_${globalCounter++}',
            title: '숙소 체크인 및 휴식',
            start_time: '18:00:00',
            category: ScheduleType.stay,
            day_number: item.day_number,
            place_name: '숙소',
            place_address: item.place_address ?? '',
          ),
        ]);
      }
    }

    return expanded;
  }

  void setSchedules(List<ScheduleModel> items) {
    state = _expandAndParseSchedules(items);
  }

  Future<void> fetchSchedules(String travelId) async {
    try {
      final items = await repository.getSchedules(travelId);
      if (items.isNotEmpty) {
        state = _expandAndParseSchedules(items);
      }
    } catch (e) {
      print('스케줄 불러오기 실패: $e');
    }
  }

  Future<void> fetchFriendSchedules(String travelId) async {
    try {
      final items = await repository.getFriendSchedules(travelId);
      if (items.isNotEmpty) {
        state = _expandAndParseSchedules(items);
      }
    } catch (e) {
      print('친구 스케줄 불러오기 실패: $e');
    }
  }

  void updateCategoryLocally(String scheduleId, ScheduleType newCategory) {
    state = state.map((item) {
      if (item.schedule_id.toString() == scheduleId.toString()) {
        return item.copyWith(category: newCategory);
      }
      return item;
    }).toList();
  }

  void updateMemo(String id, String memo) {
    state = state.map((item) {
      if (item.schedule_id.toString() == id.toString()) {
        return item.copyWith(memo: memo);
      }
      return item;
    }).toList();
  }

  void updateMemoLocally(String scheduleId, int newMemoId, String newContent) {
    state = state.map((item) {
      if (item.schedule_id.toString() == scheduleId.toString()) {
        return item.copyWith(memo_id: newMemoId, memo_content: newContent);
      }
      return item;
    }).toList();
  }

  void updateTimeLocally(String scheduleId, String newTime) {
    state = state.map((item) {
      if (item.schedule_id.toString() == scheduleId.toString()) {
        return item.copyWith(start_time: newTime);
      }
      return item;
    }).toList();
  }

  Future<void> fetchAndSyncMemo(String scheduleId) async {
    try {
      final latestMemo = await repository.getScheduleMemo(scheduleId);
      updateMemo(scheduleId, latestMemo);
    } catch (e) {
      print('메모 동기화 실패: $e');
    }
  }
}

final dayItemsProvider = Provider<List<ScheduleModel>>((ref) {
  final day = ref.watch(selectedDayProvider);
  final items = ref.watch(scheduleProvider);
  return items.where((i) => i.day_number == day).toList()
    ..sort((a, b) => a.start_time.compareTo(b.start_time));
});

final mapPinsProvider =
    FutureProvider.family<List<ScheduleModel>, String>((ref, travelId) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getTravelMapPins(travelId);
});