import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';
import 'package:tripto/src/features/chat/presentation/screens/chat_room_setup_screen.dart';

class ChatAddScreen extends StatefulWidget {
  final String? realToken; // 다른 화면에서 쓰고 있는 진짜 성공 토큰을 넘겨받는 매개변수[cite: 3]

  const ChatAddScreen({super.key, this.realToken}); //[cite: 3]

  @override
  State<ChatAddScreen> createState() => _ChatAddScreenState(); //[cite: 3]
}

class _ChatAddScreenState extends State<ChatAddScreen> {
  List<Map<String, dynamic>> _allFriends = []; //[cite: 3]
  List<Map<String, dynamic>> _selectedFriends = []; //[cite: 3]
  String _searchQuery = ""; //[cite: 3]
  bool _isLoading = true; //[cite: 3]
  final TextEditingController _controller = TextEditingController(); //[cite: 3]

  @override
  void initState() {
    super.initState(); //[cite: 3]
    if (widget.realToken != null && widget.realToken!.isNotEmpty) {
      //[cite: 3]
      AuthStorage.accessToken = widget.realToken; //[cite: 3]
    }
    _fetchFriendsList(); //[cite: 3]
  }

  /// ── 🛠️ 서버 실제 응답 구조 완벽 조준 파싱 ──
  Future<void> _fetchFriendsList() async {
    //[cite: 3]
    try {
      debugPrint(
          'ℹ️ [검증] 현재 AuthStorage.accessToken의 값: ${AuthStorage.accessToken}'); //[cite: 3]

      final response = await http.get(
        //[cite: 3]
        Uri.parse('${AuthStorage.baseUrl}/friends/list'), //[cite: 3]
        headers: AuthStorage.authHeaders, //[cite: 3]
      );

      if (response.statusCode == 200) {
        //[cite: 3]
        final List<dynamic> jsonList =
            jsonDecode(utf8.decode(response.bodyBytes)); //[cite: 3]

        setState(() {
          //[cite: 3]
          _allFriends = jsonList.map((item) {
            //[cite: 3]
            final Map<String, dynamic> itemMap =
                item is Map ? Map<String, dynamic>.from(item) : {}; //[cite: 3]
            final Map<String, dynamic> userMap = itemMap['user'] is Map
                ? Map<String, dynamic>.from(itemMap['user'])
                : {}; //[cite: 3]

            return {
              //[cite: 3]
              'friend_id': userMap['friend_id'] ?? 0, //[cite: 3]
              'name': userMap['nickname'] ?? '이름없음', //[cite: 3]
              'id': userMap['friend_unique_id'] ?? '', //[cite: 3]
            };
          }).toList(); //[cite: 3]
        });
      }
    } catch (e) {
      //[cite: 3]
      debugPrint('친구 목록 파싱 중 예외 에러 발생: $e'); //[cite: 3]
    } finally {
      //[cite: 3]
      if (mounted) {
        //[cite: 3]
        setState(() => _isLoading = false); //[cite: 3]
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //[cite: 3]
    List<Map<String, dynamic>> filteredFriends = _allFriends.where((friend) {
      //[cite: 3]
      final name = friend['name'].toString().toLowerCase(); //[cite: 3]
      final id = friend['id'].toString().toLowerCase(); //[cite: 3]
      return name.contains(_searchQuery.toLowerCase()) ||
          id.contains(_searchQuery.toLowerCase()); //[cite: 3]
    }).toList(); //[cite: 3]

    return Container(
      height: MediaQuery.of(context).size.height * 0.93, //[cite: 3]
      decoration: const BoxDecoration(
        //[cite: 3]
        color: Colors.white, //[cite: 3]
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20)), //[cite: 3]
      ),
      child: Column(
        //[cite: 3]
        children: [
          Padding(
            //[cite: 3]
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), //[cite: 3]
            child: Row(
              //[cite: 3]
              mainAxisAlignment: MainAxisAlignment.spaceBetween, //[cite: 3]
              children: [
                GestureDetector(
                  //[cite: 3]
                  onTap: () => Navigator.pop(context), //[cite: 3]
                  child: const Text('취소',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Pretendard')), //[cite: 3]
                ),
                const Text(
                  //[cite: 3]
                  '채팅방 생성', //[cite: 3]
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2939),
                      fontFamily: 'Pretendard'), //[cite: 3]
                ),
                TextButton(
                  //[cite: 3]
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0)), //[cite: 3]
                  onPressed: _selectedFriends.isEmpty //[cite: 3]
                      ? null //[cite: 3]
                      : () {
                          Navigator.push(
                            //[cite: 3]
                            context, //[cite: 3]
                            MaterialPageRoute(
                              //[cite: 3]
                              builder: (_) => ChatRoomSetupScreen(
                                //[cite: 3]
                                memberNames: _selectedFriends
                                    .map((f) => f['name'].toString())
                                    .toList(), //[cite: 3]
                                memberIds: _selectedFriends
                                    .map((f) =>
                                        int.tryParse(
                                            f['friend_id'].toString()) ??
                                        0)
                                    .toList(), //[cite: 3]
                              ),
                            ),
                          );
                        },
                  child: Text(
                    //[cite: 3]
                    '완료', //[cite: 3]
                    style: TextStyle(
                      //[cite: 3]
                      color: _selectedFriends.isEmpty
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF6241D9), //[cite: 3]
                      fontSize: 17, fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard', //[cite: 3]
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            //[cite: 3]
            padding: const EdgeInsets.symmetric(
                horizontal: 25, vertical: 10), //[cite: 3]
            child: Container(
              //[cite: 3]
              height: 44, //[cite: 3]
              padding: const EdgeInsets.symmetric(horizontal: 16), //[cite: 3]
              decoration: BoxDecoration(
                //[cite: 3]
                color: const Color(0xFFF1F5F9), //[cite: 3]
                borderRadius: BorderRadius.circular(12), //[cite: 3]
              ),
              child: TextField(
                //[cite: 3]
                controller: _controller, //[cite: 3]
                onChanged: (val) {
                  //[cite: 3]
                  setState(() {
                    //[cite: 3]
                    _searchQuery = val; //[cite: 3]
                  });
                },
                style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Pretendard',
                    color: Colors.black), //[cite: 3]
                decoration: const InputDecoration(
                  //[cite: 3]
                  hintText: "초대할 친구 이름 검색", //[cite: 3]
                  hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      fontFamily: 'Pretendard'), //[cite: 3]
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12), //[cite: 3]
                ),
              ),
            ),
          ),

          // ── 💡 [부활 기능]: 현재 상단에 선택된 참여자 가로 스크롤 편집 바 ──
          if (_selectedFriends.isNotEmpty) ...[
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                itemCount: _selectedFriends.length,
                itemBuilder: (context, index) {
                  final friend = _selectedFriends[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 50,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFEDE9FF),
                                child: Text(
                                  friend['name'].toString().substring(0, 1),
                                  style: const TextStyle(
                                      color: Color(0xFF6241D9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                friend['name']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1E2939),
                                    fontFamily: 'Pretendard'),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFriends.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                  color: Color(0xFF94A3B8),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  size: 10, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],

          Expanded(
            //[cite: 3]
            child: _isLoading //[cite: 3]
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6241D9))) //[cite: 3]
                : filteredFriends.isEmpty //[cite: 3]
                    ? const Center(
                        //[cite: 3]
                        child: Text(
                          //[cite: 3]
                          "등록된 친구가 없습니다.", //[cite: 3]
                          style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              fontFamily: 'Pretendard'), //[cite: 3]
                        ), //[cite: 3]
                      ) //[cite: 3]
                    : ListView.builder(
                        //[cite: 3]
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25), //[cite: 3]
                        itemCount: filteredFriends.length, //[cite: 3]
                        itemBuilder: (context, index) {
                          //[cite: 3]
                          final friend = filteredFriends[index]; //[cite: 3]
                          bool isSelected = _selectedFriends.any((f) =>
                              f['friend_id'] ==
                              friend['friend_id']); //[cite: 3]
                          return _buildFriendRow(
                              friend, isSelected); //[cite: 3]
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRow(Map<String, dynamic> friend, bool isSelected) {
    //[cite: 3]
    return InkWell(
      //[cite: 3]
      onTap: () {
        //[cite: 3]
        setState(() {
          //[cite: 3]
          if (isSelected) {
            //[cite: 3]
            _selectedFriends.removeWhere(
                (f) => f['friend_id'] == friend['friend_id']); //[cite: 3]
          } else {
            //[cite: 3]
            _selectedFriends.add(friend); //[cite: 3]
          }
        });
      },
      child: Container(
        //[cite: 3]
        padding: const EdgeInsets.symmetric(vertical: 12), //[cite: 3]
        decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: Color(0xFFF1F5F9), width: 0.8))), //[cite: 3]
        child: Row(
          //[cite: 3]
          children: [
            CircleAvatar(
              //[cite: 3]
              radius: 20, backgroundColor: const Color(0xFFCBD5E1), //[cite: 3]
              child: Text(
                //[cite: 3]
                friend['name'].toString().substring(0, 1), //[cite: 3]
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold), //[cite: 3]
              ),
            ),
            const SizedBox(width: 14), //[cite: 3]
            Expanded(
              //[cite: 3]
              child: Column(
                //[cite: 3]
                crossAxisAlignment: CrossAxisAlignment.start, //[cite: 3]
                children: [
                  Text(friend['name']!,
                      style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1E2939),
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600)), //[cite: 3]
                  const SizedBox(height: 2), //[cite: 3]
                  Text('@${friend['id']!}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontFamily: 'Pretendard')), //[cite: 3]
                ],
              ),
            ),
            AnimatedContainer(
              //[cite: 3]
              duration: const Duration(milliseconds: 150), //[cite: 3]
              width: 22, height: 22, //[cite: 3]
              decoration: BoxDecoration(
                //[cite: 3]
                shape: BoxShape.circle, //[cite: 3]
                color: isSelected
                    ? const Color(0xFF6241D9)
                    : Colors.transparent, //[cite: 3]
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6241D9)
                        : const Color(0xFFCBD5E1),
                    width: 1.5), //[cite: 3]
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null, //[cite: 3]
            ),
          ],
        ),
      ),
    );
  }
}
