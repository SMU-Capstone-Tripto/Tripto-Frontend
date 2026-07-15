import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/profile_model.dart';
import '../../../core/network/dio_client.dart';
<<<<<<< HEAD
import '../../../core/network/api_exception.dart' hide handleDioError;
=======
import '../../../core/network/api_exception.dart';
>>>>>>> origin/chatting

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
<<<<<<< HEAD
      {String? nickname, String? profile_image_url, String? birth}) async {
    try {
      final res = await _dio.patch('/auth/me', data: {
        if (nickname != null) 'nickname': nickname,
        if (birth != null) 'birth': birth,
=======
      {String? nickname, String? profile_image_url}) async {
    try {
      final res = await _dio.patch('/auth/me', data: {
        if (nickname != null) 'nickname': nickname,
>>>>>>> origin/chatting
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
<<<<<<< HEAD

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
=======
>>>>>>> origin/chatting
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ProfileRepository(dio);
<<<<<<< HEAD
});
=======
});
>>>>>>> origin/chatting
