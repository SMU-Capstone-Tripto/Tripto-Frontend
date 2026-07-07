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
