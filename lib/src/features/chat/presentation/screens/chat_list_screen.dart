import 'dart:convert'; 
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
  String _sortType = '최신 순';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).fetchRooms());
  }

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

  /// 📸 [완벽 매포 보정]: 설정창(Settings) 위젯의 다중 아바타 정렬 알고리즘을 소수점 단차까지 100% 동일하게 이식
  Widget _buildListCompositeAvatar(ChatModel room) {
    bool isBot = room.type == ChatType.ai;
    List<String> shortNames = [];

    try {
      final dynamic modelRaw = room;
      // 백엔드 스키마에서 멤버 목록을 확보
      final List<dynamic> memberIds = modelRaw.memberIds ?? [];
      
      // 설정창과 일치: tripto (ID: -1)를 제외한 순수 인간 참여자 장부 필터링
      final List<dynamic> pureHumanIds = memberIds.where((id) => id.toString() != '-1').toList();

      for (var id in pureHumanIds) {
        String uName = '';
        
        // 룸 내부의 유저 네임 장부 캐시 매핑 탐색
        if (modelRaw.userNames != null && modelRaw.userNames is Map) {
          uName = modelRaw.userNames[id]?.toString() ?? '';
        }
        
        if (uName.isEmpty) {
          // 이름이 비어있다면 방 이름이나 발신자명 기반 폰트 대체 대책
          uName = room.name.isNotEmpty ? room.name : '유';
        }
        
        shortNames.add(uName.isNotEmpty ? uName.substring(0, 1) : '유');
      }
    } catch (_) {}

    // 안전 예외 대책 하한선 방어
    if (shortNames.isEmpty) {
      shortNames.add(isBot ? '🤖' : '나');
    }

    final int count = shortNames.length;

    Widget singleMiniAvatar(String char, double size, {Color? bg}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg ?? const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(size * 0.35), // 설정창과 똑같은 스쿼클 라운딩
        ),
        alignment: Alignment.center,
        child: Text(
          char,
          style: TextStyle(color: Colors.white, fontSize: size * 0.45, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
        ),
      );
    }

    // 설정창 빌더 구도 기하학 좌표와 완벽 도플갱어 매칭
    if (count <= 1) {
      return singleMiniAvatar(shortNames[0], 52, bg: isBot ? const Color(0xFF925DFB) : const Color(0xFF6241D9));
    }
    else if (count == 2) {
      return Stack(
        children: [
          Positioned(left: 2, top: 2, child: singleMiniAvatar(shortNames[0], 28, bg: const Color(0xFF818CF8))),
          Positioned(right: 2, bottom: 2, child: singleMiniAvatar(shortNames[1], 28, bg: const Color(0xFF6366F1))),
        ],
      );
    }
    else if (count == 3) {
      return Stack(
        children: [
          Positioned(left: 14, top: 2, child: singleMiniAvatar(shortNames[0], 25, bg: const Color(0xFF94A3B8))),
          Positioned(left: 1, bottom: 2, child: singleMiniAvatar(shortNames[1], 25, bg: const Color(0xFF64748B))),
          Positioned(right: 1, bottom: 2, child: singleMiniAvatar(shortNames[2], 25, bg: const Color(0xFF475569))),
        ],
      );
    }
    else {
      return Stack(
        children: [
          Positioned(left: 2, top: 2, child: singleMiniAvatar(shortNames[0], 23, bg: const Color(0xFF94A3B8))),
          Positioned(right: 2, top: 2, child: singleMiniAvatar(shortNames[1], 23, bg: const Color(0xFF64748B))),
          Positioned(left: 2, bottom: 2, child: singleMiniAvatar(shortNames[2], 23, bg: const Color(0xFF475569))),
          Positioned(right: 2, bottom: 2, child: singleMiniAvatar(shortNames[3], 23, bg: const Color(0xFF334155))),
        ],
      );
    }
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
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22)),
                boxShadow: [BoxShadow(color: Color(0x1A4D48AF), blurRadius: 12, offset: Offset(0, 6))]),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('채팅', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Pretendard', letterSpacing: -0.3)),
                    Row(
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (String value) {
                            setState(() {
                              _sortType = value;
                              if (value == '최신 순') {
                                ref.read(chatSortProvider.notifier).state = ChatSortOrder.newest;
                              } else {
                                ref.read(chatSortProvider.notifier).state = ChatSortOrder.oldest;
                              }
                            });
                          },
                          offset: const Offset(0, 36),
                          constraints: const BoxConstraints(minWidth: 110, maxWidth: 110),
                          color: Colors.white, elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.zero,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              enabled: false, height: 28,
                              child: Container(alignment: Alignment.centerLeft, child: const Text('정렬 기준', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Pretendard', fontWeight: FontWeight.bold))),
                            ),
                            PopupMenuWidget(value: '최신 순', currentSort: _sortType, label: '최신 순'),
                            PopupMenuWidget(value: '안  읽음', currentSort: _sortType, label: '안  읽음'),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.1))),
                            child: Row(
                              children: [
                                Text(_sortType, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Pretendard')),
                                const SizedBox(width: 4),
                                const Icon(Icons.tune_rounded, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 26),
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                              builder: (_) => ChatAddScreen(realToken: AuthStorage.accessToken),
                            ).then((_) { ref.read(chatProvider.notifier).fetchRooms(); });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 46,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.12))),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) { setState(() { _searchQuery = value; }); },
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Pretendard'),
                    decoration: InputDecoration(
                      hintText: '대화방 이름을 검색해 보세요',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14, fontFamily: 'Pretendard'),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.6), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(onTap: () { setState(() { _searchController.clear(); _searchQuery = ''; }); }, child: const Icon(Icons.cancel_rounded, color: Colors.white70, size: 18))
                          : null,
                      border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredRooms.isEmpty
                ? Center(child: Text(_searchQuery.isEmpty ? '참여 중인 채팅방이 존재하지 않습니다.' : '\'$_searchQuery\' 검색 결과방이 없습니다.', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Pretendard')))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) => _buildPremiumRoomCard(filteredRooms[index]),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildPremiumRoomCard(ChatModel room) {
    bool isBot = room.type == ChatType.ai;

    int rawTotalCount = 2; 
    try {
      final dynamic modelRaw = room;
      if (modelRaw.memberIds != null && modelRaw.memberIds is List) {
        rawTotalCount = (modelRaw.memberIds as List).length - 1;
      }
    } catch (_) {}

    final int humanMemberCount = isBot ? 1 : (rawTotalCount <= 0 ? 1 : rawTotalCount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFEDF2F7), width: 1.0), boxShadow: [
        BoxShadow(color: const Color(0xFF1E2939).withOpacity(0.03), blurRadius: 10, offset: Offset(0, 4))
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: _buildListCompositeAvatar(room),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        room.name, 
                        style: const TextStyle(color: Color(0xFF1E2939), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Pretendard', letterSpacing: -0.4), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isBot) ...[
                      const SizedBox(width: 8), 
                      Text(
                        '$humanMemberCount', 
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Pretendard'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12), 
              Text(
                room.lastTime, 
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Pretendard'),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                Expanded(child: Text(_getCleanLastMessage(room.lastMessage), style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontFamily: 'Pretendard'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (room.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                    child: Text('${room.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Pretendard', fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PopupMenuWidget extends PopupMenuEntry<String> {
  final String value; final String currentSort; final String label;
  const PopupMenuWidget({super.key, required this.value, required this.currentSort, required this.label});
  @override double get height => 32.0;
  @override bool represents(String? value) => value == this.value;
  @override PopupMenuWidgetState createState() => PopupMenuWidgetState();
}

class PopupMenuWidgetState extends State<PopupMenuWidget> {
  @override Widget build(BuildContext context) {
    bool isSelected = widget.value == widget.currentSort;
    return InkWell(
      onTap: () => Navigator.pop(context, widget.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 14, color: isSelected ? const Color(0xFF4D48AF) : Colors.transparent),
            const SizedBox(width: 8),
            Text(widget.label, style: TextStyle(color: isSelected ? const Color(0xFF4D48AF) : const Color(0xFF334155), fontSize: 13, fontFamily: 'Pretendard', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}