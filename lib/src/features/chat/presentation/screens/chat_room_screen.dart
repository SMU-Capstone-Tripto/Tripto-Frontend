import 'dart:async';
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http; 
import 'package:tripto/src/core/auth_storage.dart';
import 'chat_room_settings_screen.dart';

/// 🤖 AI 일정 세부 연출용 정형 구조체
class ParsedTimelineItem {
  final String time;
  final String title;
  final String detail; // AI가 괄호 안에 적어준 원본 명세 데이터 (시간, 비용 등 포함)
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

  String? _currentAiStatus; 
  bool _showVoteConfirmButtons = false; 
  bool _isAiStreaming = false;
  bool _isAiSessionActive = false; 
  int? _roomOwnerId; 

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
          
          if (content.trim().isEmpty) continue;
          if (senderId > 0) _allRoomMembers.add(senderId);

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
      debugPrint('❌ 과거 채팅 내역 파싱 최종 에러 로그: $e');
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
      debugPrint('🟢 웹소켓 보안 핸드셰이크 통과 및 실시간 소켓 링크 개통 완료!');
      
      _wsSubscription = _webSocket?.listen(
        (rawData) => _parseAndAppendMessage(rawData.toString()),
        onError: (err) => debugPrint('웹소켓 에러: $err'),
      );
    } catch (e) {
      debugPrint('❌ 웹소켓 최종 연결 실패: $e');
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

        bool isAiCard = content.startsWith('{"tripto_card_type"');
        if (isAiCard) {
          final now = DateTime.now();
          final String timeStr = '${now.hour >= 12 ? "오후" : "오전"} ${(now.hour % 12 == 0 ? 12 : now.hour % 12)}:${now.minute.toString().padLeft(2, '0')}';
          
          if (mounted) {
            setState(() {
              _messages.add(<String, dynamic>{
                'message_id': msgId,
                'sender_id': -1, 
                'isMe': false,
                'text': content, 
                'time': timeStr,
              });
            });
            _scrollToBottom();
            _sendReadAcknowledge(msgId);
          }
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

        final now = DateTime.now();
        final String timeStr = '${now.hour >= 12 ? "오후" : "오전"} ${(now.hour % 12 == 0 ? 12 : now.hour % 12)}:${now.minute.toString().padLeft(2, '0')}';

        if (mounted) {
          setState(() {
            _messages.add(<String, dynamic>{
              'message_id': msgId,
              'sender_id': senderId,
              'isMe': (senderId == _myUserId), 
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
        'text': "🔍 일정을 구상하고 있습니다...", 
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
              final payload = jsonDecode(dataContent);
              debugPrint("🤖 AI 실시간 응답 payload: $payload");

              final String type = payload['type'] ?? '';

              if (type == 'status') {
                setState(() {
                  _currentAiStatus = payload['message'];
                  final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                  if (idx != -1 && accumulatedText.isEmpty) {
                    _messages[idx]['text'] = "🔍 ${payload['message']}...";
                  }
                });
              } 
              else if (type == 'result') {
                final String step = payload['step'] ?? '';
                accumulatedText = payload['content'] ?? '';

                if (step == 'vote_confirm') {
                  setState(() => _showVoteConfirmButtons = true);
                } 
                else if (step == 'optimized') {
                  finalOptimizedData = payload;
                  setState(() => _isAiSessionActive = false); 
                }

                setState(() {
                  final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                  if (idx != -1) {
                    _messages[idx]['text'] = accumulatedText + " ...";
                  }
                });
                _scrollToBottom();
              }
              else if (type == 'vote_created') {
                accumulatedText = payload['content'] ?? '';
                setState(() {
                  final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                  if (idx != -1) {
                    _messages[idx]['text'] = accumulatedText + " ...";
                  }
                });
                _scrollToBottom();
              }
              else if (type == 'error') {
                accumulatedText = "🚨 AI 오류 발생: ${payload['message']}";
                setState(() {
                  final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                  if (idx != -1) {
                    _messages[idx]['text'] = accumulatedText;
                  }
                });
              }
            } catch (_) {}
          }
        }

        bool isSocketConnected = (_webSocket != null && _webSocket!.readyState == WebSocket.open);

        if (isSocketConnected) {
          setState(() {
            _messages.removeWhere((m) => m['message_id'] == tempMsgId);
          });

          if (finalOptimizedData != null) {
            final bridgeJson = {
              "tripto_card_type": "optimized",
              "plan_title": finalOptimizedData['plan_title'],
              "itinerary": finalOptimizedData['itinerary'],
              "estimated_cost": finalOptimizedData['estimated_cost'],
              "content": accumulatedText,
            };
            _broadcastBridgeMessage(jsonEncode(bridgeJson));
          } else if (accumulatedText.isNotEmpty) {
            final bridgeJson = {
              "tripto_card_type": "text",
              "content": accumulatedText,
            };
            _broadcastBridgeMessage(jsonEncode(bridgeJson));
          }
        } else {
          setState(() {
            final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
            if (idx != -1) {
              _messages[idx]['message_id'] = DateTime.now().millisecondsSinceEpoch; 
              if (finalOptimizedData != null) {
                _messages[idx]['text'] = jsonEncode({
                  "tripto_card_type": "optimized",
                  "plan_title": finalOptimizedData['plan_title'],
                  "itinerary": finalOptimizedData['itinerary'],
                  "estimated_cost": finalOptimizedData['estimated_cost'],
                  "content": accumulatedText,
                });
              } else {
                _messages[idx]['text'] = jsonEncode({
                  "tripto_card_type": "text",
                  "content": accumulatedText,
                });
              }
            }
          });
        }
      } else {
        setState(() {
          final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
          if (idx != -1) {
            _messages[idx]['text'] = "🚨 에러가 발생하여 일정을 불러오지 못했습니다. (${response.statusCode})";
          }
        });
      }
    } catch (e) {
      debugPrint('AI 에이전트 스트림 장애: $e');
      setState(() {
        final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
        if (idx != -1) {
          _messages[idx]['text'] = "🚨 네트워크 연결 장애로 AI 답변 수신에 실패했습니다.";
        }
      });
    } finally {
      setState(() {
        _isAiStreaming = false;
        _currentAiStatus = null;
      });
    }
  }

  void _broadcastBridgeMessage(String textContent) {
    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      _webSocket!.add(jsonEncode({
        "action": "send_message",
        "content": textContent,
      }));
    }
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    final String originalText = _msgController.text.trim();
    _msgController.clear();

    final Map<String, dynamic> socketRequestPayload = {"action": "send_message", "content": originalText};
    _webSocket?.add(jsonEncode(socketRequestPayload));
    
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

    final bool isAiCall = originalText.startsWith('@tripto') || originalText.startsWith('@트립토') || _isAiSessionActive;
    final bool isVoteTrigger = _isInternalVoteWord(originalText);

    if (isAiCall || isVoteTrigger) {
      setState(() => _isAiSessionActive = true); 
      
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
    if (msgId == null) return 0;

    int unreadPeople = 0;
    for (var memberId in _allRoomMembers) {
      if (memberId == senderId) continue; 
      if (memberId == _myUserId) continue; 
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
          if (_isAiSessionActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: const Color(0xFFFAF5FF),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: Color(0xFF524582)),
                  SizedBox(width: 8),
                  Text(
                    "🤖 tripto 설계 세션 활성화 중",
                    style: TextStyle(fontSize: 11, color: Color(0xFF524582), fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                  ),
                ],
              ),
            ),
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF524582), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    label: const Text("네, 투표방을 개설합니다", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() => _showVoteConfirmButtons = false);
                      _fireAiAgentStream("네"); 
                    },
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.grey, size: 18),
                    label: const Text("아니오, 취소", style: TextStyle(color: Colors.grey)),
                    onPressed: () {
                      setState(() => _showVoteConfirmButtons = false);
                      _fireAiAgentStream("취소"); 
                    },
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
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Pretendard'),
                  decoration: const InputDecoration(hintText: '메세지를 입력하세요... (AI 소환은 @tripto / @트립토)', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 11)),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(onTap: _sendMessage, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF524582), shape: BoxShape.circle), child: const Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.white))),
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
    final String userRealName = isAi ? 'tripto' : (_userNamesMap[senderId] ?? '유저 $senderId');
    final String initialLetter = isAi ? '🤖' : (userRealName.isNotEmpty ? userRealName.substring(0, 1) : '유');

    bool isOptimizedCard = false;
    bool isAiText = false;
    Map<String, dynamic>? cardData;
    String displayAiText = rawText;

    if (rawText.startsWith('{"tripto_card_type"')) {
      try {
        final parsed = jsonDecode(rawText);
        final String cardType = parsed['tripto_card_type'] ?? '';
        if (cardType == 'optimized') {
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
              child: Text(userRealName, style: TextStyle(color: isAi ? const Color(0xFF524582) : const Color(0xFF64748B), fontSize: 12, fontFamily: 'Pretendard', fontWeight: FontWeight.bold)),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 18, 
                  backgroundColor: isAi ? const Color(0xFFF5F3FF) : const Color(0x26524582), 
                  child: isAi 
                    ? const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF524582))
                    : Text(initialLetter, style: const TextStyle(color: Color(0xFF524582), fontSize: 12, fontWeight: FontWeight.bold)),
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

  /// ── 🪙 [복원 완료]: 텍스트 훼손 없이 AI가 작성해 준 줄글 괄호 내역을 100% 온전히 추출하는 순수 파서 ──
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
            detail: detail.isNotEmpty ? "($detail)" : "", // 💡 괄호 내부 멘트 완벽 복원 보장
            icon: Icons.directions_car_filled_rounded,
            color: const Color(0xFF367BC3), // #367BC3 오션 블루
            isTransit: true,
          ));
        } else {
          items.add(ParsedTimelineItem(
            time: "경로",
            title: trimmed,
            detail: "",
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFF367BC3), // #367BC3 오션 블루
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
        Color color = const Color(0xFF524582); // #524582 퍼플

        final lowerTitle = title.toLowerCase();
        if (lowerTitle.contains('식사') || lowerTitle.contains('맛집') || lowerTitle.contains('점심') || lowerTitle.contains('저녁') || lowerTitle.contains('식당') || lowerTitle.contains('브런치') ||
            lowerTitle.contains('카페') || lowerTitle.contains('커피') || lowerTitle.contains('디저트')) {
          icon = lowerTitle.contains('카페') || lowerTitle.contains('커피') ? Icons.local_cafe_rounded : Icons.restaurant_rounded;
          color = const Color(0xFF38BFA7); // #38BFA7 청량 민트
        } else if (lowerTitle.contains('호텔') || lowerTitle.contains('숙소') || lowerTitle.contains('체크인') || lowerTitle.contains('체크아웃') || lowerTitle.contains('펜션') || lowerTitle.contains('민박')) {
          icon = Icons.hotel_rounded;
          color = const Color(0xFF8FE1A2); // #8FE1A2 연그린
        }

        items.add(ParsedTimelineItem(
          time: time,
          title: title,
          detail: detail.isNotEmpty ? "($detail)" : "", // 💡 괄호 내부 멘트 완벽 복원 보장
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
                  
                  // 💡 원본 멘트(비용 및 시각 조건문 포함)가 타임라인 바로 밑에 예쁘고 온전하게 배치됩니다.
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