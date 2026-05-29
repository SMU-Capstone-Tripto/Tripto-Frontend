import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_model.dart';

// 필터 상태
final notifFilterProvider =
    StateProvider<NotificationType?>((ref) => null); // null = 전체

// 알림 목록 (더미 데이터)
class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier()
      : super(const [
          NotificationModel(
            id: 'n1',
            type: NotificationType.friend,
            senderName: '이재민',
            message: '님이 친구 요청을 보냈습니다.',
            time: '방금 전',
            isRead: false,
            hasFriendAction: true,
          ),
          NotificationModel(
            id: 'n2',
            type: NotificationType.dday,
            senderName: '제주도 여행',
            message: 'D-7이에요! 준비되셨나요?',
            time: '1시간 전',
            isRead: false,
          ),
          NotificationModel(
            id: 'n3',
            type: NotificationType.chat,
            senderName: '제주도 가장',
            message: '채팅방에 새 메시지 3개가 있습니다.',
            time: '2시간 전',
            isRead: false,
          ),
          NotificationModel(
            id: 'n4',
            type: NotificationType.trip,
            senderName: '부산 바다 여행',
            message: '이 종료되었습니다. 즐거운 여행이었나요?',
            time: '어제 오후 6:00',
            isRead: true,
          ),
          NotificationModel(
            id: 'n5',
            type: NotificationType.friend,
            senderName: '신진영',
            message: '님이 친구 요청을 수락했습니다.',
            time: '어제 오후 2:30',
            isRead: true,
          ),
          NotificationModel(
            id: 'n6',
            type: NotificationType.chat,
            senderName: 'AI 챗봇',
            message: '이 메시지를 보냈습니다.',
            time: '어제 오전 11:20',
            isRead: true,
          ),
          NotificationModel(
            id: 'n7',
            type: NotificationType.dday,
            senderName: '제주도 여행',
            message: 'D-14 알림입니다.',
            time: '2025.02.02',
            isRead: true,
          ),
          NotificationModel(
            id: 'n8',
            type: NotificationType.trip,
            senderName: '강릉 겨울 바다 여행',
            message: '이 시작되었습니다!',
            time: '2025.12.14',
            isRead: true,
          ),
        ]);

  // 전체 읽음
  void readAll() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  // 개별 읽음
  void read(String id) {
    state =
        state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  // 친구 요청 수락
  void acceptFriend(String id) {
    state = state
        .map((n) =>
            n.id == id ? n.copyWith(isRead: true, hasFriendAction: false) : n)
        .toList();
  }

  // 친구 요청 거절 (알림 삭제)
  void declineFriend(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  // 읽지 않은 알림 수
  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationModel>>(
  (ref) => NotificationNotifier(),
);

// 필터 적용된 목록
final filteredNotifProvider = Provider<List<NotificationModel>>((ref) {
  final filter = ref.watch(notifFilterProvider);
  final notifs = ref.watch(notificationProvider);
  if (filter == null) return notifs;
  return notifs.where((n) => n.type == filter).toList();
});

// 읽지 않은 수 (홈 벨 아이콘 뱃지용)
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).where((n) => !n.isRead).length;
});
