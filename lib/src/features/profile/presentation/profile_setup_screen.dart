import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/cupertino.dart';
=======
import 'package:flutter/cupertino.dart'; 
>>>>>>> origin/chatting
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../travel_style/presentation/travel_style_screen.dart';
<<<<<<< HEAD
import '../../../core/network/auth_storage.dart';
=======
import '../../../../src/core/auth_storage.dart';
>>>>>>> origin/chatting

class ProfileSetupScreen extends StatefulWidget {
  final String email;
  final String password;
  final String verificationCode;
  final String backupEmail;
  final bool isSocial; // 🛠️ 소셜 가입 분기 변수 추가

  const ProfileSetupScreen({
    super.key,
    required this.email,
    required this.password,
    required this.verificationCode,
    required this.backupEmail,
    this.isSocial = false, // 기본값은 일반 회원가입(false)
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  File? _image;
  final picker = ImagePicker();
<<<<<<< HEAD
  bool _isLoading = false;

=======
  bool _isLoading = false; 
  
>>>>>>> origin/chatting
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
<<<<<<< HEAD
    _emailController.text = widget.email;
=======
    _emailController.text = widget.email; 
>>>>>>> origin/chatting
  }

  void _validateInputs() {
    final nickname = _nicknameController.text.trim();
    final birth = _birthController.text.trim();

    setState(() {
      _isButtonEnabled = nickname.isNotEmpty && birth.isNotEmpty;
    });
  }

  /// 프로필 생성 및 정보 수정 종합 트리거 함수
  Future<void> _submitRegistration() async {
    if (!_isButtonEnabled) return;

    setState(() => _isLoading = true);

    final birthTag = 'birth:${_birthController.text.trim()}';
    final List<String> initialTags = [birthTag];

    try {
      if (widget.isSocial) {
        // 🛠️ Case 1: 소셜 로그인 유저는 이미 가입 상태이므로 정보 갱신(PATCH /auth/me) 처리
        final response = await http.patch(
          Uri.parse('${AuthStorage.baseUrl}/auth/me'),
          headers: AuthStorage.authHeaders, // 이미 주입된 Bearer 토큰 인증 헤더 사용
          body: jsonEncode({
            'nickname': _nicknameController.text.trim(),
<<<<<<< HEAD
            'tags': initialTags,
=======
            'tags': initialTags, 
>>>>>>> origin/chatting
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TravelStyleScreen()),
          );
        } else {
          final err = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['detail'] ?? '프로필 저장에 실패했습니다.')),
          );
        }
      } else {
        // Case 2: 로컬 일반 회원가입 유저 플로우 (POST /auth/register)
        final response = await http.post(
          Uri.parse('${AuthStorage.baseUrl}/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email,
            'password': widget.password,
            'nickname': _nicknameController.text.trim(),
            'verification_code': widget.verificationCode,
<<<<<<< HEAD
            'tags': initialTags,
=======
            'tags': initialTags, 
>>>>>>> origin/chatting
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 201) {
          final loginResponse = await http.post(
            Uri.parse('${AuthStorage.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': widget.email,
              'password': widget.password,
            }),
          );

          if (loginResponse.statusCode == 200) {
            final loginData = jsonDecode(loginResponse.body);
            AuthStorage.accessToken = loginData['access_token'];
            AuthStorage.refreshToken = loginData['refresh_token'];
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TravelStyleScreen()),
          );
        } else {
          final err = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['detail'] ?? '회원가입에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 80.0),
<<<<<<< HEAD
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text('사진 삭제',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text('삭제하시겠습니까?', style: TextStyle(fontSize: 14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _image = null);
              },
              child: const Text('삭제',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
=======
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text('사진 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text('삭제하시겠습니까?', style: TextStyle(fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () { Navigator.pop(context); setState(() => _image = null); },
              child: const Text('삭제', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
>>>>>>> origin/chatting
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime(2000, 1, 1);
    DateTime tempDate = initialDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
<<<<<<< HEAD
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
=======
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
>>>>>>> origin/chatting
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
<<<<<<< HEAD
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소',
                          style: TextStyle(color: Colors.grey))),
                  const Text('생년월일 선택',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _birthController.text =
                            "${tempDate.year}년 ${tempDate.month.toString().padLeft(2, '0')}월 ${tempDate.day.toString().padLeft(2, '0')}일";
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('확인',
                        style: TextStyle(
                            color: Color(0xFF6B4FD9),
                            fontWeight: FontWeight.bold)),
=======
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
                  const Text('생년월일 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _birthController.text = "${tempDate.year}년 ${tempDate.month.toString().padLeft(2, '0')}월 ${tempDate.day.toString().padLeft(2, '0')}일";
                      });
                      Navigator.pop(context); 
                    },
                    child: const Text('확인', style: TextStyle(color: Color(0xFF6B4FD9), fontWeight: FontWeight.bold)),
>>>>>>> origin/chatting
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
<<<<<<< HEAD
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4D48AF), Color(0xFFB287FD)])),
=======
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4D48AF), Color(0xFFB287FD)])),
>>>>>>> origin/chatting
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
<<<<<<< HEAD
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 40.0),
=======
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
>>>>>>> origin/chatting
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
<<<<<<< HEAD
                                const Text('프로필 생성',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 40),
                                Center(child: _buildProfileImagePicker()),
                                const SizedBox(height: 40),
                                _buildInputField(
                                    label: '닉네임',
                                    controller: _nicknameController,
                                    hint: '닉네임 입력',
                                    focusNode: _nicknameFocus,
                                    maxLength: 10),
                                const SizedBox(height: 20),
                                _buildInputField(
                                    label: '생년월일',
                                    controller: _birthController,
                                    hint: '날짜 선택',
                                    readOnly: true,
                                    onTap: () => _selectDate(context)),
                                const SizedBox(height: 20),
                                _buildInputField(
                                    label: '이메일',
                                    controller: _emailController,
                                    hint: '',
                                    readOnly: true,
                                    focusNode: _emailFocus),
