import 'package:flutter/material.dart';
import 'chat_add_screen.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _sortType = '최신 순';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allChatRooms = [
    {
      'title': 'AI 챗봇 대화방(이름 미정)',
      'lastMsg': '안녕하세요 트립토입니다! 도움이 필요하신가요?',
      'time': '12:49',
      'rawTime': 202605281249,
      'badgeCount': 1,
      'isBot': true,
    },
    {
      'title': '제주도 가쟝',
      'lastMsg': 'ㅇㅇ 그럼 거기로?',
      'time': '12:45',
      'rawTime': 202605281245,
      'badgeCount': 3,
      'isBot': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredRooms = _allChatRooms.where((room) {
      final title = room['title'].toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();

    if (_sortType == '최신 순') {
      filteredRooms.sort((a, b) => b['rawTime'].compareTo(a['rawTime']));
    } else if (_sortType == '안  읽음') {
      filteredRooms.sort((a, b) => b['badgeCount'].compareTo(a['badgeCount']));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🛠️ [레이아웃 교정] 내부 패딩 조정으로 글씨와 버튼 위치를 완전히 상단으로 올림!
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.50, 0.00),
                end: Alignment(0.50, 1.00),
                colors: [Color(0xFF4D48AF), Color(0xFFB287FD)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        setState(() {
                          _sortType = value;
                        });
                      },
                      offset: const Offset(0, 40),
                      // 🛠️ [다이어트 완료] 정렬 팝업 박스 크기를 125 슬림 규격으로 다이어트!
                      constraints:
                          const BoxConstraints(minWidth: 125, maxWidth: 125),
                      color: const Color(0xF2E7E7E7),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          enabled: false,
                          height: 28,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 8),
                            child: const Text('채팅방 정렬',
                                style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600) // 프리텐다드
                                ),
                          ),
                        ),
                        PopupMenuWidget(
                          value: '최신 순',
                          currentSort: _sortType,
                          label: '최신 순',
                        ),
                        PopupMenuWidget(
                          value: '안  읽음',
                          currentSort: _sortType,
                          label: '안  읽음',
                        ),
                      ],
                      child: Row(
                        children: [
                          Text('채팅 ($_sortType)',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Pretendard',
                                  letterSpacing: 0.5)), // 프리텐다드
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.white, size: 26),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.white, size: 30),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const ChatAddScreen(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28), // 버튼 라인과 검색창 사이 간격을 넓혀 아래 치우침 완벽 해결
                // 검색창 유닛
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'Pretendard'), // 프리텐다드
                    decoration: InputDecoration(
                      hintText: '채팅방 검색',
                      hintStyle: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 15,
                          fontFamily: 'Pretendard'), // 프리텐다드
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFFB3B3B3), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                              child: const Icon(Icons.cancel,
                                  color: Color(0xFFB3B3B3), size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 채팅 목록 리스트 뷰 영역
          Expanded(
            child: filteredRooms.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? '채팅방이 존재하지 않습니다.'
                          : '\'$_searchQuery\'가 포함된 채팅방이 없습니다.',
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontFamily: 'Pretendard'), // 프리텐다드
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return _buildRoomItem(room);
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildRoomItem(Map<String, dynamic> room) {
    bool isBot = room['isBot'] ?? false;
    String title = room['title'];
    String lastMsg = room['lastMsg'];
    String time = room['time'];
    int badgeCount = room['badgeCount'];

    return Container(
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1.0)),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(title: title, isBotRoom: isBot),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor:
              isBot ? const Color(0xFF8055FF) : const Color(0xFFE5E7EB),
          child: isBot
              ? const Icon(Icons.smart_toy, color: Colors.white, size: 26)
              : const Icon(Icons.person, color: Colors.white, size: 26),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    letterSpacing: -0.5), // 프리텐다드
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            if (!isBot)
              const Text('4',
                  style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard')), // 프리텐다드
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            lastMsg,
            style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                fontFamily: 'Pretendard'), // 프리텐다드
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time,
                style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontFamily: 'Pretendard')), // 프리텐다드
            const SizedBox(height: 6),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFF874CFF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Pretendard'), // 프리텐다드
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PopupMenuWidget extends PopupMenuEntry<String> {
  final String value;
  final String currentSort;
  final String label;

  const PopupMenuWidget({
    super.key,
    required this.value,
    required this.currentSort,
    required this.label,
  });

  @override
  double get height => 32.0;

  @override
  bool represents(String? value) => value == this.value;

  @override
  PopupMenuWidgetState createState() => PopupMenuWidgetState();
}

class PopupMenuWidgetState extends State<PopupMenuWidget> {
  @override
  Widget build(BuildContext context) {
    bool isSelected = widget.value == widget.currentSort;
    return InkWell(
      onTap: () => Navigator.pop(context, widget.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.check,
                size: 12,
                color:
                    isSelected ? const Color(0xFF6241D9) : Colors.transparent),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                  color: isSelected ? const Color(0xFF6241D9) : Colors.black,
                  fontSize: 12,
                  fontFamily: 'Pretendard', // 프리텐다드
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
