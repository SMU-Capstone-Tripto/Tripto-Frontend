import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/profile_model.dart';
import '../data/profile_repository.dart';
import '../data/image_upload_service.dart'; // 이미지 업로드 서비스 임포트

// ── 1. 내 정보 조회 (초기 로드) ──
final profileProvider = FutureProvider<ProfileModel>((ref) async {
  // 💡 Provider 내부에서는 항상 watch를 사용해 의존성을 주입받습니다.
  return ref.watch(profileRepositoryProvider).getMe();
});

// ── 2. 프로필 이미지 업데이트 상태 관리 ──
class ProfileImageNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileImageNotifier(this._repository, this._ref)
      : super(const AsyncData(null));

  Future<void> updateProfileImage() async {
    state = const AsyncLoading(); // 로딩 상태 시작 (UI에 스피너 표시용)

    try {
      // 1. 갤러리 선택 & 크롭
      final file = await ImageUploadService.pickAndCropImage();
      if (file == null) {
        state = const AsyncData(null); // 사용자가 취소함
        return;
      }

      // 2. 백엔드에 Presigned URL 발급 요청
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final urls = await _repository.getPresignedUrl(fileName);
      if (urls == null) throw Exception('업로드 주소를 받아오지 못했습니다.');

      // 3. 발급받은 주소로 S3에 직접 업로드
      final isUploaded = await ImageUploadService.uploadToS3(
        presignedUrl: urls['upload_url']!,
        imageFile: file,
      );
      if (!isUploaded) throw Exception('S3 이미지 업로드에 실패했습니다.');

      // 4. 백엔드 DB에 새로운 이미지 URL 저장 요청
      await _repository.updateMe(profile_image_url: urls['image_url']);

      // 5. 프로필 화면 데이터 강제 새로고침 (변경된 이미지 즉시 반영)
      _ref.invalidate(profileProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      // print('에러: $e');
      state = AsyncError(e, st);
    }
  }
}

// ── 3. 프로필 이미지 컨트롤러 Provider ──
final profileImageControllerProvider =
    StateNotifierProvider<ProfileImageNotifier, AsyncValue<void>>((ref) {
  return ProfileImageNotifier(ref.watch(profileRepositoryProvider), ref);
});
