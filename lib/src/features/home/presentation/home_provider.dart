import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/friend_model.dart';

/// 다가오는 여행 Provider (더미 데이터)
export 'package:tripto/src/features/schedule/presentation/schedule_provider.dart'
    show nextTripProvider;

/// 친구 목록 Provider (더미 데이터)
/// 추후 → FutureProvider + Repository로 교체
final friendListProvider = Provider<List<FriendModel>>((ref) {
  return const [
    FriendModel(
        friend_id: 'f1',
        nikname: '이재민',
        statusMessage: '제주도 여행 함께 중',
        isOnline: true,
        avatarColor: AvatarColor.purple),
    FriendModel(
        friend_id: 'f2',
        nikname: '신진영',
        statusMessage: '최근 부산 여행',
        avatarColor: AvatarColor.pink),
    FriendModel(
        friend_id: 'f3',
        nikname: '이상원',
        statusMessage: '여행 계획 없음',
        isOnline: true,
        avatarColor: AvatarColor.teal),
    FriendModel(
        friend_id: 'f4',
        nikname: '이세은',
        statusMessage: '도쿄 여행 준비 중',
        avatarColor: AvatarColor.amber),
    FriendModel(
        friend_id: 'f5',
        nikname: '송혜주',
        statusMessage: '방콕 다녀왔어요',
        avatarColor: AvatarColor.blue),
  ];
});
