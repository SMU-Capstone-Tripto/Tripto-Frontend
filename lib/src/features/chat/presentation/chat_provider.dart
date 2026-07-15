<<<<<<< HEAD

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/domain/chat_model.dart';

// 정렬 기준
=======
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tripto/src/core/auth_storage.dart';
import 'package:tripto/src/features/chat/domain/chat_model.dart';

>>>>>>> origin/chatting
enum ChatSortOrder { newest, oldest }

final chatSortProvider = StateProvider<ChatSortOrder>((ref) => ChatSortOrder.newest);

<<<<<<< HEAD
// 채팅방 목록 상태 (추가/삭제 가능하도록 StateNotifier)
class ChatNotifier extends StateNotifier<List<ChatModel>> {
  ChatNotifier() : super(const [
    ChatModel(
      id: 'c1', name: 'AI 챗봇 대화방',
      lastMessage: '여행 계획은 마음에 드셨나요?',
      lastTime: '12:49', unreadCount: 1, type: ChatType.ai,
    ),
    ChatModel(
      id: 'c2', name: '제주도 가장',
      lastMessage: 'ㅇㅇ 그럼 거기로?',
      lastTime: '12:49', unreadCount: 3, memberCount: 4, type: ChatType.group,
    ),
    ChatModel(
      id: 'c3', name: '부산 여행~',
      lastMessage: '뭐 시에 볼까?',
      lastTime: '12:49', unreadCount: 13, memberCount: 2, type: ChatType.group,
    ),
  ]);

  // 채팅방 추가
  void addChat(String name, ChatType type) {
    final newChat = ChatModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      lastMessage: type == ChatType.ai ? 'AI와 대화를 시작해보세요' : '채팅방이 생성되었습니다',
      lastTime: '방금',
      type: type,
    );
    // 최신순이면 맨 앞에 추가
    state = [newChat, ...state];
=======
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
>>>>>>> origin/chatting
  }

  // 채팅방 삭제
  void removeChat(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatModel>>(
<<<<<<< HEAD
      (ref) => ChatNotifier(),
);

// 정렬 적용된 목록
final sortedChatProvider = Provider<List<ChatModel>>((ref) {
  final chats = ref.watch(chatProvider);
  final sort  = ref.watch(chatSortProvider);
  final sorted = [...chats];
  if (sort == ChatSortOrder.oldest) sorted.sort((a, b) => a.lastTime.compareTo(b.lastTime));
=======
  (ref) => ChatNotifier(),
);

final sortedChatProvider = Provider<List<ChatModel>>((ref) {
  final chats = ref.watch(chatProvider);
  final sort = ref.watch(chatSortProvider);
  final sorted = [...chats];
  if (sort == ChatSortOrder.oldest) {
    sorted.sort((a, b) => a.lastTime.compareTo(b.lastTime));
  }
>>>>>>> origin/chatting
  return sorted;
});