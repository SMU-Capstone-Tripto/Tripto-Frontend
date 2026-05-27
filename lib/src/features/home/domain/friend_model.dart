/// 아바타 색상 종류
enum AvatarColor { purple, pink, teal, amber, blue }

/// 친구 도메인 모델
class FriendModel {
  final String friend_id;
  final String nikname;
  final String statusMessage;
  final bool isOnline;
  final AvatarColor avatarColor;

  const FriendModel({
    required this.friend_id,
    required this.nikname,
    required this.statusMessage,
    this.isOnline = false,
    required this.avatarColor,
  });

  /// 아바타에 표시할 이름 앞 두 글자
  String get avatarLabel =>
      nikname.length >= 2 ? nikname.substring(0, 2) : nikname;
}
