import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/friend_model.dart';
import '../data/friend_repository.dart';

export 'package:tripto/src/features/schedule/presentation/schedule_provider.dart'
    show nextTripProvider;

// ── API 통신과 UI 상태 관리를 하나로 통합한 Notifier ──
class FriendNotifier extends StateNotifier<AsyncValue<List<FriendModel>>> {
  final FriendRepository _repository;

  // 생성되자마자 스켈레톤 로딩(AsyncLoading)을 띄우고 서버에서 친구 목록을 불러옵니다.
  FriendNotifier(this._repository) : super(const AsyncLoading()) {
    loadFriends();
  }

  // 1. 친구 목록 조회 (GET)
  Future<void> loadFriends() async {
    try {
      state = const AsyncLoading();
      final friends = await _repository.getFriends();
      state = AsyncData(friends); // 로딩 끝, 데이터 표시
    } catch (e, st) {
      state = AsyncError(e, st); // 에러 발생 시 Error 위젯 띄움
    }
  }

  // 2. 친구 삭제 (DELETE)
  Future<void> removeFriend(String id) async {
    try {
      // 1) 백엔드 서버에 삭제 API 전송 (Repository에 메서드가 있어야 합니다)
      await _repository.deleteFriend(id);

      // 2) 성공하면 서버 재요청 없이 현재 UI 리스트에서 해당 친구만 즉시 제거 (자연스러운 UX)
      if (state is AsyncData) {
        final currentList = state.value!;
        state = AsyncData(currentList.where((f) => f.friend_id != id).toList());
      }
    } catch (e) {
      // 나중에 스낵바(토스트 메시지)로 에러를 알릴 수 있습니다.
      print('🚨 친구 삭제 실패: $e');
    }
  }

  // 3. 친구 추가 (POST) - 나중에 친구 추가 화면에서 사용할 메서드
  Future<void> addFriend(String targetUniqueId) async {
    try {
      await _repository.addFriend(targetUniqueId);
      // 추가 성공 시, 새로고침 느낌으로 목록 전체를 다시 불러옵니다.
      await loadFriends();
    } catch (e) {
      print('🚨 친구 추가 실패: $e');
      rethrow; // UI에서 에러 메시지를 띄우기 위해 던짐
    }
  }
}

// ── UI에서 접근할 단일 Provider ──
// 기존에 나뉘어 있던 friendProvider와 friendListProvider를 하나로 합쳤습니다.
final friendListProvider =
    StateNotifierProvider<FriendNotifier, AsyncValue<List<FriendModel>>>(
  (ref) => FriendNotifier(ref.watch(friendRepositoryProvider)),
);
