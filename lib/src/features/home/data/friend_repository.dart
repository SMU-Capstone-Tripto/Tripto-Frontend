import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/friend_model.dart';
import '../../home/domain/friend_request_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';

class FriendRepository {
  final Dio _dio;
  FriendRepository(this._dio);

  // ── 1. 친구 목록 조회 (GET) ──
  Future<List<FriendModel>> getFriends() async {
    try {
      final res = await _dio.get('/friends/list');

      print('😎 [디버그] 서버가 준 친구 목록: ${res.data}');

      final list = res.data as List;
      return list.map((e) => FriendModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 2. 친구 삭제 (DELETE) ──
  Future<void> deleteFriend(String friendId) async {
    try {
      await _dio.delete('/friends/$friendId');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 3. 친구 추가 요청 (POST) ──
  Future<void> addFriend(String targetUniqueId) async {
    try {
      await _dio
          .post('/friends/request', data: {'friend_unique_id': targetUniqueId});
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 4. 친구 검색 (GET) ──
  Future<FriendModel?> searchUserByUniqueId(String uniqueId) async {
    try {
      final res = await _dio.get(
        '/friends/search/$uniqueId',
      );

      if (res.data == null || res.data.toString().isEmpty) return null;
      return FriendModel.fromJson(res.data);
    } on DioException catch (e) {
      // 404 Not Found (사용자 없음)인 경우 에러 대신 null 반환
      if (e.response?.statusCode == 404) return null;
      throw handleDioError(e);
    }
  }

  // ── 5. 받은 친구 요청 목록 조회 (GET) ──
  Future<List<FriendRequestModel>> getReceivedRequests() async {
    try {
      final res = await _dio.get('/friends/requests/received');
      final list = res.data as List;
      // 방금 만든 FriendRequestModel로 변환
      return list.map((e) => FriendRequestModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 6. 친구 요청 수락/거절 (PATCH) ──
  Future<void> respondToFriendRequest(int friendshipId, bool isAccept) async {
    try {
      await _dio.patch('/friends/request/respond', data: {
        'friendship_id': friendshipId,
        'is_accept': isAccept,
      });
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}

// ── Provider ──
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return FriendRepository(dio);
});
