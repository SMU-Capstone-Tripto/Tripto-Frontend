import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/features/chat/domain/chat_model.dart';
import 'package:tripto/src/core/auth_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum ChatSortOrder { newest, oldest, unread }

final chatSortProvider = StateProvider<ChatSortOrder>((ref) => ChatSortOrder.newest);

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatModel>>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<List<ChatModel>> {
  ChatNotifier() : super([]);
  bool _isLoading = false;

  final Map<int, String> _customRoomNames = {};

  // 💡 [읽음 추적 캐시] 사용자가 읽은 각 방의 최신 메시지 ID 보존
  final Map<int, int> _lastReadMessageIds = {};

  /// 💡 [낙관적 업데이트] 방 진입 시 안읽음 카운트 즉시 0 처리
  void markRoomAsRead(int roomId, {int? lastMsgId}) {
    if (roomId <= 0) return;
    if (lastMsgId != null && lastMsgId > 0) {
      final current = _lastReadMessageIds[roomId] ?? 0;
      if (lastMsgId > current) {
        _lastReadMessageIds[roomId] = lastMsgId;
      }
    }

    state = [
      for (final room in state)
        if ((int.tryParse(room.id.toString()) ?? 0) == roomId)
          ChatModel(
            id: room.id,
            name: room.name,
            rawLastMessage: room.rawLastMessage,
            cleanLastMessage: room.cleanLastMessage,
            lastTime: room.lastTime,
            unreadCount: 0, // 👈 즉시 0으로 설정
            type: room.type,
            memberIds: room.memberIds,
            userNames: room.userNames,
            humanProfiles: room.humanProfiles,
            derivedMemberCount: room.derivedMemberCount,
            updatedAt: room.updatedAt,
          )
        else
          room,
    ];
  }

  void updateRoomName(int roomId, String newName) {
    if (roomId <= 0 || newName.trim().isEmpty) return;
    final cleanName = newName.trim();
    _customRoomNames[roomId] = cleanName;

    state = [
      for (final room in state)
        if ((int.tryParse(room.id.toString()) ?? 0) == roomId)
          ChatModel(
            id: room.id,
            name: cleanName,
            rawLastMessage: room.rawLastMessage,
            cleanLastMessage: room.cleanLastMessage,
            lastTime: room.lastTime,
            unreadCount: room.unreadCount,
            type: room.type,
            memberIds: room.memberIds,
            userNames: room.userNames,
            humanProfiles: room.humanProfiles,
            derivedMemberCount: room.derivedMemberCount,
            updatedAt: room.updatedAt,
          )
        else
          room,
    ];
  }

  Future<void> fetchRooms() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      int myUserId = 0;
      final Map<String, String> friendNames = {};
      final Map<String, String> friendImages = {};

      try {
        final meRes = await http.get(
          Uri.parse('${AuthStorage.baseUrl}/auth/me'),
          headers: AuthStorage.authHeaders,
        );
        if (meRes.statusCode == 200) {
          final meData = jsonDecode(utf8.decode(meRes.bodyBytes));
          myUserId = int.tryParse(meData['user_id']?.toString() ?? meData['id']?.toString() ?? '0') ?? 0;
          final String? myImg = meData['profile_image']?.toString();
          final String? myNick = meData['nickname']?.toString();
          if (myUserId > 0) {
            if (myNick != null && myNick.isNotEmpty) friendNames[myUserId.toString()] = myNick;
            if (myImg != null && myImg.isNotEmpty) friendImages[myUserId.toString()] = myImg;
          }
        }
      } catch (_) {}

      try {
        final friendRes = await http.get(
          Uri.parse('${AuthStorage.baseUrl}/friends/list'),
          headers: AuthStorage.authHeaders,
        );
        if (friendRes.statusCode == 200) {
          final List<dynamic> friendList = jsonDecode(utf8.decode(friendRes.bodyBytes));
          for (var item in friendList) {
            if (item is Map && item['user'] is Map) {
              final u = item['user'];
              final String? fId = u['friend_id']?.toString() ?? u['id']?.toString();
              final String? fNick = u['nickname']?.toString();
              final String? fImg = u['profile_image']?.toString() ?? u['profile_img']?.toString();
              if (fId != null && fId.isNotEmpty) {
                if (fNick != null && fNick.isNotEmpty) friendNames[fId] = fNick;
                if (fImg != null && fImg.isNotEmpty) friendImages[fId] = fImg;
              }
            }
          }
        }
      } catch (_) {}

      final url = Uri.parse('${AuthStorage.baseUrl}/chat/rooms');
      final response = await http.get(url, headers: AuthStorage.authHeaders);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final roomsFuture = decoded.map((e) async {
            try {
              final Map<String, dynamic> roomJson = Map<String, dynamic>.from(e);
              final int roomId = int.tryParse(roomJson['room_id']?.toString() ?? roomJson['id']?.toString() ?? '0') ?? 0;

              final Map<String, dynamic> roomUserNames = {};
              final Map<String, dynamic> roomUserImages = {};

              void recordUser(dynamic uid, dynamic nick, String? img) {
                if (uid == null) return;
                final String sUid = uid.toString().trim();
                if (sUid.isEmpty || sUid == '0' || sUid == '-1') return;
                if (nick != null && nick.toString().trim().isNotEmpty) {
                  roomUserNames[sUid] = nick.toString().trim();
                }
                if (img != null && img.trim().isNotEmpty) {
                  roomUserImages[sUid] = img.trim();
                }
              }

              for (var key in ['members', 'user_profiles', 'profiles', 'users', 'participants']) {
                if (roomJson[key] is List) {
                  for (var m in (roomJson[key] as List)) {
                    if (m is Map) {
                      recordUser(
                        m['id'] ?? m['user_id'], 
                        m['nickname'] ?? m['name'], 
                        m['profile_image']?.toString() ?? m['profile_img']?.toString()
                      );
                    }
                  }
                }
              }

              if (roomId > 0) {
                try {
                  final msgRes = await http.get(
                    Uri.parse('${AuthStorage.baseUrl}/chat/$roomId/messages'),
                    headers: AuthStorage.authHeaders,
                  );
                  if (msgRes.statusCode == 200) {
                    final msgData = jsonDecode(utf8.decode(msgRes.bodyBytes));
                    if (msgData is Map) {
                      final List<dynamic> messages = msgData['messages'] ?? [];
                      final Map<String, dynamic> readStatuses = Map<String, dynamic>.from(msgData['read_statuses'] ?? {});

                      if (msgData['user_names'] is Map) {
                        (msgData['user_names'] as Map).forEach((k, v) => recordUser(k, v, null));
                      }
                      if (msgData['user_images'] is Map) {
                        (msgData['user_images'] as Map).forEach((k, v) => recordUser(k, null, v?.toString()));
                      }

                      for (var m in messages) {
                        if (m is Map) {
                          recordUser(
                            m['sender_id'] ?? m['user_id'], 
                            m['sender_nickname'] ?? m['nickname'], 
                            m['sender_profile_image']?.toString() ?? m['profile_image']?.toString()
                          );
                        }
                      }

                      if (messages.isNotEmpty) {
                        final lastMsg = messages.last;
                        roomJson['last_message'] = lastMsg['content'];
                        roomJson['last_message_time'] = lastMsg['created_at'];
                      }

                      // 💡 [핵심] 서버의 읽음 상태와 로컬에서 사용자가 읽은 상태 중 더 최신 기준 적용
                      final int myLastReadIdFromServer = int.tryParse(readStatuses[myUserId.toString()]?.toString() ?? '0') ?? 0;
                      final int localLastReadId = _lastReadMessageIds[roomId] ?? 0;
                      final int effectiveLastReadId = localLastReadId > myLastReadIdFromServer ? localLastReadId : myLastReadIdFromServer;

                      int unread = 0;
                      for (var m in messages) {
                        final int msgId = int.tryParse(m['message_id']?.toString() ?? '0') ?? 0;
                        final int senderId = int.tryParse(m['sender_id']?.toString() ?? '0') ?? 0;
                        if (senderId != myUserId && senderId != -1 && msgId > effectiveLastReadId) {
                          unread++;
                        }
                      }
                      roomJson['unread_count'] = unread;
                    }
                  }
                } catch (_) {}
              }

              roomJson['user_names'] = roomUserNames;
              roomJson['user_images'] = roomUserImages;
              roomJson['friend_images'] = friendImages;
              roomJson['friend_names'] = friendNames;

              final ChatModel parsedModel = ChatModel.fromJson(roomJson, myUserId: myUserId);

              if (_customRoomNames.containsKey(roomId)) {
                return ChatModel(
                  id: parsedModel.id,
                  name: _customRoomNames[roomId]!,
                  rawLastMessage: parsedModel.rawLastMessage,
                  cleanLastMessage: parsedModel.cleanLastMessage,
                  lastTime: parsedModel.lastTime,
                  unreadCount: parsedModel.unreadCount,
                  type: parsedModel.type,
                  memberIds: parsedModel.memberIds,
                  userNames: parsedModel.userNames,
                  humanProfiles: parsedModel.humanProfiles,
                  derivedMemberCount: parsedModel.derivedMemberCount,
                  updatedAt: parsedModel.updatedAt,
                );
              }

              return parsedModel;
            } catch (err) {
              debugPrint('⚠️ 단일 개별 방 파싱 예외 처리: $err');
              return null;
            }
          });

          final rooms = await Future.wait(roomsFuture);
          state = rooms.whereType<ChatModel>().toList();
        }
      }
    } catch (e) {
      debugPrint('❌ [fetchRooms] 에러: $e');
    } finally {
      _isLoading = false;
    }
  }
}

final sortedChatProvider = Provider<List<ChatModel>>((ref) {
  final rooms = ref.watch(chatProvider);
  final sortOrder = ref.watch(chatSortProvider);

  final List<ChatModel> sortedList = List.from(rooms);

  sortedList.sort((a, b) {
    if (sortOrder == ChatSortOrder.unread) {
      int unreadCompare = b.unreadCount.compareTo(a.unreadCount);
      if (unreadCompare != 0) return unreadCompare;
      
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    }

    final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (sortOrder == ChatSortOrder.newest) {
      return bTime.compareTo(aTime);
    } else {
      return aTime.compareTo(bTime);
    }
  });

  return sortedList;
});