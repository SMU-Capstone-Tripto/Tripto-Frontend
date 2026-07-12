import 'friend_model.dart';

class FriendRequestModel {
  final int friendshipId; // 요청을 수락/거절할 때 쓸 고유 ID
  final String status; // "pending" 등
  final FriendModel requester; // 요청을 보낸 사람의 정보

  const FriendRequestModel({
    required this.friendshipId,
    required this.status,
    required this.requester,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      // JSON의 'friendship_id' 매핑
      friendshipId: json['friendship_id'] as int,
      status: json['status'] as String? ?? 'pending',
      // 중첩된 'requester' 객체를 기존 FriendModel.fromJson을 재활용하여 파싱!
      requester:
          FriendModel.fromJson(json['requester'] as Map<String, dynamic>),
    );
  }
}