// lib/src/features/home/data/friend_repository.dart 수정본

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
      return list.map((e) {
        final Map<String, dynamic> itemMap = e as Map<String, dynamic>;
        final userData = itemMap['user'] as Map<String, dynamic>? ?? {};
        return FriendModel.fromJson(userData);
      }).toList();
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

  // ── 3. 친구 추가 (POST) ──
  Future<void> addFriend(String targetUniqueId) async {
    try {
      await _dio.post('/friends', data: {'unique_id': targetUniqueId});
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 🛠️ 4. 실시간 유저 검색 기능 추가 (GET) ──
  Future<FriendModel?> searchUser(String uniqueId) async {
    try {
      // 백엔드 명세 규격에 맞추어 queryParameters 래핑 전달
      final res = await _dio.get(
        '/users/search',
        queryParameters: {'unique_id': uniqueId},
      );
      
      if (res.data == null) return null;
      return FriendModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 서버가 유저를 찾지 못해 404를 반환할 경우 에러로 터뜨리지 않고 안전하게 null 리턴
      if (e.response?.statusCode == 404) return null;
      throw handleDioError(e);
    }
  }
}

// ── Provider ──
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return FriendRepository(dio);
});