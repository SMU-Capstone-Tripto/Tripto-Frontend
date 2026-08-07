import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_model.dart';
import '../data/notification_repository.dart'; // 💡 새로 만든 레포지토리 import
import '../data/friend_repository.dart';
import 'home_provider.dart';

// ── 필터 상태 ──
final notifFilterProvider = StateProvider<NotificationType?>((ref) => null);

// ── 알림 목록 Notifier ──
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _notifRepo; // 💡 알림 레포지토리 추가
  final FriendRepository _friendRepo;
  final Ref _ref;

  NotificationNotifier(this._notifRepo, this._friendRepo, this._ref)
      : super(const AsyncLoading()) {
    loadNotifications();
  }

  // 📡 1. 서버에서 진짜 알림 목록 불러오기 (GET 연동)
  Future<void> loadNotifications() async {
    try {
      state = const AsyncLoading();

      // 백엔드 API 찔러서 데이터 가져오기
      final rawData = await _notifRepo.getNotifications();

      // JSON 데이터를 우리가 만든 UI 모델로 변환
      final notifList =
          rawData.map((json) => NotificationModel.fromJson(json)).toList();

      state = AsyncData(notifList);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── 실시간 새 알림 동기화 (웹소켓 / FCM 용) ──
  void addRealtimeNotification(NotificationModel newNoti) {
    if (state is AsyncData) {
      final currentList = state.value!;
      state = AsyncData([newNoti, ...currentList]);
    }
  }

  // 📡 2. 전체 읽음 처리 (PATCH 연동)
  Future<void> readAll() async {
    if (state is AsyncData) {
      try {
        // 서버에 전체 읽음 요청 전송
        await _notifRepo.readAllNotifications();

        // 프론트엔드 UI 업데이트
        final current = state.value!;
        state =
            AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
      } catch (e) {
        print('전체 읽음 처리 실패: $e');
      }
    }
  }

  // 📡 3. 개별 읽음 처리 (PATCH 연동)
  Future<void> read(String id) async {
    if (state is AsyncData) {
      try {
        final notiId = int.parse(id);
        // 서버에 개별 읽음 요청 전송
        await _notifRepo.readNotification(notiId);

        // 프론트엔드 UI 업데이트
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
      final friendshipId = int.parse(id);
      await _friendRepo.respondToFriendRequest(friendshipId, true);
      _ref.invalidate(friendListProvider); // 친구 목록 갱신

      // 수락 후 해당 알림 읽음 처리 및 버튼 숨기기
      read(id);
      if (state is AsyncData) {
        final current = state.value!;
        state = AsyncData(current
            .map((n) => n.id == id ? n.copyWith(hasFriendAction: false) : n)
            .toList());
      }
    } catch (e) {
      print('🚨 수락 실패: $e');
    }
  }

  // 📡 친구 요청 거절
  Future<void> declineFriend(String id) async {
    try {
      final friendshipId = int.parse(id);
      await _friendRepo.respondToFriendRequest(friendshipId, false);

      if (state is AsyncData) {
        final current = state.value!;
        state = AsyncData(current.where((n) => n.id != id).toList());
      }
    } catch (e) {
      print('🚨 거절 실패: $e');
    }
  }
}

// ── Providers ──
final notificationProvider = StateNotifierProvider<NotificationNotifier,
    AsyncValue<List<NotificationModel>>>(
  (ref) => NotificationNotifier(
      ref.watch(notificationRepositoryProvider), // 💡 레포지토리 주입
      ref.watch(friendRepositoryProvider),
      ref),
);

// ── 필터 적용된 목록
final filteredNotifProvider =
    Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final filter = ref.watch(notifFilterProvider);
  final notifsState = ref.watch(notificationProvider);

  return notifsState.whenData((notifs) {
    if (filter == null) return notifs;
    return notifs.where((n) => n.type == filter).toList();
  });
});

// ── 읽지 않은 수 (홈 벨 아이콘 뱃지용)
final unreadCountProvider = Provider<int>((ref) {
  final notifsState = ref.watch(notificationProvider);

  return notifsState.maybeWhen(
    data: (notifs) => notifs.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
