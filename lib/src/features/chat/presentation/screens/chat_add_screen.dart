import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';
import 'package:tripto/src/features/chat/presentation/screens/chat_room_setup_screen.dart';

class ChatAddScreen extends StatefulWidget {
  final String? realToken;

  const ChatAddScreen({super.key, this.realToken});

  @override
  State<ChatAddScreen> createState() => _ChatAddScreenState();
}

class _ChatAddScreenState extends State<ChatAddScreen> {
  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _selectedFriends = [];
  String _searchQuery = "";
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();

  // 🤖 트립토 AI 고정 프로필 개체 정의
  static final Map<String, dynamic> _triptoBot = {
    'friend_id': -1,
    'name': '트립토 AI',
    'id': 'tripto_guide',
    'profile_image': null,
    'is_bot': true,
  };

  @override
  void initState() {
    super.initState();
    if (widget.realToken != null && widget.realToken!.isNotEmpty) {
      AuthStorage.accessToken = widget.realToken;
    }
    _fetchFriendsList();
  }

  /// ── 🛠️ 서버 실제 응답 구조 파싱 (S3 프로필 사진 포함) ──
  Future<void> _fetchFriendsList() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/friends/list'),
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _allFriends = jsonList.map((item) {
            final Map<String, dynamic> itemMap =
                item is Map ? Map<String, dynamic>.from(item) : {};
            final Map<String, dynamic> userMap = itemMap['user'] is Map
                ? Map<String, dynamic>.from(itemMap['user'])
                : {};

            final String? rawImg = userMap['profile_image']?.toString() ?? 
                                   userMap['profile_img']?.toString() ?? 
                                   userMap['profile_image_url']?.toString();

            return {
              'friend_id': userMap['friend_id'] ?? 0,
              'name': userMap['nickname'] ?? '이름없음',
              'id': userMap['friend_unique_id'] ?? '',
              'profile_image': (rawImg != null && rawImg.trim().isNotEmpty) ? rawImg.trim() : null,
              'is_bot': false,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('친구 목록 파싱 중 예외 에러 발생: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _formatImgUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    String trimmed = url.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    try {
      final baseUri = Uri.parse(AuthStorage.baseUrl);
      final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
      final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
      return '$origin$path';
    } catch (_) {
      return trimmed;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredFriends = _allFriends.where((friend) {
      final name = friend['name'].toString().toLowerCase();
      final id = friend['id'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          id.contains(_searchQuery.toLowerCase());
    }).toList();

    // 트립토 AI도 검색어에 맞게 표시
    final bool showTripto = _searchQuery.isEmpty || 
        '트립토 ai'.contains(_searchQuery.toLowerCase()) || 
        'tripto'.contains(_searchQuery.toLowerCase());

    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('취소',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Pretendard')),
                ),
                const Text(
                  '채팅방 생성',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2939),
                      fontFamily: 'Pretendard'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0)),
                  onPressed: _selectedFriends.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomSetupScreen(
                                memberNames: _selectedFriends
                                    .map((f) => f['name'].toString())
                                    .toList(),
                                memberIds: _selectedFriends
                                    .map((f) =>
                                        int.tryParse(
                                            f['friend_id'].toString()) ??
                                        0)
                                    .toList(),
                              ),
                            ),
                          );
                        },
                  child: Text(
                    '완료',
                    style: TextStyle(
                      color: _selectedFriends.isEmpty
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF6241D9),
                      fontSize: 17, 
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 25, vertical: 10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Pretendard',
                    color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "초대할 친구 이름 검색",
                  hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      fontFamily: 'Pretendard'),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── 선택된 참여자 가로 스크롤 편집 바 ──
          if (_selectedFriends.isNotEmpty) ...[
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                itemCount: _selectedFriends.length,
                itemBuilder: (context, index) {
                  final friend = _selectedFriends[index];
                  final bool isBot = friend['is_bot'] == true;
                  final String? formattedImg = _formatImgUrl(friend['profile_image']);
                  final String initial = friend['name'].toString().isNotEmpty ? friend['name'].toString().substring(0, 1) : '유';

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
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isBot ? const Color(0xFFF5F3FF) : const Color(0xFFEDE9FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                clipBehavior: Clip.antiAlias,
                                alignment: Alignment.center,
                                child: isBot
                                    ? const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF524582))
                                    : (formattedImg != null && formattedImg.isNotEmpty)
                                        ? Image.network(
                                            formattedImg,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Text(
                                              initial,
                                              style: const TextStyle(
                                                  color: Color(0xFF6241D9),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        : Text(
                                            initial,
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6241D9)))
                : Column(
                    children: [
                      // 🤖 1. 트립토 AI 단독 1:1 대화방 개설 고정 영역
                      if (showTripto) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: _buildFriendRow(
                            _triptoBot, 
                            _selectedFriends.any((f) => f['friend_id'] == -1),
                          ),
                        ),
                      ],
                      
                      // 👥 2. 친구 목록
                      Expanded(
                        child: filteredFriends.isEmpty && !showTripto
                            ? const Center(
                                child: Text(
                                  "등록된 친구가 없습니다.",
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard'),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                itemCount: filteredFriends.length,
                                itemBuilder: (context, index) {
                                  final friend = filteredFriends[index];
                                  bool isSelected = _selectedFriends.any((f) =>
                                      f['friend_id'] == friend['friend_id']);
                                  return _buildFriendRow(friend, isSelected);
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRow(Map<String, dynamic> friend, bool isSelected) {
    final bool isBot = friend['is_bot'] == true;
    final String? formattedImg = _formatImgUrl(friend['profile_image']);
    final String initial = friend['name'].toString().isNotEmpty ? friend['name'].toString().substring(0, 1) : '유';

    return InkWell(
      onTap: () {
        setState(() {
          if (isBot) {
            // 트립토 AI 선택 시 단독 1:1 세션으로 처리
            _selectedFriends.clear();
            _selectedFriends.add(_triptoBot);
          } else {
            // AI 봇이 선택되어 있다면 해제 후 일반 친구 추가
            _selectedFriends.removeWhere((f) => f['friend_id'] == -1);

            if (isSelected) {
              _selectedFriends.removeWhere(
                  (f) => f['friend_id'] == friend['friend_id']);
            } else {
              _selectedFriends.add(friend);
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: Color(0xFFF1F5F9), width: 0.8))),
        child: Row(
          children: [
            // 채팅방 리스트 스타일 아바타 (BorderRadius.circular(14))
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isBot ? const Color(0xFFF5F3FF) : const Color(0xFF6241D9),
                borderRadius: BorderRadius.circular(14),
                border: isBot ? Border.all(color: const Color(0xFF524582).withOpacity(0.3)) : null,
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: isBot
                  ? const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF524582))
                  : (formattedImg != null && formattedImg.isNotEmpty)
                      ? Image.network(
                          formattedImg,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            initial,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pretendard'),
                          ),
                        )
                      : Text(
                          initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pretendard'),
                        ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(friend['name']!,
                          style: TextStyle(
                              fontSize: 15,
                              color: isBot ? const Color(0xFF524582) : const Color(0xFF1E2939),
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.bold)),
                      if (isBot) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF524582),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('AI 가이드', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(isBot ? '여행 추천 및 일정 분석 에이전트' : '@${friend['id']!}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontFamily: 'Pretendard')),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF6241D9)
                    : Colors.transparent,
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6241D9)
                        : const Color(0xFFCBD5E1),
                    width: 1.5),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}