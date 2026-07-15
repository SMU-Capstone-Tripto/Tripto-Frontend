import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../profile/presentation/profile_setup_screen.dart';
import '../../../core/auth_storage.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 0;
  bool _isServiceAgreed = false;
  bool _isPrivacyAgreed = false;
  bool _isMarketingAgreed = false;
  bool _isEmailSent = false;
  bool _isLoading = false;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  double _buttonScale = 1.0;

  bool _isValidEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W).{8,}$');
    return regex.hasMatch(password);
  }

  bool get _isNextEnabled {
    switch (_currentStep) {
      case 0:
        return _isServiceAgreed && _isPrivacyAgreed;
      case 1:
        return _idController.text.length >= 4 &&
            _isValidEmail(_idController.text.trim());
      case 2:
        return _isValidPassword(_pwController.text) &&
            _pwController.text == _pwConfirmController.text;
      case 3:
        return _isEmailSent && _codeController.text.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/auth/email/send-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _isEmailSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증 코드가 이메일로 발송되었습니다.')),
        );
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['detail'] ?? '코드 발송에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신할 수 없습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
        if (_currentStep == 3) {
          _emailController.text = _idController.text.trim();
        }
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(
            email: _idController.text.trim(),
            password: _pwController.text.trim(),
            verificationCode: _codeController.text.trim(),
            backupEmail: _emailController.text.trim(),
          ),
        ),
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  // 깔끔한 화이트 톤의 약관 상세 바텀 시트
  void _showTermsDetail(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF757575)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFEEEEEE), height: 20, thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 14,
                      height: 1.6,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 5),
                  _buildHeader(),
                  const SizedBox(height: 15),
                  _buildStepIndicator(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 35),
                      child: _buildContentCard(),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 22),
            onPressed: _prevStep,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'TRIPTO',
          style: TextStyle(
            fontSize: 40,
            fontFamily: 'Bakbak One',
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '회원가입을 위해 정보를 입력해주세요',
          style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isActive = index == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 50 : 30,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isActive ? 0.9 : 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    _stepTerms(),
                    _stepInputId(),
                    _stepInputPw(),
                    _stepEmail()
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildAnimatedNextButton(),
        ],
      ),
    );
  }

  // 표준 약관 본문 문구가 적용된 가입 동의 스텝
  Widget _stepTerms() {
    bool isAllAgreed =
        _isServiceAgreed && _isPrivacyAgreed && _isMarketingAgreed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이용약관',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Pretendard')),
        const SizedBox(height: 25),
        _buildTermsRow('전체 동의', isAllAgreed, (val) {
          setState(() {
            _isServiceAgreed = _isPrivacyAgreed = _isMarketingAgreed = val!;
          });
        }, isBox: true),
        const Divider(color: Colors.white24, height: 35),
        _buildTermsRow(
          '서비스 이용동의',
          _isServiceAgreed,
          (val) => setState(() => _isServiceAgreed = val!),
          tag: '필수',
          onDetailPressed: () => _showTermsDetail('서비스 이용동의',
              '제1조 (목적)\n본 약관은 TRIPTO(이하 "회사")가 제공하는 어플리케이션 및 관련 제반 서비스(이하 "서비스")를 이용함에 있어, 회사와 회원 간의 권리, 의무 및 책임사항, 서비스 이용 조건 및 절차 등 기본적인 사항을 규정함을 목적으로 합니다.\n\n제2조 (회사의 의무)\n1. 회사는 본 약관이 정하는 바에 따라 지속적이고 안정적인 서비스를 제공하는 데 최선을 다합니다.\n2. 회사는 서비스 오류나 장애가 발생할 경우 지체 없이 이를 수리 또는 복구합니다.\n\n제3조 (회원의 의무)\n1. 회원은 관계 법령, 본 약관의 규정 및 서비스 이용 안내를 준수하여야 합니다.\n2. 회원은 다음 각 호의 행위를 하여서는 안 됩니다.\n- 신청 또는 변경 시 허위 내용의 등록\n- 타인의 정보 도용\n- 회사가 정한 정보 이외의 정보(컴퓨터 프로그램 등)의 송신 또는 게시\n- 회사 및 기타 제3자의 저작권 등 지적재산권에 대한 침해\n\n제4조 (서비스의 중단 및 면책)\n1. 회사는 컴퓨터 등 정보통신설비의 보수점검, 교체 및 통신두절 등의 고지된 사유가 발생한 경우 서비스 제공을 일시적으로 중단할 수 있습니다.\n2. 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우 회사는 서비스 제공에 관한 책임이 면제됩니다.'),
        ),
        _buildTermsRow(
          '개인정보 수집 및 이용동의',
          _isPrivacyAgreed,
          (val) => setState(() => _isPrivacyAgreed = val!),
          tag: '필수',
          onDetailPressed: () => _showTermsDetail('개인정보 수집 및 이용동의',
              'TRIPTO는 회원가입 및 원활한 서비스 제공을 위해 아래와 같이 최소한의 개인정보를 수집 및 이용합니다.\n\n1. 수집 및 이용 항목\n- 필수항목: 이메일 주소, 비밀번호, 본인인증 코드\n\n2. 수집 및 이용 목적\n- 회원 가입 의사 확인, 서비스 이용에 따른 본인 식별 및 인증, 회원 자격 유지 및 관리, 고지사항 전달, 부정 이용 방지\n\n3. 보유 및 이용 기간\n- 회원의 개인정보는 회원 탈퇴 시까지 보유 및 이용하며, 탈퇴 시 지체 없이 파기합니다.\n- 단, 관계 법령의 규정에 의하여 보존할 필요가 있는 경우 법령에서 정한 일정 기간 동안 회원 정보를 보관합니다.'),
        ),
        _buildTermsRow(
          '마케팅 활용 동의',
          _isMarketingAgreed,
          (val) => setState(() => _isMarketingAgreed = val!),
          tag: '선택',
          sub: '다양한 프로모션에 활용됩니다.',
          onDetailPressed: () => _showTermsDetail('마케팅 활용 동의',
              '1. 수집 및 이용 목적\n- TRIPTO가 제공하는 이벤트 정보, 할인 혜택, 맞춤형 추천 서비스 안내 등 광고성 정보 전송 및 마케팅 활동에 활용됩니다.\n\n2. 수집 항목\n- 이메일 주소\n\n3. 보유 및 이용 기간\n- 마케팅 동의 철회 시 또는 회원 탈퇴 시까지\n\n4. 동의 거부 권리 및 불이익\n- 귀하는 본 마케팅 활용 동의를 거부할 권리가 있습니다. 거부 시에도 서비스 이용은 가능하나, 회사가 제공하는 이벤트 혜택 및 맞춤형 추천 알림 서비스 등의 제한을 받을 수 있습니다.'),
        ),
      ],
    );
  }

  // 터치 영역이 개선되고 화살표 아이콘이 추가된 공통 약관 위젯
  Widget _buildTermsRow(
    String title,
    bool value,
    Function(bool?) onChanged, {
    bool isBox = false,
    String? tag,
    String? sub,
    VoidCallback? onDetailPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: isBox
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : null,
      decoration: isBox
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12))
          : null,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDetailPressed,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: isBox ? 16 : 14,
                                fontWeight:
                                    isBox ? FontWeight.bold : FontWeight.normal,
                                fontFamily: 'Pretendard')),
                        if (sub != null)
                          Text(sub,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontFamily: 'Pretendard')),
                      ],
                    ),
                  ),
                  if (onDetailPressed != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward_ios,
                          color: Colors.white38, size: 14),
                    ),
                ],
              ),
            ),
          ),
          if (tag != null)
            Container(
              margin: const EdgeInsets.only(left: 8, right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4)),
              child: Text(tag,
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontFamily: 'Pretendard')),
            ),
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              side: const BorderSide(color: Colors.white38),
              activeColor: Colors.white,
              checkColor: const Color(0xFF6241D9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepInputId() {
    bool isValid = _isValidEmail(_idController.text.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('아이디(이메일 주소)',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Pretendard')),
        const SizedBox(height: 25),
        _CustomTextField(
            controller: _idController,
            hint: 'example@tripto.com',
            onChanged: (v) => setState(() {})),
        if (_idController.text.isNotEmpty && !isValid)
          const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('올바른 이메일 형식으로 입력해주세요.',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontFamily: 'Pretendard'))),
      ],
    );
  }

  Widget _stepInputPw() {
    bool isPwValid = _isValidPassword(_pwController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('비밀번호',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Pretendard')),
        const SizedBox(height: 12),
        const Text('※ 대문자, 소문자, 특수문자 포함 8자 이상 필수',
            style: TextStyle(
                color: Colors.white70, fontSize: 12, fontFamily: 'Pretendard')),
        const SizedBox(height: 20),
        _CustomTextField(
            controller: _pwController,
            hint: '비밀번호를 입력해주세요',
            isPw: true,
            onChanged: (v) => setState(() {})),
        if (_pwController.text.isNotEmpty && !isPwValid)
          const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('규칙에 맞지 않는 비밀번호입니다.',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontFamily: 'Pretendard'))),
        const SizedBox(height: 15),
        _CustomTextField(
            controller: _pwConfirmController,
            hint: '비밀번호를 확인해주세요',
            isPw: true,
            onChanged: (v) => setState(() {})),
        if (_pwConfirmController.text.isNotEmpty &&
            _pwController.text != _pwConfirmController.text)
          const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('비밀번호가 일치하지 않습니다.',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontFamily: 'Pretendard'))),
      ],
    );
  }

  Widget _stepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이메일 인증',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Pretendard')),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
                child: _CustomTextField(
                    controller: _emailController,
                    hint: '인증받을 이메일 주소',
                    readOnly: true,
                    onChanged: (v) => setState(() {}))),
            const SizedBox(width: 8),
            _smallButton(
                _isEmailSent ? '재전송' : '인증 요청', () => _sendVerificationCode()),
          ],
        ),
        if (_isEmailSent) ...[
          const SizedBox(height: 20),
          const Text('인증번호 입력',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _CustomTextField(
              controller: _codeController,
              hint: '인증번호 6자리 입력',
              onChanged: (v) => setState(() {})),
        ],
      ],
    );
  }

  Widget _smallButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white24,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        child: Text(label,
            style: const TextStyle(
                fontFamily: 'Pretendard', fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAnimatedNextButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _buttonScale = 0.96),
      onTapUp: (_) => setState(() => _buttonScale = 1.0),
      onTapCancel: () => setState(() => _buttonScale = 1.0),
      onTap: _isNextEnabled ? () => _nextStep() : null,
      child: AnimatedScale(
        scale: _buttonScale,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: _isNextEnabled ? 1.0 : 0.5,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: _isNextEnabled
                  ? [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: const Center(
                child: Text('다음 단계로',
                    style: TextStyle(
                        color: Color(0xFF4A34A4),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Pretendard'))),
          ),
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String hint;
  final bool isPw;
  final bool readOnly;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const _CustomTextField(
      {required this.hint,
      this.isPw = false,
      this.readOnly = false,
      this.controller,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: isPw,
        readOnly: readOnly,
        style: TextStyle(
            color: readOnly ? Colors.white60 : Colors.white,
            fontFamily: 'Pretendard'),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Colors.white24, fontSize: 14, fontFamily: 'Pretendard'),
            border: InputBorder.none),
      ),
    );
  }
}
