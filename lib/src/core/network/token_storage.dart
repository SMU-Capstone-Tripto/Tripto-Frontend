import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// JWT 토큰을 안전하게 저장/조회
/// flutter_secure_storage → Android Keystore, iOS Keychain 사용
class TokenStorage {
  static const String baseUrl = 'http://dev-service.shop:8000/api/v1';
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  // 저장
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    await _storage.write(key: _userIdKey, value: userId);
  }

  // 조회
  static Future<String?> getAccessToken() async =>
      _storage.read(key: _accessKey);
  static Future<String?> getRefreshToken() async =>
      _storage.read(key: _refreshKey);

  // Access Token만 갱신
  static Future<void> updateAccessToken(String token) async =>
      _storage.write(key: _accessKey, value: token);

  // 로그아웃 시 전체 삭제
  static Future<void> clearTokens() async => _storage.deleteAll();

  // 로그인 여부 확인 (스플래시 화면에서 사용)
  static Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

// Provider
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
