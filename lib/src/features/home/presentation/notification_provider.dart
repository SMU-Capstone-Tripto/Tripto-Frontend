import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_model.dart';
import '../data/friend_repository.dart';
import 'home_provider.dart';

// ── 필터 상태 ──
final notifFilterProvider =
    StateProvider<NotificationType?>((ref) => null); // null = 전체[cite: 8]

// ── 알림 목록 ──
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final FriendRepository _repository; //[cite: 8]
  final Ref _ref; //[cite: 8]

  NotificationNotifier(this._repository, this._ref)
      : super(const AsyncLoading()) {
    loadNotifications(); //[cite: 8]
  }

  // 📡 서버에서 알림 불러오기
  Future<void> loadNotifications() async {
    try {
      state = const AsyncLoading(); //[cite: 8]

      // 1. 서버에서 받은 친구 요청 목록 가져오기[cite: 8]
      final requests = await _repository.getReceivedRequests(); //[cite: 8]

      // 2. 서버 모델을 UI 모델로 변환[cite: 8]
      final notifList = requests.map((req) {
        return NotificationModel(
          id: req.friendshipId.toString(), //[cite: 8]
          type: NotificationType.friendRequest, //[cite: 8]
          title: '친구 요청', //[cite: 8]
          message: '${req.requester.nickname}님이 친구 요청을 보냈습니다.', //[cite: 8]
          isRead: false, //[cite: 8]
          hasFriendAction: req.status == 'pending', //[cite: 8]

          // 💡 수정: 빈 문자열이었던 부분을 실제 데이터로 채웠습니다.[cite: 8]
          senderName: req.requester.nickname,
          time: '방금 전', // TODO: 실제 서버의 시간 데이터(created_at)를 가공해서 넣어야 합니다.
        );
      }).toList(); //[cite: 8]

      // 💡 추후 여기에 채팅 알림 API와 일정 알림 API 결과를 합쳐서 notifList에 더해주시면 됩니다.

      state = AsyncData(notifList); //[cite: 8]
    } catch (e, st) {
      state = AsyncError(e, st); //[cite: 8]
    }
  }

  // ── 💡 새로 추가: 실시간 새 알림 동기화 (웹소켓 / FCM 용) ──
  void addRealtimeNotification(NotificationModel newNoti) {
    if (state is AsyncData) {
      final currentList = state.value!;
      // 기존 리스트 맨 앞에 새 알림을 추가하여 즉시 UI와 빨간 점(Badge)을 갱신합니다.
      state = AsyncData([newNoti, ...currentList]);
    }
  }

  // 전체 읽음[cite: 8]
  void readAll() {
    if (state is AsyncData) {
      //[cite: 8]
      final current = state.value!; //[cite: 8]
      state = AsyncData(
          current.map((n) => n.copyWith(isRead: true)).toList()); //[cite: 8]
    }
  }

  // 개별 읽음[cite: 8]
  void read(String id) {
    if (state is AsyncData) {
      //[cite: 8]
      final current = state.value!; //[cite: 8]
      state = AsyncData(current
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n) //[cite: 8]
          .toList()); //[cite: 8]
    }
  }

  // 📡 친구 요청 수락[cite: 8]
  Future<void> acceptFriend(String id) async {
    try {
      final friendshipId = int.parse(id); //[cite: 8]
      await _repository.respondToFriendRequest(friendshipId, true); //[cite: 8]

      _ref.invalidate(friendListProvider); // 친구 목록 갱신[cite: 8]

      if (state is AsyncData) {
        //[cite: 8]
        final current = state.value!; //[cite: 8]
        state = AsyncData(current
            .map((n) => n.id == id
                ? n.copyWith(isRead: true, hasFriendAction: false) //[cite: 8]
                : n) //[cite: 8]
            .toList()); //[cite: 8]
      }
    } catch (e) {
      print('🚨 수락 실패: $e'); //[cite: 8]
    }
  }

  // 📡 친구 요청 거절[cite: 8]
  Future<void> declineFriend(String id) async {
    try {
      final friendshipId = int.parse(id); //[cite: 8]
      await _repository.respondToFriendRequest(friendshipId, false); //[cite: 8]

      if (state is AsyncData) {
        //[cite: 8]
        final current = state.value!; //[cite: 8]
        state =
            AsyncData(current.where((n) => n.id != id).toList()); //[cite: 8]
      }
    } catch (e) {
      print('🚨 거절 실패: $e'); //[cite: 8]
    }
  }
}

// ── Providers ──

final notificationProvider = StateNotifierProvider<NotificationNotifier,
    AsyncValue<List<NotificationModel>>>(
  (ref) => NotificationNotifier(
      ref.watch(friendRepositoryProvider), ref), //[cite: 8]
); //[cite: 8]

// ── 필터 적용된 목록[cite: 8]
final filteredNotifProvider =
    Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final filter = ref.watch(notifFilterProvider); //[cite: 8]
  final notifsState = ref.watch(notificationProvider); //[cite: 8]

  return notifsState.whenData((notifs) {
    //[cite: 8]
    if (filter == null) return notifs; //[cite: 8]
    return notifs.where((n) => n.type == filter).toList(); //[cite: 8]
  }); //[cite: 8]
}); //[cite: 8]

// ── 읽지 않은 수 (홈 벨 아이콘 뱃지용)[cite: 8]
final unreadCountProvider = Provider<int>((ref) {
  final notifsState = ref.watch(notificationProvider); //[cite: 8]

  return notifsState.maybeWhen(
    //[cite: 8]
    data: (notifs) => notifs.where((n) => !n.isRead).length, //[cite: 8]
    orElse: () => 0, //[cite: 8]
  ); //[cite: 8]
}); //[cite: 8]
