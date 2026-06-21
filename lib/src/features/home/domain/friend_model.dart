/// 아바타 색상 종류
enum AvatarColor { purple, pink, teal, amber, blue }

/// 친구 도메인 모델
class FriendModel {
  final String friend_id;
  final String nikname;
  final String statusMessage;
  final AvatarColor avatarColor;

  const FriendModel({
    required this.friend_id,
    required this.nikname,
    required this.statusMessage,
    required this.avatarColor,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    // 💡 백엔드에서 배열로 올 경우를 대비한 안전한 파싱 로직
    String parsedStatus = '';
    final statusRaw = json['status_message'];

    if (statusRaw is String) {
      parsedStatus = statusRaw; // 정상적인 문자열일 경우
    } else if (statusRaw is List && statusRaw.isNotEmpty) {
      parsedStatus = statusRaw.first.toString(); // 배열로 올 경우 첫 번째 값 사용
    }

    return FriendModel(
      friend_id: json['friend_id'] as String,
      nikname: json['nikname'] as String,
      statusMessage: parsedStatus,
      avatarColor: AvatarColor.purple, // 서버에 없으면 기본값
    );
  }

  /// 아바타에 표시할 이름 앞 두 글자
  String get avatarLabel =>
      nikname.length >= 2 ? nikname.substring(0, 2) : nikname;
}
