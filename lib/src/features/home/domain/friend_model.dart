/// 아바타 색상 종류
enum AvatarColor { purple, pink, teal, amber, blue }

/// 친구 도메인 모델
class FriendModel {
<<<<<<< HEAD
  final int friendId; // 친구 관계 ID
=======
>>>>>>> origin/chatting
  final String uniqueId;
  final String nickname;
  final String statusMessage;
  final AvatarColor avatarColor;

  const FriendModel({
<<<<<<< HEAD
    required this.friendId,
=======
>>>>>>> origin/chatting
    required this.uniqueId,
    required this.nickname,
    required this.statusMessage,
    required this.avatarColor,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
<<<<<<< HEAD
    // 'user' 객체가 있다면 그 안의 내용을, 없다면 json 전체를 사용
    final data =
        json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;

    return FriendModel(
      friendId: (data['friend_id'] as num ?? 0).toInt(),
      uniqueId: (data['friend_unique_id'] ?? '').toString(),
      nickname: (data['nickname'] ?? '이름 없음').toString(),
      statusMessage: (data['status_message'] ?? '').toString(),
      avatarColor: AvatarColor.purple, // 필요한 경우 data['avatar_color']로 매핑
=======
    // 💡 1. 먼저 'user' 객체를 안전하게 꺼내옵니다.
    // 만약 서버 구조가 달라서 'user'가 없다면, 기존 json을 그대로 사용하도록 방어 코드를 짭니다.
    final userJson = json['user'] as Map<String, dynamic>? ?? json;

    // status_message가 null로 올 수 있으므로 안전하게 처리
    String parsedStatus = '';
    final statusRaw = userJson['status_message'];

    if (statusRaw is String) {
      parsedStatus = statusRaw;
    } else if (statusRaw is List && statusRaw.isNotEmpty) {
      parsedStatus = statusRaw.first.toString();
    }

    return FriendModel(
      // 💡 2. 꺼내온 userJson 안에서 실제 정보들을 매핑합니다.
      uniqueId: userJson['friend_unique_id'] as String? ?? '',
      nickname: userJson['nickname'] as String? ?? '이름 없음',
      statusMessage: parsedStatus,
      avatarColor: AvatarColor.purple, // (추후 백엔드의 avatar_color 값으로 매핑 로직 추가 가능)
>>>>>>> origin/chatting
    );
  }

  /// 아바타에 표시할 이름 앞 두 글자
  String get avatarLabel =>
      nickname.length >= 2 ? nickname.substring(0, 2) : nickname;
<<<<<<< HEAD
}
=======
}
>>>>>>> origin/chatting
