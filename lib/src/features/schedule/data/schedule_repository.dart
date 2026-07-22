import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/schedule_model.dart';

class ScheduleRepository {
  final Dio _dio;
  ScheduleRepository(this._dio);

  /// 특정 여행의 일별 세부 일정 조회
  Future<List<ScheduleModel>> getSchedules(String travelId) async {
    try {
      final res = await _dio.get('/schedules/travel/$travelId/');
      final list = res.data as List;
      return list.map((e) => ScheduleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<List<ScheduleModel>> getFriendSchedules(String travelId) async {
    try {
      // Base URL이 적용되어 있으므로 '/feed/$travelId' 로 호출합니다.
      final res = await _dio.get('/feed/$travelId');

      // API 응답 구조를 보면 상세 정보 안에 "schedules"라는 배열이 들어있습니다.
      // 이 배열만 쏙 빼서 ScheduleModel 리스트로 변환합니다.
      final schedulesList = res.data['schedules'] as List? ?? [];

      return schedulesList
          .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ScheduleRepository(dio);
});
