import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/schedule_model.dart';
import '../data/schedule_repository.dart';
import '../data/travel_repository.dart';

final selectedDayProvider = StateProvider<int>((ref) => 1);

final scheduleProvider =
    StateNotifierProvider<ScheduleItemsNotifier, List<ScheduleModel>>(
  (ref) {
    final scheduleRepo = ref.watch(scheduleRepositoryProvider);
    final travelRepo = ref.watch(travelRepositoryProvider);
    return ScheduleItemsNotifier(scheduleRepo, travelRepo);
  },
);

class _CostExtractResult {
  final int? cost;
  final String text;
  const _CostExtractResult(this.cost, this.text);
}

class ScheduleItemsNotifier extends StateNotifier<List<ScheduleModel>> {
  final ScheduleRepository repository;
  final TravelRepository travelRepository;

  // 여행 ID별 독립 메모리 캐시 (travelId -> List<ScheduleModel>)
  static final Map<String, List<ScheduleModel>> _detailedScheduleCache = {};
  
  // 현재 보고 있는 여행 ID 추적 (데이터 혼선 방지)
  String? _currentTravelId;

  ScheduleItemsNotifier(this.repository, this.travelRepository) : super([]);

  static ScheduleType _detectCategory(String text) {
    final lower = text.toLowerCase();

    const moveKeywords = [
      '이동', '탑승', '도착', '출발', '공항', '역', '터미널', 'ktx', 'srt',
      '버스', '지하철', '택시', '비행기', '항공', '렌트', '렌터', '차량',
      '드라이브', '도보', '걷기', '페리', '여객선', '배', '케이블카', '모노레일', '환승',
      '귀가', '집결', '출국', '입국', '->', '→', '행'
    ];
    if (moveKeywords.any((k) => lower.contains(k))) return ScheduleType.move;

    const eatKeywords = [
      '식사', '맛집', '점심', '저녁', '아침', '조식', '중식', '석식', '야식', '간식',
      '식당', '카페', '커피', '디저트', '브런치', '베이커리', '빵집', '음식점', '레스토랑',
      '밥', '고기', '구이', '삼겹살', '갈비', '회', '초밥', '스시', '라멘', '국밥',
      '찌개', '탕', '파스타', '피자', '버거', '치킨', '맥주', '펍', '바', '주점',
      '이자카야', '먹거리', '포장마차', '시장', '테이크아웃', '음료', '티타임', '음식',
      '해물', '조개구이', '밀면', '돼지국밥', '막국수', '떡볶이', '분식', '만두', '우동',
      '돈가스', '돈까스', '칼국수', '냉면', '바베큐', 'bbq'
    ];
    if (eatKeywords.any((k) => lower.contains(k))) return ScheduleType.eat;

    const stayKeywords = [
      '호텔', '숙소', '리조트', '펜션', '게스트하우스', '게하', '모텔', '에어비앤비', 'airbnb',
      '민박', '글램핑', '캠핑', '호스텔', '체크인', '체크아웃', '입실', '퇴실',
      '숙박', '취침', '짐 풀기', '짐 보관', '짐 맡기기', '호캉스', '풀빌라'
    ];
    if (stayKeywords.any((k) => lower.contains(k))) return ScheduleType.stay;

    return ScheduleType.activity;
  }

  static bool _isHeaderOrDateOnly(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;

    if (RegExp(r'\d{1,2}:\d{2}').hasMatch(t)) return false;
    if (RegExp(r'^\[?\s*(?:Day\s*\d+|\d+일차)[^\]\n]*\]?$', caseSensitive: false).hasMatch(t)) {
      return true;
    }
    if (t == '일정' || t == '상세 일정' || t == '여행 일정' || t == '코스' || t == '일정표') return true;
    if (RegExp(r'^\[?\s*(?:\d{4}[-./년\s]*)?\d{1,2}[-./월\s]*\d{1,2}(?:일)?\s*(?:\([A-Za-z가-힣]+\))?\s*\]?$').hasMatch(t)) return true;

    return false;
  }

