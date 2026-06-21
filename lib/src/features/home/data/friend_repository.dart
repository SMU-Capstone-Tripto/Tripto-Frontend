import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/friend_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';

class FriendRepository {
  final Dio _dio;
  FriendRepository(this._dio);

  // ── 1. 친구 목록 조회 (GET) ──
  Future<List<FriendModel>> getFriends() async {
    try {
      final res = await _dio.get('/friends/list');
      final list = res.data as List;
      return list.map((e) => FriendModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 2. 친구 삭제 (DELETE) ──
  Future<void> deleteFriend(String friendId) async {
    try {
      // API 주소는 백엔드 명세에 맞게 설정 (예: /friends/f1)
      await _dio.delete('/friends/$friendId');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 3. 친구 추가 (POST) ──
  Future<void> addFriend(String targetUniqueId) async {
    try {
      await _dio.post('/friends', data: {'unique_id': targetUniqueId});
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
