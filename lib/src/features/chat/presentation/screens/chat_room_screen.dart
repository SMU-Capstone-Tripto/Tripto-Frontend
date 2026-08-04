import 'dart:async'; 
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http; 
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
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
  final ImagePicker _picker = ImagePicker();
  
  WebSocket? _webSocket; 
  StreamSubscription? _wsSubscription;
  bool _isHistoryLoading = true; 
  
  int _myUserId = 0; 

  final Map<int, int> _userLastReadMap = {}; 
  final Set<int> _allRoomMembers = {}; 
  final Map<int, String> _userNamesMap = {}; 
  final Map<int, String?> _userProfileImagesMap = {};

  String? _currentAiStatus; 
  bool _showVoteConfirmButtons = false; 
  bool _isAiStreaming = false;
  int? _roomOwnerId; 

  Map<String, dynamic>? _replyingMessage;
  String? _noticeMessage;

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
    _wsSubscription?.cancel(); 
    _webSocket?.close(); 
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      } else {
        debugPrint('내 프로필 실패 응답: ${response.statusCode}');
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
          final String msgType = msgMap['message_type']?.toString() ?? 'text';
          final String? senderImg = msgMap['sender_profile_image']?.toString() ?? msgMap['profile_image']?.toString();
          
          if (content.trim().isEmpty) continue;
          if (senderId > 0) {
            _allRoomMembers.add(senderId);
            if (senderImg != null && senderImg.isNotEmpty) {
              _userProfileImagesMap[senderId] = senderImg;
            }
          }

          bool isAiMessageInHistory = (senderId == -1) || content.startsWith('{"tripto_card_type"');
          int mappedSenderId = senderId;
          bool mappedIsMe = (senderId == _myUserId);

          if (isAiMessageInHistory) {
            mappedSenderId = -1; 
            mappedIsMe = false;
          }

          final String timeStr = _formatTime(msgMap['created_at']);

          if (senderId != _myUserId && msgId > highestOpponentMsgId) {
            highestOpponentMsgId = msgId;
          }

          parsedHistory.add(<String, dynamic>{
            'message_id': msgId,
            'sender_id': mappedSenderId,
            'isMe': mappedIsMe, 
            'text': content,
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
      debugPrint('🟢 웹소켓 링크 연결 성공: $fullWsPath');
      
      _wsSubscription = _webSocket?.listen(
        (rawData) {
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
      
      if (type == 'bot_status') {
        final String statusMsg = payload['content']?.toString() ?? 'AI 분석 중...';
        if (mounted) {
          setState(() {
            _currentAiStatus = statusMsg;
          });
        }
        return;
      }

      if (type == 'new_message') {
        final int senderId = int.tryParse(payload['sender_id']?.toString() ?? '0') ?? 0;
        final String content = payload['content']?.toString() ?? '';
        final int msgId = int.tryParse(payload['message_id']?.toString() ?? '0') ?? 0;
        final String step = payload['step']?.toString() ?? '';
        final String msgType = payload['message_type']?.toString() ?? 'text';

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

        bool isAi = (senderId == -1) || content.startsWith('{"tripto_card_type"');
        int mappedSenderId = isAi ? -1 : senderId;

        String formattedText = content;
        if (step == 'optimized' || payload['itinerary'] != null) {
          formattedText = jsonEncode({
            "tripto_card_type": "optimized",
            "plan_title": payload['plan_title'] ?? widget.title,
            "itinerary": payload['itinerary'] ?? [],
            "estimated_cost": payload['estimated_cost'] ?? {},
            "content": content,
          });
        } else if (step == 'vote_confirm') {
          if (mounted) setState(() => _showVoteConfirmButtons = true);
        }

        final String timeStr = _formatTime(payload['created_at']);

        if (mounted) {
          setState(() {
            _currentAiStatus = null;

            if (mappedSenderId == _myUserId) {
              final int pendingIdx = _messages.indexWhere(
                (m) => m['sender_id'] == _myUserId && (m['message_id'] == null || m['message_id'] == -888 || m['message_id'] == -999) && (m['text'] == content || m['message_type'] == msgType)
              );
              if (pendingIdx != -1) {
                _messages[pendingIdx]['message_id'] = msgId > 0 ? msgId : null;
                _messages[pendingIdx]['text'] = formattedText;
                _messages[pendingIdx]['message_type'] = msgType;
                _messages[pendingIdx]['time'] = timeStr;
                return;
              }
            }

            if (mappedSenderId == -1) {
              final int tempAiIdx = _messages.indexWhere((m) => m['message_id'] == -999);
              if (tempAiIdx != -1) {
                _messages[tempAiIdx]['message_id'] = msgId > 0 ? msgId : null;
                _messages[tempAiIdx]['text'] = formattedText;
                _messages[tempAiIdx]['message_type'] = msgType;
                _messages[tempAiIdx]['time'] = timeStr;
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
          title: const Text(
            '사진 전송 확인',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
          ),
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
              const Text(
                '선택한 사진을 채팅방에 전송하시겠습니까?',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontFamily: 'Pretendard'),
              ),
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
        body: jsonEncode({
          "content_type": "image/jpeg",
          "category": "chat",
        }),
      );

      if (presignedRes.statusCode != 200) {
        throw Exception('Presigned URL 발급 실패 (${presignedRes.statusCode})');
      }

      final presignedData = jsonDecode(utf8.decode(presignedRes.bodyBytes));
      final String uploadUrl = presignedData['upload_url'];
      final String fileUrl = presignedData['file_url'];

      final uploadRes = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: imageBytes,
      );

      if (uploadRes.statusCode != 200 && uploadRes.statusCode != 204) {
        throw Exception('S3 사진 업로드 실패 (${uploadRes.statusCode})');
      }

      final sendImageRes = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/chat/${widget.roomId}/image'),
        headers: AuthStorage.authHeaders,
        body: jsonEncode({
          "image_url": fileUrl,
        }),
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
            } else {
              _messages.add({
                'message_id': null,
                'sender_id': _myUserId,
                'isMe': true,
                'text': fileUrl,
                'message_type': 'image',
                'time': tempTimeStr,
              });
            }
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('❌ 사진 전송 프로세스 에러: $e');
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['message_id'] == -888);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 전송 실패: $e')),
        );
      }
    }
  }

  void _showImageDetailModal(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.92),
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_rounded, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text('이미지를 불러올 수 없습니다.', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Pretendard')),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF524582),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      '다운로드',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
                    ),
                    onPressed: () async {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('사진 저장 중...'), duration: Duration(milliseconds: 1000)),
                        );
                        final res = await http.get(Uri.parse(imageUrl));
                        if (res.statusCode == 200) {
                          final bytes = res.bodyBytes;
                          final tempDir = Directory.systemTemp;
                          final file = File('${tempDir.path}/tripto_${DateTime.now().millisecondsSinceEpoch}.jpg');
                          await file.writeAsBytes(bytes);

                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: 'Tripto 이미지 저장',
                          );
                        }
                      } catch (e) {
                        debugPrint('다운로드 에러: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('사진 저장에 실패했습니다.')),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              '첨부 파일 선택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
                color: Color(0xFF1E2939),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Color(0xFF524582), size: 26),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '사진 전송',
                        style: TextStyle(fontSize: 12, fontFamily: 'Pretendard', fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _fireAiAgentStream(String cleanMessage) async {
    if (_isAiStreaming) return;
    setState(() {
      _isAiStreaming = true;
      _currentAiStatus = "AI 분석 요청 중...";
    });

    final int tempMsgId = -999; 
    final String tempTimeStr = _formatTime(DateTime.now());

    setState(() {
      _messages.add(<String, dynamic>{
        'message_id': tempMsgId,
        'sender_id': -1, 
        'isMe': false,
        'text': "🔍 답변을 생성하고 있습니다...", 
        'message_type': 'text',
        'time': tempTimeStr,
      });
    });
    _scrollToBottom();

    try {
      final client = http.Client();
      final request = http.Request('POST', Uri.parse('${AuthStorage.baseUrl}/agent/chat'));
      request.headers.addAll(AuthStorage.authHeaders);
      request.body = jsonEncode({
        "message": cleanMessage,
        "room_id": widget.roomId, 
      });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('서버 응답 오류 (코드: ${response.statusCode})');
      }

      String accumulatedText = "";
      Map<String, dynamic>? finalOptimizedData;

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
                if (mounted) setState(() => _currentAiStatus = payload['message']);
              } 
              else if (type == 'result') {
                final String step = payload['step'] ?? '';
                accumulatedText = payload['content'] ?? '';

                if (step == 'vote_confirm') {
                  if (mounted) setState(() => _showVoteConfirmButtons = true); 
                } 
                else if (step == 'optimized' || payload['itinerary'] != null) {
                  finalOptimizedData = payload;
                }

                if (mounted) {
                  setState(() {
                    final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                    if (idx != -1) _messages[idx]['text'] = accumulatedText;
                  });
                  _scrollToBottom();
                }
              }
              else if (type == 'error') {
                final String errMsg = payload['message'] ?? payload['content'] ?? '응답 중 오류가 발생했습니다.';
                accumulatedText = "⚠️ $errMsg";
                if (mounted) {
                  setState(() {
                    final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                    if (idx != -1) _messages[idx]['text'] = accumulatedText;
                  });
                }
              }
            } else {
              accumulatedText = dataContent;
              if (mounted) {
                setState(() {
                  final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                  if (idx != -1) _messages[idx]['text'] = accumulatedText;
                });
              }
            }
          } catch (_) {
            accumulatedText = dataContent;
            if (mounted) {
              setState(() {
                final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
                if (idx != -1) _messages[idx]['text'] = accumulatedText;
              });
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
          if (idx != -1) {
            _messages[idx]['message_id'] = DateTime.now().millisecondsSinceEpoch; 
            _messages[idx]['time'] = _formatTime(DateTime.now());
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
    } catch (e) {
      debugPrint('AI 에이전트 장애: $e');
      if (mounted) {
        setState(() {
          final int idx = _messages.indexWhere((m) => m['message_id'] == tempMsgId);
          if (idx != -1) {
            _messages[idx]['text'] = "⚠️ 응답 실패, 다시 시도해 주세요.";
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 응답 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiStreaming = false;
          _currentAiStatus = null;
        });
      }
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

    final bool isWsConnected = (_webSocket != null && _webSocket!.readyState == WebSocket.open);
    if (!isWsConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 연결이 끊어져 메시지를 전송할 수 없습니다.')),
      );
      return;
    }

    String originalText = _msgController.text.trim();

    if (_replyingMessage != null) {
      final String replySnippet = _replyingMessage!['text'].startsWith('{"tripto_card_type"') ? "[여행 일정표]" : _replyingMessage!['text'];
      originalText = "[답장] $replySnippet\n↳ $originalText";
    }

    _msgController.clear();
    setState(() {
      _replyingMessage = null;
    });

    final bool isAiCall = originalText.contains('@tripto') || originalText.contains('@트립토');
    final bool isVoteTrigger = _isInternalVoteWord(originalText);
    final bool shouldTriggerAi = isAiCall || isVoteTrigger;

    final Map<String, dynamic> socketRequestPayload = {
      "action": "send_message",
      "content": originalText,
      "trigger_ai": shouldTriggerAi, 
      "is_ai_call": shouldTriggerAi,
    };
    _webSocket!.add(jsonEncode(socketRequestPayload));
    
    final String timeStr = _formatTime(DateTime.now());

    setState(() {
      _messages.add(<String, dynamic>{
        'message_id': null, 
        'sender_id': _myUserId,
        'isMe': true,
        'text': originalText,
        'message_type': 'text',
        'time': timeStr,
      });
      _allRoomMembers.add(_myUserId); 
    });
    _scrollToBottom();

    // NOTE: 백엔드가 trigger_ai 수신 시 AI 응답을 브로드캐스트하므로 프론트에서의 _fireAiAgentStream 중복 호출은 제거되었습니다.
  }

  bool _isInternalVoteWord(String text) {
    final triggers = ["투표할게", "투표 시작", "투표하자", "투표 만들어", "투표할래", "투표 해줘", "이제 투표", "투표 시작해", "투표 열어", "투표 개설"];
    return triggers.any((t) => text.contains(t));
  }

  int _calculateUnreadCount(Map<String, dynamic> msg) {
    final int? msgId = msg['message_id'];
    final int senderId = msg['sender_id'] ?? 0;

    if (senderId == _myUserId && (msgId == null || msgId <= 0)) {
      int count = 0;
      for (var memberId in _allRoomMembers) {
        if (memberId == _myUserId || memberId == -1) continue;
        count++;
      }
      return count;
    }

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
  Widget build(BuildContext context) {
    if (_isHistoryLoading || _myUserId == 0) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, 
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E2939), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF524582)),
        ),
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
          if (_noticeMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const Icon(Icons.push_pin_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '공지: $_noticeMessage',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E), fontFamily: 'Pretendard'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _noticeMessage = null),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF92400E)),
                  ),
                ],
              ),
            ),

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
                          if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
                            _webSocket!.add(jsonEncode({
                              "action": "send_message", 
                              "content": "@트립토 네",
                              "trigger_ai": true,
                              "is_ai_call": true,
                            }));
                          }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(left: BorderSide(color: Color(0xFF524582), width: 3.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('답장하는 메시지', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF524582), fontFamily: 'Pretendard')),
                          const SizedBox(height: 2),
                          Text(
                            _replyingMessage!['text'],
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontFamily: 'Pretendard'),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _replyingMessage = null),
                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                GestureDetector(
                  onTap: _showAddAttachmentMenu,
                  child: Container(
                    padding: const EdgeInsets.all(6), 
                    decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), 
                    child: const Icon(Icons.add_rounded, size: 22, color: Color(0xFF64748B)),
                  ),
                ),
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
    final String msgType = msg['message_type'] ?? 'text';

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

    final bool isLocalLoadingImage = msgType == 'local_image';
    final bool isImageMessage = msgType == 'image' || isLocalLoadingImage ||
        (rawText.startsWith('http') && (rawText.contains('.jpg') || rawText.contains('.png') || rawText.contains('.jpeg') || rawText.contains('s3.amazonaws') || rawText.contains('presigned')));

    return Dismissible(
      key: ValueKey('msg_${msg['message_id']}_$index'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        setState(() {
          _replyingMessage = msg;
        });
        return false; 
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.reply_rounded, color: Color(0xFF524582), size: 24),
      ),
      child: GestureDetector(
        onLongPress: () => _showChatMessageOptions(msg), 
        child: Padding(
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
                  
                  isImageMessage
                      ? GestureDetector(
                          onTap: isLocalLoadingImage ? null : () => _showImageDetailModal(rawText),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.60),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                isLocalLoadingImage
                                    ? Image.file(File(rawText), fit: BoxFit.cover)
                                    : Image.network(
                                        rawText,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 180,
                                            color: const Color(0xFFF1F5F9),
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF524582)),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) => Container(
                                          padding: const EdgeInsets.all(12),
                                          color: const Color(0xFFF1F5F9),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.broken_image_rounded, size: 20, color: Color(0xFF94A3B8)),
                                              SizedBox(width: 6),
                                              Text('이미지를 로드할 수 없습니다', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'Pretendard')),
                                            ],
                                          ),
                                        ),
                                      ),
                                if (isLocalLoadingImage)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withOpacity(0.4),
                                      child: const Center(
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : isOptimizedCard && cardData != null
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
        ),
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
          
          for (var dayPlan in itineraries)
            Builder(
              builder: (context) {
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
              },
            ),
          
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

  void _showChatMessageOptions(Map<String, dynamic> msg) {
    final bool isMyMessage = msg['isMe'] ?? false;
    final String contentText = msg['text'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: Color(0xFF524582)),
              title: const Text('답장하기', style: TextStyle(fontFamily: 'Pretendard', fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingMessage = msg;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_rounded, color: Color(0xFFD97706)),
              title: const Text('공지로 등록', style: TextStyle(fontFamily: 'Pretendard', fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _noticeMessage = contentText.startsWith('{"tripto_card_type"') ? "🗺️ [여행 일정표 카드]" : contentText;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('채팅방 상단에 공지가 등록되었습니다.')),
                );
              },
            ),
            if (isMyMessage)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4D4D)),
                title: const Text('삭제 (보내기 취소)', style: TextStyle(fontFamily: 'Pretendard', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFFF4D4D))),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _messages.remove(msg);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('메시지가 삭제되었습니다.')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}