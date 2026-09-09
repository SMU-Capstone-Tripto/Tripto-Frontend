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

  void _showTermsDetail(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          height: MediaQuery.of(context).size.height * 0.7,
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
              '제 1조 (목적)\n본 약관은 \'벌꿀오소리\' 팀이 제공하는 AI 대화형 여행 일정 생성 플랫폼 \'Tripto\'(이하 \'서비스\')의 이용과 관련하여, 팀과 회원 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.\n\n제 2조 (서비스의 내용 및 AI 면책 조항)\n① 본 서비스는 다자간 채팅 및 AI 에이전트를 활용한 맞춤형 여행 일정 생성 기능을 제공합니다.\n② [중요] 서비스 내 AI 에이전트가 제공하는 여행 일정, 예상 비용, 장소 정보 등은 외부 API 및 데이터를 기반으로 생성된 \'참고용 정보\'입니다.\n③ Tripto는 AI가 제공한 정보의 정확성, 최신성, 완전성을 보증하지 않으며, 현지 사정(영업시간 변경, 가격 변동, 휴무 등)에 따라 실제와 다를 수 있습니다. 이로 인해 발생하는 어떠한 손해에 대해서도 Tripto는 법적 책임을 지지 않습니다.\n\n제 3조 (사용자의 의무)\n① 사용자는 불법적인 목적이나 타인에게 피해를 주는 용도로 본 서비스를 이용할 수 없습니다.\n② 서비스 내 채팅방에서 타인에게 불쾌감을 주거나 욕설, 비방, 음란물 등 부적절한 정보를 전송하는 행위는 엄격히 금지됩니다.\n\n제 4조 (서비스의 변경 및 중단)\n본 서비스는 대학교 캡스톤디자인(졸업프로젝트)의 일환으로 개발 및 운영되므로, 사전 고지 없이 서비스의 일부 또는 전체가 변경, 일시 정지되거나 영구 종료될 수 있습니다.'),
        ),
        
        _buildTermsRow(
          '개인정보 수집 및 이용동의',
          _isPrivacyAgreed,
          (val) => setState(() => _isPrivacyAgreed = val!),
          tag: '필수',
          onDetailPressed: () => _showTermsDetail('개인정보 수집 및 이용동의',
              'Tripto는 원활한 서비스 제공을 위해 아래와 같이 최소한의 개인정보를 수집 및 이용하고 있습니다.\n\n1. 수집하는 개인정보 항목\n- 서비스 이용 과정에서 자동 수집되는 항목: 채팅 내역, AI 에이전트 호출 시 입력한 여행 관련 정보(목적지, 예산, 기간 등), 서비스 이용 기록\n\n2. 개인정보의 수집 및 이용 목적\n- 회원 식별 및 그룹 채팅방 참여 관리\n- 대화 내역을 기반으로 한 AI 맞춤형 여행 일정 생성 및 최적화\n- 서비스 품질 향상 및 신규 기능 개발\n\n3. 개인정보의 보유 및 이용 기간\n- 회원의 개인정보는 회원 탈퇴 시 지체 없이 파기됩니다.\n- 단, 사용자가 채팅방 내에서 메시지를 \'삭제\' 처리할 경우, 해당 메시지 데이터는 데이터베이스에서 즉시 영구 삭제됩니다.\n\n4. 개인정보의 제3자 제공 (AI 모델 활용)\n본 서비스는 맞춤형 여행 일정 생성을 위해 사용자가 챗봇을 호출할 때 입력한 정보를 외부 AI 언어 모델(LLM) API에 전송하여 처리합니다. 해당 정보는 일정 생성을 위한 일회성 목적으로만 전송되며, 외부 AI 모델의 학습용 데이터로는 절대 저장되거나 활용되지 않습니다.'),
        ),
        
        // 💡 마케팅 동의 내용 상세화 반영
        _buildTermsRow(
          '마케팅 활용 동의',
          _isMarketingAgreed,
          (val) => setState(() => _isMarketingAgreed = val!),
          tag: '선택',
          sub: 'Tripto의 혜택 및 추천 알림',
          onDetailPressed: () => _showTermsDetail('마케팅 활용 동의',
              '제 1조 (목적)\n본 약관은 Tripto(이하 \'서비스\')가 사용자에게 최적화된 마케팅 정보 및 혜택을 제공하기 위해 개인정보를 활용하는 것에 대한 제반 사항을 규정합니다.\n\n제 2조 (수집 항목 및 이용 목적)\n① 수집 항목: 이메일 주소, 서비스 이용 기록, 여행 취향 이력\n② 이용 목적:\n- Tripto 신규 서비스, 업데이트 및 이벤트 소식 안내\n- 사용자 맞춤형 여행지 추천 및 큐레이션 서비스 제공\n- 프로모션, 할인 혜택 등 광고성 정보 전달\n- 서비스 이용 통계 분석 및 마케팅 전략 수립\n\n제 3조 (보유 및 이용 기간)\n이용자의 마케팅 활용 동의 시점부터 동의 철회 또는 회원 탈퇴 시까지 해당 정보를 보유 및 이용합니다.\n\n제 4조 (동의 거부권 및 불이익)\n이용자는 본 마케팅 활용 동의를 거부할 권리가 있습니다. 동의를 거부하시더라도 Tripto의 핵심 서비스(여행 일정 생성 및 채팅 등)는 정상적으로 이용하실 수 있으나, 맞춤형 혜택 및 신규 이벤트 안내 등의 제공이 제한될 수 있습니다.'),
        ),
      ],
    );
  }

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
      decoration: isBox
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12))
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDetailPressed,
          borderRadius: BorderRadius.circular(isBox ? 12 : 8),
          child: Padding(
            padding: isBox
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                : const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
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
                GestureDetector(
                  onTap: () => onChanged(!value),
                  child: Container(
                    color: Colors.transparent,
                    width: 32,
                    height: 32,
                    alignment: Alignment.centerRight,
                    child: SizedBox(
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
                  ),
                ),
              ],
            ),
          ),
        ),
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