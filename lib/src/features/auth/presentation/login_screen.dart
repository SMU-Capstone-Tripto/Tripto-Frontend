import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

import '../../../core/auth_storage.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isObscured = true;
  bool _isIdSaved = false;
  bool _isAutoLogin = false; // 💡 자동 로그인 체크 상태 추가
  bool _isLoading = false;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAuthAndLoadSavedId();
  }

  Future<void> _initializeAuthAndLoadSavedId() async {
    try {
      await AuthStorage.init();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();

    // 1. [자동 로그인 여부 확인]
    final isAutoLoginEnabled = prefs.getBool('tripto_auto_login') ?? false;

    // 2. [아이디 저장 복원]
    final savedId = prefs.getString('tripto_saved_login_id') ?? '';

    if (mounted) {
      setState(() {
        if (savedId.isNotEmpty) {
          _idController.text = savedId;
          _isIdSaved = true;
        }
        _isAutoLogin = isAutoLoginEnabled;
      });
    }

    // 3. [자동 로그인 처리] 사용자가 '자동 로그인'을 켰고, 토큰이 유효할 때만 홈으로 스킵!
    if (isAutoLoginEnabled && (AuthStorage.accessToken?.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToMain();
      });
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void _goToMain() {
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> syncFcmTokenAfterLogin(WidgetRef ref) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        final response = await http.patch(
          Uri.parse('${AuthStorage.baseUrl}/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AuthStorage.accessToken}',
          },
          body: jsonEncode({'fcm_token': fcmToken}),
        );

        if (response.statusCode == 200) {
          debugPrint('🟢 로그인 후 FCM 토큰 서버 동기화 완료');
        } else {
          debugPrint('⚠️ FCM 토큰 서버 동기화 실패: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ FCM 토큰 동기화 에러: $e');
    }
  }

  Future<void> _handleLocalLogin() async {
    final email = _idController.text.trim();
    final password = _pwController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해 주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final String accessToken = responseData['access_token'] ?? '';
        final String refreshToken = responseData['refresh_token'] ?? '';
        final String userId = responseData['user_id']?.toString() ?? '';

        await AuthStorage.setTokens(
          access: accessToken,
          refresh: refreshToken,
          userId: userId,
        );

        // 💡 [아이디 및 자동 로그인 상태 저장]
        final prefs = await SharedPreferences.getInstance();

        // 아이디 저장 체크 시 이메일 보관
        if (_isIdSaved) {
          await prefs.setString('tripto_saved_login_id', email);
        } else {
          await prefs.remove('tripto_saved_login_id');
        }

        // 자동 로그인 체크 여부 보관
        await prefs.setBool('tripto_auto_login', _isAutoLogin);

        await syncFcmTokenAfterLogin(ref);

        _goToMain();
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['detail'] ?? '로그인 정보가 일치하지 않습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 통신 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openSocialLogin(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SocialLoginWebView(
          initialUrl: url,
          onTokenReceived:
              (accessToken, refreshToken, email, isProfileComplete) async {
            await AuthStorage.setTokens(
              access: accessToken,
              refresh: refreshToken,
              userId: email,
            );

            // 소셜 로그인은 기본적으로 자동 로그인을 켬
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('tripto_auto_login', true);

            if (mounted) {
              if (isProfileComplete) {
                _goToMain();
              } else {
                context.go('/profile-setup', extra: {
                  'email': email,
                  'password': '',
                  'verificationCode': '',
                  'backupEmail': '',
                  'isSocial': true,
                });
              }
            }
          },
        ),
      ),
    );
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
          child: Stack(
            children: [
              SingleChildScrollView(
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
                        label: '아이디(이메일) 입력',
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

                      // 💡 아이디 저장 & 자동 로그인 체크박스
                      Row(
                        children: [
                          _buildCheckbox(
                            label: '아이디 저장',
                            isChecked: _isIdSaved,
                            onTap: () =>
                                setState(() => _isIdSaved = !_isIdSaved),
                          ),
                          const SizedBox(width: 24),
                          _buildCheckbox(
                            label: '자동 로그인',
                            isChecked: _isAutoLogin,
                            onTap: () =>
                                setState(() => _isAutoLogin = !_isAutoLogin),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      _buildActionButton(
                        label: '로그인',
                        onPressed: _handleLocalLogin,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTextButton(
                            '비밀번호 찾기',
                            () => _navigateTo(const ForgotPasswordScreen()),
                          ),
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
                          _buildSnsButton(
                            'assets/images/kakao_logo.png',
                            () => _openSocialLogin(
                                '${AuthStorage.baseUrl}/auth/kakao/login'),
                          ),
                          const SizedBox(width: 30),
                          _buildSnsButton(
                            'assets/images/google_logo.png',
                            () => _openSocialLogin(
                                '${AuthStorage.baseUrl}/auth/google/login'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
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
        color: Colors.white.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.5),
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

  // 💡 체크박스를 재사용 가능하게 분리한 위젯
  Widget _buildCheckbox({
    required String label,
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? Colors.white : Colors.transparent,
                border: Border.all(color: Colors.white.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 14, color: Color(0xFF7145D0))
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
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

class SocialLoginWebView extends StatefulWidget {
  final String initialUrl;
  final Function(String accessToken, String refreshToken, String email,
      bool isProfileComplete) onTokenReceived;

  const SocialLoginWebView({
    super.key,
    required this.initialUrl,
    required this.onTokenReceived,
  });

  @override
  State<SocialLoginWebView> createState() => _SocialLoginWebViewState();
}

class _SocialLoginWebViewState extends State<SocialLoginWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) async {
            setState(() => _isLoading = false);

            if (url.contains('/auth/kakao/callback') ||
                url.contains('/auth/google/callback')) {
              try {
                final String rawHtml = await _controller
                        .runJavaScriptReturningResult("document.body.innerText")
                    as String;

                String cleanJson = rawHtml.trim();
                if (cleanJson.startsWith('"') && cleanJson.endsWith('"')) {
                  cleanJson = cleanJson.substring(1, cleanJson.length - 1);
                }
                cleanJson =
                    cleanJson.replaceAll('\\"', '"').replaceAll('\\\\', '\\');

                final Map<String, dynamic> tokenData = jsonDecode(cleanJson);
                final String? accessToken = tokenData['access_token'];
                final String? refreshToken = tokenData['refresh_token'];

                if (accessToken != null && refreshToken != null) {
                  final userRes = await http.get(
                    Uri.parse('${AuthStorage.baseUrl}/auth/me'),
                    headers: {'Authorization': 'Bearer $accessToken'},
                  );

                  String userEmail = '';
                  bool isProfileComplete = false;

                  if (userRes.statusCode == 200) {
                    final userData = jsonDecode(userRes.body);
                    userEmail = userData['email'] ?? '';
                    String nickname = userData['nickname'] ?? '';

                    if (nickname.isNotEmpty && !nickname.startsWith('카카오유저')) {
                      isProfileComplete = true;
                    }
                  }

                  if (mounted) Navigator.pop(context);
                  widget.onTokenReceived(
                      accessToken, refreshToken, userEmail, isProfileComplete);
                }
              } catch (e) {
                debugPrint("웹뷰 내부 토큰 데이터 파싱 실패 에러: $e");
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소셜 로그인',
            style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF8055FF)),
            ),
        ],
      ),
    );
  }
}
