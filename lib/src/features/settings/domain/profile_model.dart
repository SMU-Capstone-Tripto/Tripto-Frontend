class ProfileModel {
  final int userId;
  final String uniqueId;
  final String email;
  final String nickname;
  final String? profileImage; // 🎯 백엔드 필드명: profile_image
  final List<String> tags;

  const ProfileModel({
    required this.userId,
    required this.uniqueId,
    required this.email,
    required this.nickname,
    this.profileImage,
    this.tags = const [],
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        userId: json['user_id'] as int? ?? 0,
        uniqueId: json['unique_id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '여행자',
        profileImage: json['profile_image'] as String?, // 🎯 profile_image 바인딩
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}