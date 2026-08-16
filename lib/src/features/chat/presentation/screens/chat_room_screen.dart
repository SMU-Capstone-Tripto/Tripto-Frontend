import 'dart:async'; 
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http; 
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripto/src/core/auth_storage.dart';
import 'chat_room_settings_screen.dart';
import 'vote_tabs_screen.dart';

class LocalDeletionStorage {
  static Set<String> _deletedMsgIds = {};
  static Map<String, String> _roomLastMsgOverrides = {};

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deletedMsgIds = (prefs.getStringList('tripto_deleted_msg_ids') ?? []).toSet();
      
      final overrideJson = prefs.getString('tripto_room_last_msg_overrides');
      if (overrideJson != null && overrideJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(overrideJson);
        _roomLastMsgOverrides = decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (e) {
      debugPrint('LocalDeletionStorage init error: $e');
    }
  }

  static Future<void> addDeletedMsgId(int msgId) async {
    if (msgId <= 0) return;
    _deletedMsgIds.add(msgId.toString());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('tripto_deleted_msg_ids', _deletedMsgIds.toList());
    } catch (_) {}
  }

  static bool isDeleted(int msgId) {
    return _deletedMsgIds.contains(msgId.toString());
  }

  static Future<void> setRoomLastMessage(int roomId, String lastMsgText) async {
    _roomLastMsgOverrides[roomId.toString()] = lastMsgText;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tripto_room_last_msg_overrides', jsonEncode(_roomLastMsgOverrides));
    } catch (_) {}
  }

  static String? getRoomLastMessage(int roomId) {
    return _roomLastMsgOverrides[roomId.toString()];
  }

  static bool hasOverride(int roomId) {
    return _roomLastMsgOverrides.containsKey(roomId.toString());
  }
}

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
  final ImagePicker _picker = ImagePicker();

  WebSocket? _webSocket; 
  StreamSubscription? _wsSubscription;
  Timer? _aiTimeoutTimer;
  bool _isHistoryLoading = true; 
  
  int _myUserId = 0; 

  final Map<int, int> _userLastReadMap = {}; 
  final Set<int> _allRoomMembers = {}; 
  final Map<int, String> _userNamesMap = {}; 
  final Map<int, String?> _userProfileImagesMap = {};

  String? _currentAiStatus; 
  bool _showVoteConfirmButtons = false; 
  int? _roomOwnerId; 

  Map<String, dynamic>? _replyingMessage;

  bool _isSelectionMode = false;
  final Set<int> _selectedMsgIndices = {};

  Offset _tapPosition = Offset.zero;

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

  @override
  void dispose() {
    _aiTimeoutTimer?.cancel();
    _wsSubscription?.cancel(); 
    _webSocket?.close(); 
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getPureText(String text) {
    String target = text;
    if (text.contains('[REPLY_DATA]')) {
      final parts = text.split('[REPLY_DATA]');
      if (parts.length >= 3) {
        target = parts[2];
      }
    }
    String trimmed = target.trim();
    if (trimmed.startsWith('http') && (trimmed.contains('.jpg') || trimmed.contains('.png') || trimmed.contains('.jpeg') || trimmed.contains('s3.amazonaws') || trimmed.contains('presigned'))) {
      return '사진';
    }
    if (trimmed.startsWith('{"tripto_card_type"') || trimmed.contains('"itinerary"')) {
      return '[여행 일정표 카드]';
    }
    return trimmed;
  }

  String _formatTime(dynamic rawTime) {
    if (rawTime == null) {
      final now = DateTime.now();
      int h = now.hour % 12;
      if (h == 0) h = 12;
      return '${now.hour >= 12 ? "오후" : "오전"} $h:${now.minute.toString().padLeft(2, '0')}';
    }

    String str = rawTime.toString().trim();
    if (str.isEmpty) {
      final now = DateTime.now();
      int h = now.hour % 12;
      if (h == 0) h = 12;
      return '${now.hour >= 12 ? "오후" : "오전"} $h:${now.minute.toString().padLeft(2, '0')}';
    }

    if (str.startsWith('오전') || str.startsWith('오후')) {
      return str;
    }

    DateTime? parsed;
    try {
      if (!str.contains('Z') && !str.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(str)) {
        parsed = DateTime.tryParse(str);
      } else {
        parsed = DateTime.tryParse(str)?.toLocal();
      }
    } catch (_) {}

    parsed ??= DateTime.now();

    int h = parsed.hour % 12;
    if (h == 0) h = 12;
    String period = parsed.hour >= 12 ? "오후" : "오전";
    String minuteStr = parsed.minute.toString().padLeft(2, '0');

    return '$period $h:$minuteStr';
  }

  Future<void> _initializeChatRoom() async {
    await LocalDeletionStorage.init();
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
        if (mounted) {
          setState(() {
            _myUserId = int.tryParse(userData['id']?.toString() ?? userData['user_id']?.toString() ?? '0') ?? 0;
            if (_myUserId > 0) {
              _allRoomMembers.add(_myUserId);
              _userNamesMap[_myUserId] = userData['nickname']?.toString() ?? userData['name']?.toString() ?? userData['username']?.toString() ?? '나';
              
              final String? myProfileImg = userData['profile_image']?.toString() ?? userData['profile_img']?.toString();
              if (myProfileImg != null && myProfileImg.isNotEmpty) {
                _userProfileImagesMap[_myUserId] = myProfileImg;
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('내 프로필 ID 획득 예외: $e');
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

        if (currentRoom != null && currentRoom is Map && mounted) {
          final int? owner = int.tryParse(currentRoom['owner_id']?.toString() ?? '');
          if (owner != null) {
            setState(() => _roomOwnerId = owner); 
          }

          final List<dynamic>? memberIds = currentRoom['member_ids'] ?? currentRoom['invited_user_ids'];
          if (memberIds != null) {
            setState(() {
              _allRoomMembers.clear();
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
      debugPrint('방 정보 동기화 패스: $e');
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
        } else if (responseData is List) {
          historyList = responseData;
        }

        List<Map<String, dynamic>> parsedHistory = [];
        int highestOpponentMsgId = 0;

        for (var item in historyList) {
          if (item == null) continue;
          final Map<String, dynamic> msgMap = Map<String, dynamic>.from(item);
          final int msgId = int.tryParse(msgMap['message_id']?.toString() ?? '0') ?? 0;
          
          if (msgId > 0 && LocalDeletionStorage.isDeleted(msgId)) {
            continue;
          }

          final int senderId = int.tryParse(msgMap['sender_id']?.toString() ?? '0') ?? 0;
          String content = msgMap['content']?.toString() ?? '';
          final String msgType = msgMap['message_type']?.toString() ?? 'text';
          final String? senderImg = msgMap['sender_profile_image']?.toString() ?? msgMap['profile_image']?.toString();
          final String? senderNick = msgMap['sender_nickname']?.toString() ?? msgMap['nickname']?.toString();

          if (senderId > 0) {
            if (senderNick != null && senderNick.isNotEmpty) {
              _userNamesMap[senderId] = senderNick;
            }
            if (senderImg != null && senderImg.isNotEmpty) {
              _userProfileImagesMap[senderId] = senderImg;
            }
          }

          String trimmedContent = content.trim();
          if (trimmedContent.startsWith('```json')) {
            trimmedContent = trimmedContent.replaceAll('```json', '').replaceAll('```', '').trim();
          } else if (trimmedContent.startsWith('```')) {
            trimmedContent = trimmedContent.replaceAll('```', '').trim();
          }

          // DB에 저장된 과거 메시지에서 투표/확정 카드 복원
          if (trimmedContent.startsWith('{') && trimmedContent.endsWith('}')) {
            try {
              final jsonParsed = jsonDecode(trimmedContent);
              if (jsonParsed is Map<String, dynamic>) {
                final String cardType = jsonParsed['tripto_card_type'] ?? jsonParsed['step'] ?? jsonParsed['type'] ?? '';
                if (cardType == 'optimized' || jsonParsed['itinerary'] != null) {
                  trimmedContent = jsonEncode({
                    "tripto_card_type": "optimized",
                    "plan_title": jsonParsed['plan_title'] ?? jsonParsed['title'] ?? widget.title,
                    "itinerary": jsonParsed['itinerary'] ?? [],
                    "estimated_cost": jsonParsed['estimated_cost'] ?? {},
                    "content": "",
                  });
                } else if (cardType == 'vote_created' || jsonParsed['vote_id'] != null) {
                  trimmedContent = jsonEncode({
                    "tripto_card_type": "vote_created",
                    "title": "여행 일정 투표가 개설되었습니다",
                    "content": "채팅방 멤버들과 함께할 투표가 생성되었습니다.\n아래 버튼을 눌러 마음에 드는 일정에 투표해 보세요!"
                  });
                } else if (cardType == 'vote_finalized') {
                  trimmedContent = jsonEncode({
                    "tripto_card_type": "vote_finalized",
                    "title": "여행 일정이 최종 확정되었습니다!",
                    "content": "홈 화면의 [일정] 탭에서 확인해 보세요."
                  });
                }
              }
            } catch (_) {}
          }

          if (trimmedContent.contains('투표가 개설되었습니다') || trimmedContent.contains('투표가 생성되었습니다')) {
            trimmedContent = jsonEncode({
              "tripto_card_type": "vote_created",
              "title": "여행 일정 투표가 개설되었습니다",
              "content": "채팅방 멤버들과 함께할 투표가 생성되었습니다.\n아래 버튼을 눌러 마음에 드는 일정에 투표해 보세요!"
            });
          } else if (trimmedContent.contains('여행 일정이 최종 확정되었습니다')) {
            trimmedContent = jsonEncode({
              "tripto_card_type": "vote_finalized",
              "title": "여행 일정이 최종 확정되었습니다!",
              "content": "홈 화면의 [일정] 탭에서 확인해 보세요."
            });
          }

          final String step = msgMap['step']?.toString() ?? '';
          final dynamic itinerary = msgMap['itinerary'];

          if (step == 'optimized' || itinerary != null) {
            trimmedContent = jsonEncode({
              "tripto_card_type": "optimized",
              "plan_title": msgMap['plan_title'] ?? widget.title,
              "itinerary": itinerary ?? [],
              "estimated_cost": msgMap['estimated_cost'] ?? {},
              "content": "",
            });
          }

          if (trimmedContent.isEmpty) continue;

          final bool isAiMessageInHistory = (senderId == -1) || 
                                      step == 'optimized' ||
                                      step == 'vote_created' ||
                                      itinerary != null ||
                                      trimmedContent.contains('"tripto_card_type"') || 
                                      trimmedContent.contains('"itinerary"') || 
                                      trimmedContent.contains('"plan_title"') ||
                                      trimmedContent.contains('vote_created') ||
                                      trimmedContent.contains('vote_finalized');

          int mappedSenderId = isAiMessageInHistory ? -1 : senderId;
          bool mappedIsMe = (senderId == _myUserId && !isAiMessageInHistory);

          final String timeStr = _formatTime(msgMap['created_at']);
          if (senderId != _myUserId && msgId > highestOpponentMsgId) {
            highestOpponentMsgId = msgId;
          }

          parsedHistory.add(<String, dynamic>{
            'message_id': msgId,
            'sender_id': mappedSenderId,
            'isMe': mappedIsMe, 
            'text': trimmedContent,
            'message_type': msgType,
            'time': timeStr,
          });
        }

        if (mounted) {
          setState(() {
            _messages.clear(); 
            _messages.addAll(parsedHistory);
          });
          _scrollToBottom();
        }

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
      debugPrint('🟢 웹소켓 연결 성공: $fullWsPath');
      
      _wsSubscription = _webSocket?.listen(
        (rawData) {
          debugPrint('📩 [웹소켓 수신]: $rawData');
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
      
      if (type == 'status' || type == 'bot_status') {
        final String statusMsg = payload['message']?.toString() ?? payload['content']?.toString() ?? 'AI 분석 중...';
        if (mounted) {
          setState(() {
            _currentAiStatus = statusMsg;
          });
        }
        return;
      }

      if (type == 'bot_error' || type == 'error') {
        _aiTimeoutTimer?.cancel();
        final String errContent = payload['content']?.toString() ?? payload['message']?.toString() ?? '에이전트 처리 중 문제가 발생했습니다.';
        if (mounted) {
          setState(() {
            _currentAiStatus = null;
            _messages.add({
              'message_id': null,
              'sender_id': -1,
              'isMe': false,
              'text': errContent,
              'message_type': 'text',
              'time': _formatTime(DateTime.now()),
            });
          });
          _scrollToBottom();
        }
        return;
      }

      final int senderId = int.tryParse(payload['sender_id']?.toString() ?? '0') ?? 0;
      final String content = payload['content']?.toString() ?? payload['message']?.toString() ?? '';
      final int msgId = int.tryParse(payload['message_id']?.toString() ?? '0') ?? 0;
      final String step = payload['step']?.toString() ?? payload['type']?.toString() ?? '';
      final String msgType = payload['message_type']?.toString() ?? 'text';

      if (type == 'read_update') {
        final int readingUserId = int.tryParse(payload['user_id']?.toString() ?? '0') ?? 0;
        final int lastReadId = int.tryParse(payload['last_read_message_id']?.toString() ?? '0') ?? 0;
        if (mounted && readingUserId > 0 && lastReadId > 0) {
          setState(() {
            _userLastReadMap[readingUserId] = lastReadId;
            _allRoomMembers.add(readingUserId);
          });
        }
        return;
      }

      if (type == 'delete_message' || type == 'unsend_message') {
        final int deletedMsgId = int.tryParse(payload['message_id']?.toString() ?? '0') ?? 0;
        if (mounted && deletedMsgId > 0) {
          setState(() {
            _messages.removeWhere((m) => m['message_id'] == deletedMsgId);
            _updateLastMsgOverrideAfterDeletion();
          });
        }
        return;
      }

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

      bool isAi = (senderId == -1) || 
                  type == 'result' || 
                  type == 'vote_created' || 
                  step == 'vote_created' || 
                  step == 'optimized' || 
                  content.contains('"tripto_card_type"') || 
                  content.contains('"itinerary"') ||
                  content.contains('투표가 생성되었습니다') ||
                  content.contains('투표가 개설되었습니다') ||
                  content.contains('여행 일정이 최종 확정되었습니다');

      int mappedSenderId = isAi ? -1 : senderId;
      String formattedText = content;

      if (step == 'optimized' || payload['itinerary'] != null) {
        formattedText = jsonEncode({
          "tripto_card_type": "optimized",
          "plan_title": payload['plan_title'] ?? widget.title,
          "itinerary": payload['itinerary'] ?? [],
          "estimated_cost": payload['estimated_cost'] ?? {},
          "content": "",
        });
      } else if (step == 'vote_confirm') {
        if (mounted) setState(() => _showVoteConfirmButtons = true);
      } else if (step == 'vote_created' || type == 'vote_created' || content.contains('투표가 생성되었습니다') || content.contains('투표가 개설되었습니다') || content.contains('투표를 시작')) {
        formattedText = jsonEncode({
          "tripto_card_type": "vote_created",
          "title": "여행 일정 투표가 개설되었습니다",
          "content": "채팅방 멤버들과 함께할 투표가 생성되었습니다.\n아래 버튼을 눌러 마음에 드는 일정에 투표해 보세요!"
        });
      } else if (content.contains('여행 일정이 최종 확정되었습니다')) {
        formattedText = jsonEncode({
          "tripto_card_type": "vote_finalized",
          "title": "여행 일정이 최종 확정되었습니다!",
          "content": "홈 화면의 [일정] 탭에서 확인해 보세요."
        });
      } else if (step == 'vote_denied') {
        formattedText = "투표 개설은 방장만 진행할 수 있습니다.";
      } else if (step == 'vote_cancelled') {
        formattedText = "투표 개설 요청이 취소되었습니다.";
      }

      final String timeStr = _formatTime(payload['created_at']);

      if (mounted) {
        setState(() {
          if (isAi) {
            _aiTimeoutTimer?.cancel();
            _currentAiStatus = null;
          }

          if (mappedSenderId == _myUserId) {
            final int pendingIdx = _messages.indexWhere((m) {
              if (m['sender_id'] != _myUserId) return false;
              final bool isPendingId = (m['message_id'] == null || m['message_id'] == -888);
              final bool sameText = (m['text'] == content || m['text'] == formattedText);
              final bool sameType = (m['message_type'] == msgType || (msgType == 'image' && m['message_type'] == 'local_image'));
              return (isPendingId && (sameText || sameType)) || sameText;
            });

            if (pendingIdx != -1) {
              _messages[pendingIdx]['message_id'] = msgId > 0 ? msgId : null;
              _messages[pendingIdx]['text'] = formattedText;
              _messages[pendingIdx]['message_type'] = msgType;
              _messages[pendingIdx]['time'] = timeStr;
              
              LocalDeletionStorage.setRoomLastMessage(widget.roomId, formattedText);
              return;
            }
          }

          _messages.add(<String, dynamic>{
            'message_id': msgId > 0 ? msgId : null,
            'sender_id': mappedSenderId,
            'isMe': (mappedSenderId == _myUserId), 
            'text': formattedText,
            'message_type': msgType,
            'time': timeStr,
          });

          LocalDeletionStorage.setRoomLastMessage(widget.roomId, formattedText);
        });

        _scrollToBottom();

        if (senderId != _myUserId && msgId > 0) {
          _sendReadAcknowledge(msgId);
        }
      }
    } catch (e) {
      debugPrint('소켓 파싱 에러: $e');
    }
  }

  void _sendReadAcknowledge(int messageId) {
    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      final Map<String, dynamic> readPayload = {"action": "read_message", "message_id": messageId};
      _webSocket!.add(jsonEncode(readPayload));
    }
  }

  Future<void> _handleVoteConfirmResponse(bool isApprove) async {
    final String socketTriggerText = isApprove ? "@트립토 네" : "@트립토 취소";

    setState(() {
      _showVoteConfirmButtons = false;
      _currentAiStatus = isApprove ? "AI가 투표 개설 처리 중..." : "AI가 요청 취소 처리 중...";
    });

    _aiTimeoutTimer?.cancel();
    _aiTimeoutTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _currentAiStatus != null) {
        setState(() {
          _currentAiStatus = null;
          if (isApprove) {
            _messages.add({
              'message_id': null,
              'sender_id': -1,
              'isMe': false,
              'text': jsonEncode({
                "tripto_card_type": "vote_created",
                "title": "여행 일정 투표가 개설되었습니다",
                "content": "채팅방 멤버들과 함께할 투표가 생성되었습니다.\n아래 버튼을 눌러 마음에 드는 일정에 투표해 보세요!"
              }),
              'message_type': 'text',
              'time': _formatTime(DateTime.now()),
            });
          }
        });
        _scrollToBottom();
      }
    });

    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      _webSocket!.add(jsonEncode({
        "action": "send_message",
        "content": socketTriggerText,
      }));
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;
      final File imageFile = File(pickedFile.path);

      final bool? confirmSend = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('사진 전송 확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: Image.file(imageFile, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              const Text('선택한 사진을 채팅방에 전송하시겠습니까?', style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontFamily: 'Pretendard')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소', style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF524582),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('전송', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
            ),
          ],
        ),
      );

      if (confirmSend != true) return;
      final String tempTimeStr = _formatTime(DateTime.now());

      setState(() {
        _messages.add({
          'message_id': -888, 
          'sender_id': _myUserId,
          'isMe': true,
          'text': imageFile.path,
          'message_type': 'local_image',
          'time': tempTimeStr,
        });
      });
      _scrollToBottom();

      final List<int> imageBytes = await imageFile.readAsBytes();

      final presignedRes = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/uploads/presigned-url'),
        headers: AuthStorage.authHeaders,
        body: jsonEncode({"content_type": "image/jpeg", "category": "chat"}),
      );

      if (presignedRes.statusCode != 200) throw Exception('Presigned URL 발급 실패');

      final presignedData = jsonDecode(utf8.decode(presignedRes.bodyBytes));
      final String uploadUrl = presignedData['upload_url'];
      final String fileUrl = presignedData['file_url'];

      final uploadRes = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: imageBytes,
      );

      if (uploadRes.statusCode != 200 && uploadRes.statusCode != 204) throw Exception('S3 사진 업로드 실패');

      final sendImageRes = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/chat/${widget.roomId}/image'),
        headers: AuthStorage.authHeaders,
        body: jsonEncode({"image_url": fileUrl}),
      );

      if (sendImageRes.statusCode == 200 || sendImageRes.statusCode == 201) {
        if (mounted) {
          setState(() {
            final int idx = _messages.indexWhere((m) => m['message_id'] == -888);
            if (idx != -1) {
              _messages[idx] = {
                'message_id': null,
                'sender_id': _myUserId,
                'isMe': true,
                'text': fileUrl,
                'message_type': 'image',
                'time': tempTimeStr,
              };
            }
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('사진 전송 프로세스 에러: $e');
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['message_id'] == -888);
        });
      }
    }
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;

    final bool isWsConnected = (_webSocket != null && _webSocket!.readyState == WebSocket.open);
    if (!isWsConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 연결이 끊어져 메시지를 전송할 수 없습니다.')),
      );
      return;
    }

    String inputText = _msgController.text.trim();
    _msgController.clear();

    final Map<String, dynamic> socketRequestPayload = {
      "action": "send_message",
      "content": inputText,
    };
    _webSocket!.add(jsonEncode(socketRequestPayload));
    
    final String timeStr = _formatTime(DateTime.now());

    setState(() {
      _messages.add(<String, dynamic>{
        'message_id': null, 
        'sender_id': _myUserId,
        'isMe': true,
        'text': inputText,
        'message_type': 'text',
        'time': timeStr,
      });
      _allRoomMembers.add(_myUserId); 
      LocalDeletionStorage.setRoomLastMessage(widget.roomId, inputText);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _updateLastMsgOverrideAfterDeletion() {
    if (_messages.isEmpty) {
      LocalDeletionStorage.setRoomLastMessage(widget.roomId, '');
    } else {
      LocalDeletionStorage.setRoomLastMessage(widget.roomId, _messages.last['text'] ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isHistoryLoading || _myUserId == 0) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF524582))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(63),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))]),
          child: AppBar(
            backgroundColor: Colors.transparent, elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E2939), size: 20), 
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(widget.title, style: const TextStyle(color: Color(0xFF1E2939), fontSize: 18, fontFamily: 'Pretendard', fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.how_to_vote_rounded, color: Color(0xFF524582), size: 22),
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const VoteTabsScreen()),
                  ).then((result) {
                    if (result == true) {
                      final String confirmText = jsonEncode({
                        "tripto_card_type": "vote_finalized",
                        "title": "여행 일정이 최종 확정되었습니다!",
                        "content": "홈 화면의 [일정] 탭에서 확인해 보세요."
                      });

                      if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
                        _webSocket!.add(jsonEncode({
                          "action": "send_message",
                          "content": confirmText,
                        }));
                      }

                      setState(() {
                        _messages.add({
                          'message_id': null,
                          'sender_id': -1,
                          'isMe': false,
                          'text': confirmText,
                          'message_type': 'text',
                          'time': _formatTime(DateTime.now()),
                        });
                      });
                      _scrollToBottom();
                    }
                    _fetchRoomRealMembersAndNicknames();
                    _fetchChatHistory();
                  });
                },
              ),
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
                ).then((_) {
                  _fetchRoomRealMembersAndNicknames();
                  _fetchChatHistory();
                }),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
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
                    "이 일정으로 투표방 개설을 승인할까요?",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Pretendard'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF524582), 
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: const Text("네, 시작해 주세요", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pretendard', fontSize: 13)),
                        onPressed: () => _handleVoteConfirmResponse(true),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: const Text("아니오", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontFamily: 'Pretendard', fontSize: 13)),
                        onPressed: () => _handleVoteConfirmResponse(false),
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
    final String rawText = msg['text'] ?? '';
    final String msgType = msg['message_type'] ?? 'text';
    final bool isAi = (senderId == -1);

    String rawNick = _userNamesMap[senderId]?.trim() ?? '';
    rawNick = rawNick.replaceAll('<', '').replaceAll('>', '').replaceAll('(', '').replaceAll(')', '').trim();
    String userRealName = isAi ? 'tripto' : (rawNick.isEmpty ? '(알수없음)' : rawNick);
    final String initialLetter = isAi ? 'AI' : (userRealName == '(알수없음)' ? '?' : userRealName.substring(0, 1));
    final String? profileImgUrl = (isAi || userRealName == '(알수없음)') ? null : _userProfileImagesMap[senderId];

    bool isOptimizedCard = false;
    bool isVoteCreatedCard = false;
    bool isVoteFinalizedCard = false;
    Map<String, dynamic>? cardData;

    final String trimmedText = rawText.trim();
    if (trimmedText.startsWith('{') && trimmedText.endsWith('}')) {
      try {
        final parsed = jsonDecode(trimmedText);
        if (parsed is Map<String, dynamic>) {
          final String cardType = parsed['tripto_card_type'] ?? parsed['step'] ?? parsed['type'] ?? '';
          if (cardType == 'optimized' || parsed['itinerary'] != null) {
            cardData = parsed;
            isOptimizedCard = true;
          } else if (cardType == 'vote_created' || parsed['vote_id'] != null) {
            cardData = parsed;
            isVoteCreatedCard = true;
          } else if (cardType == 'vote_finalized') {
            cardData = parsed;
            isVoteFinalizedCard = true;
          }
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 상대방/AI 프로필 영역
          if (!isMe) ...[
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF5F3FF),
              ),
              alignment: Alignment.center,
              child: isAi
                  ? const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF524582))
                  : (profileImgUrl != null && profileImgUrl.isNotEmpty)
                      ? ClipOval(child: Image.network(profileImgUrl, width: 36, height: 36, fit: BoxFit.cover))
                      : Text(initialLetter, style: const TextStyle(color: Color(0xFF524582), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],

          if (isMe) ...[
            Text(msg['time'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Pretendard')),
            const SizedBox(width: 6),
          ],

          // 💡 [핵심 해결]: Flexible로 감싸 아바타와 시간 사이 남은 공간에 정확히 맞춤
          Flexible(
            child: isVoteCreatedCard && cardData != null
                ? _buildAiVoteCard(cardData)
                : isVoteFinalizedCard && cardData != null
                    ? _buildAiFinalizedCard(cardData)
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF524582) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          rawText,
                          style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1E2939), fontSize: 13.5, fontFamily: 'Pretendard', height: 1.4),
                        ),
                      ),
          ),

          if (!isMe) ...[
            const SizedBox(width: 6),
            Text(msg['time'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'Pretendard')),
          ],
        ],
      ),
    );
  }

  // 💡 오버플로우 없는 투표 개설 안내 카드
  Widget _buildAiVoteCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF524582), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF524582),
            child: const Row(
              children: [
                Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 15),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '여행 일정 투표가 개설되었습니다',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5, fontFamily: 'Pretendard'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              data['content'] ?? '채팅방 멤버들과 함께할 투표가 생성되었습니다.\n아래 버튼을 눌러 투표에 참여해 보세요.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4, fontFamily: 'Pretendard'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF524582),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VoteTabsScreen()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '투표 탭 바로가기',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pretendard'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 일정 최종 확정 안내 카드
  Widget _buildAiFinalizedCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF524582), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF524582),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 15),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '여행 일정이 최종 확정되었습니다!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5, fontFamily: 'Pretendard'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              data['content'] ?? '홈 화면의 [일정] 탭에서 확인해 보세요.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4, fontFamily: 'Pretendard'),
            ),
          ),
        ],
      ),
    );
  }
}