import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageUploadService {
  static final _picker = ImagePicker();

  /// 갤러리에서 이미지 선택 + 원형 크롭
  static Future<File?> pickAndCropImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '프로필 사진 편집',
          toolbarColor: const Color(0xFF6144B0),
          toolbarWidgetColor: Colors.white,
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: '프로필 사진 편집',
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    if (cropped == null) return null;
    return File(cropped.path);
  }

  /// S3 Presigned URL로 직접 업로드 (디버깅용 상세 XML 로그 포함)
  static Future<bool> uploadToS3({
    required String presignedUrl,
    required File imageFile,
  }) async {
    try {
      // 🎯 [307 Redirect 방지]: S3 URL 내 글로벌 주소를 서울 리전 주소로 보정
      String targetUrl = presignedUrl;
      if (targetUrl.contains('.s3.amazonaws.com/') &&
          !targetUrl.contains('.s3.ap-northeast-2.amazonaws.com/')) {
        targetUrl = targetUrl.replaceFirst(
          '.s3.amazonaws.com/',
          '.s3.ap-northeast-2.amazonaws.com/',
        );
      }

      final bytes = await imageFile.readAsBytes();

      // S3 전용 독립 Dio 객체 생성 (기존 API 토큰 헤더 중복 방지)
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final response = await dio.put(
        targetUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
          },
          followRedirects: true,
          validateStatus: (status) => true, // 모든 HTTP 응답 상태 코드를 수신하도록 설정
        ),
      );

      // 🔍 S3의 진짜 응답 상태 코드 및 본문(XML) 콘솔 출력
      debugPrint('🔍 [S3 PUT 응답 코드]: ${response.statusCode}');
      if (response.data != null && response.data.toString().isNotEmpty) {
        debugPrint('🔍 [S3 PUT 응답 본문(XML)]: ${response.data}');
      }

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      debugPrint('🚨 [S3 Dio 예외 발생]: ${e.response?.statusCode} - ${e.message}');
      if (e.response != null) {
        debugPrint('🚨 [S3 Dio 응답 본문]: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      debugPrint('🚨 [S3 업로드 일반 예외]: $e');
      return false;
    }
  }
}