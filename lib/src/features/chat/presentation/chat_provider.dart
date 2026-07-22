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

  Future<void> fetchRooms() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      int myUserId = 0;
      try {
        final meRes = await http.get(
          Uri.parse('${AuthStorage.baseUrl}/auth/me'),
          headers: AuthStorage.authHeaders,
        );
        if (meRes.statusCode == 200) {
          final meData = jsonDecode(utf8.decode(meRes.bodyBytes));
          myUserId = int.tryParse(meData['id']?.toString() ?? meData['user_id']?.toString() ?? '0') ?? 0;
        }
      } catch (_) {}

      final url = Uri.parse('${AuthStorage.baseUrl}/chat/rooms');
      final response = await http.get(url, headers: AuthStorage.authHeaders);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final roomsFuture = decoded.map((e) async {
            final Map<String, dynamic> roomJson = Map<String, dynamic>.from(e);
            final int roomId = int.tryParse(roomJson['room_id']?.toString() ?? roomJson['id']?.toString() ?? '0') ?? 0;

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
                    final Map<String, dynamic> userNames = Map<String, dynamic>.from(msgData['user_names'] ?? {});
                    final Map<String, dynamic> userImages = Map<String, dynamic>.from(msgData['user_images'] ?? msgData['profile_images'] ?? {});

                    // 🎯 [핵심 보완]: 메시지 배열 내 모든 Key(sender_profile_image, avatar, profile_img 등) 대응 수집
                    for (var m in messages) {
                      if (m is Map) {
                        final String? senderId = m['sender_id']?.toString() ?? m['user_id']?.toString();
                        final String? senderImg = m['sender_profile_image']?.toString() ?? 
                                                 m['sender_profile_img']?.toString() ?? 
                                                 m['profile_image']?.toString() ?? 
                                                 m['profile_img']?.toString() ?? 
                                                 m['profile_image_url']?.toString() ??
                                                 m['avatar']?.toString();
                        final String? senderNick = m['sender_nickname']?.toString() ?? 
                                                  m['nickname']?.toString() ?? 
                                                  m['name']?.toString();

                        if (senderId != null && senderId != '0' && senderId != '-1') {
                          if (senderImg != null && senderImg.trim().isNotEmpty) {
                            userImages[senderId] = senderImg.trim();
                          }
                          if (senderNick != null && senderNick.trim().isNotEmpty) {
                            userNames[senderId] = senderNick.trim();
                          }
                        }
                      }
                    }

                    roomJson['user_names'] = userNames;
                    roomJson['user_images'] = userImages;
                    if (msgData['member_ids'] != null) {
                      roomJson['member_ids'] = msgData['member_ids'];
                    }

                    for (var key in [
                      'profile_images', 'user_profile_images', 'images', 
                      'avatars', 'user_profiles', 'profiles', 'members',
                      'opponent', 'partner', 'target_user'
                    ]) {
                      if (msgData[key] != null) {
                        roomJson[key] = msgData[key];
                      }
                    }

                    if (messages.isNotEmpty) {
                      final lastMsg = messages.last;
                      roomJson['last_message'] = lastMsg['content'];
                      roomJson['last_message_time'] = lastMsg['created_at'];
                    }

                    final int myLastReadId = int.tryParse(readStatuses[myUserId.toString()]?.toString() ?? '0') ?? 0;
                    int unread = 0;
                    for (var m in messages) {
                      final int msgId = int.tryParse(m['message_id']?.toString() ?? '0') ?? 0;
                      final int senderId = int.tryParse(m['sender_id']?.toString() ?? '0') ?? 0;
                      if (senderId != myUserId && senderId != -1 && msgId > myLastReadId) {
                        unread++;
                      }
                    }
                    roomJson['unread_count'] = unread;
                  }
                }
              } catch (_) {}
            }
            return ChatModel.fromJson(roomJson, myUserId: myUserId);
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