import 'package:flutter/material.dart';
import 'chat_room_setup_screen.dart';

class ChatAddScreen extends StatefulWidget {
  const ChatAddScreen({super.key});

  @override
  State<ChatAddScreen> createState() => _ChatAddScreenState();
}

class _ChatAddScreenState extends State<ChatAddScreen> {
  // 피그마 기반 마스터 친구 데이터셋
  final List<Map<String, String>> _allFriends = [
    {'name': '이세은', 'id': 'tpdms13', 'image': 'https://placehold.co/100x100'},
    {'name': '김민수', 'id': 'minsu_k', 'image': 'https://placehold.co/100x101'},
    {'name': '박서준', 'id': 'seo_jun', 'image': 'https://placehold.co/100x102'},
    {'name': '이지은', 'id': 'jieun_lee', 'image': 'https://placehold.co/100x103'},
    {'name': '최유진', 'id': 'yu_jin', 'image': 'https://placehold.co/100x104'},
    {'name': '정다은', 'id': 'da_eun', 'image': 'https://placehold.co/100x105'},
    {'name': '강민호', 'id': 'min_ho_g', 'image': 'https://placehold.co/100x106'},
  ];

  List<Map<String, String>> _selectedFriends = []; 
  String _searchQuery = ""; 
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 실시간 친구 검색 필터
    List<Map<String, String>> filteredFriends = _allFriends.where((friend) {
      return friend['name']!.contains(_searchQuery) || friend['id']!.contains(_searchQuery);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 1. 상단 헤더 라인 (취소, 타이틀, 완료)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Pretendard')),
                ),
                const Text(
                  '채팅방 생성',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black, fontFamily: 'Pretendard'),
                ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  onPressed: _selectedFriends.isEmpty 
                      ? null 
                      : () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomSetupScreen(
                                members: _selectedFriends.map((f) => f['name']!).toList(),
                              ),
                            ),
                          );
                        },
                  child: Text(
                    '완료',
                    style: TextStyle(
                      color: _selectedFriends.isEmpty ? const Color(0xFFAAAAAA) : const Color(0xFF7141FF),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 🛠️ [태그 전면 제거] 피그마 순정 100% 미니멀 한 줄 검색바 복구
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Container(
              height: 42, // 피그마 규격 철저 고정
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0x33C1C1C1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(fontSize: 15, fontFamily: 'Pretendard', color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "친구 이름 검색",
                  hintStyle: TextStyle(color: Color(0xFF787878), fontSize: 16, fontFamily: 'Pretendard'),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          // 3. 피그마 순정 '친구 추가하기' 바로가기 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0x33C1C1C1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8055FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '친구 추가하기 ',
                    style: TextStyle(color: Color(0xFF1D1D1D), fontSize: 16, fontFamily: 'Pretendard', fontWeight: FontWeight.w400, letterSpacing: -1),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Color(0xFF8E8E93), size: 24),
                ],
              ),
            ),
          ),

          // 4. 친구 목록 타이틀
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(32, 10, 0, 8),
              child: Text(
                '친구 목록',
                style: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'Pretendard', letterSpacing: -1),
              ),
            ),
          ),

          // 5. 정렬된 친구 리스트 뷰 영역
          Expanded(
            child: filteredFriends.isEmpty
                ? Center(
                    child: Text(
                      "'$_searchQuery' 검색 결과가 없습니다.",
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontFamily: 'Pretendard'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    itemCount: filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = filteredFriends[index];
                      bool isSelected = _selectedFriends.any((f) => f['name'] == friend['name']);

                      return _buildFriendRow(friend, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 친구 행 타일 위젯 빌더
  Widget _buildFriendRow(Map<String, String> friend, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFriends.removeWhere((f) => f['name'] == friend['name']);
          } else {
            _selectedFriends.add(friend);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 0.8)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF5F5F5F),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend['name']!,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF1D1D1D), fontFamily: 'Pretendard', letterSpacing: -1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend['id']!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6F6F6F), fontFamily: 'Pretendard'),
                  ),
                ],
              ),
            ),
            // 보라 원형 체크박스 매핑
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF8055FF) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF8055FF) : const Color(0xFFAAAAAA),
                  width: 1.5,
                ),
              ),
              child: isSelected 
                  ? const Icon(Icons.check, size: 12, color: Colors.white) 
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}