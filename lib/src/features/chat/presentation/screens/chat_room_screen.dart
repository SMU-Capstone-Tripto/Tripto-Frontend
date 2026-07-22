import 'dart:async'; 
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http; 
import 'package:tripto/src/core/auth_storage.dart';
import 'chat_room_settings_screen.dart';

class ParsedTimelineItem {
  final String time;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final bool isTransit;

  ParsedTimelineItem({
    required this.time,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    this.isTransit = false,
  });
}

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String title;
  final bool isBotRoom;
  final int roomId; 
  final Map<int, String>? initialMemberNames; 
  final Map<int, String?>? initialMemberImages;

  const ChatRoomScreen({
    super.key, 
    required this.title, 
    this.isBotRoom = false,
    required this.roomId, 
    this.initialMemberNames, 
    this.initialMemberImages,
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
  final Map<int, String?> _userProfileImagesMap = {};

  String? _currentAiStatus; 
  bool _showVoteConfirmButtons = false; 
  bool _isAiStreaming = false;
  int? _roomOwnerId; 

  @override
  void initState() {
    super.initState();
    if (widget.initialMemberNames != null) {
      _userNamesMap.addAll(widget.initialMemberNames!);
    }
    if (widget.initialMemberImages != null) {
      _userProfileImagesMap.addAll(widget.initialMemberImages!);
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
          
          final String? myProfileImg = userData['profile_image']?.toString() ?? userData['profile_img']?.toString();
          if (myProfileImg != null && myProfileImg.isNotEmpty) {
            _userProfileImagesMap[_myUserId] = myProfileImg;
          }
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
          final int? owner = int.tryParse(currentRoom['owner_id']?.toString() ?? '');
          if (owner != null) {
            setState(() => _roomOwnerId = owner); 
          }

          final List<dynamic>? memberIds = currentRoom['member_ids'] ?? currentRoom['invited_user_ids'];
          if (memberIds != null) {
            setState(() {
              for (var id in memberIds) {
                int? parsedId = int.tryParse(id.toString());
                if (parsedId != null) _allRoomMembers.add(parsedId);
              }
            });
          }

          final dynamic members = currentRoom['members'] ?? currentRoom['user_profiles'] ?? currentRoom['profiles'];
          if (members is List) {
            setState(() {
              for (var m in members) {
                if (m is Map) {
                  final int? uId = int.tryParse(m['id']?.toString() ?? m['user_id']?.toString() ?? '');
                  final String? img = m['profile_image']?.toString() ?? m['profile_img']?.toString();
                  final String? nick = m['nickname']?.toString() ?? m['name']?.toString();
                  if (uId != null) {
                    if (img != null && img.isNotEmpty) _userProfileImagesMap[uId] = img;
                    if (nick != null && nick.isNotEmpty) _userNamesMap[uId] = nick;
                  }
                }
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('방 정보 기반 인원수 동기화 패스: $e');
    }
  }

  Future<void> _fetchChatHistory() async {
    try {
      final targetUrl = '${AuthStorage.baseUrl}/chat/${widget.roomId}/messages';
      final response = await http.get(Uri.parse(targetUrl), headers: AuthStorage.authHeaders);

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> historyList = [];
        
        if (responseData is Map) {
          historyList = responseData['messages'] ?? [];
          
          final dynamic rawReadStatuses = responseData['read_statuses'];
          if (rawReadStatuses is Map) {
            rawReadStatuses.forEach((key, value) {
              final int? uId = int.tryParse(key.toString());
              final int? lastReadId = int.tryParse(value?.toString() ?? '');
              if (uId != null && lastReadId != null) {
                _userLastReadMap[uId] = lastReadId;
                _allRoomMembers.add(uId); 
              }
            });
          }

          final dynamic rawUserNames = responseData['user_names'];
          if (rawUserNames is Map) {
            rawUserNames.forEach((key, value) {
              final int? uId = int.tryParse(key.toString());
              final String? nick = value?.toString();
              if (uId != null && nick != null && nick.trim().isNotEmpty) {
                _userNamesMap[uId] = nick;
                _allRoomMembers.add(uId); 
              }
            });
          }

          final dynamic rawUserImages = responseData['user_images'] ?? responseData['profile_images'] ?? responseData['user_profiles'];
          if (rawUserImages is Map) {
            rawUserImages.forEach((key, value) {
              final int? uId = int.tryParse(key.toString());
              final String? img = value?.toString();
              if (uId != null && img != null && img.trim().isNotEmpty) {
                _userProfileImagesMap[uId] = img;
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
          if (item == null) continue;
          final Map<String, dynamic> msgMap = Map<String, dynamic>.from(item);
          
          final int msgId = int.tryParse(msgMap['message_id']?.toString() ?? '0') ?? 0;
          final int senderId = int.tryParse(msgMap['sender_id']?.toString() ?? '0') ?? 0;
          final String content = msgMap['content']?.toString() ?? '';
          final String? senderImg = msgMap['sender_profile_image']?.toString() ?? msgMap['profile_image']?.toString();
          
          if (content.trim().isEmpty) continue;
          if (senderId > 0) {
            _allRoomMembers.add(senderId);
            if (senderImg != null && senderImg.isNotEmpty) {
              _userProfileImagesMap[senderId] = senderImg;
            }
          }

          bool isAiMessageInHistory = content.startsWith('{"tripto_card_type"');
          int mappedSenderId = senderId;
          bool mappedIsMe = (senderId == _myUserId);

          if (isAiMessageInHistory) {
            mappedSenderId = -1; 
            mappedIsMe = false;
          }

          final DateTime parsedTime = DateTime.tryParse(msgMap['created_at']?.toString() ?? '') ?? DateTime.now();
          final String timeStr = '${parsedTime.hour >= 12 ? "오후" : "오전"} ${(parsedTime.hour % 12 == 0 ? 12 : parsedTime.hour % 12)}:${parsedTime.minute.toString().padLeft(2, '0')}';

          if (senderId != _myUserId && msgId > highestOpponentMsgId) {
            highestOpponentMsgId = msgId;
          }

          parsedHistory.add(<String, dynamic>{
            'message_id': msgId,
            'sender_id': mappedSenderId,
            'isMe': mappedIsMe, 
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
    final cleanBaseUrl = AuthStorage.baseUrl.trim().replaceAll('\n', '').replaceAll('\r', '');
    final wsUrl = cleanBaseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
    
    final authHeader = AuthStorage.authHeaders['Authorization'] ?? AuthStorage.authHeaders['authorization'] ?? '';
    final token = authHeader.replaceFirst('Bearer ', '').trim();
    
    final fullWsPath = '$wsUrl/chat/ws/${widget.roomId}?user_id=$_myUserId&token=$token&access_token=$token';
    
    final Map<String, dynamic> wsHeaders = {
      'Authorization': 'Bearer $token',
      'authorization': 'Bearer $token',
      'Cookie': 'Authorization=Bearer $token; token=$token',
    };
    
    try {
      final uri = Uri.parse(cleanBaseUrl);
      wsHeaders['Host'] = uri.host + (uri.hasPort ? ':${uri.port}' : '');
      wsHeaders['Origin'] = cleanBaseUrl;
    } catch (_) {}

    try {
      _webSocket = await WebSocket.connect(fullWsPath, headers: wsHeaders);
      debugPrint('🟢 웹소켓 링크 연결 성공: $fullWsPath');
      
      _wsSubscription = _webSocket?.listen(
        (rawData) {
          // 🎯 서버 응답 실시간 출력 로그 추가
          debugPrint('📩 [웹소켓 서버 응답]: $rawData');
          _parseAndAppendMessage(rawData.toString());
        },
        onError: (err) => debugPrint('❌ 웹소켓 에러: $err'),
        onDone: () => debugPrint('⚠️ 웹소켓 연결 종료됨'),
      );
    } catch (e) {
      debugPrint('❌ 웹소켓 연결 실패: $e');
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

        final String? socketImg = payload['sender_profile_image']?.toString() ?? payload['profile_image']?.toString();
        if (senderId > 0 && socketImg != null && socketImg.isNotEmpty) {
          _userProfileImagesMap[senderId] = socketImg;
        }

        if (msgId > 0 && _messages.any((m) => m['message_id'] == msgId)) {
          return;
        }

        if (senderId == _myUserId) {
          final int pendingIndex = _messages.indexWhere(
            (m) => m['sender_id'] == _myUserId && m['message_id'] == null && m['text'] == content
          );

          if (pendingIndex != -1) {
            setState(() {
              _messages[pendingIndex]['message_id'] = msgId;
            });
            return; 
          }
        }

        bool isAiCard = content.startsWith('{"tripto_card_type"');
        int mappedSenderId = isAiCard ? -1 : senderId;

        if (mappedSenderId == -1 && _messages.any((m) => m['sender_id'] == -1 && m['text'] == content)) {
          return;
        }

        final now = DateTime.now();
        final String timeStr = '${now.hour >= 12 ? "오후" : "오전"} ${(now.hour % 12 == 0 ? 12 : now.hour % 12)}:${now.minute.toString().padLeft(2, '0')}';

        if (mounted) {
          setState(() {
            _messages.add(<String, dynamic>{
              'message_id': msgId > 0 ? msgId : null,
              'sender_id': mappedSenderId,
              'isMe': (mappedSenderId == _myUserId), 
              'text': content,
              'time': timeStr,
            });
          });
          _scrollToBottom();
          if (senderId != _myUserId && msgId > 0) {
            _sendReadAcknowledge(msgId);
          }
        }
      } 
      else if (type == 'read_update') {
        final int readingUserId = int.tryParse(payload['user_id']?.toString() ?? '0') ?? 0;
        final int lastReadId = int.tryParse(payload['last_read_message_id']?.toString() ?? '0') ?? 0;
        
        if (mounted && readingUserId > 0 && lastReadId > 0) {
          setState(() {
            _userLastReadMap[readingUserId] = lastReadId;
            _allRoomMembers.add(readingUserId);
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ 소켓 파싱 에러: $e');
    }
  }

  void _sendReadAcknowledge(int messageId) {
    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      final Map<String, dynamic> readPayload = {"action": "read_message", "message_id": messageId};
      _webSocket!.add(jsonEncode(readPayload));
    }
  }

  Future<void> _fireAiAgentStream(String cleanMessage) async {
    if (_isAiStreaming) return;
    setState(() {
      _isAiStreaming = true;
      _currentAiStatus = "AI 분석 요청 중...";
    });

    final int tempMsgId = -999; 
    setState(() {
      _messages.add(<String, dynamic>{
        'message_id': tempMsgId,
        'sender_id': -1, 
        'isMe': false,
        'text': "🔍 답변을 생성하고 있습니다...", 
        'time': '',
      });
    });
    _scrollToBottom();

    try {
      final client = http.Client();
      final request = http.Request('POST', Uri.parse('${AuthStorage.baseUrl}/agent/chat'));
      request.headers.addAll({
        ...AuthStorage.authHeaders,
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({
        "message": cleanMessage,
        "room_id": widget.roomId, 
      });

      final response = await client.send(request);
      String accumulatedText = "";
      Map<String, dynamic>? finalOptimizedData;

      if (response.statusCode == 200) {
        final streamLines = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in streamLines) {
          if (line.startsWith('data: ')) {
            final dataContent = line.substring(6).trim();
            if (dataContent == '[DONE]') break;

            try {
              if (dataContent.startsWith('{') && dataContent.endsWith('}')) {
                final payload = jsonDecode(dataContent);
                final String type = payload['type'] ?? '';

                if (type == 'status') {
                  setState(() => _currentAiStatus = payload['message']);
                } 
                else if (type == 'result') {
                  final String step = payload['step'] ?? '';
                  accumulatedText = payload['content'] ?? '';

                  if (step == 'vote_confirm') {
                    setState(() => _showVoteConfirmButtons = true); 
                  } 
                  else if (step == 'optimized' || payload['itinerary'] != null) {
                    finalOptimizedData = payload;
                  }

                  setState(() {
                    final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                    if (idx != -1) _messages[idx]['text'] = accumulatedText;
                  });
                  _scrollToBottom();
                }
              } else {
                accumulatedText = dataContent;
                setState(() {
                  final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                  if (idx != -1) _messages[idx]['text'] = accumulatedText;
                });
              }
            } catch (_) {
              accumulatedText = dataContent;
              setState(() {
                final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                if (idx != -1) _messages[idx]['text'] = accumulatedText;
              });
            }
          }
        }

        bool isSocketConnected = (_webSocket != null && _webSocket!.readyState == WebSocket.open);
        if (isSocketConnected) {
          setState(() {
            _messages.removeWhere((m) => m['message_id'] == tempMsgId);
          });
        } else {
          setState(() {
            final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
            if (idx != -1) {
              _messages[idx]['message_id'] = DateTime.now().millisecondsSinceEpoch; 
              if (finalOptimizedData != null) {
                _messages[idx]['text'] = jsonEncode({
                  "tripto_card_type": "optimized",
                  "plan_title": finalOptimizedData!['plan_title'] ?? widget.title,
                  "itinerary": finalOptimizedData!['itinerary'] ?? [],
                  "estimated_cost": finalOptimizedData!['estimated_cost'] ?? {},
                  "content": accumulatedText,
                });
              } else {
                _messages[idx]['text'] = accumulatedText;
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('AI 에이전트 장애: $e');
    } finally {
      setState(() {
        _isAiStreaming = false;
        _currentAiStatus = null;
      });
    }
  }

  void _insertAiTag() {
    const tag = '@트립토 ';
    final currentText = _msgController.text;
    if (!currentText.startsWith('@트립토') && !currentText.startsWith('@tripto')) {
      _msgController.text = '$tag$currentText';
      _msgController.selection = TextSelection.fromPosition(
        TextPosition(offset: _msgController.text.length),
      );
    }
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    final String originalText = _msgController.text.trim();
    _msgController.clear();

    // 🎯 [핵심 방어 코드 및 전송 디버그 로그 추가]
    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      final Map<String, dynamic> socketRequestPayload = {
        "action": "send_message",
        "content": originalText,
      };
      debugPrint('📤 [웹소켓 전송]: ${jsonEncode(socketRequestPayload)}');
      _webSocket!.add(jsonEncode(socketRequestPayload));
    } else {
      debugPrint('⚠️ 웹소켓 미연결 상태 (readyState: ${_webSocket?.readyState}) - 전송 불가');
    }
    
    final now = DateTime.now();
    final String timeStr = '${now.hour >= 12 ? "오후" : "오전"} ${(now.hour % 12 == 0 ? 12 : now.hour % 12)}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(<String, dynamic>{
        'message_id': null, 
        'sender_id': _myUserId,
        'isMe': true,
        'text': originalText,
        'time': timeStr,
      });
      _allRoomMembers.add(_myUserId); 
    });
    _scrollToBottom();

    final bool isAiCall = originalText.startsWith('@tripto') || originalText.startsWith('@트립토');
    final bool isVoteTrigger = _isInternalVoteWord(originalText);

    if (isAiCall || isVoteTrigger) {
      String purePrompt = originalText.replaceAll('@tripto', '').replaceAll('@트립토', '').trim();
      if (purePrompt.isEmpty && isVoteTrigger) purePrompt = originalText;
      
      if (purePrompt.isNotEmpty) {
        _fireAiAgentStream(purePrompt);
      }
    }
  }

  bool _isInternalVoteWord(String text) {
    final triggers = ["투표할게", "투표 시작", "투표하자", "투표 만들어", "투표할래", "투표 해줘", "이제 투표", "투표 시작해", "투표 열어", "투표 개설"];
    return triggers.any((t) => text.contains(t));
  }

  int _calculateUnreadCount(Map<String, dynamic> msg) {
    final int? msgId = msg['message_id'];
    final int senderId = msg['sender_id'] ?? 0;
    if (msgId == null || msgId <= 0) return 0;

    int unreadPeople = 0;
    for (var memberId in _allRoomMembers) {
      if (memberId == senderId || memberId == _myUserId || memberId == -1) continue; 

      final int lastReadId = _userLastReadMap[memberId] ?? 0;
      if (lastReadId < msgId) {
        unreadPeople++;
      }
    }
    return unreadPeople;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    final rawString = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final intVal = int.tryParse(rawString);
    if (intVal == null) return value.toString();
    
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return intVal.toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
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
                      userProfileImagesMap: _userProfileImagesMap,
                      ownerId: _roomOwnerId, 
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isHistoryLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF524582)))
                : _messages.isEmpty
                    ? const Center(child: Text("실시간 대화방이 동기화되었습니다.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Pretendard')))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildChatBubble(_messages[index], index),
                      ),
          ),
          
          if (_showVoteConfirmButtons)
            Container(
              color: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🤖 tripto의 질문: 이 일정으로 투표방 개설을 승인할까요?",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF524582), fontFamily: 'Pretendard'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF524582), 
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                        label: const Text("네, 시작해 주세요", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pretendard', fontSize: 13)),
                        onPressed: () {
                          setState(() => _showVoteConfirmButtons = false);
                          _fireAiAgentStream("네"); 
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (_currentAiStatus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFFEEF2F6),
              child: Row(
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF524582))),
                  const SizedBox(width: 12),
                  Text(_currentAiStatus!, style: const TextStyle(fontSize: 13, color: Color(0xFF524582), fontWeight: FontWeight.w600, fontFamily: 'Pretendard')),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, size: 22, color: Color(0xFF64748B))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _insertAiTag,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF524582).withOpacity(0.3)),
                ),
                child: const Text(
                  '@트립토',
                  style: TextStyle(
                    color: Color(0xFF524582),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 40, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Pretendard'),
                  decoration: const InputDecoration(
                    hintText: '메세지를 입력하세요...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF524582), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, int index) {
    final bool isMe = msg['isMe'] ?? false;
    final int senderId = msg['sender_id'] ?? 0;
    final int unreadCount = _calculateUnreadCount(msg);
    final String rawText = msg['text'] ?? '';

    final bool isAi = (senderId == -1);

    String userRealName = '';
    if (isAi) {
      userRealName = 'tripto';
    } else {
      String rawNick = _userNamesMap[senderId]?.trim() ?? '';
      rawNick = rawNick.replaceAll('<', '').replaceAll('>', '').replaceAll('(', '').replaceAll(')', '').trim();

      bool isInvalid = rawNick.isEmpty || 
                       rawNick.contains('대화상대') || 
                       rawNick.contains('알수없음') || 
                       rawNick.contains('알 수 없음') || 
                       RegExp(r'^유저\d+$').hasMatch(rawNick);

      userRealName = isInvalid ? '(알수없음)' : rawNick;
    }

    final String initialLetter = isAi ? '🤖' : (userRealName == '(알수없음)' ? '?' : userRealName.substring(0, 1));
    final String? profileImgUrl = isAi ? null : _userProfileImagesMap[senderId];

    bool isOptimizedCard = false;
    bool isAiText = false;
    Map<String, dynamic>? cardData;
    String displayAiText = rawText;

    if (rawText.startsWith('{"tripto_card_type"') || rawText.startsWith('{"plan_title"')) {
      try {
        final parsed = jsonDecode(rawText);
        final String cardType = parsed['tripto_card_type'] ?? parsed['step'] ?? '';
        if (cardType == 'optimized' || parsed['itinerary'] != null) {
          cardData = parsed;
          isOptimizedCard = true;
        } else if (cardType == 'text') {
          displayAiText = parsed['content'] ?? '';
          isAiText = true;
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 4),
              child: Text(
                userRealName, 
                style: TextStyle(
                  color: isAi ? const Color(0xFF524582) : (userRealName == '(알수없음)' ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), 
                  fontSize: 12, 
                  fontFamily: 'Pretendard', 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAi ? const Color(0xFFF5F3FF) : (userRealName == '(알수없음)' ? const Color(0xFFE2E8F0) : const Color(0x26524582)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: isAi 
                    ? const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF524582))
                    : (profileImgUrl != null && profileImgUrl.isNotEmpty)
                        ? Image.network(
                            profileImgUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              initialLetter,
                              style: TextStyle(
                                color: userRealName == '(알수없음)' ? const Color(0xFF64748B) : const Color(0xFF524582),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          )
                        : Text(
                            initialLetter,
                            style: TextStyle(
                              color: userRealName == '(알수없음)' ? const Color(0xFF64748B) : const Color(0xFF524582),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                ),
                const SizedBox(width: 10),
              ],
              if (isMe) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (unreadCount > 0) Text('$unreadCount', style: const TextStyle(color: Color(0xFF524582), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                    Text(msg['time'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Pretendard')),
                  ],
                ),
                const SizedBox(width: 6),
              ],
              
              isOptimizedCard && cardData != null
                  ? Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.62), 
                      child: _buildAiStructuredCard(cardData),
                    )
                  : isAiText || isAi
                      ? _buildAiQuestionCard(displayAiText) 
                      : Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.62),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF524582) : Colors.white,
                            borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                            border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(rawText, style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1E2939), fontSize: 14, fontFamily: 'Pretendard', height: 1.4)),
                        ),

              if (!isMe) ...[
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unreadCount > 0) Text('$unreadCount', style: const TextStyle(color: Color(0xFF524582), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
                    Text(msg['time'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Pretendard')),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiQuestionCard(String text) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.62),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF), 
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16)),
        border: Border.all(color: const Color(0xFF524582).withOpacity(0.3), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF524582)),
              const SizedBox(width: 6),
              Text("tripto 가이드 질문", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF524582).withOpacity(0.9), fontFamily: 'Pretendard')),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13.5, fontWeight: FontWeight.w500, fontFamily: 'Pretendard', height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAiStructuredCard(Map<String, dynamic> data) {
    final String title = data['plan_title'] ?? '최적화 여행 계획';
    final List<dynamic> itineraries = data['itinerary'] ?? [];
    final Map<String, dynamic> cost = data['estimated_cost'] ?? {};
    final String summaryText = data['content'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border.all(color: const Color(0xFF524582), width: 1.5), 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 6))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFF524582), borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5, fontFamily: 'Pretendard'))),
              ],
            ),
          ),
          if (summaryText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(summaryText, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4, fontFamily: 'Pretendard')),
            ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
          
          ...itineraries.map((dayPlan) {
            final String planStr = dayPlan.toString().trim();
            final List<String> lines = planStr.split('\n');
            final String dayHeader = lines.isNotEmpty ? lines[0] : '상세 일정';
            final List<ParsedTimelineItem> timelineItems = _parseItineraryLines(lines);

            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(dayHeader, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Pretendard')),
                leading: const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF524582)),
                children: [
                  Container(
                    color: const Color(0xFFFAFAFA),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: timelineItems.length,
                      itemBuilder: (context, idx) {
                        final item = timelineItems[idx];
                        return _buildTimelineRow(item, idx == timelineItems.length - 1);
                      },
                    ),
                  )
                ],
              ),
            );
          }),
          
          if (cost.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFAF5FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF524582)),
                      SizedBox(width: 6),
                      Text("💰 정밀 경비 영수증", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF524582), fontFamily: 'Pretendard')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildReceiptRow("🚗 교통비", "${_formatCurrency(cost['transportation'])}원"),
                  _buildReceiptRow("🏨 숙박비", "${_formatCurrency(cost['accommodation'])}원"),
                  _buildReceiptRow("🍔 식비", "${_formatCurrency(cost['meals'])}원"),
                  _buildReceiptRow("🎟️ 액티비티", "${_formatCurrency(cost['activities'])}원"),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(color: Color(0xFFE2E8F0), height: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("합계 금액", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Pretendard')),
                      Text("${_formatCurrency(cost['total'])}원", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF524582), fontFamily: 'Pretendard')),
                    ],
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  List<ParsedTimelineItem> _parseItineraryLines(List<String> lines) {
    final List<ParsedTimelineItem> items = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('[') && trimmed.contains('일차')) continue;
      if (trimmed.contains('일차') && trimmed.length < 10) continue;

      if (trimmed.contains('→') || trimmed.contains('->')) {
        final arrowRegex = RegExp(r'^(\d{2}:\d{2}\s*(?:→|->)\s*\d{2}:\d{2})\s*(.*)');
        final match = arrowRegex.firstMatch(trimmed);
        if (match != null) {
          final time = match.group(1) ?? '';
          final rest = match.group(2) ?? '';
          final detailMatch = RegExp(r'(.*?)\((.*?)\)').firstMatch(rest);
          final title = detailMatch != null ? detailMatch.group(1)!.trim() : rest;
          final detail = detailMatch != null ? detailMatch.group(2)!.trim() : '';

          items.add(ParsedTimelineItem(
            time: time,
            title: title.isEmpty ? "경로 이동" : title,
            detail: detail.isNotEmpty ? "($detail)" : "", 
            icon: Icons.directions_car_filled_rounded,
            color: const Color(0xFF367BC3), 
            isTransit: true,
          ));
        } else {
          items.add(ParsedTimelineItem(
            time: "경로",
            title: trimmed,
            detail: "",
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFF367BC3), 
            isTransit: true,
          ));
        }
        continue;
      }

      final rangeRegex = RegExp(r'^(\d{2}:\d{2}\s*(?:~|-)\s*\d{2}:\d{2})\s+(.*)');
      final singleRegex = RegExp(r'^(\d{2}:\d{2})\s+(.*)');
      
      String time = "";
      String rest = "";

      if (rangeRegex.hasMatch(trimmed)) {
        final match = rangeRegex.firstMatch(trimmed)!;
        time = match.group(1) ?? '';
        rest = match.group(2) ?? '';
      } else if (singleRegex.hasMatch(trimmed)) {
        final match = singleRegex.firstMatch(trimmed)!;
        time = match.group(1) ?? '';
        rest = match.group(2) ?? '';
      }

      if (time.isNotEmpty) {
        final detailMatch = RegExp(r'(.*?)\((.*?)\)').firstMatch(rest);
        final title = detailMatch != null ? detailMatch.group(1)!.trim() : rest;
        final detail = detailMatch != null ? detailMatch.group(2)!.trim() : '';

        IconData icon = Icons.explore_rounded;
        Color color = const Color(0xFF524582); 

        final lowerTitle = title.toLowerCase();
        if (lowerTitle.contains('식사') || lowerTitle.contains('맛집') || lowerTitle.contains('점심') || lowerTitle.contains('저녁') || lowerTitle.contains('식당') || lowerTitle.contains('브런치') ||
            lowerTitle.contains('카페') || lowerTitle.contains('커피') || lowerTitle.contains('디저트')) {
          icon = lowerTitle.contains('카페') || lowerTitle.contains('커피') ? Icons.local_cafe_rounded : Icons.restaurant_rounded;
          color = const Color(0xFF38BFA7); 
        } else if (lowerTitle.contains('호텔') || lowerTitle.contains('숙소') || lowerTitle.contains('체크인') || lowerTitle.contains('체크아웃') || lowerTitle.contains('펜션') || lowerTitle.contains('민박')) {
          icon = Icons.hotel_rounded;
          color = const Color(0xFF8FE1A2); 
        }

        items.add(ParsedTimelineItem(
          time: time,
          title: title,
          detail: detail.isNotEmpty ? "($detail)" : "", 
          icon: icon,
          color: color,
        ));
      } else {
        items.add(ParsedTimelineItem(
          time: "일정",
          title: trimmed,
          detail: "",
          icon: Icons.place_rounded,
          color: const Color(0xFF524582),
        ));
      }
    }
    return items;
  }

  Widget _buildTimelineRow(ParsedTimelineItem item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1), 
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 11, color: item.color), 
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5, 
                    color: const Color(0xFFE2E8F0), 
                    margin: const EdgeInsets.symmetric(vertical: 2)
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.06), 
                          borderRadius: BorderRadius.circular(3)
                        ),
                        child: Text(item.time, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: item.color, fontFamily: 'Pretendard')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(item.title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontFamily: 'Pretendard')),
                  if (item.detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.detail, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontFamily: 'Pretendard', height: 1.3)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E2939), fontFamily: 'Pretendard')),
        ],
      ),
    );
  }
}