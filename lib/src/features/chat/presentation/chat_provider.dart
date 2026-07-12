import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';
import 'package:tripto/src/features/chat/domain/chat_model.dart';

enum ChatSortOrder { newest, oldest }

final chatSortProvider = StateProvider<ChatSortOrder>((ref) => ChatSortOrder.newest);

class ChatNotifier extends StateNotifier<List<ChatModel>> {
  ChatNotifier() : super(const []) {
    fetchRooms();
  }

  /// ── 🛠️ 실시간 백엔드 가입된 채팅방 리스트 조회 연동 ──
  Future<void> fetchRooms() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthStorage.baseUrl}/chat/rooms'),
        headers: AuthStorage.authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        
        final List<ChatModel> realRooms = jsonList.map((item) {
          final String rawTime = item['created_at'] ?? '';
          String formattedTime = '방금';
          
          if (rawTime.isNotEmpty) {
            try {
              final parsedDate = DateTime.parse(rawTime);
              formattedTime = '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
            } catch (_) {}
          }

          return ChatModel(
            id: item['room_id'].toString(),
            name: item['room_name'] ?? '이름 없는 대화방',
            lastMessage: '대화 내용이 없습니다. 첫 메시지를 보내보세요!',
            lastTime: formattedTime,
            type: ChatType.group,
            unreadCount: 0,
            memberCount: 1, 
          );
        }).toList();

        state = realRooms;
      }
    } catch (e) {
      print('채팅방 목록 실시간 갱신 실패: $e');
    }
  }

  /// ── ⚙️ 추가 요구사항: 대화방 내부 웹소켓 수신 시 목록의 메시지/시간/알람 실시간 업데이트 ──
  void updateRoomMessage(String roomId, String message, String time, {bool incrementUnread = false}) {
    state = [
      for (final room in state)
        if (room.id == roomId)
          room.copyWith(
            lastMessage: message,
            lastTime: time,
            unreadCount: incrementUnread ? room.unreadCount + 1 : room.unreadCount,
          )
        else
          room
    ];
  }

  // 채팅방 삭제
  void removeChat(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatModel>>(
  (ref) => ChatNotifier(),
);

final sortedChatProvider = Provider<List<ChatModel>>((ref) {
  final chats = ref.watch(chatProvider);
  final sort = ref.watch(chatSortProvider);
  final sorted = [...chats];
  if (sort == ChatSortOrder.oldest) {
    sorted.sort((a, b) => a.lastTime.compareTo(b.lastTime));
  }
  return sorted;
});