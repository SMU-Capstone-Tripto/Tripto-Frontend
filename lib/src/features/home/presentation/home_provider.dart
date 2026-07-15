import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/friend_model.dart';
import '../data/friend_repository.dart';
export 'package:tripto/src/features/schedule/presentation/schedule_provider.dart'
    show nextTripProvider;

// ── API 통신과 UI 상태 관리를 하나로 통합한 Notifier ──
class FriendNotifier extends AsyncNotifier<List<FriendModel>> {
  // build 메서드가 기존의 생성자 + loadFriends() 역할을 합니다.
  @override
  Future<List<FriendModel>> build() async {
    final repository = ref.watch(friendRepositoryProvider);
    // return하는 순간 알아서 AsyncLoading을 거쳐 AsyncData 또는 AsyncError로 상태를 변환합니다.
    return repository.getFriends();
  }

  // 2. 친구 삭제 (DELETE)
  Future<void> removeFriend(int friendshipId) async {
    // 파라미터 타입 변경
    try {
      final repository = ref.read(friendRepositoryProvider);
      await repository.deleteFriend(friendshipId); // 이제 숫자가 전달됨

      if (state.hasValue) {
        final currentList = state.value!;
        // uniqueId 대신 friendId로 비교하도록 변경
        state = AsyncData(
            currentList.where((f) => f.friendshipId != friendshipId).toList());
      }
    } catch (e) {
      rethrow;
    }
  }

  // 3. 친구 추가 (POST)
  Future<void> addFriend(String targetUniqueId) async {
    try {
      final repository = ref.read(friendRepositoryProvider);
      await repository.addFriend(targetUniqueId);

      // ref.invalidateSelf()를 호출하면 build() 함수를 다시 실행하여
      // 서버에서 최신 목록을 아주 깔끔하게 다시 불러옵니다.
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }
}

// ── Provider ──
final friendListProvider =
    AsyncNotifierProvider<FriendNotifier, List<FriendModel>>(
  () => FriendNotifier(),
);

// ── 친구 검색 Provider ──
final friendSearchProvider = FutureProvider.autoDispose
    .family<FriendModel?, String>((ref, uniqueId) async {
  final repository = ref.watch(friendRepositoryProvider);
  return repository.searchUserByUniqueId(uniqueId);
});
