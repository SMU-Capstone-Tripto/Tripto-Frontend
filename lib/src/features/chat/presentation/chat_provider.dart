
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/domain/chat_model.dart';

// 정렬 기준
enum ChatSortOrder { newest, oldest }

final chatSortProvider = StateProvider<ChatSortOrder>((ref) => ChatSortOrder.newest);

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
  }

  // 채팅방 삭제
  void removeChat(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatModel>>(
      (ref) => ChatNotifier(),
);

// 정렬 적용된 목록
final sortedChatProvider = Provider<List<ChatModel>>((ref) {
  final chats = ref.watch(chatProvider);
  final sort  = ref.watch(chatSortProvider);
  final sorted = [...chats];
  if (sort == ChatSortOrder.oldest) sorted.sort((a, b) => a.lastTime.compareTo(b.lastTime));
  return sorted;
});