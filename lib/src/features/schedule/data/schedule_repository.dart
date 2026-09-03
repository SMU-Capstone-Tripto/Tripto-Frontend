import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart' hide handleDioError;
import '../domain/schedule_model.dart';

class ScheduleRepository {
  final Dio _dio;
  ScheduleRepository(this._dio);

  Future<List<ScheduleModel>> getSchedules(String travelId) async {
    try {
      final res = await _dio.get('/schedules/travel/$travelId');
      final list = res.data as List;
      return list.map((e) => ScheduleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<List<ScheduleModel>> getTravelMapPins(String travelId) async {
    try {
      final res = await _dio.get('/travels/$travelId/map');
      final list = res.data as List;
      return list.map((e) => ScheduleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<List<ScheduleModel>> getFriendSchedules(String travelId) async {
    try {
      final res = await _dio.get('/feed/$travelId');
      final schedulesList = res.data['schedules'] as List? ?? [];
      return schedulesList
          .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // 💡 새 일정 생성 (POST /schedules)
  Future<ScheduleModel> createSchedule({
    required int travelId,
    required int dayNumber,
    required String dateStr,
    required String placeName,
    String? placeAddress,
    required String category,
    required String startTime,
    int? cost,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await _dio.post('/schedules', data: {
        'travel_id': travelId,
        'day_number': dayNumber,
        'date': dateStr,
        'order_index': 0,
        'place_name': placeName,
        'place_address': placeAddress ?? '',
        'category': category,
        'start_time': startTime.length == 5 ? '$startTime:00' : startTime,
        'cost': cost ?? 0,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
      return ScheduleModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // 💡 일정 전체 정보 수정 (PATCH /schedules/{schedule_id})
  Future<void> updateScheduleItemData({
    required int scheduleId,
    String? placeName,
    String? placeAddress,
    String? category,
    String? startTime,
    int? cost,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (placeName != null) data['place_name'] = placeName;
      if (placeAddress != null) data['place_address'] = placeAddress;
      if (category != null) data['category'] = category;
      if (startTime != null) {
        data['start_time'] = startTime.length == 5 ? '$startTime:00' : startTime;
      }
      if (cost != null) data['cost'] = cost;

      await _dio.patch('/schedules/$scheduleId', data: data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // 💡 일정 삭제 (DELETE /schedules/{schedule_id})
  Future<void> deleteSchedule(int scheduleId) async {
    try {
      await _dio.delete('/schedules/$scheduleId');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<int> createMemo(int scheduleId, String content) async {
    try {
      final res = await _dio.post(
        '/memos',
        data: {
          'schedule_id': scheduleId,
          'content': content,
        },
      );
      return int.parse(res.data['id'].toString());
    } catch (e) {
      throw Exception('메모 생성 실패: $e');
    }
  }

  Future<void> updateMemo(int memoId, String content) async {
    try {
      await _dio.patch(
        '/memos/$memoId',
        data: {
          'content': content,
        },
      );
    } catch (e) {
      throw Exception('메모 수정 실패: $e');
    }
  }

  Future<void> deleteMemo(int memoId) async {
    try {
      await _dio.delete('/memos/$memoId');
    } catch (e) {
      throw Exception('메모 삭제 실패: $e');
    }
  }

  Future<String> getScheduleMemo(String scheduleId) async {
    try {
      final res = await _dio.get('/schedules/$scheduleId');
      final memos = res.data['memos'] as List?;
      if (memos != null && memos.isNotEmpty) {
        return memos.last['content'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> updateScheduleTime(int scheduleId, String newTime) async {
    try {
      await _dio.patch(
        '/schedules/$scheduleId',
        data: {
          'start_time': newTime.length == 5 ? '$newTime:00' : newTime,
        },
      );
    } catch (e) {
      throw Exception('시간 수정 실패: $e');
    }
  }

  Future<void> updateScheduleCategory(int scheduleId, String newCategory) async {
    try {
      await _dio.patch(
        '/schedules/$scheduleId',
        data: {
          'category': newCategory,
        },
      );
    } catch (e) {
      throw Exception('카테고리 수정 실패: $e');
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ScheduleRepository(dio);
});