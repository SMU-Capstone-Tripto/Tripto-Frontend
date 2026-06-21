import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/travel_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';

class TravelRepository {
  final Dio _dio;
  TravelRepository(this._dio);

  // ── 1. 내 여행 목록 조회 (GET) ──
  Future<List<TravelModel>> getTravels() async {
    try {
      // 💡 서버가 쿼리로 요구하는 owner_id 값을 설정합니다.
      // (현재 로그인한 유저의 ID 문자열을 넣어주시면 됩니다. 예시: 'test_owner_id')
      const ownerId = 1;

      final res = await _dio.get(
        '/travels',
        queryParameters: {'owner_id': ownerId}, // 👈 쿼리 파라미터 추가!
      );

      final list = res.data as List;
      return list
          .map((e) => TravelModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 2. 새 여행 생성 (POST) ──
  Future<void> createTravel(TravelModel newTravel) async {
    try {
      await _dio.post('/travels', data: newTravel.toCreateJson());
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 3. 여행 삭제 (DELETE) ──
  Future<void> deleteTravel(String travelId) async {
    try {
      await _dio.delete('/travels/$travelId');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}

// ── Provider ──
final travelRepositoryProvider = Provider<TravelRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return TravelRepository(dio);
});
