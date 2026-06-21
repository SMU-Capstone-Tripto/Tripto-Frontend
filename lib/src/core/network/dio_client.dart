import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_storage.dart';
import 'api_exception.dart';

const _baseUrl = 'http://dev-service.shop:8000/api/v1';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // 인터셉터 등록
    _dio.interceptors.add(_AuthInterceptor(_dio));
    _dio.interceptors.add(_LogInterceptor()); // 개발 중 로그 확인용
  }

  Dio get dio => _dio;
}

// ── JWT 인터셉터 ──
class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false; // 중복 갱신 방지

  _AuthInterceptor(this._dio);

  // 모든 요청에 Access Token 자동 첨부
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // 401 에러 시 토큰 자동 갱신
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        // Refresh Token으로 새 Access Token 발급
        final refreshed = await _refreshToken();
        if (refreshed) {
          // 새 토큰으로 원래 요청 재시도
          final newToken = await TokenStorage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // 갱신 실패 → 로그아웃 처리
        await TokenStorage.clearTokens();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  // 토큰 갱신 요청
  Future<bool> _refreshToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccessToken = response.data['access_token'] as String;
      await TokenStorage.updateAccessToken(newAccessToken);
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ── 로그 인터셉터 (개발용) ──
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('── 요청 ──────────────────');
    debugPrint('${options.method} ${options.path}');
    debugPrint('Body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('── 응답 ${response.statusCode} ──');
    debugPrint('${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('── 에러 ${err.response?.statusCode} ──');
    debugPrint(err.message);
    handler.next(err);
  }
}

// ── DioException → ApiException 변환 헬퍼 ──
ApiException handleDioError(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout =>
      ApiException.timeout(),
    DioExceptionType.connectionError => ApiException.network(),
    DioExceptionType.badResponse => ApiException.fromStatusCode(
        e.response?.statusCode ?? 0,
        e.response?.data?['detail'] as String?,
      ),
    _ => ApiException(message: '알 수 없는 오류가 발생했어요'),
  };
}

// ── Provider ──
final dioClientProvider = Provider<DioClient>((ref) => DioClient());
