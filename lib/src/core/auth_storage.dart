class AuthStorage {
  // 백엔드 기본 API 주소 설정
  static const String baseUrl = 'http://dev-service.shop:8000/api/v1';
  
  // 로그인 및 회원가입 성공 시 발급받은 액세스 토큰을 메모리에 실시간 보관
  static String? accessToken;
  static String? refreshToken;

  // 인증이 필요한 API를 호출할 때 공통으로 사용할 Bearer 헤더 맵 반환
  static Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }
}