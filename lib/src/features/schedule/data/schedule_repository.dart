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

  /// 특정 여행의 지도 핀(마커) 목록 조회
  Future<List<ScheduleModel>> getTravelMapPins(String travelId) async {
    try {
      // 이미지에 나와있는 엔드포인트 호출
      final res = await _dio.get('/travels/$travelId/map');

      final list = res.data as List;
      // 응답 형태가 기존 스케줄 모델과 호환된다고 가정합니다.
      return list.map((e) => ScheduleModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// 친구 피드용 스케줄 조회
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

  // 1. 메모 생성 (POST)
  Future<void> createMemo(int scheduleId, String content) async {
    try {
      await _dio.post(
        '/memos',
        data: {
          'schedule_id': scheduleId,
          'content': content, // Swagger에 정의된 키값으로 변경하세요
        },
      );
    } catch (e) {
      throw Exception('메모 생성 실패: $e');
    }
  }

  // 2. 메모 수정 (PATCH)
  Future<void> updateMemo(int memoId, String content) async {
    try {
      await _dio.patch(
        '/memos/$memoId',
        data: {
          'content': content, // Swagger에 정의된 키값으로 변경하세요
        },
      );
    } catch (e) {
      throw Exception('메모 수정 실패: $e');
    }
  }

  // 3. 메모 삭제 (DELETE) - 당장 쓰지 않더라도 미리 만들어두면 좋습니다.
  Future<void> deleteMemo(int memoId) async {
    try {
      await _dio.delete('/memos/$memoId');
    } catch (e) {
      throw Exception('메모 삭제 실패: $e');
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ScheduleRepository(dio);
});
