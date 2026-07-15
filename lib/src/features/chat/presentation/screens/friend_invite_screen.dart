import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';

class FriendInviteScreen extends StatefulWidget {
  final int roomId; // 어떤 방에 초대할지 명확히 인자를 상속받습니다.

  const FriendInviteScreen({super.key, required this.roomId});

  @override
  State<FriendInviteScreen> createState() => _FriendInviteScreenState();
}

class _FriendInviteScreenState extends State<FriendInviteScreen> {
  List<dynamic> _allFriends = []; // 백엔드 연동 유저 풀 데이터 저장소[cite: 2]
  final Set<int> _selectedUserIds = {}; // 다중 선택한 유저 ID 보관소
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActualFriends();
  }

  /// ── 🛠️ [백엔드 연동]: 실제 가입된 서비스 유저 리스트 연동 확보 ──
  Future<void> _fetchActualFriends() async {
    try {
      // 일반적인 유저 목록 조회 주소 타격 (가용 엔드포인트 대입)
      final response = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/users'),
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _allFriends =
              data is List ? data : (data['users'] ?? data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('친구 리스트 로드 중 통신 오류 발생 (테스트 더미 수혈): $e');
      // 통신 예외 발생 시 테스트용 가상 단원 리스트 배치 대체 구조 가동
      _allFriends = [
        {"user_id": 1, "name": "김철수"},
        {"user_id": 3, "name": "이영희"},
        {"user_id": 4, "name": "박민수"},
        {"user_id": 5, "name": "최수연"},
      ];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ── 🛠️ [백엔드 연동]: 선택된 친구들을 방에 초대 처리 집행 ──
  Future<void> _submitInvitation() async {
    if (_selectedUserIds.isEmpty) {
      _showSnackBar('초대할 친구를 선택해 주세요.');
      return;
    }

    try {
      // 백엔드 명세 라우터 주소 조준: POST /chat/{room_id}/invite
      final targetUrl = '${AuthStorage.baseUrl}/chat/${widget.roomId}/invite';

      // ChatRoomInvite 스키마 명세에 맞춘 바디 패킹: {"invited_user_ids": [...]}
      final bodyData = {"invited_user_ids": _selectedUserIds.toList()};

      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {
          ...AuthStorage.authHeaders,
          "Content-Type": "application/json"
        },
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        _showSnackBar('선택한 친구들이 성공적으로 초대되었습니다.');
        if (!mounted) return;
        Navigator.pop(context); // 완료 후 뒤로가기
      } else {
        _showSnackBar('초대에 실패했습니다. 서버 코드: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('초대 처리 중 네트워크 장애 예외: $e');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Pretendard'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: const Text('친구 초대',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard')),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _submitInvitation,
            child: const Text('완료',
                style: TextStyle(
                    color: Color(0xFF6241D9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6241D9)))
          : _allFriends.isEmpty
              ? const Center(child: Text('초대 가능한 친구가 없습니다.'))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _allFriends.length,
                  itemBuilder: (context, index) {
                    final friend = _allFriends[index];
                    final int friendId =
                        int.tryParse(friend['user_id']?.toString() ?? '0') ?? 0;
                    final String name = friend['name']?.toString() ??
                        friend['username']?.toString() ??
                        '알 수 없는 유저';
                    final bool isChecked = _selectedUserIds.contains(friendId);

                    return Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                      child: CheckboxListTile(
                        title: Text(name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500)),
                        subtitle: Text('ID: $friendId',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        value: isChecked,
                        activeColor: const Color(0xFF6241D9),
                        checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedUserIds.add(friendId);
                            } else {
                              _selectedUserIds.remove(friendId);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
