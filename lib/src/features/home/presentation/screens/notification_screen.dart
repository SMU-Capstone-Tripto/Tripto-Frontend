// lib/src/features/notification/presentation/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // 💡 GoRouter 추가
import 'package:tripto/src/constants/app_theme.dart';
import 'package:tripto/src/features/home/domain/notification_model.dart';
import '../notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(filteredNotifProvider);
    final filter = ref.watch(notifFilterProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5FA),
      body: Column(
        children: [
          // ── 그라데이션 헤더 ──
          Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8A6BFF), Color(0xFF6144B0)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('알림',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                    GestureDetector(
                      onTap: notifier.readAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('모두 읽음',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: '전체',
                        active: filter == null,
                        onTap: () =>
                            ref.read(notifFilterProvider.notifier).state = null,
                      ),
                      ...NotificationType.values.map((t) => _FilterChip(
                            label: t.label,
                            active: filter == t,
                            onTap: () => ref
                                .read(notifFilterProvider.notifier)
                                .state = t,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 알림 목록 ──
          Expanded(
            child: notifsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, st) => Center(child: Text('오류 발생:\n$err')),
              data: (notifs) {
                if (notifs.isEmpty) return const _EmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 40),
                  itemCount: notifs.length,
                  itemBuilder: (_, i) {
                    final notif = notifs[i];
                    return _NotifItem(
                      notif: notif,
                      onTap: () {
                        // 💡 3단계: 읽음 처리 후 화면 이동
                        notifier.read(notif.id);

                        switch (notif.type) {
                          case NotificationType.friendRequest:
                            // 친구 요청은 해당 카드에서 버튼으로 처리하므로 패스
                            break;
                          case NotificationType.chat:
                            context.go('/chat'); // 채팅 탭으로 슝!
                            break;
                          case NotificationType.schedule:
                            context.go('/schedule'); // 일정 탭으로 슝!
                            break;
                        }
                      },
                      onAccept: () => notifier.acceptFriend(notif.id),
                      onDecline: () => notifier.declineFriend(notif.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 반투명 필터 칩 ──
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.primary : Colors.white.withOpacity(0.8),
            )),
      ),
    );
  }
}

// ── 알림 아이템 ──
class _NotifItem extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _NotifItem(
      {required this.notif,
      required this.onTap,
      required this.onAccept,
      required this.onDecline});

  static const _configs = {
    NotificationType.friendRequest: _Config(
        Icons.person_add_outlined, Color(0xFFEDE9FF), Color(0xFF6144B0)),
    NotificationType.chat: _Config(
        Icons.chat_bubble_outline, Color(0xFFE6F1FB), Color(0xFF185FA5)),
    NotificationType.schedule: _Config(
        Icons.event_note_outlined, Color(0xFFE1F5EE), Color(0xFF0F6E56)),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _configs[notif.type]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white.withOpacity(0.6) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: notif.isRead
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF6144B0).withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 18, right: 8),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notif.isRead ? Colors.transparent : AppColors.primary),
            ),
            Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(color: cfg.bgColor, shape: BoxShape.circle),
              child: Icon(cfg.icon, size: 20, color: cfg.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF1E2939),
                          fontWeight:
                              notif.isRead ? FontWeight.w500 : FontWeight.w700),
                      children: [
                        TextSpan(
                            text: notif.senderName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        TextSpan(text: ' ${notif.message}'),
                      ],
                    ),
                  ),
                  if (notif.hasFriendAction)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          _ActionBtn(
                              label: '수락', primary: true, onTap: onAccept),
                          const SizedBox(width: 8),
                          _ActionBtn(
                              label: '거절', primary: false, onTap: onDecline),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(notif.time,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFC0BBDE))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary ? Colors.white : AppColors.primary)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 48, color: Color(0xFFC0BBDE)),
          SizedBox(height: 12),
          Text('알림이 없습니다',
              style: TextStyle(fontSize: 14, color: Color(0xFFC0BBDE))),
        ],
      ),
    );
  }
}

class _Config {
  final IconData icon;
  final Color bgColor, color;
  const _Config(this.icon, this.bgColor, this.color);
}
