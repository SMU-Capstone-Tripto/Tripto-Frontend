import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_model.dart';
import '../data/friend_repository.dart';
import 'home_provider.dart';

// ── 필터 상태 ──
final notifFilterProvider =
    StateProvider<NotificationType?>((ref) => null); // null = 전체

// ── 알림 목록 ──
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final FriendRepository _repository;
  final Ref _ref;

  NotificationNotifier(this._repository, this._ref)
      : super(const AsyncLoading()) {
    loadNotifications();
  }

  // 📡 서버에서 알림 불러오기
  Future<void> loadNotifications() async {
    try {
      state = const AsyncLoading();

      // 1. 서버에서 받은 친구 요청 목록 가져오기
      final requests = await _repository.getReceivedRequests();

      // 2. 서버 모델(FriendRequestModel)을 UI 모델(NotificationModel)로 변환!
      final notifList = requests.map((req) {
        return NotificationModel(
          id: req.friendshipId.toString(),
          // 💡 수정: friendRequest 대신 기존에 만들어두신 friend 사용
          type: NotificationType.friendRequest,
          title: '친구 요청',
          message: '${req.requester.nickname}님이 친구 요청을 보냈습니다.',
          isRead: false,
          hasFriendAction: req.status == 'pending', senderName: '', time: '',
        );
      }).toList();

      state = AsyncData(notifList);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // 전체 읽음 (로컬 상태만 변경하거나, 추후 전체 읽음 API 추가)
  void readAll() {
    if (state is AsyncData) {
      final current = state.value!;
      state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
    }
  }

  // 개별 읽음
  void read(String id) {
    if (state is AsyncData) {
      final current = state.value!;
      state = AsyncData(current
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList());
    }
  }

  // 📡 친구 요청 수락
  Future<void> acceptFriend(String id) async {
    try {
      // 1. 백엔드에 수락 요청 (id를 다시 int로 변환)
      final friendshipId = int.parse(id);
      await _repository.respondToFriendRequest(friendshipId, true);

      _ref.invalidate(friendListProvider); // 친구 목록 갱신

      // 2. UI 즉시 업데이트
      if (state is AsyncData) {
        final current = state.value!;
        state = AsyncData(current
            .map((n) => n.id == id
                ? n.copyWith(isRead: true, hasFriendAction: false)
                : n)
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
      await _repository.respondToFriendRequest(friendshipId, false);

      // 삭제 시 리스트에서 완전히 제거
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
  (ref) => NotificationNotifier(ref.watch(friendRepositoryProvider), ref),
);

// ── 필터 적용된 목록 (AsyncValue 대응) ──
final filteredNotifProvider =
    Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final filter = ref.watch(notifFilterProvider);
  final notifsState = ref.watch(notificationProvider);

  // 데이터가 있을 때만 필터링 수행
  return notifsState.whenData((notifs) {
    if (filter == null) return notifs;
    return notifs.where((n) => n.type == filter).toList();
  });
});

// ── 읽지 않은 수 (홈 벨 아이콘 뱃지용, AsyncValue 대응) ──
final unreadCountProvider = Provider<int>((ref) {
  final notifsState = ref.watch(notificationProvider);

  // 데이터가 로딩/에러일 때는 뱃지를 0으로 표시
  return notifsState.maybeWhen(
    data: (notifs) => notifs.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