  static String _cleanDateAndHeaderPrefix(String text) {
    String s = text.trim();
    s = s.replaceAll(RegExp(r'[\*\_`~]'), '').trim();
    s = s.replaceAll(RegExp(r'^([-•*#]+|\d+[\.\)]\s*)'), '').trim();
    s = s.replaceAll(RegExp(r'^\[?\s*(?:Day\s*\d+|\d+일차)[^\n:\-\]]*[:\-\]]*\s*', caseSensitive: false), '').trim();
    s = s.replaceAll(RegExp(r'^\[?\s*(?:\d{4}[-./년\s]+)?\d{1,2}[-./월\s]+\d{1,2}(?:일)?\s*(?:\([A-Za-z가-힣]+\))\s*\]?\s*[:\-\s~–—→>]*\s*', caseSensitive: false), '').trim();
    s = s.replaceAll(RegExp(r'^\[?\s*\d{4}[-./]\d{1,2}[-./]\d{1,2}\s*\]?\s*[:\-\s~–—→>]*\s*'), '').trim();
    return s;
  }

  static String stripTimePrefix(String text) {
    String s = text.trim();
    s = s.replaceAll(
      RegExp(r'^\[?\s*(?:(?:오전|오후|AM|PM)\s*)?\d{1,2}:\d{2}(?:\s*(?:~|-|→|->)\s*(?:(?:오전|오후|AM|PM)\s*)?\d{1,2}:\d{2})?\s*\]?\s*[:\-\s~–—→>]*', caseSensitive: false),
      '',
    ).trim();
    s = s.replaceAll(RegExp(r'^[:\-\s~–—→>]+'), '').trim();
    return s;
  }

