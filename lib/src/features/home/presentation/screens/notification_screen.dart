// lib/src/features/notification/presentation/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/constants/app_theme.dart';
import 'package:tripto/src/features/home/domain/notification_model.dart';
import 'package:tripto/src/features/home/presentation/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 이제 notifs는 AsyncValue<List<NotificationModel>> 타입입니다.
    final notifsAsync = ref.watch(filteredNotifProvider);
    final filter = ref.watch(notifFilterProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 앱바 ──
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 12, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('알림',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2939))),
                ),
                TextButton(
                  onPressed: notifier.readAll,
                  child: const Text('모두 읽음',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),

          // ── 필터 탭 ──
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  // 전체
                  _FilterChip(
                    label: '전체',
                    active: filter == null,
                    onTap: () =>
                        ref.read(notifFilterProvider.notifier).state = null,
                  ),
                  // 타입별 (enum values 순회)
                  ...NotificationType.values.map((t) => _FilterChip(
                        label: t.label, // NotificationType 확장에 label이 있다고 가정
                        active: filter == t,
                        onTap: () =>
                            ref.read(notifFilterProvider.notifier).state = t,
                      )),
                ],
              ),
            ),
          ),

          // ── 알림 목록 (AsyncValue 상태 처리) ──
          Expanded(
            child: notifsAsync.when(
              // 1. 로딩 중일 때
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              // 2. 에러가 났을 때
              error: (err, st) => Center(
                child: Text('알림을 불러오지 못했습니다.\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              // 3. 데이터를 성공적으로 받아왔을 때
              data: (notifs) {
                if (notifs.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.separated(
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: Color(0xFFF0EEFF), indent: 20),
                  itemBuilder: (_, i) => _NotifItem(
                    notif: notifs[i],
                    onTap: () => notifier.read(notifs[i].id),
                    // 💡 API와 연결된 프로바이더의 함수 호출!
                    onAccept: () => notifier.acceptFriend(notifs[i].id),
                    onDecline: () => notifier.declineFriend(notifs[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 필터 칩 ──
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
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary,
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

  // 타입별 아이콘/색상
  static const _configs = {
    NotificationType.friendRequest: _Config(
        Icons.person_add_outlined, Color(0xFFEDE9FF), Color(0xFF6144B0)),
    NotificationType.dday: _Config(
        Icons.calendar_today_outlined, Color(0xFFFFF0F0), Color(0xFFD93030)),
    NotificationType.chat: _Config(
        Icons.chat_bubble_outline, Color(0xFFE6F1FB), Color(0xFF185FA5)),
    NotificationType.trip:
        _Config(Icons.flight_outlined, Color(0xFFE1F5EE), Color(0xFF0F6E56)),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _configs[notif.type]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color:
            notif.isRead ? Colors.white : AppColors.primary.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 읽지 않음 점
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 18, right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notif.isRead ? Colors.transparent : AppColors.primary,
              ),
            ),

            // 아이콘
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(color: cfg.bgColor, shape: BoxShape.circle),
              child: Icon(cfg.icon, size: 20, color: cfg.color),
            ),
            const SizedBox(width: 12),

            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 메시지 (이름 굵게)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF1E2939),
                        fontWeight:
                            notif.isRead ? FontWeight.w400 : FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                            text: notif.senderName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: notif.message),
                      ],
                    ),
                  ),

                  // 친구 요청 버튼
                  if (notif.hasFriendAction)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          _ActionBtn(
                              label: '수락', primary: true, onTap: onAccept),
                          const SizedBox(width: 6),
                          _ActionBtn(
                              label: '거절', primary: false, onTap: onDecline),
                        ],
                      ),
                    ),

                  const SizedBox(height: 4),
                  Text(notif.time,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}

// 빈 상태
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('알림이 없습니다',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
