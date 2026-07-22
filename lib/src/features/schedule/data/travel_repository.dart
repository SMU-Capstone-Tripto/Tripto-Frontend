import 'package:dio/dio.dart';
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
      // 1. 피드 API를 호출해서 모든 친구의 여행 일정을 통째로 가져옵니다.
      final res = await _dio.get('/feed');

      final list = res.data as List;

      // 2. 💡 여기가 핵심! 리스트 중에서 'owner_id'가 내가 누른 친구의 ID와 일치하는 것만 걸러냅니다.
      final filteredList = list.where((e) {
        final item = e as Map<String, dynamic>;
        // JSON 데이터의 owner_id와 전달받은 friendId가 같은지 비교
        return item['owner_id'] == friendId;
      }).toList();

      // 3. 걸러낸 데이터만 모델로 변환해서 화면에 넘겨줍니다.
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
      // 명세서에 맞춰 /feed/{travel_id} 호출
      final res = await _dio.get('/feed/$travelId');
      return TravelModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}

// Provider를 통해 외부에서 TravelRepository를 주입받아 사용할 수 있도록 설정
final travelRepositoryProvider = Provider<TravelRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return TravelRepository(dio);
});

// 화면에서 데이터를 읽어올 때 사용할 Provider
final savedTravelsProvider = FutureProvider<List<TravelModel>>((ref) async {
  return ref.watch(travelRepositoryProvider).getTravels();
});

// 친구 여행 목록 조회를 위한 Provider
final friendTravelsProvider = FutureProvider.autoDispose
    .family<List<TravelModel>, int>((ref, friendId) async {
  return ref.watch(travelRepositoryProvider).getFriendTravels(friendId);
});

// 친구 여행 상세 조회를 위한 Provider
final friendTravelDetailProvider =
    FutureProvider.autoDispose.family<TravelModel, int>((ref, travelId) async {
  return ref.watch(travelRepositoryProvider).getFriendTravelDetail(travelId);
});
