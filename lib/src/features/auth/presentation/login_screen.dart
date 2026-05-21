import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // [추가] kIsWeb(웹 여부 확인) 기능을 쓰기 위해 필요합니다.
import 'signup_screen.dart';
import '../../home/presentation/main_home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// 사용자 로그인 화면 위젯.
class LoginScreen extends StatefulWidget {
  /// [LoginScreen] 생성자.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// LoginScreen 상태 및 입력 로직 제어 클래스.
class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true;
  bool _isIdSaved = false;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainHomeScreen()),
    );
  }

  /// 외부 시스템 브라우저를 개방하여 소셜 로그인 인증을 수행함.
  Future<void> _openSocialLogin(String url) async {
    final Uri uri = Uri.parse(url);
    
    try {
      // [최종 솔루션] 웹이든 모바일이든 무조건 LaunchMode.externalApplication(새 탭/외부 브라우저)으로 엽니다.
      // 이렇게 하면 플러터 웹이 요청을 가로채지 못하므로 무한 로딩이 무조건 깨집니다.
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw '브라우저를 열 수 없습니다.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4E48AF), Color(0xFFB387FE)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  const Center(
                    child: Text(
                      'TRIPTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                  _buildInputField(
                    controller: _idController,
                    label: '아이디 입력',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildInputField(
                    controller: _pwController,
                    label: '비밀번호 입력',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _isObscured,
                    onEyePressed: () =>
                        setState(() => _isObscured = !_isObscured),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildIdSaveCheckbox(),
                  ),
                  const SizedBox(height: 30),
                  _buildActionButton(
                    label: '로그인',
                    onPressed: _goToMain,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTextButton('비밀번호 찾기', () {}),
                      Container(
                        width: 1,
                        height: 12,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      _buildTextButton(
                        '회원가입',
                        () => _navigateTo(const SignupScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  const Center(
                    child: Text(
                      'SNS 계정으로 간편 로그인하세요.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 카카오 로그인 버튼
                      _buildSnsButton(
                        'assets/images/kakao_logo.png',
                        () => _openSocialLogin(
                            'https://kauth.kakao.com/oauth/authorize?client_id=7999cdaddd8a1bc0df49b5c2906dfcf2&redirect_uri=http://localhost:8000/api/v1/auth/kakao/callback&response_type=code'),
                      ),
                      const SizedBox(width: 30),
                      // 구글 로그인 버튼
                      _buildSnsButton(
                        'assets/images/google_logo.png',
                        () => _openSocialLogin(
                            'https://accounts.google.com/o/oauth2/v2/auth?client_id=YOUR_GOOGLE_CLIENT_ID_HERE&redirect_uri=http://localhost:8000/api/v1/auth/google/callback&response_type=code&scope=openid%20email%20profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onEyePressed,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 30),
          Icon(icon, color: Colors.white70, size: 20),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(
                  color: Colors.white.withAlpha(127),
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: onEyePressed,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdSaveCheckbox() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isIdSaved = !_isIdSaved),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _isIdSaved ? Colors.white : Colors.transparent,
                border: Border.all(color: Colors.white.withAlpha(153)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _isIdSaved
                  ? const Icon(Icons.check, size: 14, color: Color(0xFF7145D0))
                  : null,
            ),
            const SizedBox(width: 8),
            const Text(
              '아이디 저장',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7145D0),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildSnsButton(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 55,
        height: 55,
        child: ClipOval(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image, color: Colors.white),
          ),
        ),
      ),
    );
  }
}