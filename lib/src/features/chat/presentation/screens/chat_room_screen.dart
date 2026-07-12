import 'dart:async';
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http; 
import 'package:tripto/src/core/auth_storage.dart';
import 'chat_room_settings_screen.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String title;
  final bool isBotRoom;
  final int roomId; 
  final Map<int, String>? initialMemberNames; 

  const ChatRoomScreen({
    super.key, 
    required this.title, 
    this.isBotRoom = false,
    required this.roomId, 
    this.initialMemberNames, 
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  WebSocket? _webSocket; 
  StreamSubscription? _wsSubscription;
  bool _isHistoryLoading = true; 
  int _myUserId = 2; 

  final Map<int, int> _userLastReadMap = {}; 
  final Set<int> _allRoomMembers = {}; 
  final Map<int, String> _userNamesMap = {}; 

  @override
  void initState() {
    super.initState();
    if (widget.initialMemberNames != null) {
      _userNamesMap.addAll(widget.initialMemberNames!);
    }
    _initializeChatRoom();
  }

  Future<void> _initializeChatRoom() async {
    await _fetchMyProfile();
    await _fetchRoomRealMembersAndNicknames(); 
    await _connectWebSocket(); 
    await _fetchChatHistory(); 
  }

  Future<void> _fetchMyProfile() async {
    try {
      final response = await http.get(Uri.parse('${AuthStorage.baseUrl}/auth/me'), headers: AuthStorage.authHeaders);
      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _myUserId = int.tryParse(userData['id']?.toString() ?? userData['user_id']?.toString() ?? '2') ?? 2;
          _allRoomMembers.add(_myUserId);
          _userNamesMap[_myUserId] = userData['nickname']?.toString() ?? userData['name']?.toString() ?? userData['username']?.toString() ?? '나';
        });
      }
    } catch (e) {
      debugPrint('내 프로필 ID 획득 실패: $e');
    }
  }

  Future<void> _fetchRoomRealMembersAndNicknames() async {
    try {
      final response = await http.get(Uri.parse('${AuthStorage.baseUrl}/chat/rooms'), headers: AuthStorage.authHeaders);
      if (response.statusCode == 200) {
        final List<dynamic> rooms = jsonDecode(utf8.decode(response.bodyBytes));
        final currentRoom = rooms.firstWhere(
          (r) => (int.tryParse(r['room_id']?.toString() ?? r['id']?.toString() ?? '') == widget.roomId),
          orElse: () => null,
        );

        if (currentRoom != null && currentRoom is Map) {
          final List<dynamic>? memberIds = currentRoom['member_ids'] ?? currentRoom['invited_user_ids'];
          if (memberIds != null) {
            setState(() {
              for (var id in memberIds) {
                int? parsedId = int.tryParse(id.toString());
                if (parsedId != null) _allRoomMembers.add(parsedId);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('방 정보 기반 인원수 동기화 패스: $e');
    }
  }

  /// ── 💥 [파서 고도화]: 타이트한 제네릭 검사(is Map<String, dynamic>)를 깨부수고 무조건 장부를 파싱합니다. ──
  Future<void> _fetchChatHistory() async {
    try {
      final targetUrl = '${AuthStorage.baseUrl}/chat/${widget.roomId}/messages';
      final response = await http.get(Uri.parse(targetUrl), headers: AuthStorage.authHeaders);

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        List<dynamic> historyList = [];
        
        // 💡 맵 구조이기만 하면 변환 형태와 상관없이 무조건 진입하도록 수정[cite: 8]
        if (responseData is Map) {
          historyList = responseData['messages'] ?? [];
          
          final readStatuses = responseData['read_statuses'] ?? {};
          if (readStatuses is Map) {
            readStatuses.forEach((key, value) {
              final int? uId = int.tryParse(key.toString());
              final int? lastReadId = int.tryParse(value.toString());
              if (uId != null && lastReadId != null) {
                _userLastReadMap[uId] = lastReadId;
              }
            });
          }

          final userNames = responseData['user_names'] ?? {};
          if (userNames is Map) {
            userNames.forEach((key, value) {
              final int? uId = int.tryParse(key.toString());
              if (uId != null && value != null && value.toString().trim().isNotEmpty) {
                _userNamesMap[uId] = value.toString();
              }
            });
          }
        } 
        else if (responseData is List) {
          historyList = responseData;
        }

        List<Map<String, dynamic>> parsedHistory = [];
        int highestOpponentMsgId = 0;

        for (var item in historyList) {
          if (item is! Map) continue;
          
          final int msgId = int.tryParse(item['message_id']?.toString() ?? '0') ?? 0;
          final int senderId = int.tryParse(item['sender_id']?.toString() ?? '0') ?? 0;
          final String content = item['content']?.toString() ?? '';
          
          if (content.trim().isEmpty) continue;
          if (senderId > 0) _allRoomMembers.add(senderId);

          final DateTime parsedTime = DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.now();
          final String timeStr = '${parsedTime.hour >= 12 ? "오후" : "오전"} ${(parsedTime.hour % 12 == 0 ? 12 : parsedTime.hour % 12)}:${parsedTime.minute.toString().padLeft(2, '0')}';

          if (senderId != _myUserId && msgId > highestOpponentMsgId) {
            highestOpponentMsgId = msgId;
          }

          parsedHistory.add({
            'message_id': msgId,
            'sender_id': senderId,
            'isMe': (senderId == _myUserId), 
            'text': content,
            'time': timeStr,
          });
        }

        setState(() {
          _messages.clear(); 
          _messages.addAll(parsedHistory);
        });
        _scrollToBottom();

        if (highestOpponentMsgId > 0) {
          _sendReadAcknowledge(highestOpponentMsgId);
        }
      }
    } catch (e) {
      debugPrint('❌ 과거 채팅 내역 파싱 에러: $e');
    } finally {
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> _connectWebSocket() async {
    final wsUrl = AuthStorage.baseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
    final fullWsPath = '$wsUrl/chat/ws/${widget.roomId}?user_id=$_myUserId';

    try {
      _webSocket = await WebSocket.connect(fullWsPath);
      _wsSubscription = _webSocket?.listen(
        (rawData) => _parseAndAppendMessage(rawData.toString()),
        onError: (err) => debugPrint('웹소켓 에러: $err'),
      );
    } catch (e) {
      debugPrint('웹소켓 연결 실패: $e');
    }
  }

  void _parseAndAppendMessage(String rawData) {
    try {
      final Map<String, dynamic> payload = jsonDecode(rawData);
      final String type = payload['type'] ?? '';
      
      if (type == 'new_message') {
        final int senderId = int.tryParse(payload['sender_id']?.toString() ?? '0') ?? 0;
        final String content = payload['content']?.toString() ?? '';
        final int msgId = int.tryParse(payload['message_id']?.toString() ?? '0') ?? 0;

        if (senderId > 0) _allRoomMembers.add(senderId);

        final String? socketNick = payload['sender_nickname']?.toString();
        if (senderId > 0 && socketNick != null && socketNick.isNotEmpty) {
          _userNamesMap[senderId] = socketNick;
        }

        if (senderId == _myUserId) {
          setState(() {
            for (int i = _messages.length - 1; i >= 0; i--) {
              if (_messages[i]['sender_id'] == _myUserId && _messages[i]['message_id'] == null) {
                _messages[i]['message_id'] = msgId;
                break;
              }
            }
          });
          return;
        }

        final now = DateTime.now();
        final String timeStr = '${now.hour >= 12 ? "오후" : "오전"} ${(now.hour % 12 == 0 ? 12 : now.hour % 12)}:${now.minute.toString().padLeft(2, '0')}';

        if (mounted) {
          setState(() {
            _messages.add({
              'message_id': msgId,
              'sender_id': senderId,
              'isMe': false, 
              'text': content,
              'time': timeStr,
            });
          });
          _scrollToBottom();
          _sendReadAcknowledge(msgId);
        }
      } 
      else if (type == 'read_update') {
        final int readingUserId = int.tryParse(payload['user_id']?.toString() ?? '0') ?? 0;
        final int lastReadId = int.tryParse(payload['last_read_message_id']?.toString() ?? '0') ?? 0;
        
        setState(() {
          _userLastReadMap[readingUserId] = lastReadId;
          if (readingUserId > 0) _allRoomMembers.add(readingUserId);
        });
      }
    } catch (e) {
      debugPrint('⚠️ 실시간 소켓 JSON 파싱 실패: $e');
    }
  }

  void _sendReadAcknowledge(int messageId) {
    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      final Map<String, dynamic> readPayload = {"action": "read_message", "message_id": messageId};
      _webSocket!.add(jsonEncode(readPayload));
    }
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    final String userText = _msgController.text.trim();
    
    final Map<String, dynamic> socketRequestPayload = {"action": "send_message", "content": userText};
    _webSocket?.add(jsonEncode(socketRequestPayload));
    
    final now = DateTime.now();
    final String timeStr = '${now.hour >= 12 ? "오후" : "오전"} ${(now.hour % 12 == 0 ? 12 : now.hour % 12)}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add({
        'message_id': null, 
        'sender_id': _myUserId,
        'isMe': true,
        'text': userText,
        'time': timeStr,
      });
      _msgController.clear();
    });
    _scrollToBottom();
  }

  void _showDeleteMessageDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text('선택한 메시지를 삭제하시겠습니까?\n(내 화면에서만 제거됩니다.)', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 15, fontFamily: 'Pretendard', height: 1.4)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey, fontSize: 14))),
          TextButton(onPressed: () { setState(() => _messages.removeAt(index)); Navigator.pop(context); }, child: const Text('삭제', style: TextStyle(color: Color(0xFFFF4D4D), fontSize: 14, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  int _calculateUnreadCount(Map<String, dynamic> msg) {
    final int? msgId = msg['message_id'];
    final int senderId = msg['sender_id'] ?? 0;
    if (msgId == null) return 0;

    int totalMembers = _allRoomMembers.length;
    if (totalMembers < 2) totalMembers = 2;

    final int targetCount = totalMembers - 1; 
    int readCount = 0;

    if (senderId != _myUserId) readCount++; 

    _userLastReadMap.forEach((userId, lastReadId) {
      if (userId != senderId && _allRoomMembers.contains(userId)) { 
        if (lastReadId >= msgId) readCount++;
      }
    });

    int remainingUnread = targetCount - readCount;
    return remainingUnread < 0 ? 0 : remainingUnread;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel(); 
    _webSocket?.close(); 
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(63),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))]),
          child: AppBar(
            backgroundColor: Colors.transparent, elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E2939), size: 20), onPressed: () => Navigator.pop(context)),
            title: Text(widget.title, style: const TextStyle(color: Color(0xFF1E2939), fontSize: 18, fontFamily: 'Pretendard', fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E2939), size: 24),
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => ChatRoomSettingsScreen(
                      title: widget.title,
                      roomId: widget.roomId, 
                      activeMemberIds: _allRoomMembers.toList(), 
                      userNamesMap: _userNamesMap, 
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isHistoryLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6241D9)))
          : _messages.isEmpty
              ? const Center(child: Text("실시간 대화방이 동기화되었습니다.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Pretendard')))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg, index);
                  },
                ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, size: 22, color: Color(0xFF64748B))),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Pretendard'),
                  decoration: const InputDecoration(hintText: '메세지를 입력하세요...', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 11)),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(onTap: _sendMessage, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF6241D9), shape: BoxShape.circle), child: const Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.white))),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, int index) {
    final bool isMe = msg['isMe'] ?? false;
    final int senderId = msg['sender_id'] ?? 0;
    final int unreadCount = _calculateUnreadCount(msg);

    final String userRealName = _userNamesMap[senderId] ?? '유저 $senderId';
    final String initialLetter = userRealName.isNotEmpty ? userRealName.substring(0, 1) : '유';

    return GestureDetector(
      onLongPress: () => _showDeleteMessageDialog(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 4),
                child: Text(userRealName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Pretendard', fontWeight: FontWeight.w600)),
              ),
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 18, 
                    backgroundColor: const Color(0x266241D9), 
                    child: Text(initialLetter, style: const TextStyle(color: Color(0xFF6241D9), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                ],
                if (isMe) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (unreadCount > 0) Text('$unreadCount', style: const TextStyle(color: Color(0xFF6241D9), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                      Text(msg['time'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Pretendard')),
                    ],
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.62),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF6241D9) : Colors.white,
                    borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                    border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1E2939), fontSize: 14, fontFamily: 'Pretendard', height: 1.4)),
                ),
                if (!isMe) ...[
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (unreadCount > 0) Text('$unreadCount', style: const TextStyle(color: Color(0xFF6241D9), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                      Text(msg['time'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Pretendard')),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}