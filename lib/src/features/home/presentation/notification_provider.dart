import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_model.dart';
import '../data/notification_repository.dart';
import '../data/friend_repository.dart';
import 'home_provider.dart';

// ── 필터 상태 (클래스 밖) ──
final notifFilterProvider = StateProvider<NotificationType?>((ref) => null);

// ── 알림 목록 Notifier ──
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _notifRepo;
  final FriendRepository _friendRepo;
  final Ref _ref;

  NotificationNotifier(this._notifRepo, this._friendRepo, this._ref)
      : super(const AsyncLoading()) {
    loadNotifications();
  }

  // 1. 서버에서 진짜 알림 목록 불러오기
  Future<void> loadNotifications() async {
    try {
      state = const AsyncLoading();
      final rawData = await _notifRepo.getNotifications();

      final notifList = rawData
          .map((json) => NotificationModel.fromJson(json))
          // 💡 핵심 1: 서버에서 데이터를 가져올 때, '이미 읽음(처리 완료)' 상태인 친구 요청 알림은 아예 목록에서 제거합니다!
          .where((noti) {
        if (noti.type == NotificationType.friendRequest && noti.isRead) {
          return false;
        }
        return true;
      }).toList();

      state = AsyncData(notifList);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // 실시간 새 알림 동기화
  void addRealtimeNotification(NotificationModel newNoti) {
    if (state is AsyncData) {
      final currentList = state.value!;
      state = AsyncData([newNoti, ...currentList]);
    }
  }

  // 2. 전체 읽음 처리
  Future<void> readAll() async {
    if (state is AsyncData) {
      try {
        await _notifRepo.readAllNotifications();
        final current = state.value!;
        state =
            AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
      } catch (e) {
        print('전체 읽음 처리 실패: $e');
      }
    }
  }

  // 3. 개별 읽음 처리
  Future<void> read(String id) async {
    if (state is AsyncData) {
      try {
        final notiId = int.parse(id);
        await _notifRepo.readNotification(notiId);
        final current = state.value!;
        state = AsyncData(current
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList());
      } catch (e) {
        print('개별 읽음 처리 실패: $e');
      }
    }
  }

  // 📡 친구 요청 수락
  Future<void> acceptFriend(String id) async {
    try {
      final notiId = int.parse(id);

      // 💡 핵심 2: 수락 시 서버에 "이 알림 처리했으니 읽음으로 바꿔줘!" 라고 못박아둡니다.
      await _notifRepo.readNotification(notiId);

      await _friendRepo.respondToFriendRequest(notiId, true);
      _ref.invalidate(friendListProvider); // 친구 목록 갱신
    } catch (e) {
      print('🚨 이미 처리된 옛날 요청이라 서버에서 에러 발생: $e');
    } finally {
      if (state is AsyncData) {
        final current = state.value!;
        state = AsyncData(current.where((n) => n.id != id).toList());
      }
    }
  }

  // 📡 친구 요청 거절
  Future<void> declineFriend(String id) async {
    try {
      final notiId = int.parse(id);

      // 💡 핵심 2: 거절 시에도 서버에 "이 알림 처리했으니 읽음으로 바꿔줘!" 라고 못박아둡니다.
      await _notifRepo.readNotification(notiId);

      await _friendRepo.respondToFriendRequest(notiId, false);
    } catch (e) {
      print('🚨 이미 처리된 옛날 요청이라 서버에서 에러 발생: $e');
    } finally {
      if (state is AsyncData) {
        final current = state.value!;
        state = AsyncData(current.where((n) => n.id != id).toList());
      }
    }
  }
}

// ── Providers ──

final notificationProvider = StateNotifierProvider<NotificationNotifier,
    AsyncValue<List<NotificationModel>>>(
  (ref) => NotificationNotifier(ref.watch(notificationRepositoryProvider),
      ref.watch(friendRepositoryProvider), ref),
);

final filteredNotifProvider =
    Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final filter = ref.watch(notifFilterProvider);
  final notifsState = ref.watch(notificationProvider);

  return notifsState.whenData((notifs) {
    if (filter == null) return notifs;
    return notifs.where((n) => n.type == filter).toList();
  });
});

final unreadCountProvider = Provider<int>((ref) {
  final notifsState = ref.watch(notificationProvider);

  return notifsState.maybeWhen(
    data: (notifs) => notifs.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