=======
                                const Text('프로필 생성', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 40),
                                Center(child: _buildProfileImagePicker()),
                                const SizedBox(height: 40),
                                _buildInputField(label: '닉네임', controller: _nicknameController, hint: '닉네임 입력', focusNode: _nicknameFocus, maxLength: 10),
                                const SizedBox(height: 20),
                                _buildInputField(label: '생년월일', controller: _birthController, hint: '날짜 선택', readOnly: true, onTap: () => _selectDate(context)),
                                const SizedBox(height: 20),
                                _buildInputField(label: '이메일', controller: _emailController, hint: '', readOnly: true, focusNode: _emailFocus),
>>>>>>> origin/chatting
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
              if (_isLoading)
<<<<<<< HEAD
                const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
=======
                const Center(child: CircularProgressIndicator(color: Colors.white)),
>>>>>>> origin/chatting
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
<<<<<<< HEAD
            final pickedFile =
                await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null)
              setState(() => _image = File(pickedFile.path));
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              image: _image != null
                  ? DecorationImage(
                      image: FileImage(_image!), fit: BoxFit.cover)
                  : const DecorationImage(
                      image: NetworkImage("https://placehold.co/120x120"),
                      fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
            right: 0,
            bottom: 0,
            child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Color(0xFF404040), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 18))),
        if (_image != null)
          Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                  onTap: _showDeleteConfirmation,
                  child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.redAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 12)))),
=======
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) setState(() => _image = File(pickedFile.path));
          },
          child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, 
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2), 
              image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : const DecorationImage(image: NetworkImage("https://placehold.co/120x120"), fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF404040), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18))),
        if (_image != null)
          Positioned(top: 8, right: 8, child: GestureDetector(onTap: _showDeleteConfirmation, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 12)))),
