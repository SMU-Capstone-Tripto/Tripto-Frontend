<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'chat_add_screen.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
=======
import 'dart:convert'; // 💡 JSON 판독용 임포트 추가
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/core/auth_storage.dart'; 
import 'package:tripto/src/features/chat/domain/chat_model.dart';
import 'package:tripto/src/features/chat/presentation/chat_provider.dart';
import 'package:tripto/src/features/chat/presentation/screens/chat_add_screen.dart';
import 'package:tripto/src/features/chat/presentation/screens/chat_room_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
>>>>>>> origin/chatting
  String _sortType = '최신 순';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

<<<<<<< HEAD
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
=======
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).fetchRooms());
  }

  /// 🤖 [마지막 메시지 정제 필터]: 생짜 JSON 데이터가 목록창에 터지는 결함을 가둡니다.[cite: 3]
  String _getCleanLastMessage(String rawMessage) {
    final trimmed = rawMessage.trim();
    if (trimmed.isEmpty) return '대화 기록이 없습니다.';
    
    if (trimmed.startsWith('{"tripto_card_type"')) {
      try {
        final parsed = jsonDecode(trimmed);
        final String cardType = parsed['tripto_card_type'] ?? '';
        if (cardType == 'optimized') {
          return '🗺️ AI 최적화 여행 일정표가 도착했습니다!';
        } else if (cardType == 'text') {
          return parsed['content'] ?? '';
        }
      } catch (_) {}
      return '🤖 tripto 가이드 브릿지 메시지';
    }
    return rawMessage;
  }

  @override
  Widget build(BuildContext context) {
    final allRooms = ref.watch(sortedChatProvider);

    List<ChatModel> filteredRooms = allRooms.where((room) {
      final title = room.name.toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4D48AF), Color(0xFF7C5CFC)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x1A4D48AF),
                      blurRadius: 12,
                      offset: Offset(0, 6))
                ]),
>>>>>>> origin/chatting
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
<<<<<<< HEAD
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
=======
                    const Text(
                      '채팅',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Pretendard',
                          letterSpacing: -0.3),
                    ),
                    Row(
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (String value) {
                            setState(() {
                              _sortType = value;
                              if (value == '최신 순') {
                                ref.read(chatSortProvider.notifier).state =
                                    ChatSortOrder.newest;
                              } else {
                                ref.read(chatSortProvider.notifier).state =
                                    ChatSortOrder.oldest;
                              }
                            });
                          },
                          offset: const Offset(0, 36),
                          constraints: const BoxConstraints(
                              minWidth: 110, maxWidth: 110),
                          color: Colors.white,
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
                                child: const Text('정렬 기준',
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.bold)),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _sortType,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Pretendard'),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.tune_rounded,
                                    color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.add_comment_rounded,
                              color: Colors.white, size: 26),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => ChatAddScreen(realToken: AuthStorage.accessToken),
                            ).then((_) {
                              ref.read(chatProvider.notifier).fetchRooms();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
>>>>>>> origin/chatting
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(
<<<<<<< HEAD
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
=======
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Pretendard'),
                    decoration: InputDecoration(
                      hintText: '대화방 이름을 검색해 보세요',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 14,
                          fontFamily: 'Pretendard'),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withOpacity(0.6), size: 20),
>>>>>>> origin/chatting
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
<<<<<<< HEAD
                              child: const Icon(Icons.cancel,
                                  color: Color(0xFFB3B3B3), size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
=======
                              child: const Icon(Icons.cancel_rounded,
                                  color: Colors.white70, size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
>>>>>>> origin/chatting
                    ),
                  ),
                ),
              ],
            ),
          ),
<<<<<<< HEAD
          // 채팅 목록 리스트 뷰 영역
=======
>>>>>>> origin/chatting
          Expanded(
            child: filteredRooms.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
<<<<<<< HEAD
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
=======
                          ? '참여 중인 채팅방이 존재하지 않습니다.'
                          : '\'$_searchQuery\' 검색 결과방이 없습니다.',
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontFamily: 'Pretendard'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return _buildPremiumRoomCard(room);
>>>>>>> origin/chatting
                    },
                  ),
          )
        ],
      ),
    );
  }

<<<<<<< HEAD
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
=======
  Widget _buildPremiumRoomCard(ChatModel room) {
    bool isBot = room.type == ChatType.ai;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDF2F7), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E2939).withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  title: room.name,
                  isBotRoom: isBot,
                  roomId: int.tryParse(room.id.toString()) ?? 14, 
                ),
              ),
            );
          },
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isBot
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFF818CF8), const Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              isBot ? Icons.auto_awesome_rounded : Icons.forum_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: const TextStyle(
                      color: Color(0xFF1E2939),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      letterSpacing: -0.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(room.lastTime,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontFamily: 'Pretendard')),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getCleanLastMessage(room.lastMessage), // 🎯 가공 파서 연결 적용 부위[cite: 3]
                    style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontFamily: 'Pretendard'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (room.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444), // 🔴 알람 배지 보존[cite: 3]
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${room.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
          ),
>>>>>>> origin/chatting
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
<<<<<<< HEAD
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
=======
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 14,
                color:
                    isSelected ? const Color(0xFF4D48AF) : Colors.transparent),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF4D48AF)
                      : const Color(0xFF334155),
                  fontSize: 13,
                  fontFamily: 'Pretendard',
>>>>>>> origin/chatting
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> origin/chatting
