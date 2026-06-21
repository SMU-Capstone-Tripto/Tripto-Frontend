import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/profile_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';

class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  // ── 1. 내 정보 조회 ──
  Future<ProfileModel> getMe() async {
    try {
      final res = await _dio.get('/auth/me');
      return ProfileModel.fromJson(res.data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 2. 내 정보 수정 (닉네임, 프로필 이미지 URL 등) ──
  Future<ProfileModel> updateMe(
      {String? nikname, String? profile_image_url}) async {
    try {
      final res = await _dio.patch('/auth/me', data: {
        if (nikname != null) 'nikname': nikname,
        if (profile_image_url != null)
          'profile_image_url': profile_image_url, // 프로필 이미지 URL 수정 파라미터 추가
      });
      return ProfileModel.fromJson(res.data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 3. S3 업로드용 Presigned URL 요청 (추가된 부분!) ──
  Future<Map<String, String>?> getPresignedUrl(String fileName) async {
    try {
      // API 주소는 실제 백엔드 명세에 맞춰 수정해 주세요 (예: /images/presigned)
      final res =
          await _dio.post('/images/presigned', data: {'file_name': fileName});
      return {
        'uploadUrl': res.data['upload_url'] as String, // S3에 직접 쏠 PUT 주소
        'imageUrl': res.data['image_url'] as String, // DB에 저장할 최종 이미지 주소
      };
    } on DioException catch (e) {
      print('Presigned URL 발급 실패: ${e.message}');
      return null;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ProfileRepository(dio);
});
