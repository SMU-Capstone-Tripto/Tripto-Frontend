import 'package:flutter/material.dart';
import '../../profile/presentation/profile_setup_screen.dart';

/// 회원가입 내부 단계를 순차 관리하는 시퀀스 위젯.
class SignupScreen extends StatefulWidget {
  /// [SignupScreen] 생성자.
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

/// SignupScreen 분기 및 정규식 처리 클래스.
class _SignupScreenState extends State<SignupScreen> {
  /// 현재 시퀀스 진행값
  int _currentStep = 0;

  /// 동의 및 검증 제어 플래그 변수
  bool _isServiceAgreed = false;
  bool _isPrivacyAgreed = false;
  bool _isMarketingAgreed = false;
  bool _isEmailSent = false;

  /// 각 단계별 데이터를 수집할 전용 텍스트 필드 제어 장치
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  /// 인터랙션 전용 컴포넌트 배율 제어값
  double _buttonScale = 1.0;

  /// 포맷팅 문자 규격을 통한 타겟 주소 데이터 적합성 검증.
  ///
  /// - [email]: 대상 문자열 주소 정보.
  /// - 반환값: 패스 여부 (bool).
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  /// 활성화 필수 조건 테이블 충족 여부 연산 반환.
  ///
  /// - 반환값: 버튼 개방 판단 여부 플래그 (bool).
  bool get _isNextEnabled {
    switch (_currentStep) {
      case 0: return _isServiceAgreed && _isPrivacyAgreed;
      case 1: return _idController.text.length >= 4;
      case 2: return _pwController.text.length >= 6 && _pwController.text == _pwConfirmController.text;
      case 3: return _isEmailSent && _codeController.text.isNotEmpty;
      default: return false;
    }
  }

