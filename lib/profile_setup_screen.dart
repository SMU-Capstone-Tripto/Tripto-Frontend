import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'travel_style_screen.dart';

/// 사용자 프로필 정보를 설정하는 화면 위젯.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

/// [ProfileSetupScreen]의 상태 및 입력 로직 관리 클래스.
class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  File? _image;
  final picker = ImagePicker();
  
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _nicknameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_validateInputs);
    _birthController.addListener(_validateInputs);
    _emailController.addListener(_validateInputs);
  }

  /// 모든 필수 입력값의 유효성을 검사함.
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

  /// 프로필 사진 삭제 확인 팝업을 표시함.
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 80.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // 팝업창도 부드럽게
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

  /// 휠 스피너 방식의 날짜 선택기를 호출함.
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
                      Navigator.pop(context); // 현재 모달창 닫기
                      
                      // ✨ 포커스 버그 해결: 노드에 직접 포커스 요청
                      // 팝업이 닫힌 후 안전하게 다음 입력창으로 커서를 옮김
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

  /// 프로필 사진 선택 위젯을 생성함.
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

  /// 부드러운 네모 상자 스타일의 입력 필드를 생성함.
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
              borderRadius: BorderRadius.circular(15), // ✨ 부드러운 네모로 변경
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

  /// 선호 스타일 조사 화면으로 이동하는 완료 버튼을 생성함.
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
          borderRadius: BorderRadius.circular(15), // ✨ 버튼도 부드러운 네모로 변경
        ),
        child: Center(child: Text('저장 및 완료', style: TextStyle(color: _isButtonEnabled ? const Color(0xFF6B4FD9) : Colors.white60, fontSize: 17, fontWeight: FontWeight.bold))),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose(); _birthController.dispose(); _emailController.dispose();
    _nicknameFocus.dispose(); _emailFocus.dispose();
    super.dispose();
  }
}

/// 클릭 시 크기 애니메이션이 적용된 버튼 위젯.
class _AnimatedScaleButton extends StatefulWidget {
  final Widget child; final VoidCallback onPressed; final bool isEnabled;
  const _AnimatedScaleButton({required this.child, required this.onPressed, required this.isEnabled});
  @override State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

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