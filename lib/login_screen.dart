import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'travel_style_screen.dart';

/// 사용자 로그인을 담당하는 화면 위젯.
///
/// 아이디/비밀번호 입력, 아이디 저장, SNS 로그인 연동 기능을 제공함.
class LoginScreen extends StatefulWidget {
  /// [LoginScreen] 위젯의 생성자.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// [LoginScreen]의 상태 및 UI 로직을 관리하는 클래스.
class _LoginScreenState extends State<LoginScreen> {
  /// 비밀번호 숨김 여부 상태 변수
  bool _isObscured = true;
  /// 아이디 저장 체크박스 상태 변수
  bool _isIdSaved = false;

  /// 아이디 입력란 제어용 컨트롤러
  final TextEditingController _idController = TextEditingController();
  /// 비밀번호 입력란 제어용 컨트롤러
  final TextEditingController _pwController = TextEditingController();

  /// 지정된 페이지로 화면을 전환함.
  ///
  /// - [page]: 이동할 대상 위젯.
  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  /// 로그인 화면의 전체 레이아웃을 빌드함

  /// 배경 그라데이션, 로고, 입력 필드, 로그인 및 SNS 버튼 포함.
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
                    onPressed: () => _navigateTo(const TravelStyleScreen()),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTextButton(
                        '비밀번호 찾기',
                        () => _navigateTo(const NextPage(title: "비밀번호 찾기")),
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
                        () => _navigateTo(const KakaoLoginScreen()),
                      ),
                      const SizedBox(width: 30),
                      _buildSnsButton(
                        'assets/images/google_logo.png',
                        () => _navigateTo(const GoogleLoginScreen()),
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

  /// 공통 텍스트 입력 필드를 생성함.
  ///
  /// - [controller]: 텍스트 제어용 컨트롤러.
  /// - [label]: 힌트 텍스트 문구.
  /// - [icon]: 좌측 표시 아이콘 데이터.
  /// - [isPassword]: 비밀번호 필드 여부.
  /// - [obscureText]: 텍스트 숨김 상태.
  /// - [onEyePressed]: 숨김/보기 아이콘 클릭 시 실행할 함수.
  /// - 반환값: 구성된 입력 필드 위젯.
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
        color: Colors.white.withValues(alpha: 0.2),
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
                  color: Colors.white.withValues(alpha: 0.5),
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

  /// 아이디 저장 상태를 제어하는 체크박스 위젯을 생성함.
  ///
  /// - 반환값: 라벨과 체크박스가 결합된 위젯.
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
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

  /// 강조된 메인 액션 버튼을 생성함.
  ///
  /// - [label]: 버튼에 표시될 텍스트.
  /// - [onPressed]: 버튼 클릭 시 실행할 콜백 함수.
  /// - 반환값: 둥근 모서리의 버튼 위젯.
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

  /// 텍스트 형태의 링크 버튼을 생성함.
  ///
  /// - [label]: 버튼 텍스트 문구.
  /// - [onTap]: 클릭 시 실행할 콜백 함수.
  /// - 반환값: 클릭 영역이 확장된 텍스트 위젯.
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

  /// 원형 형태의 SNS 로그인 버튼을 생성함.
  ///
  /// - [assetPath]: 로고 이미지 파일 경로.
  /// - [onTap]: 클릭 시 실행할 콜백 함수.
  /// - 반환값: 이미지 기반 원형 버튼 위젯.
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

// --- 임시 이동 화면 클래스 정의 ---

/// 카카오 로그인 동작을 시뮬레이션하는 임시 화면.
class KakaoLoginScreen extends StatelessWidget {
  const KakaoLoginScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('카카오 로그인')),
    body: const Center(child: Text('카카오 로그인 화면')),
  );
}

/// 구글 로그인 동작을 시뮬레이션하는 임시 화면.
class GoogleLoginScreen extends StatelessWidget {
  const GoogleLoginScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('구글 로그인')),
    body: const Center(child: Text('구글 로그인 화면')),
  );
}

/// 일반적인 페이지 이동 결과를 보여주는 공용 임시 화면.
class NextPage extends StatelessWidget {
  /// 화면 중앙에 표시될 제목
  final String title;
  /// [NextPage] 위젯의 생성자.
  const NextPage({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text('$title 페이지')),
  );
}