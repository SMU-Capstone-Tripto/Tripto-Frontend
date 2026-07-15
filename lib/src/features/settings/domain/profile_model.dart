class ProfileModel {
  final String nickname;
  final String unique_id;
  final String email;
  final String? profile_image_url;
  final String? avatarUrl;

  const ProfileModel({
    required this.nickname,
    required this.unique_id,
    required this.email,
    this.profile_image_url,
    this.avatarUrl,
  });

  // 💡 백엔드 응답을 안전하게 파싱하도록 보완
  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        nickname: json['nickname'] as String? ?? '여행자', // 닉네임이 없으면 '여행자'
        unique_id: json['unique_id'] as String? ?? '', // ID가 없으면 빈 문자열
        email: json['email'] as String? ?? '',
        profile_image_url:
            json['profile_image_url'] as String?, // 프로필 이미지 URL은 null 허용
        avatarUrl: json['avatarUrl'] as String?, // 아바타 URL은 null 허용
      );
}