  /// 회원가입 하위 다음 단계로 라우팅 제어 또는 최종 완성 화면 교체 전환.
  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
      );
    }
  }

  /// 이전 시퀀스 단계 복귀 처리 및 첫 노출 시 이탈 팝 아웃 수행.
  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  /// 메인 가입 레이아웃 및 폼 프레임워크 빌드.
  ///
  /// - [context]: 빌드 컨텍스트 메타데이터.
  /// - 반환값: 안전 영역 보정 적용 [Scaffold] 위젯.
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
          child: Column(
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
        ),
      ),
    );
  }

  /// 단일 네비게이션 제어 상단 바 영역 생성.
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: _prevStep,
          ),
        ],
      ),
    );
  }

  /// 전면 타이틀 텍스트 조합 객체 생성.
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
          style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Pretendard', fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// 상태 애니메이션 포함 진행 바 래퍼 생성.
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
            color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  /// 동적 인덱스 스택 바인딩 카드 베이스 레이어 구현.
  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: IndexedStack(
                index: _currentStep,
                children: [ _stepTerms(), _stepInputId(), _stepInputPw(), _stepEmail() ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildAnimatedNextButton(),
        ],
      ),
    );
  }

  /// 시퀀스 0단계 약관 동의 뷰 조립.
  Widget _stepTerms() {
    bool isAllAgreed = _isServiceAgreed && _isPrivacyAgreed && _isMarketingAgreed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이용약관', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Pretendard')),
        const SizedBox(height: 25),
        _buildTermsRow('전체 동의', isAllAgreed, (val) {
          setState(() { _isServiceAgreed = _isPrivacyAgreed = _isMarketingAgreed = val!; });
        }, isBox: true),
        const Divider(color: Colors.white24, height: 35),
        _buildTermsRow('서비스 이용동의', _isServiceAgreed, (val) => setState(() => _isServiceAgreed = val!), tag: '필수'),
        _buildTermsRow('개인정보 수집 및 이용동의', _isPrivacyAgreed, (val) => setState(() => _isPrivacyAgreed = val!), tag: '필수'),
        _buildTermsRow('마케팅 활용 동의', _isMarketingAgreed, (val) => setState(() => _isMarketingAgreed = val!), tag: '선택', sub: '다양한 프로모션에 활용됩니다.'),
      ],
    );
  }

  /// 약관 로우 컴포넌트 단위 생성 빌더.
  ///
  /// - [title]: 동의 라벨명.
  /// - [value]: 연동 체크박스 상태 데이터 변수.
  /// - [onChanged]: 값 변경 스위칭 감지 핸들러 콜백 함수.
  /// - [isBox]: 전용 테두리 수용 박스 활성화 여부.
  /// - [tag]: 노출 조건 태그 명칭.
  /// - [sub]: 서브 하단 부가 해설 문구.
  Widget _buildTermsRow(String title, bool value, Function(bool?) onChanged, {bool isBox = false, String? tag, String? sub}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: isBox ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12) : null,
      decoration: isBox ? BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontSize: isBox ? 16 : 14, fontWeight: isBox ? FontWeight.bold : FontWeight.normal, fontFamily: 'Pretendard')),
                if (sub != null) Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Pretendard')),
              ],
            ),
          ),
          if (tag != null)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
              child: Text(tag, style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Pretendard')),
            ),
          SizedBox(
            width: 24, height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              side: const BorderSide(color: Colors.white38),
              activeColor: Colors.white,
              checkColor: const Color(0xFF6241D9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  /// 시퀀스 1단계 유저 식별자 인풋 폼 세트 생성.
  Widget _stepInputId() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('아이디', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Pretendard')),
        const SizedBox(height: 25),
        _CustomTextField(controller: _idController, hint: '아이디를 입력해주세요', onChanged: (v) => setState(() {})),
        if (_idController.text.isNotEmpty && _idController.text.length < 4)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('4자 이상 입력해주세요.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontFamily: 'Pretendard'))),
      ],
    );
  }

  /// 시퀀스 2단계 인증 암호 구조 수립 폼 레이아웃 조립.
  Widget _stepInputPw() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('비밀번호', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Pretendard')),
        const SizedBox(height: 25),
        _CustomTextField(controller: _pwController, hint: '비밀번호를 입력해주세요', isPw: true, onChanged: (v) => setState(() {})),
        if (_pwController.text.isNotEmpty && _pwController.text.length < 6)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('비밀번호는 6자리 이상 입력해주세요.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontFamily: 'Pretendard'))),
        const SizedBox(height: 15),
        _CustomTextField(controller: _pwConfirmController, hint: '비밀번호를 확인해주세요', isPw: true, onChanged: (v) => setState(() {})),
        if (_pwConfirmController.text.isNotEmpty && _pwController.text != _pwConfirmController.text)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('비밀번호가 일치하지 않습니다.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontFamily: 'Pretendard'))),
      ],
    );
  }

  /// 시퀀스 3단계 연락처 이메일 발송 검증 제어 영역 빌드.
  Widget _stepEmail() {
    bool isValid = _isValidEmail(_emailController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이메일 인증', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Pretendard')),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(child: _CustomTextField(controller: _emailController, hint: '이메일을 입력해주세요', onChanged: (v) => setState(() {}))),
            const SizedBox(width: 8),
            _smallButton(_isEmailSent ? '재전송' : '전송', () {
              if (isValid) setState(() => _isEmailSent = true);
            }),
          ],
        ),
        if (_emailController.text.isNotEmpty && !isValid)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('이메일 형식에 맞게 입력해주세요.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontFamily: 'Pretendard'))),
        if (_isEmailSent) ...[
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('인증번호가 발송되었습니다.', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Pretendard'))),
          _CustomTextField(controller: _codeController, hint: '인증번호를 입력해주세요', onChanged: (v) => setState(() {})),
        ],
      ],
    );
  }

  /// 부가 액션 전용 소형 고정 스퀘어 버튼 컴포넌트 빌드.
  ///
  /// - [label]: 버튼 바인딩용 스트링 문자 정보.
  /// - [onPressed]: 호출 대상 제어 로직.
  Widget _smallButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(label, style: const TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// 배율 물리 스케일 연동 조건부 개방 진행 버튼 객체 생성.
  Widget _buildAnimatedNextButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _buttonScale = 0.96),
      onTapUp: (_) => setState(() => _buttonScale = 1.0),
      onTapCancel: () => setState(() => _buttonScale = 1.0),
      onTap: _isNextEnabled ? _nextStep : null,
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
              boxShadow: _isNextEnabled ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))] : [],
            ),
            child: Center(
              child: Text(
                _currentStep == 3 ? '가입 완료' : '다음 단계로', 
                style: const TextStyle(color: Color(0xFF4A34A4), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Pretendard')
              )
            ),
          ),
        ),
      ),
    );
  }
}

/// 공용 특화 커스텀 텍스트 인풋 위젯 정의.
class _CustomTextField extends StatelessWidget {
  /// 수용 힌트 구문 정보 명칭
  final String hint;
  /// 암호화 보안 속성 플래그 변수
  final bool isPw;
  /// 연동 전용 제어 컨트롤러
  final TextEditingController? controller;
  /// 내부 문자 변경 탐지 실행 함수 콜백
  final Function(String)? onChanged;

  /// [_CustomTextField] 생성자.
  const _CustomTextField({required this.hint, this.isPw = false, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: isPw,
        style: const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 14, fontFamily: 'Pretendard'), border: InputBorder.none),
      ),
    );
  }
}