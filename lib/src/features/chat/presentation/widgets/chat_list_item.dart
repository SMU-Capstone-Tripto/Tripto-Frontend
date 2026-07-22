import 'package:flutter/material.dart';
import 'package:tripto/src/core/auth_storage.dart';
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
    final int memberCount = chat.derivedMemberCount;

    return Dismissible(
      key: ValueKey('dismiss_item_${chat.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFD93030),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
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
              _ChatCompositeAvatar(room: chat),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            chat.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2A5E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (memberCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$memberCount',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7C5CFC),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      chat.cleanLastMessage,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9993C4)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    chat.lastTime,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9993C4)),
                  ),
                  const SizedBox(height: 5),
                  if (chat.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${chat.unreadCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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

class _ChatCompositeAvatar extends StatelessWidget {
  final ChatModel room;

  const _ChatCompositeAvatar({required this.room});

  @override
  Widget build(BuildContext context) {
    final profiles = room.humanProfiles;

    if (profiles.isEmpty) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF6241D9),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Text(
          '나',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    String? formatImgUrl(String? url) {
      if (url == null || url.trim().isEmpty) return null;
      final trimmed = url.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed;
      }
      String cleanBase = AuthStorage.baseUrl.replaceAll('\n', '').replaceAll('\r', '').trim();
      if (cleanBase.endsWith('/api/v1')) {
        cleanBase = cleanBase.substring(0, cleanBase.length - 7);
      } else if (cleanBase.endsWith('/api')) {
        cleanBase = cleanBase.substring(0, cleanBase.length - 4);
      }
      if (cleanBase.endsWith('/')) {
        cleanBase = cleanBase.substring(0, cleanBase.length - 1);
      }
      return trimmed.startsWith('/') ? '$cleanBase$trimmed' : '$cleanBase/$trimmed';
    }

    Widget singleMiniAvatar(Map<String, String?> profile, double size, {Color? bg}) {
      final String nick = (profile['nickname'] ?? '유저').trim();
      final String? rawImg = profile['profile_image'];
      final String? formattedUrl = formatImgUrl(rawImg);
      final String initial = nick.isNotEmpty ? nick.substring(0, 1) : '유';

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg ?? const Color(0xFF6241D9),
          borderRadius: BorderRadius.circular(size * 0.35),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: (formattedUrl != null && formattedUrl.isNotEmpty)
            ? Image.network(
                formattedUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    }

    if (profiles.length == 1) {
      return singleMiniAvatar(profiles[0], 46, bg: const Color(0xFF6241D9));
    }

    final int count = profiles.length;

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (count == 2) ...[
            Positioned(left: 0, top: 0, child: singleMiniAvatar(profiles[0], 25, bg: const Color(0xFF818CF8))),
            Positioned(right: 0, bottom: 0, child: singleMiniAvatar(profiles[1], 25, bg: const Color(0xFF6366F1))),
          ] else if (count == 3) ...[
            Positioned(left: 10, top: 0, child: singleMiniAvatar(profiles[0], 22, bg: const Color(0xFF94A3B8))),
            Positioned(left: 0, bottom: 0, child: singleMiniAvatar(profiles[1], 22, bg: const Color(0xFF64748B))),
            Positioned(right: 0, bottom: 0, child: singleMiniAvatar(profiles[2], 22, bg: const Color(0xFF475569))),
          ] else ...[
            Positioned(left: 0, top: 0, child: singleMiniAvatar(profiles[0], 21, bg: const Color(0xFF94A3B8))),
            Positioned(right: 0, top: 0, child: singleMiniAvatar(profiles[1], 21, bg: const Color(0xFF64748B))),
            Positioned(left: 0, bottom: 0, child: singleMiniAvatar(profiles[2], 21, bg: const Color(0xFF475569))),
            Positioned(right: 0, bottom: 0, child: singleMiniAvatar(profiles[3], 21, bg: const Color(0xFF334155))),
          ],
        ],
      ),
    );
  }
}