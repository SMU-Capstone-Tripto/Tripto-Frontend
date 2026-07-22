import 'dart:convert';

enum ChatType { user, ai }

class ChatModel {
  final dynamic id;
  final String name;
  final String rawLastMessage;
  final String cleanLastMessage;
  final String lastTime;
  final int unreadCount;
  final ChatType type;
  final List<dynamic> memberIds;
  final Map<String, dynamic>? userNames;
  final List<Map<String, String?>> humanProfiles;
  final int derivedMemberCount;
  final DateTime? updatedAt;

  ChatModel({
    required this.id,
    required this.name,
    required this.rawLastMessage,
    required this.cleanLastMessage,
    required this.lastTime,
    required this.unreadCount,
    required this.type,
    this.memberIds = const [],
    this.userNames,
    this.humanProfiles = const [],
    this.derivedMemberCount = 1,
    this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, {int myUserId = 0}) {
    final rawId = json['room_id'] ?? json['id'] ?? 0;
    String roomName = json['room_name']?.toString() ?? json['name']?.toString() ?? '';

    // 1. 메시지 파싱
    dynamic rawMsgObj = json['last_message'] ?? 
                        json['recent_message'] ?? 
                        json['latest_message'] ?? 
                        json['last_content'] ?? 
                        json['content'] ?? 
                        json['message'];

    String rawMsg = '';
    if (rawMsgObj is String) {
      rawMsg = rawMsgObj;
    } else if (rawMsgObj is Map) {
      rawMsg = rawMsgObj['content']?.toString() ?? 
               rawMsgObj['text']?.toString() ?? 
               rawMsgObj['message']?.toString() ?? '';
    } else if (rawMsgObj != null) {
      rawMsg = rawMsgObj.toString();
    }

    String cleanMsg = rawMsg.trim();
    if (cleanMsg.isEmpty) {
      cleanMsg = '대화 기록이 없습니다. 첫 메세지를 보내주세요.';
    } else if (cleanMsg.startsWith('{') && cleanMsg.endsWith('}')) {
      try {
        final parsed = jsonDecode(cleanMsg);
        if (parsed is Map) {
          final String cardType = parsed['tripto_card_type'] ?? parsed['step'] ?? '';
          if (cardType == 'optimized' || parsed['itinerary'] != null) {
            cleanMsg = '🗺️ AI 최적화 여행 일정표가 도착했습니다!';
          } else if (parsed['content'] != null && parsed['content'].toString().trim().isNotEmpty) {
            cleanMsg = parsed['content'].toString();
          } else if (parsed['message'] != null && parsed['message'].toString().trim().isNotEmpty) {
            cleanMsg = parsed['message'].toString();
          } else if (parsed['plan_title'] != null) {
            cleanMsg = '🗺️ ${parsed['plan_title']}';
          } else {
            cleanMsg = '🤖 tripto 가이드 메시지';
          }
        }
      } catch (_) {}
    }

    // 2. 시간 계산
    final String rawTime = json['last_message_time']?.toString() ?? 
                           json['updated_at']?.toString() ?? 
                           json['created_at']?.toString() ?? '';
    
    DateTime? parsedDate;
    if (rawTime.isNotEmpty) {
      if (!rawTime.contains('Z') && !rawTime.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(rawTime)) {
        parsedDate = DateTime.tryParse('${rawTime}Z')?.toLocal() ?? DateTime.tryParse(rawTime)?.toLocal();
      } else {
        parsedDate = DateTime.tryParse(rawTime)?.toLocal();
      }
    }

    String formattedTime = '';
    if (parsedDate != null) {
      final now = DateTime.now();
      if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day) {
        int h = parsedDate.hour % 12;
        if (h == 0) h = 12;
        formattedTime = '${parsedDate.hour >= 12 ? "오후" : "오전"} $h:${parsedDate.minute.toString().padLeft(2, '0')}';
      } else {
        formattedTime = '${parsedDate.month}/${parsedDate.day}';
      }
    }

    // 3. 멤버 수집
    List<dynamic> members = [];
    if (json['member_ids'] is List) {
      members = List.from(json['member_ids']);
    } else if (json['invited_user_ids'] is List) {
      members = List.from(json['invited_user_ids']);
    } else if (json['members'] is List) {
      members = List.from(json['members']);
    }

    Map<String, dynamic>? parsedUserNames;
    if (json['user_names'] is Map) {
      parsedUserNames = Map<String, dynamic>.from(json['user_names']);
    }

    final bool isAiRoom = json['type'] == 'ai' || 
                         members.contains(-1) || 
                         members.contains('-1') ||
                         roomName.toLowerCase().contains('tripto') || 
                         roomName.contains('트립토');

    // 4. 유저 닉네임 정제 Map
    Map<String, String> cleanedUserNames = {};
    if (parsedUserNames != null) {
      parsedUserNames.forEach((key, val) {
        String nick = '';
        if (val is Map) {
          nick = val['nickname']?.toString() ?? val['name']?.toString() ?? '';
        } else if (val != null) {
          nick = val.toString();
        }

        nick = nick.replaceAll('<', '').replaceAll('>', '').replaceAll('(', '').replaceAll(')', '').trim();

        if (nick.isEmpty || 
            nick.contains('대화상대') || 
            nick.contains('알수없음') || 
            nick.contains('알 수 없음') || 
            RegExp(r'^유저\d+$').hasMatch(nick)) {
          cleanedUserNames[key.toString()] = (key.toString() == '-1') ? '트립토 AI' : '(알수없음)';
        } else {
          cleanedUserNames[key.toString()] = nick;
        }
      });
    }

    // 5. 트립토(-1) & 나간 유저('(알수없음)')를 완전히 제외한 인간 프로필 수집
    List<Map<String, String?>> memberProfiles = [];
    List<String> activeHumanNicknames = [];

    // 🎯 [타입 오류 완치 지점]: 명시적 if-else 분기로 Object 타입 추론 차단
    Iterable<dynamic> targetIds;
    if (members.isNotEmpty) {
      targetIds = members;
    } else if (parsedUserNames != null) {
      targetIds = parsedUserNames.keys;
    } else {
      targetIds = const [];
    }

    for (var id in targetIds) {
      final String sId = id.toString();
      if (sId == '-1') continue;

      String nick = cleanedUserNames[sId] ?? '';

      if (nick == '(알수없음)' || nick.isEmpty) continue;

      String? imgUrl;
      if (parsedUserNames != null && parsedUserNames[sId] is Map) {
        imgUrl = parsedUserNames[sId]['profile_image']?.toString();
      }

      if ((imgUrl == null || imgUrl.isEmpty) && json['user_images'] is Map) {
        imgUrl = json['user_images'][sId]?.toString();
      }

      activeHumanNicknames.add(nick);

      if (memberProfiles.length < 4) {
        memberProfiles.add({
          'nickname': nick,
          'profile_image': (imgUrl != null && imgUrl.isNotEmpty) ? imgUrl : null,
        });
      }
    }

    roomName = roomName.replaceAll('<', '').replaceAll('>', '').trim();
    if (roomName.isEmpty || roomName.contains('대화상대') || roomName.contains('알수없음') || RegExp(r'^유저\d+$').hasMatch(roomName)) {
      if (activeHumanNicknames.isNotEmpty) {
        roomName = activeHumanNicknames.join(', ');
      } else {
        roomName = isAiRoom ? '트립토 AI 가이드' : '채팅방';
      }
    }

    int humanCount = activeHumanNicknames.length;
    if (humanCount == 0 && !isAiRoom) humanCount = 1;

    return ChatModel(
      id: rawId,
      name: roomName,
      rawLastMessage: rawMsg,
      cleanLastMessage: cleanMsg,
      lastTime: formattedTime,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      type: isAiRoom ? ChatType.ai : ChatType.user,
      memberIds: members,
      userNames: cleanedUserNames,
      humanProfiles: memberProfiles,
      derivedMemberCount: humanCount,
      updatedAt: parsedDate,
    );
  }
}