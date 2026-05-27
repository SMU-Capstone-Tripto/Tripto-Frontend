
class ProfileModel {
  final String nikname;
  final String unique_id;
  final String? avatarUrl;

  const ProfileModel({
    required this.nikname,
    required this.unique_id,
    this.avatarUrl,
  });
}