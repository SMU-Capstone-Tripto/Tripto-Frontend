import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;

class ImageUploadService {
  static final _picker = ImagePicker();

  /// 갤러리에서 이미지 선택 + 크롭
  static Future<File?> pickAndCropImage() async {
    // 1. 갤러리에서 선택
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;

    // 2. 원형 크롭
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // 정사각형
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '프로필 사진 편집',
          toolbarColor: const Color(0xFF6144B0),
          toolbarWidgetColor: Colors.white,
          cropStyle: CropStyle.circle, // 원형 크롭
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

  /// S3 Presigned URL로 업로드
  /// 백엔드에서 uploadUrl 받아서 이미지 직접 업로드
  static Future<bool> uploadToS3({
    required String presignedUrl,
    required File imageFile,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: bytes,
      );

      // 💡 S3가 반환한 응답 상태 코드와 바디 출력
      // debugPrint('S3 응답 코드: ${response.statusCode}');
      // debugPrint('S3 응답 메시지: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('S3 업로드 실패: $e');
      return false;
    }
  }
}
