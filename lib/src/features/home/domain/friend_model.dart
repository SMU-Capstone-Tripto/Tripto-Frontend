/// 아바타 색상 종류
enum AvatarColor { purple, pink, teal, amber, blue }

/// 친구 도메인 모델
class FriendModel {
  final int friendId; // 친구 관계 ID
  final String uniqueId;
  final String nickname;
  final String statusMessage;
  final AvatarColor avatarColor;

  const FriendModel({
    required this.friendId,
    required this.uniqueId,
    required this.nickname,
    required this.statusMessage,
    required this.avatarColor,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    // 'user' 객체가 있다면 그 안의 내용을, 없다면 json 전체를 사용
    final data =
        json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;

    return FriendModel(
      friendId: (data['friend_id'] as num ?? 0).toInt(),
      uniqueId: (data['friend_unique_id'] ?? '').toString(),
      nickname: (data['nickname'] ?? '이름 없음').toString(),
      statusMessage: (data['status_message'] ?? '').toString(),
      avatarColor: AvatarColor.purple, // 필요한 경우 data['avatar_color']로 매핑
    );
  }

  /// 아바타에 표시할 이름 앞 두 글자
  String get avatarLabel =>
      nickname.length >= 2 ? nickname.substring(0, 2) : nickname;
}
