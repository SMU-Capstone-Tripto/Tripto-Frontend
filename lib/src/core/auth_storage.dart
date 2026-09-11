import 'package:flutter_dotenv/flutter_dotenv.dart'; // 💡 환경변수 패키지 추가
import 'network/token_storage.dart';

class AuthStorage {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://dev-service.shop/api/v1';
  
  static String? accessToken;
  static String? refreshToken;

  /// 앱 최초 실행 시 또는 자동 로그인 시 기기에 저장된 토큰을 메모리로 복원
  static Future<void> init() async {
    try {
      accessToken = await TokenStorage.getAccessToken();
      refreshToken = await TokenStorage.getRefreshToken();
    } catch (e) {
      // TokenStorage 불러오기 실패 시 예외 처리
      accessToken = null;
      refreshToken = null;
    }
  }

  /// 토큰을 메모리와 기기 저장소(TokenStorage)에 동시에 저장
  static Future<void> setTokens({
    required String access,
    required String refresh,
    String? userId,
  }) async {
    accessToken = access;
    refreshToken = refresh;

    await TokenStorage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      userId: userId ?? '',
    );
  }

  /// 로그아웃 시 메모리와 기기 저장소 모두 초기화
  static Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    await TokenStorage.clearTokens();
  }

  // 인증이 필요한 API를 호출할 때 공통으로 사용할 Bearer 헤더 맵 반환
  static Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (accessToken != null && accessToken!.isNotEmpty) 
        'Authorization': 'Bearer $accessToken',
    };
  }
}