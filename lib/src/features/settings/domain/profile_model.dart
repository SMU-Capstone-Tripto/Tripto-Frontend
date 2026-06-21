class ProfileModel {
  final String nikname;
  final String unique_id;
  final String? profile_image_url;

  const ProfileModel({
    required this.nikname,
    required this.unique_id,
    this.profile_image_url,
  });

  // 💡 백엔드 응답을 안전하게 파싱하도록 보완
  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        nikname: json['nikname'] as String? ?? '여행자', // 닉네임이 없으면 '여행자'
        unique_id: json['unique_id'] as String? ?? '', // ID가 없으면 빈 문자열
        profile_image_url:
            json['profile_image_url'] as String?, // 프로필 이미지 URL은 null 허용
      );
}
