import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/core/auth_storage.dart'; 
import 'package:tripto/src/features/chat/domain/chat_model.dart';
import 'package:tripto/src/features/chat/presentation/chat_provider.dart';
import 'package:tripto/src/features/chat/presentation/screens/chat_add_screen.dart';
import 'package:tripto/src/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:tripto/src/features/settings/presentation/profile_provider.dart';
import 'package:http/http.dart' as http; 

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> with AutomaticKeepAliveClientMixin {
  String _sortType = '최신 순';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Set<int> _pinnedRoomIds = {};
  final Set<int> _mutedRoomIds = {};
  Offset _tapPosition = Offset.zero;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await LocalDeletionStorage.init();
      if (mounted) {
        ref.read(chatProvider.notifier).fetchRooms();
      }
    });
  }

  String _formatCleanLastMessage(String rawText) {
    if (rawText.isEmpty) return '';
    String text = rawText;
    if (text.contains('[REPLY_DATA]')) {
      final parts = text.split('[REPLY_DATA]');
      if (parts.length >= 3) {
        text = parts[2];
      }
    }
    String trimmed = text.trim();
    if (trimmed.startsWith('http') && (trimmed.contains('.jpg') || trimmed.contains('.png') || trimmed.contains('.jpeg') || trimmed.contains('s3.amazonaws') || trimmed.contains('presigned'))) {
      return '사진을 보냈습니다.';
    }
    if (trimmed.startsWith('{"tripto_card_type"') || trimmed.contains('"itinerary"')) {
      return '여행 일정을 작성했습니다.';
    }
    return trimmed;
  }

  Future<void> _leaveRoomSilently(int roomId) async {
    try {
      final targetUrl = '${AuthStorage.baseUrl}/chat/$roomId/leave';
      await http.delete(Uri.parse(targetUrl), headers: AuthStorage.authHeaders);
      ref.read(chatProvider.notifier).fetchRooms();
    } catch (e) {
      debugPrint('❌ 슬라이드 퇴장 통신 에러: $e');
    }
  }

  Future<void> _updateRoomTitleOnServer(int roomId, String newName) async {
    ref.read(chatProvider.notifier).updateRoomName(roomId, newName);

    try {
      final cleanBase = AuthStorage.baseUrl.trim().replaceAll('\n', '').replaceAll('\r', '');
      final uri = Uri.parse('$cleanBase/chat/$roomId/name').replace(
        queryParameters: {'room_name': newName, 'name': newName},
      );
      
      final headers = {
        ...AuthStorage.authHeaders,
        'Content-Type': 'application/json; charset=utf-8',
      };

      await http.put(
        uri, 
        headers: headers,
        body: jsonEncode({'room_name': newName, 'name': newName}),
      );
    } catch (e) {
      debugPrint('❌ 방 이름 백엔드 동기화 예외 에러: $e');
    }
  }

  Future<bool?> _showLeaveConfirmDialog(String roomName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '채팅방을 나가시겠습니까?', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
            ),
            const SizedBox(height: 15),
            Text(
              '\'$roomName\' 방을 나가면 대화 내용이 삭제되며\n채팅 목록에서도 대화방이 영구 제외됩니다.', 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Color(0xFF555555), fontSize: 13.5, fontFamily: 'Pretendard', height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 48, 
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)), 
                      alignment: Alignment.center, 
                      child: const Text('취소', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'Pretendard')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 48, 
                      decoration: BoxDecoration(color: const Color(0xFFFF4D4D), borderRadius: BorderRadius.circular(12)), 
                      alignment: Alignment.center, 
                      child: const Text('나가기', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'Pretendard')),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showEditRoomNameDialog(ChatModel room, int roomId) {
    final TextEditingController nameEditController = TextEditingController(text: room.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('채팅방 이름 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
        content: TextField(
          controller: nameEditController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14),
          decoration: const InputDecoration(
            hintText: '변경할 방 이름을 입력하세요',
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6241D9))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6241D9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              final typedName = nameEditController.text.trim();
              Navigator.pop(context);
              if (typedName.isNotEmpty) {
                _updateRoomTitleOnServer(roomId, typedName);
              }
            },
            child: const Text('변경', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
          )
        ],
      ),
    );
  }

  void _showKakaoContextMenu(ChatModel room, int roomId, Offset tapPosition) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final bool isPinned = _pinnedRoomIds.contains(roomId);
    final bool isMuted = _mutedRoomIds.contains(roomId);

    final String? selectedValue = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      items: [
        const PopupMenuItem<String>(
          value: 'open',
          height: 38,
          child: Text('채팅방 열기', style: TextStyle(fontSize: 13.5, fontFamily: 'Pretendard', color: Color(0xFF1E2939))),
        ),
        const PopupMenuItem<String>(
          value: 'rename',
          height: 38,
          child: Text('채팅방 이름 설정', style: TextStyle(fontSize: 13.5, fontFamily: 'Pretendard', color: Color(0xFF1E2939))),
        ),
        PopupMenuItem<String>(
          value: 'pin',
          height: 38,
          child: Text(
            isPinned ? '채팅방 상단 고정 해제' : '채팅방 상단 고정',
            style: const TextStyle(fontSize: 13.5, fontFamily: 'Pretendard', color: Color(0xFF1E2939)),
          ),
        ),
        PopupMenuItem<String>(
          value: 'mute',
          height: 38,
          child: Text(
            isMuted ? '알림 켜기' : '알림 끄기',
            style: const TextStyle(fontSize: 13.5, fontFamily: 'Pretendard', color: Color(0xFF1E2939)),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'leave',
          height: 38,
          child: Text(
            '채팅방 나가기',
            style: TextStyle(fontSize: 13.5, fontFamily: 'Pretendard', color: Color(0xFFFF4D4D), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    if (selectedValue == 'open') {
      _navigateToRoom(room, roomId);
    } else if (selectedValue == 'rename') {
      _showEditRoomNameDialog(room, roomId);
    } else if (selectedValue == 'pin') {
      setState(() {
        if (isPinned) {
          _pinnedRoomIds.remove(roomId);
        } else {
          _pinnedRoomIds.add(roomId);
        }
      });
    } else if (selectedValue == 'mute') {
      setState(() {
        if (isMuted) {
          _mutedRoomIds.remove(roomId);
        } else {
          _mutedRoomIds.add(roomId);
        }
      });
    } else if (selectedValue == 'leave') {
      final bool? confirm = await _showLeaveConfirmDialog(room.name);
      if (confirm == true && roomId > 0) {
        _leaveRoomSilently(roomId);
      }
    }
  }

  // 💡 [수정] 방 진입 시 즉시 markRoomAsRead 호출
  void _navigateToRoom(ChatModel room, int parsedRoomId) {
    bool isBot = room.type == ChatType.ai;

    final Map<int, String> roomMemberNames = {};
    final Map<int, String?> roomMemberImages = {};

    for (var p in room.humanProfiles) {
      final int? uId = int.tryParse(p['id']?.toString() ?? p['user_id']?.toString() ?? '');
      final String? nick = p['nickname'] ?? p['name'];
      final String? img = p['profile_image'] ?? p['profile_img'] ?? p['image'] ?? p['user_image'];

      if (uId != null) {
        if (nick != null && nick.isNotEmpty) roomMemberNames[uId] = nick;
        if (img != null && img.isNotEmpty) roomMemberImages[uId] = img;
      }
    }

    // 💡 방을 누르는 즉시 로컬 안읽음 카운트를 0으로 초기화
    if (parsedRoomId > 0) {
      ref.read(chatProvider.notifier).markRoomAsRead(parsedRoomId);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          title: room.name,
          isBotRoom: isBot,
          roomId: parsedRoomId, 
          initialMemberNames: roomMemberNames.isNotEmpty ? roomMemberNames : null,
          initialMemberImages: roomMemberImages.isNotEmpty ? roomMemberImages : null,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
      ref.read(chatProvider.notifier).fetchRooms();
    });
  }

  Widget _buildListCompositeAvatar(ChatModel room) {
    final myProfile = ref.watch(profileProvider).value;
    final String? myProfileImg = myProfile?.profileImage;
    final String myNickname = (myProfile?.nickname ?? '').trim();
    final String myUserIdStr = (myProfile as dynamic)?.userId?.toString() ?? 
                               (myProfile as dynamic)?.id?.toString() ?? '';

    final profiles = room.humanProfiles;

    if (profiles.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF6241D9),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: const Text('나', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
      );
    }

    String? formatImgUrl(String? url) {
      if (url == null || url.trim().isEmpty) return null;
      String trimmed = url.trim();

      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed;
      }

      try {
        final cleanBase = AuthStorage.baseUrl.trim().replaceAll('\n', '').replaceAll('\r', '');
        final baseUri = Uri.parse(cleanBase);
        final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
        final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
        return '$origin$path';
      } catch (_) {
        return trimmed;
      }
    }

    Widget singleMiniAvatar(Map<String, dynamic> profile, double size, {Color? bg}) {
      final dynamic target = profile['friend'] ?? profile['user'] ?? profile['profile'] ?? profile;
      
      final String nick = (target['nickname'] ?? target['name'] ?? target['username'] ?? profile['nickname'] ?? profile['name'] ?? '유저').toString().trim();
      final String pId = target['id']?.toString() ?? profile['id']?.toString() ?? '';
      
      String? rawImg = target['profile_image'] ?? 
                       target['profile_img'] ?? 
                       target['profile_image_url'] ?? 
                       target['image'] ?? 
                       target['user_image'] ?? 
                       target['avatar'] ??
                       profile['profile_image'] ??
                       profile['profile_img'] ??
                       profile['profile_image_url'] ??
                       profile['image'] ??
                       profile['user_image'] ??
                       profile['avatar'];

      bool isMe = (myUserIdStr.isNotEmpty && pId == myUserIdStr) || 
                  (myNickname.isNotEmpty && nick == myNickname) || 
                  nick == '나';

      if ((rawImg == null || rawImg.toString().trim().isEmpty) && isMe) {
        rawImg = myProfileImg;
      }

      final String? formattedUrl = formatImgUrl(rawImg);
      final String initial = nick.isNotEmpty ? nick.substring(0, 1) : '유';

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg ?? const Color(0xFF6241D9),
          borderRadius: BorderRadius.circular(size * 0.35), 
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: (formattedUrl != null && formattedUrl.isNotEmpty)
            ? Image.network(
                formattedUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  initial,
                  style: TextStyle(color: Colors.white, fontSize: size * 0.45, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                ),
              )
            : Text(
                initial,
                style: TextStyle(color: Colors.white, fontSize: size * 0.45, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
              ),
      );
    }

    final int count = profiles.length;

    if (count == 1) {
      return singleMiniAvatar(profiles[0], 48, bg: const Color(0xFF6241D9));
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (count == 2) ...[
            Positioned(left: 0, top: 0, child: singleMiniAvatar(profiles[0], 26, bg: const Color(0xFF818CF8))),
            Positioned(right: 0, bottom: 0, child: singleMiniAvatar(profiles[1], 26, bg: const Color(0xFF6366F1))),
          ] else if (count == 3) ...[
            Positioned(left: 11, top: 0, child: singleMiniAvatar(profiles[0], 23, bg: const Color(0xFF94A3B8))),
            Positioned(left: 0, bottom: 0, child: singleMiniAvatar(profiles[1], 23, bg: const Color(0xFF64748B))),
            Positioned(right: 0, bottom: 0, child: singleMiniAvatar(profiles[2], 23, bg: const Color(0xFF475569))),
          ] else ...[
            Positioned(left: 0, top: 0, child: singleMiniAvatar(profiles[0], 22, bg: const Color(0xFF94A3B8))),
            Positioned(right: 0, top: 0, child: singleMiniAvatar(profiles[1], 22, bg: const Color(0xFF64748B))),
            Positioned(left: 0, bottom: 0, child: singleMiniAvatar(profiles[2], 22, bg: const Color(0xFF475569))),
            Positioned(right: 0, bottom: 0, child: singleMiniAvatar(profiles[3], 22, bg: const Color(0xFF334155))),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final allRooms = ref.watch(sortedChatProvider);

    final Set<int> seenRoomIds = {};
    List<ChatModel> filteredRooms = [];

    for (var room in allRooms) {
      final int rId = int.tryParse(room.id.toString()) ?? 0;
      if (rId > 0 && !seenRoomIds.contains(rId)) {
        seenRoomIds.add(rId);
        final title = room.name.toLowerCase();
        if (title.contains(_searchQuery.toLowerCase())) {
          filteredRooms.add(room);
        }
      }
    }

    filteredRooms.sort((a, b) {
      final int aRoomId = int.tryParse(a.id.toString()) ?? 0;
      final int bRoomId = int.tryParse(b.id.toString()) ?? 0;
      final bool aPinned = _pinnedRoomIds.contains(aRoomId);
      final bool bPinned = _pinnedRoomIds.contains(bRoomId);

      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

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
                              } else if (value == '안  읽음') {
                                ref.read(chatSortProvider.notifier).state = ChatSortOrder.unread;
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
            child: RefreshIndicator(
              color: const Color(0xFF7C5CFC),
              backgroundColor: Colors.white,
              onRefresh: () async {
                await ref.read(chatProvider.notifier).fetchRooms();
              },
              child: filteredRooms.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(child: Text(_searchQuery.isEmpty ? '참여 중인 채팅방이 존재하지 않습니다.' : '\'$_searchQuery\' 검색 결과방이 없습니다.', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Pretendard'))),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) => _buildDismissibleCard(filteredRooms[index]),
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDismissibleCard(ChatModel room) {
    final int parsedRoomId = int.tryParse(room.id.toString()) ?? 0;

    return Dismissible(
      key: ValueKey('dismiss_room_${room.id}'),
      direction: DismissDirection.endToStart, 
      confirmDismiss: (direction) async {
        final bool? result = await _showLeaveConfirmDialog(room.name);
        return result ?? false; 
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D4D), 
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('방 나가기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pretendard')),
            SizedBox(width: 8),
            Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      onDismissed: (direction) {
        if (parsedRoomId > 0) {
          _leaveRoomSilently(parsedRoomId);
        }
      },
      child: _buildPureCardBody(room, parsedRoomId),
    );
  }

  Widget _buildPureCardBody(ChatModel room, int parsedRoomId) {
    final bool isPinned = _pinnedRoomIds.contains(parsedRoomId);
    final bool isMuted = _mutedRoomIds.contains(parsedRoomId);

    final String rawLastMsg = LocalDeletionStorage.hasOverride(parsedRoomId)
        ? (LocalDeletionStorage.getRoomLastMessage(parsedRoomId) ?? '')
        : room.cleanLastMessage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPinned ? const Color(0xFFF1F0FF) : Colors.white, 
        borderRadius: BorderRadius.circular(18), 
        border: Border.all(color: isPinned ? const Color(0xFF7C5CFC).withOpacity(0.3) : const Color(0xFFEDF2F7), width: 1.0), 
        boxShadow: [BoxShadow(color: const Color(0xFF1E2939).withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTapDown: (details) {
            _tapPosition = details.globalPosition;
          },
          onTap: () => _navigateToRoom(room, parsedRoomId),
          onLongPress: () {
            _showKakaoContextMenu(room, parsedRoomId, _tapPosition);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildListCompositeAvatar(room),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (isPinned) ...[
                                  const Icon(Icons.push_pin_rounded, size: 14, color: Color(0xFF7C5CFC)),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    room.name, 
                                    style: const TextStyle(color: Color(0xFF1E2939), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Pretendard', letterSpacing: -0.4), 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (room.derivedMemberCount > 0) ...[
                                  const SizedBox(width: 5), 
                                  Text(
                                    '${room.derivedMemberCount}', 
                                    style: const TextStyle(color: Color(0xFF7C5CFC), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMuted) ...[
                                const Icon(Icons.notifications_off_rounded, size: 13, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                room.lastTime, 
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Pretendard'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatCleanLastMessage(rawLastMsg), 
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontFamily: 'Pretendard'), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (room.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444), 
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${room.unreadCount}', 
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
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