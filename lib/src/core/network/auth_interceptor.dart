import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage storage;

  AuthInterceptor(this.dio, {this.storage = const FlutterSecureStorage()});

  // ── 1. 요청(Request)을 보낼 때 ──
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // 저장소에서 Access Token 꺼내기
    final accessToken = await storage.read(key: 'ACCESS_TOKEN');

    // 토큰이 존재하면 헤더에 Authorization 추가
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // 다음 단계로 패스
    return handler.next(options);
  }

  // ── 2. 에러(Error)가 발생했을 때 ──
  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    // 401 Unauthorized 에러 (토큰 만료 또는 인증 실패)
    if (err.response?.statusCode == 401) {
      print('🚨 401 권한 에러: 토큰이 만료되었거나 유효하지 않습니다.');

      // TODO: 백엔드에 Refresh Token을 보내서 새로운 Access Token을 발급받는 로직 추가
      // 갱신에 실패하면 저장된 토큰을 지우고 로그인 화면으로 강제 이동(Logout) 처리
    }

    return handler.next(err);
  }
}
