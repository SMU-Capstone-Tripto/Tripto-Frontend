import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../travel_style/presentation/travel_style_screen.dart';

/// 사용자 인적 요건 및 프로필 명세를 결정하는 스크린 객체.
class ProfileSetupScreen extends StatefulWidget {
  /// [ProfileSetupScreen] 생성자.
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

/// ProfileSetupScreen 바인딩 제어 및 이미지 수집 관리 클래스.
class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  /// 바이너리 수집 이미지 개체 파일 포인터
  File? _image;
  /// 미디어 스토리지 접근 디바이스 픽커 장치
  final picker = ImagePicker();
  
  /// 전용 항목 제어 컨트롤러 명세
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  /// 비동기 컴포넌트 이탈 포커싱 제어 노드 객체
  final FocusNode _nicknameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  /// 제출 완료 전용 버튼 개방 트리거 상태 변수
  bool _isButtonEnabled = false;

  /// 컨트롤러 변화 추적을 위한 이벤트 핸들러 리스너 선언 및 할당.
  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_validateInputs);
    _birthController.addListener(_validateInputs);
    _emailController.addListener(_validateInputs);
  }

  /// 수집 데이터의 정합성과 필수 여부를 조건 체크하여 변수 값 결정.
  void _validateInputs() {
    final nickname = _nicknameController.text.trim();
    final birth = _birthController.text.trim();
    final email = _emailController.text.trim();

    bool isEmailValid = email.isEmpty || 
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

    setState(() {
      _isButtonEnabled = nickname.isNotEmpty && birth.isNotEmpty && isEmailValid;
    });
  }

  /// 바이너리 리소스 데이터 해제 처리를 위한 모달창 호출 제어.
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 80.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text('사진 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text('삭제하시겠습니까?', style: TextStyle(fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () { Navigator.pop(context); setState(() => _image = null); },
              child: const Text('삭제', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// 시각화 데이트 스피너 시스템 모달 시트 개방 엔진 구동.
  ///
  /// - [context]: 위젯 트리 위치 메타데이터.
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime(2000, 1, 1);
    DateTime tempDate = initialDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
                  const Text('생년월일 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _birthController.text = "${tempDate.year}년 ${tempDate.month.toString().padLeft(2, '0')}월 ${tempDate.day.toString().padLeft(2, '0')}일";
                      });
                      Navigator.pop(context);
                      _emailFocus.requestFocus(); 
                    },
                    child: const Text('확인', style: TextStyle(color: Color(0xFF6B4FD9), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime date) => tempDate = date,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 프로필 화면의 전체 프레임 컴포넌트 렌더링.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4D48AF), Color(0xFFB287FD)])),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('프로필 생성', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 40),
                            Center(child: _buildProfileImagePicker()),
                            const SizedBox(height: 40),
                            _buildInputField(label: '닉네임', controller: _nicknameController, hint: '닉네임 입력', focusNode: _nicknameFocus, maxLength: 10),
                            const SizedBox(height: 20),
                            _buildInputField(label: '생년월일', controller: _birthController, hint: '날짜 선택', readOnly: true, onTap: () => _selectDate(context)),
                            const SizedBox(height: 20),
                            _buildInputField(label: '이메일 (선택)', controller: _emailController, hint: 'tripto@example.com', focusNode: _emailFocus, keyboardType: TextInputType.emailAddress),
                          ],
                        ),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 미디어 접근 권한 포함 서클 아바타 피커 유닛 모듈 빌드.
  Widget _buildProfileImagePicker() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) setState(() => _image = File(pickedFile.path));
          },
          child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : const DecorationImage(image: NetworkImage("https://placehold.co/120x120"), fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF404040), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18))),
        if (_image != null)
          Positioned(top: 8, right: 8, child: GestureDetector(onTap: _showDeleteConfirmation, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 12)))),
      ],
    );
  }

  /// 다용도 폼 라벨 매핑 인풋 패키지 생성.
  Widget _buildInputField({
    required String label, required TextEditingController controller, required String hint, FocusNode? focusNode,
    int? maxLength, bool readOnly = false, VoidCallback? onTap, TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15), 
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: controller, focusNode: focusNode, maxLength: maxLength, readOnly: readOnly, onTap: onTap, keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(counterText: "", border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14), contentPadding: const EdgeInsets.symmetric(vertical: 15),
                suffix: maxLength != null ? Text('${controller.text.length}/$maxLength', style: const TextStyle(color: Colors.white38, fontSize: 12)) : null),
            ),
          ),
        ),
      ],
    );
  }

  /// 가입 취향 서베이 라우트로 진입 제어하는 메인 하단 버튼 생성.
  Widget _buildSubmitButton() {
    return _AnimatedScaleButton(
      isEnabled: _isButtonEnabled,
      onPressed: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TravelStyleScreen()));
      },
      child: Container(
        width: double.infinity, height: 55, margin: const EdgeInsets.only(top: 30),
        decoration: BoxDecoration(
          color: _isButtonEnabled ? Colors.white : Colors.white.withValues(alpha: 0.3), 
          borderRadius: BorderRadius.circular(15), 
        ),
        child: Center(child: Text('저장 및 완료', style: TextStyle(color: _isButtonEnabled ? const Color(0xFF6B4FD9) : Colors.white60, fontSize: 17, fontWeight: FontWeight.bold))),
      ),
    );
  }

  /// 컨트롤러 자원 역배정 해제 및 메모리 점유 누수 차단.
  @override
  void dispose() {
    _nicknameController.dispose(); _birthController.dispose(); _emailController.dispose();
    _nicknameFocus.dispose(); _emailFocus.dispose();
    super.dispose();
  }
}

/// 탭 상호작용 피드백 축소 연동 특화 상태 애니메이션 컴포넌트 클래스.
class _AnimatedScaleButton extends StatefulWidget {
  final Widget child; 
  final VoidCallback onPressed; 
  final bool isEnabled;

  const _AnimatedScaleButton({required this.child, required this.onPressed, required this.isEnabled});
  @override State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

/// _AnimatedScaleButton 단일 모듈 라이프사이클 뷰 제어 클래스.
class _AnimatedScaleButtonState extends State<_AnimatedScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => setState(() => _scale = 0.96) : null,
      onTapUp: widget.isEnabled ? (_) { setState(() => _scale = 1.0); widget.onPressed(); } : null,
      onTapCancel: widget.isEnabled ? () => setState(() => _scale = 1.0) : null,
      child: AnimatedScale(scale: _scale, duration: const Duration(milliseconds: 100), child: widget.child),
    );
  }
}