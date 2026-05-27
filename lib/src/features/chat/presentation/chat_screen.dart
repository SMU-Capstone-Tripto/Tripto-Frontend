
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'package:tripto/src/features/chat/domain/chat_model.dart';
import 'package:tripto/src/features/chat/presentation/chat_provider.dart';
import 'package:tripto/src/features/chat/presentation/widgets/chat_list_item.dart';
import 'package:tripto/src/features/chat/presentation/widgets/create_chat_dialog.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats   = ref.watch(sortedChatProvider);
    final sort    = ref.watch(chatSortProvider);
    final notifier = ref.read(chatProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 상단 헤더 ──
          _ChatHeader(
            sort: sort,
            onSortChanged: (s) => ref.read(chatSortProvider.notifier).state = s,
            onCreateChat: (type) async {
              final name = await showCreateChatDialog(context, type);
              if (name != null && name.isNotEmpty) notifier.addChat(name, type);
            },
          ),

          // ── 채팅 목록 ──
          Expanded(
            child: ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFF0EEFF)),
              itemBuilder: (context, i) => ChatListItem(
                chat: chats[i],
                onDelete: () => notifier.removeChat(chats[i].id),
                onTap: () {
                  // TODO: 채팅방 상세 이동
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 헤더 ──
class _ChatHeader extends StatefulWidget {
  final ChatSortOrder sort;
  final ValueChanged<ChatSortOrder> onSortChanged;
  final ValueChanged<ChatType> onCreateChat;

  const _ChatHeader({
    required this.sort,
    required this.onSortChanged,
    required this.onCreateChat,
  });

  @override
  State<_ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<_ChatHeader> {
  bool _sortOpen = false;
  bool _addOpen  = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              // ── 채팅 타이틀 + 정렬 드롭다운 ──
              _SortButton(
                label: widget.sort == ChatSortOrder.newest ? '채팅' : '채팅',
                isOpen: _sortOpen,
                onTap: () => setState(() {
                  _sortOpen = !_sortOpen;
                  _addOpen = false;
                }),
              ),
              const Spacer(),

              // ── + 버튼 + 드롭다운 ──
              _AddButton(
                isOpen: _addOpen,
                onTap: () => setState(() {
                  _addOpen = !_addOpen;
                  _sortOpen = false;
                }),
                onCreateGroup: () {
                  setState(() => _addOpen = false);
                  widget.onCreateChat(ChatType.group);
                },
                onCreateAi: () {
                  setState(() => _addOpen = false);
                  widget.onCreateChat(ChatType.ai);
                },
              ),
            ],
          ),

          // ── 정렬 드롭다운 패널 ──
          if (_sortOpen)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      ),
                    _SortItem(
                      label: '최신순',
                      selected: widget.sort == ChatSortOrder.newest,
                      onTap: () {
                        widget.onSortChanged(ChatSortOrder.newest);
                        setState(() => _sortOpen = false);
                      },
                    ),
                    _SortItem(
                      label: '오래된순',
                      selected: widget.sort == ChatSortOrder.oldest,
                      onTap: () {
                        widget.onSortChanged(ChatSortOrder.oldest);
                        setState(() => _sortOpen = false);
                      },
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── 검색창 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '채팅방 검색',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                      isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 채팅 타이틀 + 정렬 토글
class _SortButton extends StatelessWidget {
  final String label;
  final bool isOpen;
  final VoidCallback onTap;
  const _SortButton({required this.label, required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: isOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.8), size: 20),
          ),
        ],
      ),
    );
  }
}

// 헤더 아이콘 버튼
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// + 버튼 + 드롭다운
class _AddButton extends StatefulWidget {
  final VoidCallback onCreateGroup;
  final VoidCallback onCreateAi;
  const _AddButton({required this.onCreateGroup, required this.onCreateAi, required bool isOpen, required void Function() onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  OverlayEntry? _entry;
  final _key = GlobalKey();

  void _open() {
    final box = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // 외부 탭 시 닫기
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // 드롭다운 메뉴
          Positioned(
            top: offset.dy + size.height + 8,
            right: MediaQuery.of(context).size.width - offset.dx - size.width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AddMenuItem(
                      icon: Icons.group_outlined,
                      iconBg: const Color(0xFFEDE9FF),
                      iconColor: const Color(0xFF6144B0),
                      label: '그룹 채팅방 만들기',
                      onTap: () { _close(); widget.onCreateGroup(); },
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    _AddMenuItem(
                      icon: Icons.smart_toy_outlined,
                      iconBg: const Color(0xFFE1F5EE),
                      iconColor: const Color(0xFF0F6E56),
                      label: 'AI 채팅방 만들기',
                      onTap: () { _close(); widget.onCreateAi(); },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _entry == null ? _open : _close,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}


class _AddMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label;
  final VoidCallback onTap;
  const _AddMenuItem({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D2A5E)))),
          ],
        ),
      ),
    );
  }
}

class _SortItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.check, size: 14,
                color: selected ? const Color(0xFF6144B0) : Colors.transparent),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? const Color(0xFF6144B0) : const Color(0xFF2D2A5E),
            )),
          ],
        ),
      ),
    );
  }
}