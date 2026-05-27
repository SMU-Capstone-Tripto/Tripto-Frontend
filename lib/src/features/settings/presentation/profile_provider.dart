
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripto/src/features/settings/domain/profile_model.dart';

// 더미 데이터 - 추후 API로 교체
final profileProvider = Provider<ProfileModel>((ref) {
  return const ProfileModel(
    nikname: '나여행',
    unique_id: 'traveljangjiang123',
  );
});