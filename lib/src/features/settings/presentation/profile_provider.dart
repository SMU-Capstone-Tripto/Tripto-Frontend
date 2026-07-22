import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/profile_model.dart';
import '../data/profile_repository.dart';
import '../data/image_upload_service.dart';

final profileProvider = FutureProvider<ProfileModel>((ref) async {
  return ref.watch(profileRepositoryProvider).getMe();
});

class ProfileImageNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileImageNotifier(this._repository, this._ref)
      : super(const AsyncData(null));

  Future<void> updateProfileImage() async {
    state = const AsyncLoading();

    try {
      // 1. 갤러리 이미지 선택 & 크롭
      final file = await ImageUploadService.pickAndCropImage();
      if (file == null) {
        state = const AsyncData(null);
        return;
      }
      debugPrint('📸 이미지 선택/크롭 완료: ${file.path}');

      // 2. Presigned URL 발급 요청
      final urls = await _repository.getPresignedUrl();
      
      // 🎯 [핵심 수정]: ! 연산자 대신 null-safe 처리
      final String uploadUrl = urls?['uploadUrl'] ?? '';
      final String imageUrl = urls?['imageUrl'] ?? '';

      if (uploadUrl.isEmpty || imageUrl.isEmpty) {
        throw Exception('Presigned URL 또는 이미지 URL 생성 실패');
      }
      debugPrint('🔗 Presigned URL 발급 성공: $uploadUrl');

      // 3. S3 직접 업로드 (PUT)
      final isUploaded = await ImageUploadService.uploadToS3(
        presignedUrl: uploadUrl,
        imageFile: file,
      );
      if (!isUploaded) throw Exception('S3 직접 업로드(PUT) 실패');
      debugPrint('☁️ S3 이미지 업로드 완료!');

      // 4. DB에 최종 이미지 URL 업데이트
      await _repository.updateMe(profileImage: imageUrl);
      debugPrint('💾 프로필 DB URL 업데이트 완료!');

      // 5. 화면 캐시 강제 무효화로 UI 갱신
      _ref.invalidate(profileProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      debugPrint('🚨 프로필 사진 변경 실패 상세: $e');
      state = AsyncError(e, st);
    }
  }
}

final profileImageControllerProvider =
    StateNotifierProvider<ProfileImageNotifier, AsyncValue<void>>((ref) {
  return ProfileImageNotifier(ref.watch(profileRepositoryProvider), ref);
});