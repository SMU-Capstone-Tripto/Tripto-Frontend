<<<<<<< HEAD
import 'package:dio/dio.dart';

=======
>>>>>>> origin/chatting
/// API 에러 타입 정의
/// 화면에서 에러 종류에 따라 다른 메시지 표시
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? errorCode;

  const ApiException({
    this.statusCode,
    required this.message,
    this.errorCode,
  });

  // 상태 코드별 메시지 자동 생성
  factory ApiException.fromStatusCode(int statusCode, [String? message]) {
    return switch (statusCode) {
      400 => ApiException(statusCode: 400, message: message ?? '잘못된 요청이에요'),
      401 => ApiException(statusCode: 401, message: '로그인이 필요해요'),
      403 => ApiException(statusCode: 403, message: '권한이 없어요'),
      404 => ApiException(statusCode: 404, message: '정보를 찾을 수 없어요'),
      409 => ApiException(statusCode: 409, message: message ?? '이미 존재하는 정보예요'),
      500 => ApiException(statusCode: 500, message: '서버 오류가 발생했어요'),
      _ =>
        ApiException(statusCode: statusCode, message: message ?? '오류가 발생했어요'),
    };
  }

  // 네트워크 에러
  factory ApiException.network() => const ApiException(
        message: '네트워크 연결을 확인해주세요',
        errorCode: 'ERR_NETWORK',
      );

  // 타임아웃
  factory ApiException.timeout() => const ApiException(
        message: '요청 시간이 초과됐어요',
        errorCode: 'ERR_TIMEOUT',
      );

  @override
  String toString() => 'ApiException($statusCode): $message';
}
<<<<<<< HEAD

// 💡 안전하게 에러 메시지를 추출하는 함수
String extractErrorMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String) {
      return detail;
    } else if (detail is List && detail.isNotEmpty) {
      // 리스트인 경우 첫 번째 에러의 메시지 추출
      return detail.first['msg']?.toString() ?? '잘못된 입력입니다.';
    }
  }
  return '오류가 발생했어요';
}

// 💡 수정된 handleDioError
Exception handleDioError(DioException e) {
  String message = '오류가 발생했어요';

  if (e.response?.data is Map<String, dynamic>) {
    final data = e.response!.data as Map<String, dynamic>;
    final detail = data['detail'];

    if (detail is String) {
      message = detail;
    } else if (detail is List && detail.isNotEmpty) {
      message = detail.first['msg']?.toString() ?? '잘못된 요청입니다.';
    }
  }

  return ApiException.fromStatusCode(e.response?.statusCode ?? 500, message);
}
=======
>>>>>>> origin/chatting
