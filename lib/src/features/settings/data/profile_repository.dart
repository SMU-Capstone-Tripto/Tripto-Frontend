import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/profile_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart' hide handleDioError;

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
      {String? nickname, String? profile_image_url, String? birth}) async {
    try {
      final res = await _dio.patch('/auth/me', data: {
        if (nickname != null) 'nickname': nickname,
        if (birth != null) 'birth': birth,
        if (profile_image_url != null)
          'profile_image_url': profile_image_url, // 프로필 이미지 URL 수정 파라미터 추가
      });
      return ProfileModel.fromJson(res.data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 3. S3 업로드용 Presigned URL 요청 ──
  Future<Map<String, String>?> getPresignedUrl(String fileName) async {
    try {
      final res = await _dio.post('/uploads/presigned-url', data: {
        'content_type': 'image/jpeg',
        'category': 'profile',
      });

      // 💡 디버깅용 로그 추가 (서버 응답 확인)
      print('서버 응답 데이터: ${res.data}');

      final data = res.data;
      if (data == null) return null;

      // 💡 안전하게 형변환 (Null-safe 처리)
      final uploadUrl = data['upload_url']?.toString();
      final imageUrl = data['file_url']?.toString();

      if (uploadUrl == null || imageUrl == null) {
        print('🚨 응답에 upload_url 또는 file_url이 없습니다.');
        return null;
      }

      return {
        'upload_url': uploadUrl,
        'image_url': imageUrl,
      };
    } on DioException catch (e) {
      print('Presigned URL 발급 실패: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  // ── 4. 비밀번호 변경 ──
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String verificationCode,
  }) async {
    try {
      // 💡 백엔드 명세에 따라 URL('/auth/password')과 파라미터 이름을 맞춰주세요.
      await _dio.patch('/auth/password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'verification_code': verificationCode,
      });
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 5. 비밀번호 변경용 인증번호 발송 요청 ──
  Future<void> requestVerificationCode(String email) async {
    try {
      await _dio.post('/auth/email/send-code', data: {
        'email': email,
      });
    } on DioException catch (e) {
      print('🚨 인증번호 발송 에러 상세: ${e.response?.data}');
      throw handleDioError(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ProfileRepository(dio);
});
