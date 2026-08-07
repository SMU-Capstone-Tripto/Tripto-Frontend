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

  // 1. 메모 생성 (POST) - 새로 만들어진 메모의 ID(int)를 반환하도록 수정!
  Future<int> createMemo(int scheduleId, String content) async {
    try {
      final res = await _dio.post(
        '/memos', // 💡 만약 307이나 404 에러가 나면 '/memos/' 처럼 끝에 슬래시를 붙여보세요!
        data: {
          'schedule_id': scheduleId,
          'content': content,
        },
      );
      // 백엔드가 준 응답 데이터에서 'id'를 뽑아냅니다.
      return int.parse(res.data['id'].toString());
    } catch (e) {
      print('🚨 API 에러(createMemo): $e');
      throw Exception('메모 생성 실패: $e');
    }
  }

  // 2. 메모 수정 (PATCH)
  Future<void> updateMemo(int memoId, String content) async {
    try {
      await _dio.patch(
        '/memos/$memoId',
        data: {
          'content': content,
        },
      );
    } catch (e) {
      print('🚨 API 에러(updateMemo): $e');
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

  // ── 💡 새로 추가: 특정 스케줄의 최신 메모 가져오기 ──
  Future<String> getScheduleMemo(String scheduleId) async {
    try {
      final res = await _dio.get('/schedules/$scheduleId');

      final memos = res.data['memos'] as List?;
      if (memos != null && memos.isNotEmpty) {
        // 메모가 여러 개일 경우 가장 첫 번째(또는 마지막) 메모의 내용을 가져옵니다.
        return memos.last['content'] ?? '';
      }
      return '';
    } catch (e) {
      print('단건 메모 조회 에러: $e');
      return '';
    }
  }

  // 특정 스케줄의 시간(start_time) 수정하기
  Future<void> updateScheduleTime(int scheduleId, String newTime) async {
    try {
      // API 명세(Swagger)에 일정 수정 엔드포인트가 PATCH /schedules/{id} 인지 확인 후 맞춰주세요!
      await _dio.patch(
        '/schedules/$scheduleId',
        data: {
          'start_time': newTime, // 백엔드가 요구하는 시간 포맷에 맞게 키값을 설정하세요
        },
      );
    } catch (e) {
      print('🚨 시간 수정 실패: $e');
      throw Exception('시간 수정 실패: $e');
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ScheduleRepository(dio);
});