>>>>>>> origin/chatting
      ],
    );
  }

  Widget _buildInputField({
<<<<<<< HEAD
    required String label,
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
=======
    required String label, required TextEditingController controller, required String hint, FocusNode? focusNode,
    int? maxLength, bool readOnly = false, VoidCallback? onTap, TextInputType keyboardType = TextInputType.text,
>>>>>>> origin/chatting
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
<<<<<<< HEAD
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
=======
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
>>>>>>> origin/chatting
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
<<<<<<< HEAD
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLength: maxLength,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              style: TextStyle(
                  color: readOnly ? Colors.white60 : Colors.white,
                  fontSize: 15),
              decoration: InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  suffix: maxLength != null
                      ? Text('${controller.text.length}/$maxLength',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12))
                      : null),
=======
              color: Colors.white.withOpacity(0.15), 
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)), 
            ),
            child: TextField(
              controller: controller, focusNode: focusNode, maxLength: maxLength, readOnly: readOnly, onTap: onTap, keyboardType: keyboardType,
              style: TextStyle(color: readOnly ? Colors.white60 : Colors.white, fontSize: 15),
              decoration: InputDecoration(counterText: "", border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14), contentPadding: const EdgeInsets.symmetric(vertical: 15), 
                suffix: maxLength != null ? Text('${controller.text.length}/$maxLength', style: const TextStyle(color: Colors.white38, fontSize: 12)) : null),
>>>>>>> origin/chatting
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return _AnimatedScaleButton(
      isEnabled: _isButtonEnabled,
<<<<<<< HEAD
      onPressed: () => _submitRegistration(),
      child: Container(
        width: double.infinity,
        height: 55,
        margin: const EdgeInsets.only(top: 30),
        decoration: BoxDecoration(
          color:
              _isButtonEnabled ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
            child: Text('저장 및 완료',
                style: TextStyle(
                    color: _isButtonEnabled
                        ? const Color(0xFF6B4FD9)
                        : Colors.white60,
                    fontSize: 17,
                    fontWeight: FontWeight.bold))),
=======
      onPressed: () => _submitRegistration(), 
      child: Container(
        width: double.infinity, height: 55, margin: const EdgeInsets.only(top: 30),
        decoration: BoxDecoration(
          color: _isButtonEnabled ? Colors.white : Colors.white.withOpacity(0.3), 
          borderRadius: BorderRadius.circular(15), 
        ),
        child: Center(child: Text('저장 및 완료', style: TextStyle(color: _isButtonEnabled ? const Color(0xFF6B4FD9) : Colors.white60, fontSize: 17, fontWeight: FontWeight.bold))),
>>>>>>> origin/chatting
      ),
    );
  }

  @override
  void dispose() {
<<<<<<< HEAD
    _nicknameController.dispose();
    _birthController.dispose();
    _emailController.dispose();
    _nicknameFocus.dispose();
    _emailFocus.dispose();
=======
    _nicknameController.dispose(); _birthController.dispose(); _emailController.dispose();
    _nicknameFocus.dispose(); _emailFocus.dispose();
>>>>>>> origin/chatting
    super.dispose();
  }
}

class _AnimatedScaleButton extends StatefulWidget {
<<<<<<< HEAD
  final Widget child;
  final VoidCallback onPressed;
  final bool isEnabled;

  const _AnimatedScaleButton(
      {required this.child, required this.onPressed, required this.isEnabled});
  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
=======
  final Widget child; 
  final VoidCallback onPressed; 
  final bool isEnabled;

  const _AnimatedScaleButton({required this.child, required this.onPressed, required this.isEnabled});
  @override State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
>>>>>>> origin/chatting
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => setState(() => _scale = 0.96) : null,
<<<<<<< HEAD
      onTapUp: widget.isEnabled
          ? (_) {
              setState(() => _scale = 1.0);
              widget.onPressed();
            }
          : null,
      onTapCancel: widget.isEnabled ? () => setState(() => _scale = 1.0) : null,
      child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: widget.child),
    );
  }
}
=======
      onTapUp: widget.isEnabled ? (_) { setState(() => _scale = 1.0); widget.onPressed(); } : null,
      onTapCancel: widget.isEnabled ? () => setState(() => _scale = 1.0) : null,
      child: AnimatedScale(scale: _scale, duration: const Duration(milliseconds: 100), child: widget.child),
    );
  }
}
>>>>>>> origin/chatting
