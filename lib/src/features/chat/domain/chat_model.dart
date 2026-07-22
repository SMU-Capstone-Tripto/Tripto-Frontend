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

    // 3. 유저 ID 기준 백엔드 전체 유저 프로필 수집
    final Map<int, Map<String, dynamic>> userStore = {};

    Map<String, dynamic> getOrInitUser(int uid) {
      return userStore.putIfAbsent(uid, () => {
        'id': uid,
        'nickname': '',
        'profile_image': null,
      });
    }

    final List<dynamic> rawMemberList = [];
    for (var key in ['members', 'user_profiles', 'profiles', 'member_ids', 'invited_user_ids', 'users', 'participants']) {
      if (json[key] is List) {
        rawMemberList.addAll(json[key] as List);
      }
    }

    final List<int> memberIdsOnly = [];

    for (var item in rawMemberList) {
      if (item is Map) {
        final int? uid = int.tryParse(item['id']?.toString() ?? item['user_id']?.toString() ?? item['friend_id']?.toString() ?? '');
        if (uid != null) {
          if (!memberIdsOnly.contains(uid)) memberIdsOnly.add(uid);
          var u = getOrInitUser(uid);
          String? nick = item['nickname']?.toString() ?? item['name']?.toString() ?? item['username']?.toString();
          String? img = item['profile_image']?.toString() ?? item['profile_img']?.toString() ?? item['profile_image_url']?.toString() ?? item['image']?.toString() ?? item['user_image']?.toString() ?? item['avatar']?.toString();
          if (nick != null && nick.trim().isNotEmpty) u['nickname'] = nick.trim();
          if (img != null && img.trim().isNotEmpty) u['profile_image'] = img.trim();
        }
      } else if (item != null) {
        final int? uid = int.tryParse(item.toString());
        if (uid != null) {
          if (!memberIdsOnly.contains(uid)) memberIdsOnly.add(uid);
          getOrInitUser(uid);
        }
      }
    }

    for (var key in ['opponent', 'target_user', 'partner', 'other_user', 'receiver', 'user', 'friend']) {
      if (json[key] is Map) {
        final Map<String, dynamic> item = json[key];
        final int? uid = int.tryParse(item['id']?.toString() ?? item['user_id']?.toString() ?? '');
        if (uid != null) {
          if (!memberIdsOnly.contains(uid)) memberIdsOnly.add(uid);
          var u = getOrInitUser(uid);
          String? nick = item['nickname']?.toString() ?? item['name']?.toString() ?? item['username']?.toString();
          String? img = item['profile_image']?.toString() ?? item['profile_img']?.toString() ?? item['profile_image_url']?.toString() ?? item['image']?.toString() ?? item['avatar']?.toString();
          if (nick != null && nick.trim().isNotEmpty) u['nickname'] = nick.trim();
          if (img != null && img.trim().isNotEmpty) u['profile_image'] = img.trim();
        }
      }
    }

    if (json['user_names'] is Map) {
      (json['user_names'] as Map).forEach((k, v) {
        final int? uid = int.tryParse(k.toString());
        if (uid != null) {
          var u = getOrInitUser(uid);
          if (v is Map) {
            String? nick = v['nickname']?.toString() ?? v['name']?.toString();
            String? img = v['profile_image']?.toString() ?? v['profile_img']?.toString() ?? v['profile_image_url']?.toString() ?? v['image']?.toString();
            if (nick != null && nick.trim().isNotEmpty) u['nickname'] = nick.trim();
            if (img != null && img.trim().isNotEmpty) u['profile_image'] = img.trim();
          } else if (v != null && v.toString().trim().isNotEmpty) {
            u['nickname'] = v.toString().trim();
          }
        }
      });
    }

    for (var key in ['user_images', 'profile_images', 'user_profile_images', 'images', 'avatars']) {
      if (json[key] is Map) {
        (json[key] as Map).forEach((k, v) {
          final int? uid = int.tryParse(k.toString());
          if (uid != null && v != null) {
            var u = getOrInitUser(uid);
            if (v is Map) {
              String? img = v['profile_image']?.toString() ?? v['profile_img']?.toString() ?? v['profile_image_url']?.toString() ?? v['image']?.toString();
              if (img != null && img.trim().isNotEmpty) u['profile_image'] = img.trim();
            } else if (v.toString().trim().isNotEmpty) {
              u['profile_image'] = v.toString().trim();
            }
          }
        });
      }
    }

    for (var imgKey in ['partner_profile_image', 'opponent_profile_image', 'target_profile_image', 'profile_image', 'image']) {
      if (json[imgKey] != null && json[imgKey].toString().trim().isNotEmpty) {
        final String directImg = json[imgKey].toString().trim();
        for (var uid in userStore.keys) {
          if (uid != -1 && (myUserId == 0 || uid != myUserId)) {
            if (userStore[uid]!['profile_image'] == null) {
              userStore[uid]!['profile_image'] = directImg;
            }
          }
        }
      }
    }

    final bool isAiRoom = json['type'] == 'ai' || 
                         memberIdsOnly.contains(-1) || 
                         userStore.containsKey(-1) ||
                         roomName.toLowerCase().contains('tripto') || 
                         roomName.contains('트립토');

    // 4. 유저 프로필 및 닉네임 정제
    List<Map<String, String?>> humanProfiles = [];
    List<String> activeHumanNicknames = [];
    Map<String, String> cleanedUserNames = {};

    userStore.forEach((uid, uData) {
      final String sId = uid.toString();
      if (uid == -1) {
        cleanedUserNames['-1'] = '트립토 AI';
        return;
      }

      String rawNick = uData['nickname']?.toString().trim() ?? '';
      rawNick = rawNick.replaceAll('<', '').replaceAll('>', '').replaceAll('(', '').replaceAll(')', '').trim();

      bool isInvalid = rawNick.isEmpty || 
                       rawNick.contains('대화상대') || 
                       rawNick.contains('알수없음') || 
                       rawNick.contains('알 수 없음') || 
                       RegExp(r'^유저\d+$').hasMatch(rawNick);

      String displayNick = isInvalid ? '유저 $uid' : rawNick;
      cleanedUserNames[sId] = isInvalid ? '(알수없음)' : displayNick;

      String? imgUrl = uData['profile_image']?.toString().trim();
      if (imgUrl != null && imgUrl.isEmpty) imgUrl = null;

      activeHumanNicknames.add(displayNick);

      humanProfiles.add({
        'id': sId,
        'nickname': displayNick,
        'profile_image': imgUrl,
      });
    });

    // 🎯 1:1 대화방일 때 내 프로필을 뒤로 정렬
    if (myUserId > 0 && humanProfiles.length == 2) {
      humanProfiles.sort((a, b) {
        if (a['id'] == myUserId.toString()) return 1;
        if (b['id'] == myUserId.toString()) return -1;
        return 0;
      });
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
      memberIds: memberIdsOnly.isNotEmpty ? memberIdsOnly : userStore.keys.toList(),
      userNames: cleanedUserNames,
      humanProfiles: humanProfiles,
      derivedMemberCount: humanCount,
      updatedAt: parsedDate,
    );
  }
}