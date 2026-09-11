import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'token_storage.dart';
import 'api_exception.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? 'https://dev-service.shop/api/v1',
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
  bool _isRefreshing = false; 
  
  // 토큰 갱신 중 발생하는 401 요청들을 대기시킬 큐(Queue)
  final List<Map<String, dynamic>> _failedRequests = [];

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

  // 401 에러 시 토큰 자동 갱신 및 동시성 처리
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      
      if (_isRefreshing) {
        // 이미 다른 요청이 토큰을 갱신 중이라면, 실패 처리하지 않고 큐에 보관
        _failedRequests.add({'err': err, 'handler': handler});
        return; 
      }

      _isRefreshing = true;
      try {
        // Refresh Token으로 새 Access Token 발급
        final refreshed = await _refreshToken();
        
        if (refreshed) {
          final newToken = await TokenStorage.getAccessToken();

          // 1. 트리거가 된 첫 번째 요청 새 토큰으로 재시도
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);

          // 2. 큐에 대기 중이던 나머지 요청들 일괄 재시도
          for (var req in _failedRequests) {
            final queuedErr = req['err'] as DioException;
            final queuedHandler = req['handler'] as ErrorInterceptorHandler;
            
            queuedErr.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            
            try {
              final queuedResponse = await _dio.fetch(queuedErr.requestOptions);
              queuedHandler.resolve(queuedResponse);
            } catch (e) {
              queuedHandler.next(queuedErr);
            }
          }
        } else {
          // 갱신 실패: 첫 요청 및 큐에 있는 모든 요청 에러 처리
          _rejectAll(err, handler);
        }
      } catch (_) {
        _rejectAll(err, handler);
      } finally {
        // 상태 초기화 및 큐 비우기
        _isRefreshing = false;
        _failedRequests.clear();
      }
      return;
    }
    handler.next(err);
  }

  // 실패 시 일괄 거절 및 로그아웃 처리
  void _rejectAll(DioException err, ErrorInterceptorHandler handler) async {
    handler.next(err);
    for (var req in _failedRequests) {
      (req['handler'] as ErrorInterceptorHandler).next(req['err'] as DioException);
    }
    await TokenStorage.clearTokens();
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
    debugPrint(err.message ?? 'Unknown Error');
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