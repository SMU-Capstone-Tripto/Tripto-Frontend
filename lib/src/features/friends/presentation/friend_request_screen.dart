<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/auth_storage.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  // ── 요청 목록 API 호출 ──
  Future<void> _fetchRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/friends/requests/received'),
        headers: AuthStorage.authHeaders,
      );
      if (response.statusCode == 200) {
        setState(() => _requests = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("요청 목록 조회 실패: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── 수락/거절 API 호출 ──
  Future<void> _respond(int friendshipId, String action) async {
    final response = await http.patch(
      Uri.parse('${AuthStorage.baseUrl}/friends/request/respond'),
      headers: AuthStorage.authHeaders,
      body: jsonEncode({'friendship_id': friendshipId, 'action': action}),
    );
    if (response.statusCode == 200) {
      _fetchRequests(); // 목록 갱신
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(action == 'accept' ? '친구 요청을 수락했습니다.' : '요청을 거절했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('받은 친구 요청')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('받은 요청이 없습니다.'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return ListTile(
                      title: Text(req['requester']['nickname']),
                      subtitle:
                          Text('ID: ${req['requester']['friend_unique_id']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                              onPressed: () =>
                                  _respond(req['friendship_id'], 'accept'),
                              child: const Text('수락')),
                          TextButton(
                              onPressed: () =>
                                  _respond(req['friendship_id'], 'reject'),
                              child: const Text('거절',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
=======
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
>>>>>>> origin/chatting
