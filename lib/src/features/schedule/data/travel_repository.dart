import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/travel_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart' hide handleDioError;

class TravelRepository {
  final Dio _dio;
  TravelRepository(this._dio);

  // ── 1. 내 여행 목록 조회 (GET) ──
  Future<List<TravelModel>> getTravels() async {
    try {
      final res = await _dio.get('/travels');
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

  // ── 4. 친구 여행 목록 조회 (GET) ──
  Future<List<TravelModel>> getFriendTravels(int friendId) async {
    try {
      final res = await _dio.get('/feed');
      final list = res.data as List;

      final filteredList = list.where((e) {
        final item = e as Map<String, dynamic>;
        return item['owner_id'] == friendId;
      }).toList();

      return filteredList
          .map((e) => TravelModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 5. 친구 여행 상세 조회 (GET) ──
  Future<TravelModel> getFriendTravelDetail(int travelId) async {
    try {
      final res = await _dio.get('/feed/$travelId');
      return TravelModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 6. 여행 상세 원본 조회 (타입 캐스팅 함정 방어 및 디버그 로깅) ──
  Future<Map<String, dynamic>> getTravelDetailRaw(String travelId) async {
    try {
      Response res;
      try {
        res = await _dio.get('/travels/$travelId');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // 백엔드 단수/복수 라우트 방어
          res = await _dio.get('/travel/$travelId');
        } else {
          rethrow;
        }
      }

      debugPrint('📡 [TravelDetail API] 응답 코드: ${res.statusCode}');

      if (res.data != null && res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return {};
    } on DioException catch (e) {
      debugPrint('🚨 [TravelDetail API 에러]: 상태코드=${e.response?.statusCode}, 메시지=$e');
      throw handleDioError(e);
    } catch (e) {
      debugPrint('🚨 [TravelDetail 기타 파싱 에러]: $e');
      return {};
    }
  }
}

final travelRepositoryProvider = Provider<TravelRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return TravelRepository(dio);
});

final savedTravelsProvider = FutureProvider<List<TravelModel>>((ref) async {
  return ref.watch(travelRepositoryProvider).getTravels();
});

final friendTravelsProvider = FutureProvider.autoDispose
    .family<List<TravelModel>, int>((ref, friendId) async {
  return ref.watch(travelRepositoryProvider).getFriendTravels(friendId);
});

final friendTravelDetailProvider =
    FutureProvider.autoDispose.family<TravelModel, int>((ref, travelId) async {
  return ref.watch(travelRepositoryProvider).getFriendTravelDetail(travelId);
});