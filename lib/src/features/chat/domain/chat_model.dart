
enum ChatType { group, ai }

class ChatModel {
  final String id;
  final String name;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final int memberCount;
  final ChatType type;

  const ChatModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastTime,
    required this.type,
    this.unreadCount = 0,
    this.memberCount = 1,
  });

  ChatModel copyWith({
    String? name, String? lastMessage,
    String? lastTime, int? unreadCount, int? memberCount,
  }) => ChatModel(
    id: id, type: type,
    name: name ?? this.name,
    lastMessage: lastMessage ?? this.lastMessage,
    lastTime: lastTime ?? this.lastTime,
    unreadCount: unreadCount ?? this.unreadCount,
    memberCount: memberCount ?? this.memberCount,
  );
}