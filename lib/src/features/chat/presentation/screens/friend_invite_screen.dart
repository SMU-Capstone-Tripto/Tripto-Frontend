import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';

class FriendInviteScreen extends StatefulWidget {
  final int roomId;
  final List<int> existingMemberIds; 

  const FriendInviteScreen({
    super.key, 
    required this.roomId,
    required this.existingMemberIds,
  });

  @override
  State<FriendInviteScreen> createState() => _FriendInviteScreenState();
}

class _FriendInviteScreenState extends State<FriendInviteScreen> {
  List<Map<String, dynamic>> _allFriends = [];
  final Set<int> _selectedFriendIds = {};
  final Set<String> _selectedFriendNames = {};
  
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isInviting = false;
  String _myNickname = '나';

  @override
  void initState() {
    super.initState();
    _fetchMyProfileAndFriends();
  }

  Future<void> _fetchMyProfileAndFriends() async {
    try {
      final myRes = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/auth/me'),
        headers: AuthStorage.authHeaders,
      );
      if (myRes.statusCode == 200) {
        final myData = jsonDecode(utf8.decode(myRes.bodyBytes));
        _myNickname = myData['nickname'] ?? myData['name'] ?? '나';
      }

      final targetUrl = '${AuthStorage.baseUrl}/friends/list';
      final friendsRes = await http.get(
        Uri.parse(targetUrl),
        headers: AuthStorage.authHeaders,
      );

      List<dynamic> friendListRaw = [];

      if (friendsRes.statusCode == 200) {
        final dynamic responseData = jsonDecode(utf8.decode(friendsRes.bodyBytes));
        if (responseData is List) {
          friendListRaw = responseData;
        } else if (responseData is Map) {
          friendListRaw = responseData['friends'] ?? 
                          responseData['data'] ?? 
                          responseData['users'] ?? 
                          responseData['result'] ?? 
                          responseData['friend_list'] ?? [];
        }
      }

      final List<Map<String, dynamic>> parsed = [];

      for (var item in friendListRaw) {
        if (item is Map) {
          final dynamic targetObj = item['friend'] ?? item['user'] ?? item['target_user'] ?? item;

          final int? id = int.tryParse(
            targetObj['id']?.toString() ?? 
            targetObj['friend_id']?.toString() ?? 
            targetObj['user_id']?.toString() ?? 
            item['id']?.toString() ?? 
            item['friend_id']?.toString() ?? ''
          );

          final String name = targetObj['nickname']?.toString() ?? 
                              targetObj['name']?.toString() ?? 
                              targetObj['username']?.toString() ?? 
                              item['nickname']?.toString() ?? '친구';

          final String? img = targetObj['profile_image']?.toString() ?? 
                              targetObj['profile_img']?.toString() ?? 
                              targetObj['image']?.toString() ?? 
                              item['profile_image']?.toString();

          if (id != null && id > 0) {
            // 📌 방에 참여 중인 유저 엄격 체크
            final bool isAlreadyInRoom = widget.existingMemberIds.any((mId) => mId == id);

            parsed.add({
              'id': id,
              'name': name,
              'profile_image': img,
              'is_already_in': isAlreadyInRoom,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _allFriends = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('친구 목록 불러오기 예외: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitInvitation() async {
    if (_selectedFriendIds.isEmpty || _isInviting) return;

    setState(() => _isInviting = true);

    try {
      final List<int> inviteList = _selectedFriendIds.toList();
      final String invitedNamesStr = _selectedFriendNames.join('님, ') + '님';
      final String systemInviteMessage = '$_myNickname님이 $invitedNamesStr을 초대했습니다.';

      // 1. 초대 API 호출
      await http.post(
        Uri.parse('${AuthStorage.baseUrl}/chat/${widget.roomId}/invite'),
        headers: AuthStorage.authHeaders,
        body: jsonEncode({
          "user_ids": inviteList,
          "invited_user_ids": inviteList,
        }),
      );

      // 2. 초대 시스템 메시지 직접 전송
      await http.post(
        Uri.parse('${AuthStorage.baseUrl}/chat/${widget.roomId}/messages'),
        headers: AuthStorage.authHeaders,
        body: jsonEncode({
          "content": systemInviteMessage,
          "message_type": "system",
        }),
      );

      // 📌 선택된 친구들의 최신 객체 정보 추출
      final List<Map<String, dynamic>> invitedFriendsInfo = _allFriends
          .where((f) => _selectedFriendIds.contains(f['id']))
          .toList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$invitedNamesStr 초대 완료!')),
        );
        // 설정 화면으로 초대한 친구 정보 결과 넘겨주기
        Navigator.pop(context, invitedFriendsInfo);
      }
    } catch (e) {
      debugPrint('초대 통신 예외: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대 처리 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFriends = _allFriends.where((f) {
      final String name = f['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '대화상대 초대하기',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedFriendNames.isNotEmpty)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _selectedFriendNames.map((name) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Pretendard'),
                    ),
                  );
                }).toList(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 14, fontFamily: 'Pretendard'),
                      decoration: const InputDecoration(
                        hintText: '이름 검색',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '친구 ${_allFriends.length}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF524582)))
                : filteredFriends.isEmpty
                    ? const Center(child: Text('초대 가능한 친구가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Pretendard')))
                    : ListView.builder(
                        itemCount: filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];
                          final int fId = friend['id'];
                          final String fName = friend['name'];
                          final String? fImg = friend['profile_image'];
                          final bool isAlreadyIn = friend['is_already_in'] ?? false;
                          final bool isSelected = _selectedFriendIds.contains(fId);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                            onTap: isAlreadyIn ? null : () {
                              setState(() {
                                if (isSelected) {
                                  _selectedFriendIds.remove(fId);
                                  _selectedFriendNames.remove(fName);
                                } else {
                                  _selectedFriendIds.add(fId);
                                  _selectedFriendNames.add(fName);
                                }
                              });
                            },
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAlreadyIn ? const Color(0xFFE2E8F0) : const Color(0xFF93C5FD),
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: (fImg != null && fImg.isNotEmpty)
                                  ? Image.network(fImg, width: 42, height: 42, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(fName.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                                  : Text(fName.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                            ),
                            title: Text(
                              fName,
                              style: TextStyle(
                                fontSize: 15, 
                                fontWeight: FontWeight.w600, 
                                color: isAlreadyIn ? const Color(0xFF94A3B8) : const Color(0xFF1E293B), 
                                fontFamily: 'Pretendard'
                              ),
                            ),
                            trailing: isAlreadyIn
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '참여 중',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                                    ),
                                  )
                                : Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFFFFE600) : Colors.white,
                                      border: Border.all(color: isSelected ? const Color(0xFFFFE600) : const Color(0xFFCBD5E1), width: 1.5),
                                    ),
                                    child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
                                  ),
                          );
                        },
                      ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedFriendIds.isNotEmpty ? const Color(0xFFFFE600) : const Color(0xFFF1F5F9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  onPressed: _selectedFriendIds.isNotEmpty && !_isInviting ? _submitInvitation : null,
                  child: _isInviting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(
                          '확인',
                          style: TextStyle(
                            color: _selectedFriendIds.isNotEmpty ? Colors.black : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}