  static _CostExtractResult _extractAndCleanCost(String text, int? existingCost) {
    int? cost = (existingCost != null && existingCost > 0) ? existingCost : null;
    String cleaned = text;

    cleaned = cleaned.replaceAll(RegExp(r'[·,/~–—\s]*요금\s*미정', caseSensitive: false), '').trim();

    final costRegex = RegExp(
      r'(?:[·,/~–—\s]*)(?:(?:예상\s*비용|비용|경비|약|1인당|1인|인당|요금)\s*[:\s]*)?([\d,]+)\s*원',
      caseSensitive: false,
    );

    final match = costRegex.firstMatch(cleaned);
    if (match != null) {
      final rawNumber = match.group(1)?.replaceAll(',', '').trim() ?? '';
      final parsed = int.tryParse(rawNumber);
      if (parsed != null && parsed > 0) {
        cost ??= parsed;
      }
      cleaned = cleaned.replaceFirst(match.group(0)!, '').trim();
    }

    cleaned = cleaned.replaceAll(RegExp(r'[·,·/]\s*\)'), ')');
    cleaned = cleaned.replaceAll(RegExp(r'\(\s*[·,·/]'), '(');
    cleaned = cleaned.replaceAll(RegExp(r'\(\s*\)'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\[\s*\]'), '').trim();

    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }

    cleaned = cleaned.replaceAll(RegExp(r'[\s\-:–—,·]+$'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[\s\-:–—,·]+'), '').trim();

    return _CostExtractResult(cost, cleaned.isNotEmpty ? cleaned : text);
  }

  static List<ScheduleModel> parseItinerary(List<dynamic> itineraries, {String city = ''}) {
    final List<ScheduleModel> result = [];
    int globalCounter = 1;

    for (int dayIdx = 0; dayIdx < itineraries.length; dayIdx++) {
      final int dayNum = dayIdx + 1;
      final dynamic rawDay = itineraries[dayIdx];

      if (rawDay is Map) {
        final String rawTitle = rawDay['title'] ?? rawDay['place_name'] ?? rawDay['content'] ?? '상세 일정';
        String cleanTitle = _cleanDateAndHeaderPrefix(rawTitle);
        cleanTitle = stripTimePrefix(cleanTitle);

        final existingCost = int.tryParse(rawDay['cost']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '');
        final costExtract = _extractAndCleanCost(cleanTitle, existingCost);
        cleanTitle = costExtract.text;
        final cost = costExtract.cost;

        final String time = rawDay['start_time'] ?? rawDay['time'] ?? '10:00:00';
        final int day = int.tryParse(rawDay['day_number']?.toString() ?? rawDay['day']?.toString() ?? '') ?? dayNum;

        result.add(
          ScheduleModel(
            schedule_id: 'itin_${day}_${globalCounter++}',
            title: cleanTitle.isNotEmpty ? cleanTitle : '상세 일정',
            content: cleanTitle,
            start_time: time.length == 5 ? '$time:00' : time,
            category: _detectCategory(cleanTitle),
            day_number: day,
            place_name: rawDay['place_name'] != null ? stripTimePrefix(rawDay['place_name']) : cleanTitle,
            place_address: rawDay['place_address'] ?? city,
            cost: cost,
          ),
        );
        continue;
      }

      String dayStr = rawDay.toString().trim();
      List<String> rawChunks = [];
      if (dayStr.contains('\n')) {
        rawChunks = dayStr.split('\n');
      } else if (dayStr.contains('→') || dayStr.contains('->')) {
        rawChunks = dayStr.split(RegExp(r'→|->'));
      } else if (dayStr.contains(',')) {
        rawChunks = dayStr.split(',');
      } else {
        rawChunks = [dayStr];
      }

      int currentMinute = 8 * 60;

      for (var chunk in rawChunks) {
        String trimmed = chunk.trim();
        if (trimmed.isEmpty) continue;

        if (_isHeaderOrDateOnly(trimmed)) continue;

        trimmed = _cleanDateAndHeaderPrefix(trimmed);
        if (trimmed.isEmpty || _isHeaderOrDateOnly(trimmed)) continue;

        final timeRegex = RegExp(
          r'^(?:\[?\s*(?:(오전|오후|AM|PM)\s*)?(\d{1,2}:\d{2})(?:\s*(?:~|-|→|->)\s*(?:(?:오전|오후|AM|PM)\s*)?\d{1,2}:\d{2})?\s*\]?)\s*(.*)',
          caseSensitive: false,
        );
        final match = timeRegex.firstMatch(trimmed);

        String timeStr;
        String text = trimmed;

        if (match != null) {
          final ampm = match.group(1)?.toUpperCase();
          final rawTime = match.group(2) ?? '';
          text = (match.group(3) ?? '').trim();

          final parts = rawTime.split(':');
          int hour = int.tryParse(parts[0]) ?? 10;
          final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

          if ((ampm == '오후' || ampm == 'PM') && hour < 12) {
            hour += 12;
          } else if ((ampm == '오전' || ampm == 'AM') && hour == 12) {
            hour = 0;
          }

          currentMinute = hour * 60 + minute;
          final formattedHour = hour.toString().padLeft(2, '0');
          final formattedMin = minute.toString().padLeft(2, '0');
          timeStr = '$formattedHour:$formattedMin:00';
          currentMinute += 45;
        } else {
          final h = (currentMinute ~/ 60) % 24;
          final m = currentMinute % 60;
          timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
          currentMinute += 30;
        }

        text = stripTimePrefix(text);

        final costExtract = _extractAndCleanCost(text, null);
        text = costExtract.text;
        final int? cost = costExtract.cost;

        if (text.isEmpty) text = trimmed.isNotEmpty ? trimmed : '일정';

        String placeName = text;
        if (placeName.contains('(')) {
          placeName = placeName.split('(')[0].trim();
        }
        if (placeName.contains(' - ')) {
          placeName = placeName.split(' - ')[0].trim();
        } else if (placeName.contains(' : ')) {
          placeName = placeName.split(' : ')[0].trim();
        }

        result.add(
          ScheduleModel(
            schedule_id: 'itin_${dayNum}_${globalCounter++}',
            title: text,
            content: text,
            start_time: timeStr,
            category: _detectCategory(text),
            day_number: dayNum,
            place_name: placeName.isNotEmpty ? placeName : text,
            place_address: city,
            cost: cost,
          ),
        );
      }
    }
    return result;
  }

  static List<ScheduleModel> _expandAndParseSchedules(List<ScheduleModel> rawItems) {
    final List<ScheduleModel> expanded = [];
    int globalCounter = 1;

    for (var item in rawItems) {
      if (_isHeaderOrDateOnly(item.title)) continue;

      String cleanTitle = _cleanDateAndHeaderPrefix(item.title);
      cleanTitle = stripTimePrefix(cleanTitle);

      final costExtract = _extractAndCleanCost(cleanTitle, item.cost);
      cleanTitle = costExtract.text;
      final int? finalCost = costExtract.cost;

      final String rawPlace = item.place_name ?? '';
      String cleanPlace = stripTimePrefix(rawPlace);
      cleanPlace = _extractAndCleanCost(cleanPlace, finalCost).text;

      final String finalPlace = cleanPlace.isNotEmpty ? cleanPlace : cleanTitle;

      expanded.add(
        ScheduleModel(
          schedule_id: item.schedule_id.isNotEmpty ? item.schedule_id : '${item.day_number}_${globalCounter++}',
          title: cleanTitle.isNotEmpty ? cleanTitle : '상세 일정',
          content: item.content ?? cleanTitle,
          start_time: item.start_time.isNotEmpty ? item.start_time : '10:00:00',
          category: item.category != ScheduleType.activity ? item.category : _detectCategory(cleanTitle),
          day_number: item.day_number,
          place_name: finalPlace,
          place_address: item.place_address ?? '',
          cost: finalCost,
          latitude: item.latitude,
          longitude: item.longitude,
          memo_id: item.memo_id,
          memo_content: item.memo_content,
        ),
      );
    }
    return expanded;
  }

  void setSchedules(List<ScheduleModel> items, {String? travelId}) {
    if (travelId != null && travelId.isNotEmpty) {
      _currentTravelId = travelId;
      _detailedScheduleCache[travelId] = items;
    }
    state = items;
  }

  Future<void> saveOrUpdateSchedule(
    ScheduleModel updatedItem, {
    required String travelId,
    required DateTime tripStartDate,
  }) async {
    final String oldId = updatedItem.schedule_id;
    final int? realId = int.tryParse(oldId);
    final int travelIdInt = int.tryParse(travelId) ?? 0;

    final scheduleDate = tripStartDate.add(Duration(days: updatedItem.day_number - 1));
    final dateStr =
        '${scheduleDate.year}-${scheduleDate.month.toString().padLeft(2, '0')}-${scheduleDate.day.toString().padLeft(2, '0')}';

    final categoryBackendMap = {
      ScheduleType.move: '이동',
      ScheduleType.eat: '식사',
      ScheduleType.stay: '숙소',
      ScheduleType.activity: '관광',
    };
    final catStr = categoryBackendMap[updatedItem.category] ?? '관광';

    ScheduleModel finalItem = updatedItem;

    try {
      if (realId != null && realId > 0) {
        await repository.updateScheduleItemData(
          scheduleId: realId,
          placeName: updatedItem.place_name,
          placeAddress: updatedItem.place_address,
          category: catStr,
          startTime: updatedItem.start_time,
          cost: updatedItem.cost,
        );
      } else if (travelIdInt > 0) {
        final created = await repository.createSchedule(
          travelId: travelIdInt,
          dayNumber: updatedItem.day_number,
          dateStr: dateStr,
          placeName: updatedItem.place_name ?? updatedItem.title,
          placeAddress: updatedItem.place_address,
          category: catStr,
          startTime: updatedItem.start_time,
          cost: updatedItem.cost,
        );
        finalItem = updatedItem.copyWith(schedule_id: created.schedule_id);
      }
    } catch (e) {
      debugPrint('서버 일정 동기화 실패 (로컬 우선 반영): $e');
    }

    final updatedList = state.map((item) {
      if (item.schedule_id == oldId) {
        return finalItem;
      }
      return item;
    }).toList();

    state = updatedList;
    _detailedScheduleCache[travelId] = updatedList;
  }

  Future<void> addScheduleDirectly(
    ScheduleModel newItem, {
    required String travelId,
    required DateTime tripStartDate,
  }) async {
    final int travelIdInt = int.tryParse(travelId) ?? 0;
    final scheduleDate = tripStartDate.add(Duration(days: newItem.day_number - 1));
    final dateStr =
        '${scheduleDate.year}-${scheduleDate.month.toString().padLeft(2, '0')}-${scheduleDate.day.toString().padLeft(2, '0')}';

    final categoryBackendMap = {
      ScheduleType.move: '이동',
      ScheduleType.eat: '식사',
      ScheduleType.stay: '숙소',
      ScheduleType.activity: '관광',
    };
    final catStr = categoryBackendMap[newItem.category] ?? '관광';

    ScheduleModel finalItem = newItem;

    try {
      if (travelIdInt > 0) {
        final created = await repository.createSchedule(
          travelId: travelIdInt,
          dayNumber: newItem.day_number,
          dateStr: dateStr,
          placeName: newItem.place_name ?? newItem.title,
          placeAddress: newItem.place_address,
          category: catStr,
          startTime: newItem.start_time,
          cost: newItem.cost,
        );
        finalItem = newItem.copyWith(schedule_id: created.schedule_id);
      }
    } catch (e) {
      debugPrint('신규 일정 서버 등록 실패 (로컬 우선 추가): $e');
    }

    final newList = [...state, finalItem];
    state = newList;
    _detailedScheduleCache[travelId] = newList;
  }

  Future<void> deleteScheduleItem(String scheduleId, {required String travelId}) async {
    final int? realId = int.tryParse(scheduleId);
    if (realId != null && realId > 0) {
      try {
        await repository.deleteSchedule(realId);
      } catch (e) {
        debugPrint('일정 삭제 서버 호출 실패: $e');
      }
    }

    final newList = state.where((item) => item.schedule_id != scheduleId).toList();
    state = newList;
    _detailedScheduleCache[travelId] = newList;
  }

  // 💡 [핵심 해결] 여행별 상태 격리 (이전 여행 데이터가 새 여행에 노출되지 않도록 조치)
  Future<void> fetchSchedules(String travelId) async {
    try {
      debugPrint('🚀 [fetchSchedules 시작] travelId: $travelId (기존 travelId: $_currentTravelId)');

      // 다른 여행으로 전환 시 이전 여행 데이터 즉시 비우고 캐시 확인
      if (_currentTravelId != travelId) {
        _currentTravelId = travelId;
        final cached = _detailedScheduleCache[travelId];
        if (cached != null && cached.isNotEmpty) {
          debugPrint('🛡️ [캐시 복원] 여행 $travelId 캐시 적용 (${cached.length}개)');
          state = cached;
          return;
        } else {
          // 캐시가 없으면 이전 여행 데이터를 화면에서 즉시 제거
          state = [];
        }
      } else {
        final cached = _detailedScheduleCache[travelId];
        if (cached != null && cached.isNotEmpty) {
          state = cached;
          return;
        }
      }

      // 1. GET /travels/{travel_id} 에서 itinerary 조회
      try {
        final travelDetail = await travelRepository.getTravelDetailRaw(travelId);
        dynamic rawItinerary = travelDetail['itinerary'];

        if (rawItinerary == null && travelDetail['data'] is Map) {
          rawItinerary = travelDetail['data']['itinerary'];
        }

        if (rawItinerary is String) {
          try {
            rawItinerary = jsonDecode(rawItinerary);
          } catch (_) {}
        }

        final String city = travelDetail['destination']?.toString() ?? travelDetail['city']?.toString() ?? '';

        if (rawItinerary is List && rawItinerary.isNotEmpty) {
          final parsedFromItinerary = parseItinerary(rawItinerary, city: city);
          if (parsedFromItinerary.isNotEmpty) {
            debugPrint('✅ [itinerary 파싱 성공] 여행 $travelId 아이템 ${parsedFromItinerary.length}개');
            state = parsedFromItinerary;
            _detailedScheduleCache[travelId] = parsedFromItinerary;
            return;
          }
        }
      } catch (e) {
        debugPrint('travel detail itinerary 파싱 실패: $e');
      }

      // 2. 수동 생성 일정이거나 DB schedules 조회
      final items = await repository.getSchedules(travelId);
      final parsed = items.isNotEmpty ? _expandAndParseSchedules(items) : <ScheduleModel>[];

      if (parsed.isNotEmpty) {
        debugPrint('✅ [DB schedules 파싱 성공] 여행 $travelId 아이템 ${parsed.length}개');
        state = parsed;
        _detailedScheduleCache[travelId] = parsed;
        return;
      }

      // 3. 해당 여행에 등록된 일정이 없다면 빈 리스트 표시 (이전 여행 데이터 유지 안 함)
      state = [];
    } catch (e) {
      debugPrint('🚨 [스케줄 불러오기 에러]: $e');
      final cached = _detailedScheduleCache[travelId];
      state = cached ?? [];
    }
  }

  Future<void> fetchFriendSchedules(String travelId) async {
    try {
      _currentTravelId = travelId;
      state = [];
      final items = await repository.getFriendSchedules(travelId);
      state = items.isNotEmpty ? _expandAndParseSchedules(items) : [];
    } catch (e) {
      debugPrint('친구 스케줄 불러오기 실패: $e');
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
      state = state.map((item) {
        if (item.schedule_id.toString() == scheduleId.toString()) {
          return item.copyWith(memo: latestMemo);
        }
        return item;
      }).toList();
    } catch (e) {
      debugPrint('메모 동기화 실패: $e');
    }
  }
}

final dayItemsProvider = Provider<List<ScheduleModel>>((ref) {
  final day = ref.watch(selectedDayProvider);
  final items = ref.watch(scheduleProvider);
  return items.where((i) => i.day_number == day).toList()
    ..sort((a, b) => a.start_time.compareTo(b.start_time));
});
/*
final mapPinsProvider =
    FutureProvider.family<List<ScheduleModel>, String>((ref, travelId) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getTravelMapPins(travelId);
});
*/