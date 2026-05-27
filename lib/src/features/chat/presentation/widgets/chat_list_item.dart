
import 'package:flutter/material.dart';
import '../../../chat/domain/chat_model.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // 좌→우 슬라이드로 삭제 (이미지 기준 우측 빨간 버튼)
      key: ValueKey(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFD93030),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        // 삭제 확인 없이 바로 삭제 (필요하면 confirm dialog 추가)
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // 아바타
              _ChatAvatar(type: chat.type),
              const SizedBox(width: 12),

              // 채팅 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(chat.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2D2A5E)),
                            overflow: TextOverflow.ellipsis),
                        if (chat.type == ChatType.group) ...[
                          const SizedBox(width: 4),
                          Text('${chat.memberCount}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9993C4))),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(chat.lastMessage,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9993C4)),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 시간 + 읽지 않은 수
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(chat.lastTime,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9993C4))),
                  const SizedBox(height: 5),
                  if (chat.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6144B0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${chat.unreadCount}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final ChatType type;
  const _ChatAvatar({required this.type});

  @override
  Widget build(BuildContext context) {
    final isAi = type == ChatType.ai;
    return CircleAvatar(
      radius: 23,
      backgroundColor: isAi ? const Color(0xFFE1F5EE) : const Color(0xFFEDE9FF),
      child: Icon(
        isAi ? Icons.smart_toy_outlined : Icons.group_outlined,
        size: 22,
        color: isAi ? const Color(0xFF0F6E56) : const Color(0xFF6144B0),
      ),
    );
  }
}