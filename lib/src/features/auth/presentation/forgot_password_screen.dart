import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/auth_storage.dart'; // 공통 URL 저장소 경로 연동

/// 사용자 비밀번호 찾기 및 즉시 재설정 시퀀스 위젯.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0; // 0: 이메일 인증, 1: 새 비밀번호 입력
  bool _isEmailSent = false;
  bool _isLoading = false;
  double _buttonScale = 1.0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();

  bool _isValidEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  /// 백엔드 정규식과 매칭되는 대소문자, 숫자, 특수문자(@$!%*?&) 포함 8자 이상 검증 규칙
  bool _isValidPassword(String password) {
    final regex = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return regex.hasMatch(password);
  }

  /// 단계별 하단 액션 버튼 활성화 제어 식
  bool get _isNextEnabled {
    if (_currentStep == 0) {
      return _isEmailSent && _codeController.text.trim().isNotEmpty;
    } else {
      return _isValidPassword(_pwController.text) &&
          _pwController.text == _pwConfirmController.text;
    }
  }

  /// ── [1단계] 이메일 인증 코드 발송 API 연동 (POST /auth/email/send-code) ──
  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/auth/email/send-code'), //
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}), //
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
          SnackBar(content: Text(err['detail'] ?? '인증 코드 발송에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 통신 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ── [2단계] 이메일 인증 번호 검증 API 연동 (POST /auth/email/verify-code) ──
  Future<void> _verifyCodeAndNext() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/auth/email/verify-code'), //
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(), //
          'code': _codeController.text.trim(), //
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _currentStep = 1; // 인증 성공 시 새 비밀번호 입력 단계로 전환
        });
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['detail'] ?? '인증번호가 올바르지 않습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신할 수 없습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ── [3단계] 최종 새 비밀번호 재설정 통신 트리거 (POST /auth/password/reset) ──
  Future<void> _submitPasswordReset() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AuthStorage.baseUrl}/auth/password/reset'), //
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(), //
          'verification_code': _codeController.text.trim(), //
          'new_password': _pwController.text.trim(), //
        }),
      );

      if (!mounted) return;

      // 백엔드가 응답한 실제 상태와 본문을 터미널에 기록
      debugPrint("★ 백엔드 반환 코드: ${response.statusCode}");
      debugPrint("★ 백엔드 반환 본문: ${response.body}");

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['detail'] ?? '비밀번호 변경에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('변경 완료',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
        content: const Text('비밀번호 재설정이 성공적으로 완료되었습니다.\n새로운 비밀번호로 로그인해 주세요.',
            style: TextStyle(fontFamily: 'Pretendard')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 알림창 닫기
              Navigator.pop(context); // 로그인 화면으로 복귀
            },
            child: const Text('확인',
                style: TextStyle(
                    color: Color(0xFF6241D9),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard')),
          ),
        ],
      ),
    );
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
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
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 22),
                          onPressed: _prevStep,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Column(
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
                        '비밀번호 분실 계정의 신규 인증 및 재설정을 진행합니다',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 35),
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
                                child: IndexedStack(
                                  index: _currentStep,
                                  children: [
                                    _stepEmailVerification(),
                                    _stepNewPasswordInput()
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildActionButton(),
                          ],
                        ),
                      ),
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

  /// [0단계 UI] 이메일 입력 및 인증번호 확인 레이아웃
  Widget _stepEmailVerification() {
    bool isValid = _isValidEmail(_emailController.text.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('비밀번호 찾기',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Pretendard')),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _emailController,
                  onChanged: (v) => setState(() {}),
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'Pretendard'),
                  decoration: const InputDecoration(
                    hintText: '가입한 이메일 주소 입력',
                    hintStyle: TextStyle(
                        color: Colors.white24,
                        fontSize: 14,
                        fontFamily: 'Pretendard'),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isValid ? () => _sendVerificationCode() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_isEmailSent ? '재전송' : '전송',
                    style: const TextStyle(
                        fontFamily: 'Pretendard', fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        if (_emailController.text.isNotEmpty &&
            !_isValidEmail(_emailController.text.trim()))
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('이메일 형식에 맞게 입력해주세요.',
                style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontFamily: 'Pretendard')),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _codeController,
              onChanged: (v) => setState(() {}),
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'Pretendard'),
              decoration: const InputDecoration(
                hintText: '인증번호 6자리 입력',
                hintStyle: TextStyle(
                    color: Colors.white24,
                    fontSize: 14,
                    fontFamily: 'Pretendard'),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// [1단계 UI] 새 비밀번호 입력 레이아웃
  Widget _stepNewPasswordInput() {
    bool isPwValid = _isValidPassword(_pwController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('새 비밀번호 설정',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Pretendard')),
        const SizedBox(height: 12),
        const Text('※ 영문 대소문자, 숫자, 특수문자 포함 8자 이상 필수',
            style: TextStyle(
                color: Colors.white60, fontSize: 12, fontFamily: 'Pretendard')),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12)),
          child: TextField(
            controller: _pwController,
            onChanged: (v) => setState(() {}),
            obscureText: true,
            style:
                const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
            decoration: const InputDecoration(
                hintText: '새 비밀번호를 입력해주세요',
                hintStyle: TextStyle(
                    color: Colors.white24,
                    fontSize: 14,
                    fontFamily: 'Pretendard'),
                border: InputBorder.none),
          ),
        ),
        if (_pwController.text.isNotEmpty && !isPwValid)
          const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('대소문자, 숫자, 특수문자를 포함하여 8자 이상 입력해주세요.',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontFamily: 'Pretendard'))),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12)),
          child: TextField(
            controller: _pwConfirmController,
            onChanged: (v) => setState(() {}),
            obscureText: true,
            style:
                const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
            decoration: const InputDecoration(
                hintText: '새 비밀번호를 한 번 더 입력해주세요',
                hintStyle: TextStyle(
                    color: Colors.white24,
                    fontSize: 14,
                    fontFamily: 'Pretendard'),
                border: InputBorder.none),
          ),
        ),
        if (_pwConfirmController.text.isNotEmpty &&
            _pwController.text != _pwConfirmController.text)
          const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('새 비밀번호가 일치하지 않습니다.',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontFamily: 'Pretendard'))),
      ],
    );
  }

  /// 하단 애니메이션 작동 액션 버튼
  Widget _buildActionButton() {
    return GestureDetector(
      onTapDown:
          _isNextEnabled ? (_) => setState(() => _buttonScale = 0.96) : null,
      onTapUp:
          _isNextEnabled ? (_) => setState(() => _buttonScale = 1.0) : null,
      onTapCancel:
          _isNextEnabled ? () => setState(() => _buttonScale = 1.0) : null,
      child: AnimatedScale(
        scale: _buttonScale,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: _isNextEnabled ? 1.0 : 0.5,
          child: ElevatedButton(
            onPressed: _isNextEnabled
                ? (_currentStep == 0
                    ? () => _verifyCodeAndNext()
                    : () => _submitPasswordReset())
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4A34A4),
              minimumSize: const Size(double.infinity, 58),
              elevation: _isNextEnabled ? 4 : 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              _currentStep == 0 ? '인증번호 확인' : '비밀번호 변경 완료',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Pretendard'),
            ),
          ),
        ),
      ),
    );
  }
}
