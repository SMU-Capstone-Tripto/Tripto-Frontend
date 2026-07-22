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

  // ── 2. 내 정보 수정 (백엔드 UserUpdateRequest와 키값 일치) ──
  Future<ProfileModel> updateMe({
    String? nickname,
    String? profileImage,
    List<String>? tags,
  }) async {
    try {
      final res = await _dio.patch('/auth/me', data: {
        if (nickname != null) 'nickname': nickname,
        if (profileImage != null) 'profile_image': profileImage,
        if (tags != null) 'tags': tags,
      });
      return ProfileModel.fromJson(res.data);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 3. S3 Presigned URL 요청 (백엔드 s3_service.py 및 uploads.py 명세 반영) ──
  Future<Map<String, String>?> getPresignedUrl({
    String contentType = 'image/jpeg',
    String category = 'profile',
  }) async {
    try {
      final res = await _dio.post(
        '/uploads/presigned-url',
        data: {
          'content_type': contentType,
          'category': category,
        },
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(res.data);

      // 백엔드 s3_service.py의 반환 키: 'upload_url', 'file_url'
      final String uploadUrl = (data['upload_url'] ?? '').toString();
      final String imageUrl = (data['file_url'] ?? data['image_url'] ?? '').toString();

      return {
        'uploadUrl': uploadUrl,
        'imageUrl': imageUrl,
      };
    } on DioException catch (e) {
      print('Presigned URL 발급 실패: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  // ── 4. 비밀번호 변경 (로그인 상태) ──
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String verificationCode,
  }) async {
    try {
      await _dio.patch('/auth/password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'verification_code': verificationCode,
      });
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── 5. 이메일 인증번호 발송 요청 ──
  Future<void> requestVerificationCode(String email) async {
    try {
      await _dio.post('/auth/email/send-code', data: {
        'email': email,
      });
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ProfileRepository(dio);
});