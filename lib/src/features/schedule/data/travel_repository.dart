import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/travel_model.dart';
import '../../../core/network/dio_client.dart';
<<<<<<< HEAD
import '../../../core/network/api_exception.dart' hide handleDioError;
=======
import '../../../core/network/api_exception.dart';
>>>>>>> origin/chatting

class TravelRepository {
  final Dio _dio;
  TravelRepository(this._dio);

  // ── 1. 내 여행 목록 조회 (GET) ──
  Future<List<TravelModel>> getTravels() async {
    try {
<<<<<<< HEAD
      final res = await _dio.get('/travels');
=======
      const ownerId = 1;

      final res = await _dio.get(
        '/travels',
        queryParameters: {'owner_id': ownerId}, // 👈 쿼리 파라미터 추가!
      );
>>>>>>> origin/chatting

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
<<<<<<< HEAD

// 화면에서 데이터를 읽어올 때 사용할 Provider
final savedTravelsProvider = FutureProvider<List<TravelModel>>((ref) async {
  return ref.watch(travelRepositoryProvider).getTravels();
});
=======
>>>>>>> origin/chatting
